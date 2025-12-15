<?php

namespace App\Services;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use App\Services\Handlers\BusinessHandlerInterface;
use App\Services\Handlers\RestaurantHandler;
use App\Services\Handlers\OrderTrackingHandler;
use Illuminate\Support\Facades\Log;
use Exception;

/**
 * ConversationHandler - Main orchestrator for AI conversations.
 * 
 * This class handles the general flow of conversations and delegates
 * business-specific logic to the appropriate handler based on
 * the merchant's business type.
 */
class ConversationHandler
{
    protected WhatsAppService $whatsApp;
    protected RAGService $rag;
    protected BookingService $booking;
    protected OrderService $order;
    protected OpenAIService $openAI;

    // Business handlers
    protected RestaurantHandler $restaurantHandler;
    protected OrderTrackingHandler $orderTrackingHandler;

    public function __construct(
        WhatsAppService $whatsApp,
        RAGService $rag,
        BookingService $booking,
        OrderService $order,
        OpenAIService $openAI,
        RestaurantHandler $restaurantHandler,
        OrderTrackingHandler $orderTrackingHandler
    ) {
        $this->whatsApp = $whatsApp;
        $this->rag = $rag;
        $this->booking = $booking;
        $this->order = $order;
        $this->openAI = $openAI;
        $this->restaurantHandler = $restaurantHandler;
        $this->orderTrackingHandler = $orderTrackingHandler;

        // Set up response callbacks for handlers
        $sendResponseCallback = fn($conversation, $content) => $this->sendResponse($conversation, $content);
        $this->restaurantHandler->setSendResponseCallback($sendResponseCallback);
        $this->orderTrackingHandler->setSendResponseCallback($sendResponseCallback);
    }

    /**
     * Get the appropriate handler for a merchant's business type.
     */
    protected function getHandler(?User $merchant): BusinessHandlerInterface
    {
        if ($merchant && $merchant->isOrderTracking()) {
            return $this->orderTrackingHandler;
        }

        // Default to restaurant handler
        return $this->restaurantHandler;
    }

    /**
     * Handle an incoming WhatsApp message.
     *
     * @param array $messageData Parsed message data from webhook
     * @return void
     */
    public function handleIncomingMessage(array $messageData): void
    {
        try {
            // Get or create conversation
            $conversation = $this->getOrCreateConversation($messageData);

            // Store the incoming message
            $message = $this->storeMessage($conversation, $messageData);

            // Update last message timestamp
            $conversation->update(['last_message_at' => now()]);

            // Check if conversation is in admin mode
            if ($conversation->isAdminMode()) {
                Log::info('Conversation in admin mode, skipping AI response', [
                    'conversation_id' => $conversation->id,
                ]);
                return;
            }

            // Check if it's a non-text message
            if ($messageData['message_type'] !== 'text') {
                $this->handleNonTextMessage($conversation, $messageData);
                // Mark as read after handling non-text message
                $this->whatsApp->markAsRead($messageData['message_id']);
                return;
            }

            // Process the message with AI
            $responded = $this->processWithAI($conversation, $message, $messageData['content']);

            // Only mark as read if we successfully responded
            if ($responded) {
                $this->whatsApp->markAsRead($messageData['message_id']);
            }

        } catch (Exception $e) {
            Log::error('Failed to handle incoming message', [
                'error' => $e->getMessage(),
                'message_data' => $messageData,
            ]);
        }
    }

    /**
     * Get existing conversation or create a new one.
     */
    protected function getOrCreateConversation(array $messageData): Conversation
    {
        $conversation = Conversation::where('whatsapp_id', $messageData['from'])->first();

        if (!$conversation) {
            $conversation = Conversation::create([
                'whatsapp_id' => $messageData['from'],
                'phone_number' => $messageData['from'],
                'customer_name' => $messageData['contact_name'],
                'mode' => 'ai',
                'status' => 'active',
                'last_message_at' => now(),
            ]);

            Log::info('New conversation created', [
                'conversation_id' => $conversation->id,
                'phone' => $messageData['from'],
            ]);
        } elseif ($messageData['contact_name'] && !$conversation->customer_name) {
            $conversation->update(['customer_name' => $messageData['contact_name']]);
        }

        return $conversation;
    }

    /**
     * Store a message in the database.
     */
    protected function storeMessage(Conversation $conversation, array $messageData): Message
    {
        return Message::create([
            'conversation_id' => $conversation->id,
            'direction' => 'inbound',
            'sender_type' => 'customer',
            'message_type' => $messageData['message_type'],
            'content' => $messageData['content'],
            'whatsapp_message_id' => $messageData['message_id'],
            'status' => 'delivered',
            'metadata' => $messageData['metadata'],
        ]);
    }

    /**
     * Handle non-text messages (images, audio, etc.).
     */
    protected function handleNonTextMessage(Conversation $conversation, array $messageData): void
    {
        // Escalate to admin for non-text messages
        $reason = "Customer sent a {$messageData['message_type']} message which cannot be processed automatically.";

        $conversation->escalateToAdmin($reason);

        Log::info('Non-text message escalated to admin', [
            'conversation_id' => $conversation->id,
            'message_type' => $messageData['message_type'],
        ]);
    }

    /**
     * Process a text message with AI.
     * Returns true if a response was sent, false otherwise.
     */
    protected function processWithAI(Conversation $conversation, Message $message, string $content): bool
    {
        // Get the merchant associated with this conversation
        $merchant = $this->getMerchantForConversation($conversation);
        $handler = $this->getHandler($merchant);

        // Step 0: Check if there's an active conversation context that needs handling
        $context = $conversation->getContext();
        if ($context) {
            // First try handler-specific context handling
            if ($handler->handleContextualResponse($conversation, $content, $context)) {
                return true;
            }

            // Then try general context handling (affirmative/negative responses)
            if ($this->handleContextualResponse($conversation, $content, $context)) {
                return true;
            }
        }

        // Store message ID before handler processes (for comparison later)
        $inboundMessageId = $message->id;

        // Delegate to the appropriate business handler
        $handler->processMessage($conversation, $message, $content, $merchant ?? new User());

        // Note: If the handler doesn't handle the message (e.g., general_question),
        // it will return without sending a response and we handle it here
        // Use direct query (not relationship) to avoid Eloquent caching issues
        $latestMessage = Message::where('conversation_id', $conversation->id)
            ->orderByDesc('id')
            ->first();

        Log::debug('Checking if handler sent response', [
            'inbound_message_id' => $inboundMessageId,
            'latest_message_id' => $latestMessage?->id,
            'latest_direction' => $latestMessage?->direction,
            'should_handle_general' => $latestMessage && $latestMessage->id === $inboundMessageId,
        ]);

        if ($latestMessage && $latestMessage->id === $inboundMessageId) {
            // No response was sent by handler, handle as general question
            $this->handleGeneralQuestion($conversation, $content);
        }

        // A response was sent (either by handler or general question handler)
        return true;
    }

    /**
     * Get the merchant (user) associated with this conversation.
     * For now, we use the first user. In multi-tenant, this would be from conversation->user_id.
     */
    protected function getMerchantForConversation(Conversation $conversation): ?User
    {
        // TODO: In multi-tenant, get from conversation->user relationship
        // For now, get the first user as the merchant
        return User::first();
    }

    /**
     * Handle contextual follow-up responses like "Yes", "No", "OK" in any language.
     * Uses AI to understand the user's intent rather than hardcoded word lists.
     * Returns true if the context was handled, false otherwise.
     */
    protected function handleContextualResponse(Conversation $conversation, string $content, array $context): bool
    {
        $contextType = $context['type'];
        $contextData = $context['data'] ?? [];

        Log::info('Processing contextual response', [
            'conversation_id' => $conversation->id,
            'context_type' => $contextType,
            'content' => $content,
        ]);

        // Use AI to understand if the response is affirmative, negative, or something else
        $responseType = $this->detectResponseType($content, $contextType);

        Log::info('Response type detected', [
            'response_type' => $responseType,
        ]);

        // Get the appropriate handler for context-specific handling
        $merchant = $this->getMerchantForConversation($conversation);
        $handler = $this->getHandler($merchant);

        // Handle affirmative/negative responses for common confirmation contexts
        switch ($contextType) {
            case Conversation::CONTEXT_AWAITING_BOOKING_CONFIRMATION:
            case Conversation::CONTEXT_AWAITING_ORDER_CONFIRMATION:
                if ($responseType === 'affirmative') {
                    $conversation->clearContext();
                    $handler->handleGreeting($conversation, $merchant ?? new User());
                    return true;
                } elseif ($responseType === 'negative') {
                    $conversation->clearContext();
                    $this->sendResponse($conversation, "No problem! Let me know if you need anything else. 😊");
                    return true;
                }
                break;

            case Conversation::CONTEXT_AWAITING_CANCELLATION_CONFIRMATION:
                if ($responseType === 'affirmative') {
                    $bookingId = $contextData['booking_id'] ?? null;
                    $orderId = $contextData['order_id'] ?? null;
                    $conversation->clearContext();

                    if ($bookingId && $handler instanceof RestaurantHandler) {
                        $handler->confirmBookingCancellation($conversation, $bookingId);
                        return true;
                    }
                    // TODO: Add order cancellation handling when implemented
                } elseif ($responseType === 'negative') {
                    $conversation->clearContext();
                    $this->sendResponse($conversation, "Okay, no changes made. Let me know if you need anything else!");
                    return true;
                }
                break;
        }

        // Context wasn't handled, return false to continue with normal processing
        return false;
    }

    /**
     * Use AI to detect if a response is affirmative, negative, or other.
     * Supports any language (English, Chinese, Malay, etc.).
     */
    protected function detectResponseType(string $content, string $contextType): string
    {
        $contextDescription = match ($contextType) {
            Conversation::CONTEXT_AWAITING_BOOKING_CONFIRMATION => 'making a reservation or booking',
            Conversation::CONTEXT_AWAITING_CANCELLATION_CONFIRMATION => 'cancelling a booking or order',
            Conversation::CONTEXT_ORDER_FLOW => 'placing an order',
            default => 'a yes/no question',
        };

        $prompt = <<<PROMPT
You are analyzing a user's response in a business chatbot conversation.
The system asked the user about: {$contextDescription}
The user responded: "{$content}"

Classify this response into ONE of these categories:
- "affirmative" - if the user is saying yes, agreeing, confirming, or showing positive intent (in any language)
- "negative" - if the user is saying no, declining, refusing, or showing negative intent (in any language)
- "other" - if the response is something else entirely (a new question, unrelated topic, etc.)

Examples of "affirmative" in various languages: yes, ok, sure, 好, 可以, 要, ya, boleh, sí, oui
Examples of "negative" in various languages: no, nope, 不, 不要, 算了, tidak, tidak mahu, no quiero, non

Respond with ONLY ONE WORD: affirmative, negative, or other
PROMPT;

        try {
            $response = $this->openAI->chat([
                ['role' => 'user', 'content' => $prompt]
            ]);

            $result = strtolower(trim($response));

            // Validate the response
            if (in_array($result, ['affirmative', 'negative', 'other'])) {
                return $result;
            }

            // If response contains the words, extract them
            if (str_contains($result, 'affirmative'))
                return 'affirmative';
            if (str_contains($result, 'negative'))
                return 'negative';

            return 'other';
        } catch (Exception $e) {
            Log::warning('Failed to detect response type with AI, falling back to keyword matching', [
                'error' => $e->getMessage(),
            ]);

            // Fallback to basic keyword matching if AI fails
            return $this->detectResponseTypeFallback($content);
        }
    }

    /**
     * Fallback response type detection using keyword matching.
     */
    protected function detectResponseTypeFallback(string $content): string
    {
        $normalized = strtolower(trim($content));

        $affirmative = ['yes', 'yeah', 'yep', 'sure', 'ok', 'okay', 'yup', 'definitely', 'please', 'confirm', 'proceed', 'go ahead', 'y', 'ya', 'ye', '好', '可以', '要', '是', 'boleh', 'ya', 'baik'];
        $negative = ['no', 'nope', 'nah', 'cancel', 'never mind', 'nevermind', 'forget it', 'n', 'not now', 'later', '不', '不要', '算了', '不用', 'tidak', 'tak'];

        if (in_array($normalized, $affirmative))
            return 'affirmative';
        if (in_array($normalized, $negative))
            return 'negative';

        return 'other';
    }

    /**
     * Handle general questions using RAG.
     */
    protected function handleGeneralQuestion(Conversation $conversation, string $question): void
    {
        // Get business type for appropriate RAG response
        $merchant = $this->getMerchantForConversation($conversation);
        $businessType = ($merchant && $merchant->isOrderTracking()) ? 'order_tracking' : 'restaurant';

        $result = $this->rag->generateResponse($question, $conversation, $businessType);

        if (!$result['confident']) {
            // Escalate to admin
            $conversation->escalateToAdmin($result['reason']);

            Log::info('Question escalated to admin', [
                'conversation_id' => $conversation->id,
                'reason' => $result['reason'],
            ]);

            // Don't send any response
            return;
        }

        $this->sendResponse($conversation, $result['response']);
    }

    /**
     * Send a response to the customer.
     */
    public function sendResponse(Conversation $conversation, string $content): void
    {
        try {
            // Send via WhatsApp
            $result = $this->whatsApp->sendMessage($conversation->phone_number, $content);

            // Store the outgoing message
            Message::create([
                'conversation_id' => $conversation->id,
                'direction' => 'outbound',
                'sender_type' => 'ai',
                'message_type' => 'text',
                'content' => $content,
                'whatsapp_message_id' => $result['messages'][0]['id'] ?? null,
                'status' => 'sent',
            ]);

        } catch (Exception $e) {
            Log::error('Failed to send response', [
                'conversation_id' => $conversation->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Handle message status update.
     */
    public function handleStatusUpdate(array $statusData): void
    {
        $message = Message::where('whatsapp_message_id', $statusData['message_id'])->first();

        if ($message) {
            $message->update(['status' => $statusData['status']]);
        }
    }

    /**
     * Send admin reply to customer.
     *
     * @param Conversation $conversation
     * @param string $content
     * @return Message
     */
    public function sendAdminReply(Conversation $conversation, string $content): Message
    {
        // Send via WhatsApp
        $result = $this->whatsApp->sendMessage($conversation->phone_number, $content);

        // Store the outgoing message
        $message = Message::create([
            'conversation_id' => $conversation->id,
            'direction' => 'outbound',
            'sender_type' => 'admin',
            'message_type' => 'text',
            'content' => $content,
            'whatsapp_message_id' => $result['messages'][0]['id'] ?? null,
            'status' => 'sent',
        ]);

        // Mark as no longer needing reply
        $conversation->update(['needs_reply' => false]);

        return $message;
    }
}
