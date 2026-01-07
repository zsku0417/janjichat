<?php

namespace App\Services;

use App\Events\NewMessageEvent;
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
    // Response message constants
    public const MSG_ESCALATION = "I'll connect you with our team. Someone will be with you shortly.";
    public const MSG_CANCEL_DECLINED = "No problem! Let me know if you need anything else. 😊";
    public const MSG_CHANGES_CANCELLED = "Okay, no changes made. Let me know if you need anything else!";
    public const MSG_DEFAULT_GREETING = "Hi! Welcome";

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
            $result = $this->getOrCreateConversation($messageData);
            $conversation = $result['conversation'];
            $isNew = $result['isNew'];

            // Check if conversation has no prior messages (fresh start or cleared)
            $isFirstMessage = $isNew || $conversation->messages()->count() === 0;

            // Store the incoming message FIRST (before any responses)
            $message = $this->storeMessage($conversation, $messageData);

            // Update last message timestamp
            $conversation->update(['last_message_at' => now()]);

            // Send greeting for first message in new conversation AFTER storing customer's message
            if ($isFirstMessage) {
                $this->sendInitialGreeting($conversation);
                // Continue processing - don't return early!
                // The customer's first message may contain an order/booking request
            }

            // Check if conversation is in admin mode
            if ($conversation->isAdminMode()) {
                Log::info('Conversation in admin mode, skipping AI response', [
                    'conversation_id' => $conversation->id,
                ]);
                return;
            }

            // Check if it's a non-text message
            if ($messageData['message_type'] !== 'text') {
                $this->handleNonTextMessage($conversation, $messageData, $message);
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
     * Returns array with conversation and isNew flag.
     * Multi-tenant: Conversations are unique per customer+merchant pair.
     */
    protected function getOrCreateConversation(array $messageData): array
    {
        // Find merchant by phone_number_id from webhook
        $merchant = $this->findMerchantByPhoneNumberId($messageData['phone_number_id'] ?? null);

        if (!$merchant) {
            Log::warning('No merchant found for phone_number_id', [
                'phone_number_id' => $messageData['phone_number_id'] ?? 'missing',
            ]);
            // Fall back to first merchant (backward compatibility)
            $merchant = User::where('role', User::ROLE_MERCHANT)->first();
        }

        // Multi-tenant: Find conversation by BOTH whatsapp_id AND merchant user_id
        // This allows the same customer to have separate conversations with different merchants
        $conversationQuery = Conversation::where('whatsapp_id', $messageData['from']);

        if ($merchant) {
            $conversationQuery->where('user_id', $merchant->id);
        }

        $conversation = $conversationQuery->first();

        $isNew = false;

        if (!$conversation) {
            // No conversation exists for this customer+merchant, create a new one
            $conversation = Conversation::create([
                'user_id' => $merchant?->id,
                'whatsapp_id' => $messageData['from'],
                'phone_number' => $messageData['from'],
                'customer_name' => $messageData['contact_name'],
                'mode' => 'ai',
                'status' => 'active',
                'last_message_at' => now(),
            ]);

            $isNew = true;

            Log::info('New conversation created', [
                'conversation_id' => $conversation->id,
                'phone' => $messageData['from'],
                'merchant_id' => $merchant?->id,
            ]);
        } else {
            // Update customer name if we have it now but didn't before
            if ($messageData['contact_name'] && !$conversation->customer_name) {
                $conversation->update(['customer_name' => $messageData['contact_name']]);
            }

            Log::info('Existing conversation found', [
                'conversation_id' => $conversation->id,
                'merchant_id' => $conversation->user_id,
            ]);
        }

        return ['conversation' => $conversation, 'isNew' => $isNew];
    }

    /**
     * Find merchant by WhatsApp phone number ID.
     */
    protected function findMerchantByPhoneNumberId(?string $phoneNumberId): ?User
    {
        if (!$phoneNumberId) {
            Log::warning('Phone number ID is null when finding merchant');
            return null;
        }

        $merchant = User::where('role', User::ROLE_MERCHANT)
            ->where('whatsapp_phone_number_id', $phoneNumberId)
            ->first();

        if (!$merchant) {
            Log::warning('No merchant found for phone_number_id', [
                'phone_number_id' => $phoneNumberId,
            ]);
        }

        Log::info('Merchant found', [
            'merchant_id' => $merchant->id,
            'merchant_name' => $merchant->name ?? null,
            'phone_number_id' => $phoneNumberId,
        ]);

        return $merchant;
    }

    /**
     * Store a message in the database.
     */
    protected function storeMessage(Conversation $conversation, array $messageData): Message
    {
        $mediaUrl = null;

        // For image messages, download from WhatsApp and upload to Cloudinary
        if ($messageData['message_type'] === 'image') {
            $mediaUrl = $this->processAndUploadMedia($messageData);
        }

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'direction' => 'inbound',
            'sender_type' => 'customer',
            'message_type' => $messageData['message_type'],
            'content' => $messageData['content'],
            'whatsapp_message_id' => $messageData['message_id'],
            'status' => 'delivered',
            'metadata' => $messageData['metadata'],
            'media_url' => $mediaUrl,
        ]);

        // Broadcast new message event for real-time frontend updates
        broadcast(new NewMessageEvent($conversation, $message))->toOthers();

        return $message;
    }

    /**
     * Process media from WhatsApp and upload to Cloudinary.
     * Returns the Cloudinary URL or null on failure.
     */
    protected function processAndUploadMedia(array $messageData): ?string
    {
        try {
            $mediaId = $messageData['metadata']['media_id'] ?? null;
            if (!$mediaId) {
                Log::warning('No media_id in message metadata');
                return null;
            }

            // Download from WhatsApp
            $mediaData = $this->whatsApp->downloadMedia($mediaId);
            if (!$mediaData) {
                Log::warning('Failed to download media from WhatsApp', ['media_id' => $mediaId]);
                return null;
            }

            // Upload to Cloudinary using MediaService
            $mediaService = app(MediaService::class);
            $cloudinaryUrl = $mediaService->uploadImageFromBinary(
                $mediaData['content'],
                $mediaData['filename'],
                $mediaData['mime_type']
            );

            return $cloudinaryUrl;

        } catch (Exception $e) {
            Log::error('Failed to process and upload media', [
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Handle non-text messages (images, audio, etc.).
     * Business-specific logic:
     * - Restaurant: Escalate all images to admin
     * - Order Tracking: AI analyzes if it's a payment proof
     *
     * @param Conversation $conversation
     * @param array $messageData
     * @param Message $message The already-stored message with media_url
     */
    protected function handleNonTextMessage(Conversation $conversation, array $messageData, Message $message): void
    {
        $merchant = $this->getMerchantForConversation($conversation);
        $messageType = $messageData['message_type'];

        // Only process images for now
        if ($messageType !== 'image') {
            $this->escalateNonTextMessage($conversation, $messageType, 'Other media types not supported');
            return;
        }

        // Use the media URL from the message that was just stored
        $mediaUrl = $message->media_url;

        // Restaurant: Always escalate images
        if (!$merchant || !$merchant->isOrderTracking()) {
            $this->escalateNonTextMessage($conversation, $messageType, 'Restaurant business type');
            return;
        }

        // Order Tracking: Analyze if image is a payment proof
        if (!$mediaUrl) {
            Log::warning('No media URL for image analysis');
            $this->escalateNonTextMessage($conversation, $messageType, 'Could not upload image');
            return;
        }

        try {
            // Use AI Vision to analyze the image
            $analysis = $this->openAI->analyzePaymentProof($mediaUrl);

            Log::info('Payment proof analysis result', [
                'conversation_id' => $conversation->id,
                'is_payment_proof' => $analysis['is_payment_proof'],
                'confidence' => $analysis['confidence'],
            ]);

            if ($analysis['is_payment_proof'] && $analysis['confidence'] >= 0.6) {
                // It's likely a payment proof - acknowledge and notify admin will verify
                $response = "Thank you for sending your payment screenshot! 📸\n\n" .
                    "Our team will verify it shortly and update your order status.\n\n" .
                    "Please wait for confirmation. We'll get back to you soon! 🙏";

                $this->sendResponse($conversation, $response);

                // Still escalate to admin for manual verification, but with different reason
                $conversation->escalateToAdmin('Payment proof received - needs verification');

                Log::info('Payment proof acknowledged', [
                    'conversation_id' => $conversation->id,
                    'confidence' => $analysis['confidence'],
                ]);
            } else {
                // Not a payment proof - escalate to admin
                $reason = "Customer sent an image that doesn't appear to be payment proof. AI analysis: " . ($analysis['description'] ?? 'Unknown content');
                $this->escalateNonTextMessage($conversation, $messageType, $reason);
            }

        } catch (Exception $e) {
            Log::error('Payment proof analysis failed', [
                'conversation_id' => $conversation->id,
                'error' => $e->getMessage(),
            ]);
            // On error, escalate to admin
            $this->escalateNonTextMessage($conversation, $messageType, 'AI analysis failed');
        }
    }

    /**
     * Escalate a non-text message to admin.
     */
    protected function escalateNonTextMessage(Conversation $conversation, string $messageType, string $reason): void
    {
        $fullReason = "Customer sent a {$messageType} message. Reason: {$reason}";
        $conversation->escalateToAdmin($fullReason);

        Log::info('Non-text message escalated to admin', [
            'conversation_id' => $conversation->id,
            'message_type' => $messageType,
            'reason' => $reason,
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

        // Step 0: Check for talk_to_human intent FIRST (before context handling)
        $businessType = $merchant?->business_type ?? 'restaurant';
        $talkToHumanResult = $this->rag->detectIntent($content, $conversation, $businessType);

        if ($talkToHumanResult['intent'] === 'talk_to_human') {
            // Escalate to admin
            $conversation->escalateToAdmin("Customer requested to talk to a human");

            // Send acknowledgment
            $this->sendResponse($conversation, self::MSG_ESCALATION);

            Log::info('Customer requested human support', [
                'conversation_id' => $conversation->id,
            ]);

            return true;
        }

        // Step 1: Check if there's an active conversation context that needs handling
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
        return $conversation->merchant;
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
                    $this->sendResponse($conversation, self::MSG_CANCEL_DECLINED);
                    return true;
                }
                break;

            case Conversation::CONTEXT_AWAITING_CANCELLATION_CONFIRMATION:
                if ($responseType === 'affirmative') {
                    $bookingId = $contextData['booking_id'] ?? null;
                    $conversation->clearContext();

                    if ($bookingId && $handler instanceof RestaurantHandler) {
                        $handler->confirmBookingCancellation($conversation, $bookingId);
                        return true;
                    }
                } elseif ($responseType === 'negative') {
                    $conversation->clearContext();
                    $this->sendResponse($conversation, self::MSG_CHANGES_CANCELLED);
                    return true;
                }
                break;

            case Conversation::CONTEXT_AWAITING_ORDER_CANCELLATION_CONFIRMATION:
                if ($responseType === 'affirmative') {
                    $orderId = $contextData['order_id'] ?? null;
                    if ($orderId && $handler instanceof OrderTrackingHandler) {
                        $handler->executeCancellation($conversation, $orderId);
                        return true;
                    }
                } elseif ($responseType === 'negative') {
                    $conversation->clearContext();
                    $this->sendResponse($conversation, self::MSG_CHANGES_CANCELLED);
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
            Conversation::CONTEXT_AWAITING_ORDER_CONFIRMATION => 'placing an order',
            Conversation::CONTEXT_AWAITING_CANCELLATION_CONFIRMATION => 'cancelling a booking',
            Conversation::CONTEXT_AWAITING_ORDER_CANCELLATION_CONFIRMATION => 'cancelling an order',
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
            $message = Message::create([
                'conversation_id' => $conversation->id,
                'direction' => 'outbound',
                'sender_type' => 'ai',
                'message_type' => 'text',
                'content' => $content,
                'whatsapp_message_id' => $result['messages'][0]['id'] ?? null,
                'status' => 'sent',
            ]);

            // Broadcast new message event for real-time frontend updates
            broadcast(new NewMessageEvent($conversation, $message))->toOthers();

        } catch (Exception $e) {
            Log::error('Failed to send response', [
                'conversation_id' => $conversation->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Send initial greeting message for new conversations.
     * Priority: greeting_message > "Hi! Welcome to {business_name}" > "Hi! Welcome"
     */
    protected function sendInitialGreeting(Conversation $conversation): void
    {
        try {
            // Get merchant for this conversation (works in webhook context)
            $merchant = $this->getMerchantForConversation($conversation);
            $merchantSetting = $merchant?->merchantSettings;

            // Determine greeting message
            $greeting = null;

            if ($merchantSetting && !empty($merchantSetting->greeting_message)) {
                // Priority 1: Use custom greeting message
                $greeting = $merchantSetting->greeting_message;
            } elseif ($merchantSetting && !empty($merchantSetting->business_name)) {
                // Priority 2: Use business name
                $greeting = "Hi! Welcome to {$merchantSetting->business_name}";
            } else {
                // Priority 3: Default fallback
                $greeting = self::MSG_DEFAULT_GREETING;
            }

            // Send greeting
            $this->sendResponse($conversation, $greeting);

            Log::info('Initial greeting sent', [
                'conversation_id' => $conversation->id,
                'merchant_id' => $merchant?->id,
                'greeting_used' => !empty($merchantSetting?->greeting_message) ? 'custom' : (!empty($merchantSetting?->business_name) ? 'business_name' : 'default'),
            ]);

        } catch (Exception $e) {
            Log::error('Failed to send initial greeting', [
                'conversation_id' => $conversation->id,
                'error' => $e->getMessage(),
            ]);
            // Send default greeting as fallback
            $this->sendResponse($conversation, self::MSG_DEFAULT_GREETING);
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

        // Broadcast new message event for real-time frontend updates
        broadcast(new NewMessageEvent($conversation, $message))->toOthers();

        // Mark as no longer needing reply
        $conversation->update(['needs_reply' => false]);

        return $message;
    }
}
