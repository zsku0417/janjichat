<?php

namespace App\Services\Handlers;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\Order;
use App\Models\User;
use App\Services\OrderService;
use App\Services\RAGService;
use App\Services\WhatsAppService;
use Illuminate\Support\Facades\Log;
use Exception;

/**
 * Handler for Order Tracking business type.
 * Manages all order-related conversation logic.
 */
class OrderTrackingHandler implements BusinessHandlerInterface
{
    protected OrderService $order;
    protected RAGService $rag;
    protected WhatsAppService $whatsApp;

    /**
     * Callback to send response (injected by ConversationHandler)
     */
    protected $sendResponseCallback;

    public function __construct(
        OrderService $order,
        RAGService $rag,
        WhatsAppService $whatsApp
    ) {
        $this->order = $order;
        $this->rag = $rag;
        $this->whatsApp = $whatsApp;
    }

    /**
     * Set the callback for sending responses.
     */
    public function setSendResponseCallback(callable $callback): void
    {
        $this->sendResponseCallback = $callback;
    }

    /**
     * Send a response using the callback.
     */
    protected function sendResponse(Conversation $conversation, string $content): void
    {
        if ($this->sendResponseCallback) {
            call_user_func($this->sendResponseCallback, $conversation, $content);
        }
    }

    /**
     * Process an incoming message for order tracking business type.
     */
    public function processMessage(Conversation $conversation, Message $message, string $content, User $merchant): void
    {
        Log::info('Processing order tracking message', [
            'conversation_id' => $conversation->id,
            'merchant_id' => $merchant->id,
        ]);

        // Check if this looks like a filled order form
        if ($this->order->isOrderAttempt($content)) {
            $this->handleOrderAttempt($conversation, $content, $merchant);
            return;
        }

        // For any greeting or first message, detect intent
        $intentResult = $this->rag->detectIntent($content, $conversation, 'order_tracking');
        $intent = $intentResult['intent'];

        Log::info('Order tracking intent detected', [
            'conversation_id' => $conversation->id,
            'intent' => $intent,
        ]);

        switch ($intent) {
            case 'greeting':
            case 'order_request':
                $this->handleGreeting($conversation, $merchant);
                break;

            case 'order_inquiry':
                $this->handleOrderStatusInquiry($conversation, $merchant);
                break;

            case 'general_question':
            default:
                // Check if they might want to order based on keywords
                if ($this->looksLikeBusinessIntent($content)) {
                    $this->handleGreeting($conversation, $merchant);
                } else {
                    // Return to let ConversationHandler handle general questions
                    return;
                }
                break;
        }
    }

    /**
     * Handle greeting for order tracking - show order form.
     */
    public function handleGreeting(Conversation $conversation, User $merchant): void
    {
        $orderForm = $this->order->getOrderFormTemplate($merchant);

        $this->sendResponse($conversation, $orderForm);

        // Set context to await order
        $conversation->setContext(Conversation::CONTEXT_ORDER_FLOW, [
            'step' => 'awaiting_form',
        ]);
    }

    /**
     * Handle contextual responses specific to order tracking.
     */
    public function handleContextualResponse(Conversation $conversation, string $content, array $context): bool
    {
        $contextType = $context['type'];
        $contextData = $context['data'] ?? [];

        switch ($contextType) {
            case Conversation::CONTEXT_ORDER_FLOW:
                // For now, order flow expects complete form submission
                // Could be extended to handle partial orders
                return false;
        }

        return false;
    }

    /**
     * Get keywords that indicate order intent.
     */
    public function getIntentKeywords(): array
    {
        return ['order', 'buy', 'purchase', 'want', 'get', 'beli', 'nak', 'mau', '要', '买', 'menu', 'price', 'harga'];
    }

    /**
     * Check if content looks like customer wants to order.
     */
    public function looksLikeBusinessIntent(string $content): bool
    {
        $normalized = strtolower($content);

        foreach ($this->getIntentKeywords() as $keyword) {
            if (str_contains($normalized, $keyword)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Handle a filled order form attempt.
     */
    public function handleOrderAttempt(Conversation $conversation, string $content, User $merchant): void
    {
        // Parse the order using AI
        $parsedOrder = $this->order->parseOrderFromMessage($content, $merchant);

        if (!$parsedOrder || !($parsedOrder['is_valid'] ?? false)) {
            $reason = $parsedOrder['reason'] ?? 'Could not parse order details.';
            $response = "Sorry, I couldn't process your order. " . $reason . "\n\n" .
                "Please make sure to include:\n" .
                "• Products and quantities (e.g., Product A x2)\n" .
                "• Date and time needed\n\n" .
                "Would you like me to show the order form again?";

            $this->sendResponse($conversation, $response);
            return;
        }

        // Create the order
        $order = $this->order->createOrder($parsedOrder, $merchant, $conversation);

        if (!$order) {
            $response = "Sorry, there was an error creating your order. Please try again or contact us directly.";
            $this->sendResponse($conversation, $response);
            return;
        }

        // Send confirmation
        $confirmation = $this->order->getOrderConfirmationMessage($order);
        $this->sendResponse($conversation, $confirmation);

        // Clear the order context
        $conversation->clearContext();
    }

    /**
     * Handle order status inquiry.
     */
    public function handleOrderStatusInquiry(Conversation $conversation, User $merchant): void
    {
        // Get recent orders for this customer
        $recentOrders = Order::where('conversation_id', $conversation->id)
            ->orderBy('created_at', 'desc')
            ->limit(3)
            ->get();

        if ($recentOrders->isEmpty()) {
            $response = "You don't have any orders yet. Would you like to place an order?";
            $this->sendResponse($conversation, $response);
            return;
        }

        $statusList = $recentOrders->map(function ($order) {
            $statusEmoji = match ($order->status) {
                'pending_payment' => '⏳',
                'processing' => '🔄',
                'completed' => '✅',
                'cancelled' => '❌',
                default => '❓',
            };
            return "{$statusEmoji} Order #{$order->id} - {$order->status_label} (RM" . number_format($order->total_amount, 2) . ")";
        })->implode("\n");

        $response = "*Your Recent Orders:*\n\n" . $statusList . "\n\nNeed help with any of these orders?";
        $this->sendResponse($conversation, $response);
    }
}
