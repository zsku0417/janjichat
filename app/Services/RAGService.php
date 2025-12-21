<?php

namespace App\Services;

use App\Models\DocumentChunk;
use App\Models\Conversation;
use App\Models\MerchantSetting;
use App\Models\RestaurantSetting;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RAGService
{
    protected OpenAIService $openAI;
    protected float $confidenceThreshold;

    public function __construct(OpenAIService $openAI)
    {
        $this->openAI = $openAI;
        $this->confidenceThreshold = config('openai.confidence_threshold', 0.2);
    }

    /**
     * Search the knowledge base for relevant content.
     * Filters by user_id to ensure multi-tenancy (each merchant sees only their own documents).
     *
     * @param string $query
     * @param int|null $userId The merchant's user ID to filter documents
     * @param int $limit
     * @return Collection
     */
    public function search(string $query, ?int $userId = null, int $limit = 5): Collection
    {
        // Generate embedding for the query
        $queryEmbedding = $this->openAI->createEmbedding($query);
        $embeddingString = '[' . implode(',', $queryEmbedding) . ']';

        // Build query with optional user_id filter for multi-tenancy
        if ($userId) {
            // Filter by merchant's documents only
            $results = DB::select("
                SELECT 
                    dc.id,
                    dc.document_id,
                    dc.content,
                    dc.chunk_index,
                    d.original_name as document_name,
                    1 - (dc.embedding <=> ?::vector) as similarity
                FROM document_chunks dc
                JOIN documents d ON d.id = dc.document_id
                WHERE d.status = 'completed'
                AND d.user_id = ?
                ORDER BY dc.embedding <=> ?::vector
                LIMIT ?
            ", [$embeddingString, $userId, $embeddingString, $limit]);
        } else {
            // No user filter (backward compatibility, though not recommended)
            $results = DB::select("
                SELECT 
                    dc.id,
                    dc.document_id,
                    dc.content,
                    dc.chunk_index,
                    d.original_name as document_name,
                    1 - (dc.embedding <=> ?::vector) as similarity
                FROM document_chunks dc
                JOIN documents d ON d.id = dc.document_id
                WHERE d.status = 'completed'
                ORDER BY dc.embedding <=> ?::vector
                LIMIT ?
            ", [$embeddingString, $embeddingString, $limit]);
        }

        return collect($results);
    }

    /**
     * Generate a response using RAG (Retrieval Augmented Generation).
     * The AI can answer from both the knowledge base AND conversation history.
     *
     * @param string $query
     * @param Conversation $conversation
     * @param string $businessType The business type ('restaurant' or 'order_tracking')
     * @return array ['response' => string|null, 'confident' => bool, 'reason' => string|null]
     */
    public function generateResponse(string $query, Conversation $conversation, string $businessType = 'restaurant'): array
    {
        // Get merchant ID for filtering documents (multi-tenancy)
        $merchantId = $conversation->user_id;

        // Step 1: Search knowledge base for relevant documents (filtered by merchant)
        $searchResults = $this->search($query, $merchantId);
        $topScore = $searchResults->first()?->similarity ?? 0;

        // Step 2: Build context from knowledge base (even if low score, include what we found)
        $knowledgeContext = "";
        if ($topScore >= $this->confidenceThreshold) {
            $knowledgeContext = $this->buildContext($searchResults);
        } else {
            $knowledgeContext = "No highly relevant documents found in knowledge base.";
            Log::info('RAG: Low knowledge base match, will rely on conversation context', [
                'query' => $query,
                'top_score' => $topScore,
            ]);
        }

        // Step 3: Get conversation history - this is ALWAYS included
        $conversationHistory = $this->getConversationHistory($conversation);

        // Step 4: Generate response with AI - it can answer from EITHER source
        return $this->generateWithConfidence($query, $knowledgeContext, $conversationHistory, $conversation, $businessType);
    }

    /**
     * Build context string from search results.
     */
    protected function buildContext(Collection $results): string
    {
        $context = "Relevant information from knowledge base:\n\n";

        foreach ($results as $index => $result) {
            if ($result->similarity >= $this->confidenceThreshold) {
                $context .= "--- Source: {$result->document_name} ---\n";
                $context .= $result->content . "\n\n";
            }
        }

        return $context;
    }

    /**
     * Get formatted conversation history.
     */
    protected function getConversationHistory(Conversation $conversation): array
    {
        $messages = $conversation->messages()
            ->where('message_type', 'text')
            ->orderBy('created_at', 'asc')
            ->take(20) // Last 20 messages for context
            ->get();

        $history = [];
        foreach ($messages as $message) {
            $role = $message->isInbound() ? 'user' : 'assistant';
            $history[] = [
                'role' => $role,
                'content' => $message->content,
            ];
        }

        return $history;
    }

    /**
     * Generate response with confidence self-evaluation.
     */
    protected function generateWithConfidence(
        string $query,
        string $context,
        array $conversationHistory,
        Conversation $conversation,
        string $businessType = 'restaurant'
    ): array {
        $systemPrompt = $this->buildSystemPrompt($context, $businessType, $conversation);

        // Add the current query to history
        $conversationHistory[] = [
            'role' => 'user',
            'content' => $query,
        ];

        // Ask AI to respond with confidence evaluation
        $evaluationPrompt = $systemPrompt . "\n\n" .
            "CRITICAL LANGUAGE RULE (MUST FOLLOW FIRST):\n" .
            "STEP 1: Detect the language of the customer's CURRENT query below.\n" .
            "STEP 2: Your response MUST be written ENTIRELY in that same language.\n" .
            "Examples: 'What time?' = English reply | '几点?' = Chinese reply | 'Pukul berapa?' = Malay reply\n" .
            "DO NOT DEFAULT TO CHINESE. If the customer writes in ENGLISH, reply in ENGLISH.\n\n" .
            "CONFIDENCE RULE:\n" .
            "You can be confident if you can answer from EITHER:\n" .
            "- The conversation history (what the customer told you earlier in this chat)\n" .
            "- The knowledge base context\n\n" .
            "If the customer asks about something THEY mentioned earlier (their name, where they're from, their preferences, etc.), " .
            "you should be confident and answer based on the conversation history.\n\n" .
            "Only indicate low confidence if the information is not in either source.\n\n" .
            "Respond in JSON format:\n" .
            "{\n" .
            "  \"detected_language\": \"The language of the customer's message (english/chinese/malay/other)\",\n" .
            "  \"response\": \"Your response written ENTIRELY in the detected_language\",\n" .
            "  \"confident\": true/false,\n" .
            "  \"reason\": \"If not confident, explain why in 1-2 sentences\"\n" .
            "}";

        try {
            $result = $this->openAI->chatJson($conversationHistory, $evaluationPrompt);

            $confident = $result['confident'] ?? false;
            $response = $result['response'] ?? null;
            $reason = $result['reason'] ?? null;

            if (!$confident || empty($response)) {
                Log::info('RAG: AI not confident in response', [
                    'query' => $query,
                    'reason' => $reason,
                ]);

                return [
                    'response' => null,
                    'confident' => false,
                    'reason' => $reason ?? 'The AI was not confident enough to provide a response.',
                ];
            }

            return [
                'response' => $response,
                'confident' => true,
                'reason' => null,
            ];

        } catch (\Exception $e) {
            Log::error('RAG: Failed to generate response', [
                'error' => $e->getMessage(),
            ]);

            return [
                'response' => null,
                'confident' => false,
                'reason' => 'An error occurred while generating the response.',
            ];
        }
    }

    /**
     * Build the system prompt for the AI based on business type.
     * For order_tracking, includes the merchant's product catalog.
     */
    protected function buildSystemPrompt(string $context, string $businessType = 'restaurant', ?Conversation $conversation = null): string
    {
        $settings = RestaurantSetting::getInstance();

        // Get merchant from conversation (preferred) or fallback to first merchant
        $merchant = $conversation?->user ?? User::where('role', User::ROLE_MERCHANT)->first();
        $merchantSettings = $merchant ? MerchantSetting::where('user_id', $merchant->id)->first() : null;

        $tone = $merchantSettings?->ai_tone ?? 'You are a friendly and professional assistant.';
        $businessName = $merchantSettings?->business_name ?? 'Our Business';
        $openingTime = $settings?->formatted_opening_time ?? '10:00 AM';
        $closingTime = $settings?->formatted_closing_time ?? '10:00 PM';
        $operatingHours = "{$openingTime} - {$closingTime}";

        // Get business-specific configuration
        $config = $this->getBusinessConfig($businessType);

        // Build product catalog for order_tracking businesses
        $productCatalog = '';
        if ($businessType === 'order_tracking' && $merchant) {
            $products = $merchant->products()->active()->get();
            if ($products->isNotEmpty()) {
                $productCatalog = "\n\nPRODUCT CATALOG (Available Products):\n";
                foreach ($products as $product) {
                    $productCatalog .= "• {$product->name} - RM" . number_format((float) $product->price, 2);
                    if ($product->description) {
                        $productCatalog .= " - {$product->description}";
                    }
                    $productCatalog .= "\n";
                }
                $productCatalog .= "\nWhen customers ask about products, use this catalog to answer. You can suggest products based on their preferences.";
            }
        }

        return <<<PROMPT
{$tone}

You are an AI assistant for {$businessName}. Your role is to help customers with:
1. {$config['role1']}
2. {$config['role2']}
3. {$config['role3']}

Operating Hours: {$operatingHours}
{$productCatalog}

KNOWLEDGE BASE CONTEXT:
{$context}

RULES:
- You can answer questions from TWO sources:
  1. The CONVERSATION HISTORY (previous messages in this chat) - use this to remember what the customer told you earlier
  2. The KNOWLEDGE BASE CONTEXT above - use this for {$config['contextType']} information
- If the customer asks something they mentioned earlier in the conversation (like their name, preferences), refer to the conversation history to answer
- If the question is about {$config['questionType']}, refer to the knowledge base
- If you cannot find the answer in either source, indicate low confidence
- Be helpful, concise, and friendly
- Detect and respond in the same language the customer uses
- Never make up information that's not in either source
- {$config['collectionNote']}
PROMPT;
    }

    /**
     * Get business-specific configuration for prompts.
     */
    protected function getBusinessConfig(string $businessType): array
    {
        if ($businessType === 'order_tracking') {
            return [
                'role1' => 'Answering questions about products and services based on the provided knowledge base',
                'role2' => 'Helping with placing orders',
                'role3' => 'Providing information about operating hours, products, and services',
                'contextType' => 'business-specific',
                'questionType' => 'products, services, or policies',
                'collectionNote' => 'For order requests, you\'ll need to collect: products, quantities, delivery/pickup preference, and contact details',
            ];
        }

        // Default: Restaurant
        return [
            'role1' => 'Answering questions about the restaurant based on the provided knowledge base',
            'role2' => 'Helping with table bookings',
            'role3' => 'Providing information about operating hours, menu, and services',
            'contextType' => 'restaurant-specific',
            'questionType' => 'restaurant information (menu, hours, policies)',
            'collectionNote' => 'For booking requests, you\'ll need to collect: name, date, time, and number of guests',
        ];
    }

    /**
     * Detect the intent of a customer message with full conversation context.
     * Like ChatGPT, the AI understands the full conversation history to determine intent.
     *
     * @param string $message The current message
     * @param Conversation $conversation The conversation for context
     * @param string $businessType The business type ('restaurant' or 'order_tracking')
     * @return array ['intent' => string, 'entities' => array]
     */
    public function detectIntent(string $message, Conversation $conversation, string $businessType = 'restaurant'): array
    {
        // Get conversation history for context (like ChatGPT)
        $conversationHistory = $this->getConversationHistory($conversation);

        // Build a summary of conversation context for the AI
        $historyContext = "";
        if (!empty($conversationHistory)) {
            $historyContext = "CONVERSATION HISTORY (for context):\n";
            foreach ($conversationHistory as $msg) {
                $role = $msg['role'] === 'user' ? 'Customer' : 'Assistant';
                // Limit each message to avoid token overflow
                $content = mb_substr($msg['content'], 0, 300);
                if (strlen($msg['content']) > 300) {
                    $content .= '...';
                }
                $historyContext .= "- {$role}: {$content}\n";
            }
            $historyContext .= "\n---\n\n";
        }

        // Build business-type specific prompt
        $systemPrompt = $this->buildIntentPrompt($historyContext, $message, $businessType);

        try {
            $result = $this->openAI->chatJson([
                ['role' => 'user', 'content' => $message]
            ], $systemPrompt);

            Log::info('Smart intent detection result', [
                'conversation_id' => $conversation->id,
                'message' => mb_substr($message, 0, 100),
                'intent' => $result['intent'] ?? 'other',
                'reasoning' => $result['reasoning'] ?? 'none',
            ]);

            return [
                'intent' => $result['intent'] ?? 'other',
                'entities' => $result['entities'] ?? [],
            ];
        } catch (\Exception $e) {
            Log::error('Intent detection failed', ['error' => $e->getMessage()]);
            return [
                'intent' => 'other',
                'entities' => [],
            ];
        }
    }

    /**
     * Build the intent detection prompt based on business type.
     */
    protected function buildIntentPrompt(string $historyContext, string $message, string $businessType): string
    {
        // Get business-specific intent configuration
        $config = $this->getIntentConfig($businessType);

        return <<<PROMPT
You are an intelligent AI assistant analyzing customer messages for a {$config['businessLabel']} chatbot.
Your job is to understand the FULL CONTEXT of the conversation and determine the customer's true intent.

{$historyContext}

CURRENT MESSAGE TO ANALYZE:
"{$message}"

Based on the conversation history and current message, determine the customer's intent.

IMPORTANT CONTEXT RULES:
{$config['contextRules']}
- Be smart about understanding follow-up messages in the context of the conversation

Respond in JSON format:
{
    "intent": "one of: {$config['intentList']}",
    "entities": {$config['entities']},
    "reasoning": "brief explanation of why you chose this intent"
}

Intent definitions:
- greeting: Customer is saying hello or starting a conversation
- general_question: Customer is asking a general question about {$config['questionSubject']}
{$config['intentDefinitions']}
- other: Anything else

Only include entities that are explicitly mentioned. Use null for unmentioned entities.
PROMPT;
    }

    /**
     * Get business-specific intent detection configuration.
     */
    protected function getIntentConfig(string $businessType): array
    {
        if ($businessType === 'order_tracking') {
            return [
                'businessLabel' => 'business',
                'contextRules' => '- If the conversation shows an order was just placed and the customer is now asking to add/change something, this is an "order_modify" NOT a new "order_request"
- If the customer says "I want to order" or similar with no prior order in the conversation, this is an "order_request"
- If the customer has an existing order (shown in conversation) and wants to cancel it, this is "order_cancel"',
                'intentList' => 'talk_to_human, greeting, general_question, order_request, order_inquiry, order_modify, order_cancel, other',
                'entities' => '{
        "name": "extracted name if mentioned",
        "products": "list of products mentioned",
        "quantity": "quantities if mentioned",
        "delivery_type": "delivery or pickup if mentioned",
        "date": "extracted date if mentioned (YYYY-MM-DD format)",
        "time": "extracted time if mentioned (HH:MM format)",
        "special_request": "any special requests mentioned"
    }',
                'questionSubject' => 'products or services',
                'intentDefinitions' => '- talk_to_human: **HIGHEST PRIORITY** Customer wants to speak to a real person/human/staff (English: "talk to human", "speak to someone", "customer service", "real person" | Malay: "nak cakap dengan orang", "boleh cakap dengan staff" | Chinese: "我要跟人说话", "找真人", "人工客服")
- order_request: Customer wants to place a NEW order (no prior order in this conversation)
- order_modify: Customer wants to CHANGE or ADD something to their existing/recent order
- order_inquiry: Customer asking about their existing order status or details
- order_cancel: Customer wants to cancel an order',
            ];
        }

        // Default: Restaurant
        return [
            'businessLabel' => 'restaurant',
            'contextRules' => '- IMPORTANT: "Can I make another booking?" or "I want to book again" or "book多一个" is a BOOKING_REQUEST, not an inquiry - the customer wants to CREATE a new reservation
- If the conversation shows a booking was just confirmed and the customer is now asking to add/change something (like decorations, special requests, seating preferences), this is a "booking_modify" NOT a new "booking_request"
- If the customer says "I want to book" or "make a reservation" with no prior booking OR says they want to make ANOTHER booking, this is a "booking_request"
- "booking_inquiry" is ONLY for checking STATUS of existing bookings (e.g., "check my booking", "when is my reservation", "what time is my booking")
- If the customer has an existing booking (shown in conversation) and wants to cancel it, this is "booking_cancel"',
            'intentList' => 'talk_to_human, greeting, general_question, booking_request, booking_inquiry, booking_modify, booking_cancel, other',
            'entities' => '{
        "name": "extracted name if mentioned",
        "date": "extracted date if mentioned (YYYY-MM-DD format)",
        "time": "extracted time if mentioned (HH:MM format)",
        "pax": "number of guests if mentioned",
        "special_request": "any special requests mentioned (decorations, seating preferences, celebrations, dietary requirements, etc.)"
    }',
            'questionSubject' => 'the restaurant',
            'intentDefinitions' => '- talk_to_human: **HIGHEST PRIORITY** Customer wants to speak to a real person/human/staff (English: "talk to human", "speak to someone", "customer service", "real person" | Malay: "nak cakap dengan orang", "boleh cakap dengan staff" | Chinese: "我要跟人说话", "找真人", "人工客服")
- booking_request: Customer wants to make a NEW reservation OR make ANOTHER reservation (includes: "I want to book", "make a reservation", "can I book?", "book another one", "book多一个", "想订位")
- booking_modify: Customer wants to CHANGE or ADD something to their existing/recent booking (e.g., change time, add special request)
- booking_inquiry: Customer asking to CHECK STATUS of existing booking (e.g., "check my booking", "when is my reservation?", "what time is my booking?", "我的预订是什么时候")
- booking_cancel: Customer wants to cancel a booking',
        ];
    }

    /**
     * Generate a contextual AI response based on intent and business data.
     * This allows the AI to craft natural, conversational responses instead of using templates.
     *
     * @param string $intent The detected intent (e.g., 'booking_modify', 'booking_inquiry')
     * @param string $customerMessage The customer's message
     * @param array $businessData Context data like bookings, orders, settings
     * @param Conversation $conversation The conversation for history
     * @param string $businessType The business type for tone
     * @return string The AI-generated response
     */
    public function generateContextualResponse(
        string $intent,
        string $customerMessage,
        array $businessData,
        Conversation $conversation,
        string $businessType = 'restaurant'
    ): string {
        // Get ai_tone from MerchantSetting
        $merchant = $conversation->merchant;
        $merchantSettings = $merchant ? MerchantSetting::where('user_id', $merchant->id)->first() : null;
        $aiTone = $merchantSettings?->ai_tone ?? 'friendly and professional';

        // Get conversation history for context
        $historyContext = '';
        $recentMessages = $conversation->messages()
            ->orderBy('created_at', 'desc')
            ->take(6)
            ->get()
            ->reverse();

        foreach ($recentMessages as $msg) {
            $role = $msg->direction === 'inbound' ? 'Customer' : 'Assistant';
            $historyContext .= "{$role}: {$msg->content}\n";
        }

        // Format business data for AI
        $dataContext = $this->formatBusinessDataForAI($businessData);

        // Build a detailed prompt for natural response generation
        $prompt = $this->buildContextualResponsePrompt(
            $intent,
            $customerMessage,
            $dataContext,
            $historyContext,
            $aiTone,
            $businessType
        );

        try {
            $response = $this->openAI->chat([
                ['role' => 'user', 'content' => $prompt]
            ]);

            return trim($response);
        } catch (\Exception $e) {
            Log::error('Failed to generate contextual response', [
                'intent' => $intent,
                'error' => $e->getMessage(),
            ]);

            // Fallback to a generic response
            return "I'd be happy to help you with that. Could you please provide more details?";
        }
    }

    /**
     * Format business data array into readable context for AI.
     */
    protected function formatBusinessDataForAI(array $data): string
    {
        $context = "";

        // Include merchant templates if provided
        if (isset($data['booking_form_template'])) {
            $context .= "BOOKING FORM TEMPLATE (Use this when customer wants to make a booking):\n";
            $context .= $data['booking_form_template'] . "\n\n";
        }

        // Order tracking templates
        if (isset($data['order_form_template'])) {
            $context .= "ORDER FORM TEMPLATE (Use this when customer wants to place an order):\n";
            $context .= $data['order_form_template'] . "\n\n";
        }

        if (isset($data['confirmation_template'])) {
            $context .= "CONFIRMATION TEMPLATE:\n";
            $context .= $data['confirmation_template'] . "\n\n";
        }

        if (isset($data['reminder_template'])) {
            $context .= "REMINDER TEMPLATE:\n";
            $context .= $data['reminder_template'] . "\n\n";
        }

        if (isset($data['business_name'])) {
            $context .= "BUSINESS NAME: " . $data['business_name'] . "\n\n";
        }

        if (isset($data['greeting_message'])) {
            $context .= "GREETING MESSAGE: " . $data['greeting_message'] . "\n\n";
        }

        if (isset($data['bookings']) && is_array($data['bookings'])) {
            $context .= "CUSTOMER'S BOOKINGS:\n";
            foreach ($data['bookings'] as $booking) {
                $context .= "- Booking ID: {$booking['id']}\n";
                $context .= "  Date: {$booking['date']}\n";
                $context .= "  Time: {$booking['time']}\n";
                $context .= "  Guests: {$booking['pax']}\n";
                if (isset($booking['table'])) {
                    $context .= "  Table: {$booking['table']}\n";
                }
                if (isset($booking['special_requests'])) {
                    $context .= "  Special Requests: {$booking['special_requests']}\n";
                }
                $context .= "\n";
            }
        }

        if (isset($data['orders']) && is_array($data['orders'])) {
            $context .= "CUSTOMER'S ORDERS:\n";
            foreach ($data['orders'] as $order) {
                // Support numbered format for selection
                $prefix = isset($order['number']) ? "{$order['number']}. " : "";
                $context .= "{$prefix}Order #{$order['id']}";
                if (isset($order['status'])) {
                    $context .= " - {$order['status']}";
                }
                $context .= "\n";
                if (!empty($order['items'])) {
                    $context .= "   Items: {$order['items']}\n";
                }
                if (!empty($order['total'])) {
                    $context .= "   Total: {$order['total']}\n";
                }
                if (!empty($order['datetime'])) {
                    $context .= "   Scheduled: {$order['datetime']}\n";
                }
                if (!empty($order['fulfillment'])) {
                    $context .= "   Fulfillment: {$order['fulfillment']}\n";
                }
                if (!empty($order['delivery_address'])) {
                    $context .= "   Delivery Address: {$order['delivery_address']}\n";
                }
                $context .= "\n";
            }
        }

        if (isset($data['settings'])) {
            $context .= "BUSINESS SETTINGS:\n";
            foreach ($data['settings'] as $key => $value) {
                $context .= "- {$key}: {$value}\n";
            }
        }

        if (isset($data['action_needed'])) {
            $context .= "\nACTION NEEDED: {$data['action_needed']}\n";
        }

        if (isset($data['action_result'])) {
            $context .= "\nACTION RESULT: {$data['action_result']}\n";
        }

        return $context ?: "No additional business data available.";
    }

    /**
     * Get intent-specific guidance for AI response generation.
     */
    protected function getIntentGuidance(string $intent, string $businessType): string
    {
        if ($businessType === 'restaurant') {
            return match ($intent) {
                'booking_request' => "The customer wants to make a booking. IMPORTANT: Show ONLY the booking form template - do NOT repeat, summarize, or reference previous conversation topics. Just acknowledge briefly and show the booking form.",
                'booking_inquiry' => "The customer is asking about their booking. Show them their booking details in a friendly way.",
                'booking_modify' => "The customer wants to modify their booking. If they provided new details (date/time/pax), confirm the changes. If they just said 'reschedule' without new details, show their current booking and ask what they'd like to change.",
                'booking_cancel' => "The customer wants to cancel. Show their booking and ask for confirmation before canceling.",
                'general_question' => "Answer the customer's question using available information.",
                default => "Help the customer with their request.",
            };
        }

        // Order tracking
        return match ($intent) {
            'order_request' => "The customer wants to place an order. Guide them through the ordering process.",
            'order_inquiry' => "The customer is asking about their order. Show them order status and details.",
            'order_modify' => "The customer wants to modify their order. Show current order and help them make changes.",
            'order_cancel' => "The customer wants to cancel their order. Confirm before canceling.",
            'general_question' => "Answer the customer's question using available information.",
            default => "Help the customer with their request.",
        };
    }

    /**
     * Build detailed prompt for contextual AI response generation.
     */
    protected function buildContextualResponsePrompt(
        string $intent,
        string $customerMessage,
        string $dataContext,
        string $historyContext,
        string $aiTone,
        string $businessType
    ): string {
        $businessLabel = $businessType === 'order_tracking' ? 'business' : 'restaurant';
        $intentGuidance = $this->getIntentGuidance($intent, $businessType);

        return <<<PROMPT
                    You are a helpful {$businessLabel} assistant. Your personality: {$aiTone}

                    CONVERSATION HISTORY:
                    {$historyContext}

                    CUSTOMER'S LATEST MESSAGE:
                    "{$customerMessage}"

                    DETECTED INTENT: {$intent}
                    {$intentGuidance}

                    BUSINESS DATA:
                    {$dataContext}

                    CRITICAL INSTRUCTIONS (MUST FOLLOW):
                    
                    1. **LANGUAGE MATCHING (ABSOLUTE PRIORITY - CHECK FIRST)**:
                       - Look at the CUSTOMER'S LATEST MESSAGE above
                       - If the message is in ENGLISH (like "Nice", "OK", "Yes"), reply in ENGLISH
                       - If the message is in 中文 (Chinese), reply in 中文
                       - If the message is in Bahasa Melayu, reply in Bahasa Melayu
                       - WARNING: Do NOT default to Chinese when customer writes English!
                       - The word "Nice" is ENGLISH - reply in English.
                       - The word "OK" is ENGLISH - reply in English.
                    
                    2. Generate a natural, conversational response
                    3. Be warm and helpful, use appropriate emojis sparingly
                    4. If showing booking/order details, format them nicely with emojis (📅 for date, ⏰ for time, 👥 for guests)
                    5. If you need more information from customer, ask clearly
                    6. Keep response concise but complete
                    7. NEVER expose technical errors or system details to customer
                    8. If action_result shows an error, apologize and offer alternatives

                    Respond directly as the assistant (no JSON, no prefix, just the message):
                PROMPT;
    }
}

