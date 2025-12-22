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
use Carbon\Carbon;

/**
 * Handler for Order Tracking business type.
 * Manages all order-related conversation logic with smart AI responses.
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
     * Converts escaped newlines (literal \n) to real newlines for proper formatting.
     */
    protected function sendResponse(Conversation $conversation, string $content): void
    {
        if ($this->sendResponseCallback) {
            // Convert escaped newlines to real newlines (AI sometimes returns literal \n)
            $content = str_replace(['\\n', '\n'], "\n", $content);
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

        // INTENT-FIRST: Always detect intent first to properly distinguish modifications from new orders
        $intentResult = $this->rag->detectIntent($content, $conversation, 'order_tracking');
        $intent = $intentResult['intent'];
        $entities = $intentResult['entities'];

        Log::info('Order tracking intent detected', [
            'conversation_id' => $conversation->id,
            'intent' => $intent,
            'entities' => $entities,
        ]);

        // Only process as a new order if:
        // 1. Intent is specifically 'order_request' (not modify)
        // 2. Message looks like a filled order form
        if ($intent === 'order_request' && $this->order->isOrderAttempt($content)) {
            $this->handleOrderAttempt($conversation, $content, $merchant);
            return;
        }

        // Handle based on intent
        switch ($intent) {
            case 'greeting':
                // For greetings, let AI generate a friendly response without the order form
                $this->handleSimpleGreeting($conversation, $merchant);
                break;

            case 'order_request':
                // Show order form for order requests (but not filled forms - those handled above)
                $this->handleGreeting($conversation, $merchant);
                break;

            case 'order_inquiry':
                $this->handleOrderInquiry($conversation, $merchant);
                break;

            case 'order_modify':
                $this->handleOrderModify($conversation, $content, $merchant);
                break;

            case 'order_cancel':
                $this->handleOrderCancel($conversation, $merchant);
                break;

            case 'general_question':
            default:
                // Let ConversationHandler handle general questions
                // AI intent detection is trusted
                return;
        }
    }

    /**
     * Handle simple greeting - just a friendly response without order form.
     */
    protected function handleSimpleGreeting(Conversation $conversation, User $merchant): void
    {
        $merchantSettings = $merchant->merchantSettings;
        $businessName = $merchantSettings?->business_name ?? $merchant->name;

        // Let AI generate a natural friendly response
        $aiResponse = $this->rag->generateContextualResponse(
            'greeting',
            $conversation->messages()->orderByDesc('created_at')->first()->content,
            ['business_name' => $businessName],
            $conversation,
            'order_tracking'
        );

        $this->sendResponse($conversation, $aiResponse);
    }

    /**
     * Handle greeting for order tracking - show order form with AI-generated intro.
     * This is required by BusinessHandlerInterface.
     */
    public function handleGreeting(Conversation $conversation, User $merchant): void
    {
        // Get merchant settings templates
        $merchantSettings = $merchant->merchantSettings;
        $orderFormTemplate = $merchantSettings?->booking_form_template;

        // If no custom template, use default
        if (empty($orderFormTemplate)) {
            $orderFormTemplate = $this->order->getOrderFormTemplate($merchant);
        }

        // Prepare business data for AI context
        $businessData = [
            'order_form_template' => $orderFormTemplate,
            'business_name' => $merchantSettings?->business_name ?? $merchant->name,
        ];

        // Let AI generate a natural response that incorporates the order form
        $aiResponse = $this->rag->generateContextualResponse(
            'order_request',
            $conversation->messages()->orderByDesc('created_at')->first()->content,
            $businessData,
            $conversation,
            'order_tracking'
        );

        $this->sendResponse($conversation, $aiResponse);

        // Set context to await order
        $conversation->setContext(Conversation::CONTEXT_ORDER_FLOW, [
            'step' => 'awaiting_form',
        ]);
    }

    /**
     * Handle contextual responses specific to order tracking.
     * INTENT-FIRST: Always detect intent first, only use context if intent matches.
     */
    public function handleContextualResponse(Conversation $conversation, string $content, array $context): bool
    {
        $contextType = $context['type'];
        $contextData = $context['data'] ?? [];

        // INTENT-FIRST: Detect intent from current message
        $intentResult = $this->rag->detectIntent($content, $conversation, 'order_tracking');
        $intent = $intentResult['intent'];
        $entities = $intentResult['entities'];

        Log::info('Intent-first context check (order_tracking)', [
            'conversation_id' => $conversation->id,
            'context_type' => $contextType,
            'detected_intent' => $intent,
        ]);

        // Determine if intent is compatible with current context
        $orderRelatedIntents = ['greeting', 'order_request'];
        $isOrderFormInput = $this->order->isOrderAttempt($content);

        switch ($contextType) {
            case Conversation::CONTEXT_AWAITING_ORDER_CONFIRMATION:
                // This is handled by detectResponseType in ConversationHandler
                return false;

            case Conversation::CONTEXT_ORDER_FLOW:
                // If customer provides order form data, continue order
                if ($isOrderFormInput) {
                    return $this->continueOrderFlow($conversation, $content, $contextData);
                }

                // If intent is still order-related OR providing order details
                if (in_array($intent, $orderRelatedIntents) || !empty($entities['products'])) {
                    return $this->continueOrderFlow($conversation, $content, $contextData);
                }

                // INTENT CHANGED - clear context and let main handler process
                Log::info('Intent changed, clearing order context', [
                    'conversation_id' => $conversation->id,
                    'new_intent' => $intent,
                ]);
                $conversation->clearContext();
                return false;

            case Conversation::CONTEXT_ORDER_SELECTION:
                // User needs to select which order to modify/cancel
                return $this->handleOrderSelection($conversation, $content, $contextData);

            case Conversation::CONTEXT_AWAITING_ORDER_CANCELLATION_CONFIRMATION:
                // This is handled by detectResponseType in ConversationHandler
                return false;
        }

        return false;
    }

    /**
     * Continue order flow when customer provides more details.
     */
    protected function continueOrderFlow(Conversation $conversation, string $content, array $contextData): bool
    {
        // Get merchant
        $merchant = $conversation->merchant;
        if (!$merchant) {
            return false;
        }

        // Try to parse as order
        if ($this->order->isOrderAttempt($content)) {
            $this->handleOrderAttempt($conversation, $content, $merchant);
            return true;
        }

        return false;
    }

    /**
     * Handle a filled order form attempt.
     */
    public function handleOrderAttempt(Conversation $conversation, string $content, ?User $merchant): void
    {
        // Parse the order using AI
        $parsedOrder = $this->order->parseOrderFromMessage($content, $merchant);

        if (!$parsedOrder || !($parsedOrder['is_valid'] ?? false)) {
            $reason = $parsedOrder['reason'] ?? 'Could not parse order details.';
            $missingFields = $parsedOrder['missing_fields'] ?? [];

            // Let AI generate a helpful response
            $response = $this->rag->generateContextualResponse(
                'order_request',
                $content,
                [
                    'action_result' => "Order incomplete: {$reason}",
                    'missing_fields' => $missingFields,
                    'action_needed' => 'Ask the customer for the missing information. Do NOT create the order yet.',
                    'business_name' => $merchant->merchantSettings?->business_name ?? $merchant->name,
                    'products_found' => !empty($parsedOrder['products']),
                ],
                $conversation,
                'order_tracking'
            );

            $this->sendResponse($conversation, $response);
            return;
        }

        // Create the order
        try {
            $order = $this->order->createOrder($parsedOrder, $merchant, $conversation);

            if (!$order) {
                $response = "Sorry, there was an error creating your order. Please try again or contact us directly.";
                $this->sendResponse($conversation, $response);
                return;
            }

            // Send confirmation
            $confirmation = $this->order->getOrderConfirmationMessage($order);
            $this->sendResponse($conversation, $confirmation);

            // Send payment message if configured
            $paymentMessage = $this->order->getPaymentMessage($order);
            if ($paymentMessage) {
                $this->sendResponse($conversation, $paymentMessage);
            }

            // Clear the order context
            $conversation->clearContext();
        } catch (Exception $e) {
            // Log the error but NEVER expose internal errors to customers
            Log::error('Error during order creation', [
                'conversation_id' => $conversation->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            // Switch to admin mode so merchant can handle manually
            $conversation->update([
                'mode' => 'admin',
                'needs_reply' => true,
            ]);

            // Do NOT send any response to customer
        }
    }

    /**
     * Handle order inquiry.
     * Uses AI to craft natural responses showing order details.
     */
    public function handleOrderInquiry(Conversation $conversation, User $merchant): void
    {
        // First try to find orders by conversation_id (most reliable)
        $orders = $this->order->getOrdersByConversation($conversation->id);

        // If no orders found by conversation, try by phone number
        if ($orders->isEmpty() && $conversation->phone_number) {
            $orders = $this->order->getCustomerOrders($conversation->phone_number, $merchant->id);
        }

        if ($orders->isEmpty()) {
            // Set context so "Yes" response will start order flow
            $conversation->setContext(Conversation::CONTEXT_AWAITING_ORDER_CONFIRMATION, [
                'prompted_at' => now()->toDateTimeString(),
            ]);

            // Let AI craft the response
            $response = $this->rag->generateContextualResponse(
                'order_inquiry',
                'checking my order',
                [
                    'orders' => [],
                    'action_needed' => 'No orders found - offer to place a new order',
                ],
                $conversation,
                'order_tracking'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Format orders for AI context
        $orderData = $orders->map(function ($order) {
            return [
                'id' => $order->id,
                'status' => $order->status_label,
                'items' => $order->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', '),
                'total' => 'RM' . number_format($order->total_amount, 2),
                'datetime' => $order->requested_datetime?->format('d M Y, g:i A'),
                'fulfillment' => $order->fulfillment_type,
            ];
        })->toArray();

        // Let AI craft a natural response
        $response = $this->rag->generateContextualResponse(
            'order_inquiry',
            'checking my order',
            ['orders' => $orderData],
            $conversation,
            'order_tracking'
        );
        $this->sendResponse($conversation, $response);
    }

    /**
     * Handle order modification request.
     * Uses AI to craft natural responses with order context.
     * Asks user to choose if multiple active orders exist.
     */
    public function handleOrderModify(Conversation $conversation, string $content, User $merchant): void
    {
        // First try to find orders by conversation_id
        $orders = $this->order->getOrdersByConversation($conversation->id);

        // If no orders found by conversation, try by phone number
        if ($orders->isEmpty() && $conversation->phone_number) {
            $orders = $this->order->getCustomerOrders($conversation->phone_number, $merchant->id);
        }

        if ($orders->isEmpty()) {
            $response = $this->rag->generateContextualResponse(
                'order_modify',
                $content,
                [
                    'orders' => [],
                    'action_result' => 'No active orders found for this customer',
                ],
                $conversation,
                'order_tracking'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Format all orders for AI context
        $orderData = $orders->map(function ($order, $index) {
            return [
                'number' => $index + 1,
                'id' => $order->id,
                'status' => $order->status_label,
                'items' => $order->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', '),
                'total' => 'RM' . number_format($order->total_amount, 2),
                'datetime' => $order->requested_datetime?->format('d M Y, g:i A'),
                'fulfillment' => $order->fulfillment_type,
            ];
        })->toArray();

        // Check if user has already selected an order from context
        $context = $conversation->getContext();
        $selectedOrderId = null;

        if ($context && $context['type'] === Conversation::CONTEXT_ORDER_SELECTION) {
            $selectedOrderId = $context['data']['order_id'] ?? null;
        }

        // If multiple orders and no selection yet, ask user to choose
        if ($orders->count() > 1 && !$selectedOrderId) {
            // Set context to await order selection
            $orderIds = $orders->pluck('id')->toArray();
            $conversation->setContext(Conversation::CONTEXT_ORDER_SELECTION, [
                'action' => 'modify',
                'order_ids' => $orderIds,
            ]);

            $response = $this->rag->generateContextualResponse(
                'order_modify',
                $content,
                [
                    'orders' => $orderData,
                    'action_needed' => 'Multiple orders found. Ask customer which order they want to modify by number (1, 2, 3, etc.)',
                ],
                $conversation,
                'order_tracking'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Use selected order or first order
        $order = $selectedOrderId
            ? $orders->firstWhere('id', $selectedOrderId)
            : $orders->first();

        if (!$order) {
            $this->sendResponse($conversation, "I couldn't find that order. Please try again.");
            return;
        }

        // Clear selection context
        if ($selectedOrderId) {
            $conversation->clearContext();
        }

        // Use AI to parse what the customer wants to change
        $newDetails = $this->order->parseOrderChanges($content, $order, $conversation);

        Log::info('AI parsed order modification request', [
            'conversation_id' => $conversation->id,
            'order_id' => $order->id,
            'content' => $content,
            'parsed_details' => $newDetails,
        ]);

        // If customer provided new details, try to modify
        if (!empty($newDetails)) {
            try {
                // Store previous total for payment calculations
                $previousTotal = (float) $order->total_amount;

                $updatedOrder = $this->order->modifyOrder($order, $newDetails);

                $updatedData = [
                    'id' => $updatedOrder->id,
                    'status' => $updatedOrder->status_label,
                    'items' => $updatedOrder->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', '),
                    'total' => 'RM ' . number_format((float) $updatedOrder->total_amount, 2),
                    'datetime' => $updatedOrder->requested_datetime?->format('d M Y, g:i A'),
                    'fulfillment' => $updatedOrder->fulfillment_type,
                ];

                $response = $this->rag->generateContextualResponse(
                    'order_modify',
                    $content,
                    [
                        'orders' => [$updatedData],
                        'action_result' => 'Order successfully updated',
                    ],
                    $conversation,
                    'order_tracking'
                );
                $this->sendResponse($conversation, $response);

                // Send payment message if applicable (price changed)
                $paymentMessage = $this->order->getPaymentMessage($updatedOrder, $previousTotal);
                if ($paymentMessage) {
                    $this->sendResponse($conversation, $paymentMessage);
                }

                return;

            } catch (Exception $e) {
                Log::error('Order modification failed', [
                    'conversation_id' => $conversation->id,
                    'order_id' => $order->id,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);

                // Switch to admin mode
                $conversation->update([
                    'mode' => 'admin',
                    'needs_reply' => true,
                ]);
                return;
            }
        }

        // No new details provided - ask what they want to change
        $currentOrderData = [
            'id' => $order->id,
            'status' => $order->status_label,
            'items' => $order->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', '),
            'total' => 'RM' . number_format($order->total_amount, 2),
            'datetime' => $order->requested_datetime?->format('d M Y, g:i A'),
            'fulfillment' => $order->fulfillment_type,
            'delivery_address' => $order->delivery_address,
        ];

        $response = $this->rag->generateContextualResponse(
            'order_modify',
            $content,
            [
                'orders' => [$currentOrderData],
                'action_needed' => 'Ask customer what they would like to change (items, delivery time, delivery address, or fulfillment type)',
            ],
            $conversation,
            'order_tracking'
        );
        $this->sendResponse($conversation, $response);
    }

    /**
     * Handle order selection when user has multiple orders.
     * Processes user input like "1", "2", "first", etc.
     */
    protected function handleOrderSelection(Conversation $conversation, string $content, array $contextData): bool
    {
        $orderIds = $contextData['order_ids'] ?? [];
        $action = $contextData['action'] ?? 'modify';

        if (empty($orderIds)) {
            $conversation->clearContext();
            return false;
        }

        // Try to extract selection number from message
        $selection = null;

        // Check for number patterns: "1", "#1", "number 1", "first", etc.
        if (preg_match('/^#?(\d+)$/', trim($content), $match)) {
            $selection = (int) $match[1];
        } elseif (preg_match('/(first|1st)/i', $content)) {
            $selection = 1;
        } elseif (preg_match('/(second|2nd)/i', $content)) {
            $selection = 2;
        } elseif (preg_match('/(third|3rd)/i', $content)) {
            $selection = 3;
        } elseif (preg_match('/number\s*(\d+)/i', $content, $match)) {
            $selection = (int) $match[1];
        }

        // Validate selection
        if ($selection && $selection >= 1 && $selection <= count($orderIds)) {
            $selectedOrderId = $orderIds[$selection - 1];

            // Clear selection context and proceed with action
            if ($action === 'cancel') {
                // Set confirmation context and proceed
                $conversation->setContext(Conversation::CONTEXT_AWAITING_ORDER_CANCELLATION_CONFIRMATION, [
                    'order_id' => $selectedOrderId,
                ]);

                $order = Order::find($selectedOrderId);
                if ($order) {
                    $response = $this->rag->generateContextualResponse(
                        'order_cancel',
                        $content,
                        [
                            'orders' => [
                                [
                                    'id' => $order->id,
                                    'status' => $order->status_label,
                                    'items' => $order->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', '),
                                    'total' => 'RM' . number_format((float) $order->total_amount, 2),
                                ]
                            ],
                            'action_needed' => 'Ask customer to confirm cancellation of this order',
                        ],
                        $conversation,
                        'order_tracking'
                    );
                    $this->sendResponse($conversation, $response);
                    return true;
                }
            } else {
                // Modify action - store selected order in context for modification
                $conversation->setContext(Conversation::CONTEXT_ORDER_SELECTION, [
                    'action' => 'modify',
                    'order_id' => $selectedOrderId,
                    'order_ids' => $orderIds,
                ]);

                // Re-call handleOrderModify with the selected order
                $merchant = $conversation->merchant;
                if ($merchant) {
                    $this->handleOrderModify($conversation, $content, $merchant);
                    return true;
                }
            }
        }

        // Selection not recognized - ask again
        $orders = Order::whereIn('id', $orderIds)->with('items')->get();
        $orderData = $orders->map(function ($order, $index) {
            return [
                'number' => $index + 1,
                'id' => $order->id,
                'status' => $order->status_label,
                'items' => $order->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', '),
                'total' => 'RM' . number_format($order->total_amount, 2),
            ];
        })->toArray();

        $response = $this->rag->generateContextualResponse(
            $action === 'cancel' ? 'order_cancel' : 'order_modify',
            $content,
            [
                'orders' => $orderData,
                'action_needed' => "Customer input not recognized. Ask them to reply with a number (1, 2, 3) to select which order to {$action}.",
            ],
            $conversation,
            'order_tracking'
        );
        $this->sendResponse($conversation, $response);
        return true;
    }

    /**
     * Handle order cancellation.
     * Asks user to choose if multiple active orders exist.
     */
    public function handleOrderCancel(Conversation $conversation, User $merchant): void
    {
        // First try to find orders by conversation_id
        $orders = $this->order->getOrdersByConversation($conversation->id);

        // If no orders found by conversation, try by phone number
        if ($orders->isEmpty() && $conversation->phone_number) {
            $orders = $this->order->getCustomerOrders($conversation->phone_number, $merchant->id);
        }

        if ($orders->isEmpty()) {
            $conversation->setContext(Conversation::CONTEXT_AWAITING_ORDER_CONFIRMATION, [
                'prompted_at' => now()->toDateTimeString(),
            ]);

            $response = $this->rag->generateContextualResponse(
                'order_cancel',
                'cancel my order',
                [
                    'orders' => [],
                    'action_result' => 'No active orders found to cancel',
                ],
                $conversation,
                'order_tracking'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Format orders for AI display
        $orderData = $orders->map(function ($order, $index) {
            return [
                'number' => $index + 1,
                'id' => $order->id,
                'status' => $order->status_label,
                'items' => $order->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', '),
                'total' => 'RM' . number_format($order->total_amount, 2),
                'datetime' => $order->requested_datetime?->format('d M Y, g:i A'),
            ];
        })->toArray();

        // If multiple orders, ask user to choose which one to cancel
        if ($orders->count() > 1) {
            $conversation->setContext(Conversation::CONTEXT_ORDER_SELECTION, [
                'action' => 'cancel',
                'order_ids' => $orders->pluck('id')->toArray(),
            ]);

            $response = $this->rag->generateContextualResponse(
                'order_cancel',
                'cancel my order',
                [
                    'orders' => $orderData,
                    'action_needed' => 'Multiple orders found. Ask customer which order they want to cancel by number (1, 2, 3, etc.)',
                ],
                $conversation,
                'order_tracking'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Single order - ask for confirmation
        $order = $orders->first();
        $conversation->setContext(Conversation::CONTEXT_AWAITING_ORDER_CANCELLATION_CONFIRMATION, [
            'order_id' => $order->id,
        ]);

        $response = $this->rag->generateContextualResponse(
            'order_cancel',
            'cancel my order',
            [
                'orders' => [$orderData[0]],
                'action_needed' => 'Ask customer to confirm they want to cancel this order',
            ],
            $conversation,
            'order_tracking'
        );
        $this->sendResponse($conversation, $response);
    }

    /**
     * Execute order cancellation after confirmation.
     * Called by ConversationHandler when customer confirms cancellation.
     */
    public function executeCancellation(Conversation $conversation, int $orderId): void
    {
        $order = Order::find($orderId);

        if (!$order) {
            $this->sendResponse($conversation, "I couldn't find that order. It may have already been cancelled.");
            $conversation->clearContext();
            return;
        }

        try {
            $this->order->cancelOrder($order);

            $response = $this->rag->generateContextualResponse(
                'order_cancel',
                'confirmed cancellation',
                [
                    'orders' => [
                        [
                            'id' => $order->id,
                            'status' => 'Cancelled',
                        ]
                    ],
                    'action_result' => 'Order successfully cancelled',
                ],
                $conversation,
                'order_tracking'
            );
            $this->sendResponse($conversation, $response);
            $conversation->clearContext();

        } catch (Exception $e) {
            Log::error('Order cancellation failed', [
                'conversation_id' => $conversation->id,
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);

            $conversation->update([
                'mode' => 'admin',
                'needs_reply' => true,
            ]);
        }
    }
}
