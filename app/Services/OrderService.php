<?php

namespace App\Services;

use App\Models\Conversation;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Exception;

class OrderService
{
    protected OpenAIService $openAI;

    public function __construct(OpenAIService $openAI)
    {
        $this->openAI = $openAI;
    }

    /**
     * Get the order form template for the merchant.
     * Uses custom template from settings if set, otherwise falls back to default.
     */
    public function getOrderFormTemplate(User $merchant): string
    {
        // Check for custom template in merchant settings
        $setting = $merchant->merchantSetting;
        if ($setting && !empty($setting->booking_form_template)) {
            return $setting->booking_form_template;
        }

        // Default template
        $businessName = $setting?->business_name ?? $merchant->name ?? 'Our Store';

        return <<<TEMPLATE
Welcome to {$businessName}! 🛒

To place an order please fill in the form below:

📦 *Product you want to order:*
(e.g.:
Product A x2
Product B x3)

📅 *Date Time Need* (e.g. DD-MM-YYYY, 2:45pm):

📍 *Delivery Address* (Leave blank for pickup):

📝 *Special Note:*

---
Please copy and fill in the form, then send it back to us!
TEMPLATE;
    }

    /**
     * Parse order details from customer message using AI.
     */
    public function parseOrderFromMessage(string $message, User $merchant): ?array
    {
        // Get active products for context
        $products = $merchant->products()->active()->get();
        $productList = $products->map(fn($p) => "- {$p->name} (RM{$p->price})")->implode("\n");

        $prompt = <<<PROMPT
You are parsing a customer order message. The merchant has these products available:
{$productList}

Customer message:
---
{$message}
---

Extract the following information from the message. Return a JSON object with these fields:
- products: array of {name: string, quantity: number} - match to available products or use the name customer provided
- datetime: string in "YYYY-MM-DD HH:mm" format (convert relative dates like "tomorrow" to actual dates, current date is today)
- delivery_address: string or null (null if empty/blank or pickup)
- special_notes: string or null
- is_valid: boolean - true if all required fields (products, datetime) are present

If you can't parse the message as an order, return: {"is_valid": false, "reason": "explanation"}

Current date/time: {now}

IMPORTANT: Return ONLY valid JSON, no markdown, no explanation.
PROMPT;

        $prompt = str_replace('{now}', now()->format('Y-m-d H:i'), $prompt);

        try {
            $response = $this->openAI->chat([
                ['role' => 'user', 'content' => $prompt]
            ]);

            // Clean the response - remove markdown code blocks if present
            $response = preg_replace('/```json\s*/', '', $response);
            $response = preg_replace('/```\s*/', '', $response);
            $response = trim($response);

            $parsed = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                Log::warning('Failed to parse AI order response as JSON', [
                    'response' => $response,
                    'error' => json_last_error_msg(),
                ]);
                return null;
            }

            return $parsed;
        } catch (Exception $e) {
            Log::error('Failed to parse order with AI', [
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Create an order from parsed data.
     */
    public function createOrder(array $orderData, User $merchant, Conversation $conversation): ?Order
    {
        try {
            return DB::transaction(function () use ($orderData, $merchant, $conversation) {
                // Determine fulfillment type
                $fulfillmentType = !empty($orderData['delivery_address']) ? 'delivery' : 'pickup';

                // Parse datetime
                $requestedDatetime = $this->parseDateTime($orderData['datetime'] ?? '');
                if (!$requestedDatetime) {
                    $requestedDatetime = now()->addDay(); // Default to tomorrow
                }

                // Generate unique order code for this merchant
                // Get order prefix from OrderTrackingSetting if available
                $orderPrefix = $merchant->orderTrackingSetting?->order_prefix;

                // Find the last order number for this merchant
                $lastOrder = Order::where('user_id', $merchant->id)
                    ->orderBy('id', 'desc')
                    ->first();

                // Extract numeric part from last order code  
                $lastNumber = 0;
                if ($lastOrder && $lastOrder->code) {
                    // Remove prefix if present to get just the number
                    $numericPart = preg_replace('/^[A-Za-z]+-/', '', $lastOrder->code);
                    $lastNumber = (int) $numericPart;
                }

                $nextNumber = $lastNumber + 1;
                $numberPart = str_pad($nextNumber, 4, '0', STR_PAD_LEFT);
                $orderCode = $orderPrefix ? "{$orderPrefix}-{$numberPart}" : $numberPart;

                // Create the order
                $order = Order::create([
                    'user_id' => $merchant->id,
                    'conversation_id' => $conversation->id,
                    'code' => $orderCode,
                    'customer_name' => $conversation->customer_name ?? 'Customer',
                    'customer_phone' => $conversation->phone_number ?? $conversation->whatsapp_id,
                    'fulfillment_type' => $fulfillmentType,
                    'delivery_address' => $orderData['delivery_address'] ?? null,
                    'requested_datetime' => $requestedDatetime,
                    'notes' => $orderData['special_notes'] ?? null,
                    'status' => Order::STATUS_PENDING_PAYMENT,
                    'total_amount' => 0,
                ]);

                $totalAmount = 0;

                // Create order items
                foreach ($orderData['products'] ?? [] as $productData) {
                    $productName = $productData['name'];
                    $quantity = (int) ($productData['quantity'] ?? 1);

                    // Try to find matching product
                    $product = $merchant->products()
                        ->where('name', 'LIKE', "%{$productName}%")
                        ->active()
                        ->first();

                    $unitPrice = $product?->price ?? 0;
                    $subtotal = $unitPrice * $quantity;
                    $totalAmount += $subtotal;

                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $product?->id,
                        'product_name' => $product?->name ?? $productName,
                        'quantity' => $quantity,
                        'unit_price' => $unitPrice,
                        'subtotal' => $subtotal,
                    ]);
                }

                // Update total amount
                $order->update(['total_amount' => $totalAmount]);

                Log::info('Order created from WhatsApp', [
                    'order_id' => $order->id,
                    'conversation_id' => $conversation->id,
                    'total' => $totalAmount,
                ]);

                return $order;
            });
        } catch (Exception $e) {
            Log::error('Failed to create order', [
                'error' => $e->getMessage(),
                'order_data' => $orderData,
            ]);
            return null;
        }
    }

    /**
     * Generate order confirmation message.
     * Uses custom template from settings if set, otherwise falls back to default.
     */
    public function getOrderConfirmationMessage(Order $order): string
    {
        $order->load(['items', 'user.merchantSettings']);

        // Prepare data for placeholders
        $itemsList = $order->items->map(function ($item) {
            return "• {$item->product_name} x{$item->quantity} - RM" . number_format($item->subtotal, 2);
        })->implode("\n");

        $fulfillment = $order->fulfillment_type === 'pickup'
            ? '🏪 Pickup'
            : "🚚 Delivery to: {$order->delivery_address}";

        $notes = $order->notes ? "\n📝 Notes: {$order->notes}" : '';

        // Check for custom template
        $setting = $order->user?->merchantSettings;
        if ($setting && !empty($setting->confirmation_template)) {
            // Replace placeholders in custom template
            $template = $setting->confirmation_template;
            $replacements = [
                '{name}' => $order->customer_name,
                '{order_code}' => $order->code,
                '{total}' => 'RM' . $order->formatted_total,
                '{items}' => $itemsList,
                '{datetime}' => $order->requested_datetime?->format('d M Y, g:i A') ?? 'TBD',
                '{fulfillment}' => $fulfillment,
                '{phone}' => $order->customer_phone,
                '{notes}' => $notes,
            ];

            return str_replace(array_keys($replacements), array_values($replacements), $template);
        }

        // Default template
        return <<<MESSAGE
✅ *Order Confirmed!*

Order #{$order->code}

*Items:*
{$itemsList}

💰 *Total: RM{$order->formatted_total}*

📅 *Requested Time:* {$order->requested_datetime->format('d M Y, g:i A')}
{$fulfillment}{$notes}

---
Your order status: *Pending Payment Verification*

We will notify you once payment is verified and your order is being processed. Thank you! 🙏
MESSAGE;
    }

    /**
     * Parse datetime string to Carbon instance.
     */
    protected function parseDateTime(?string $datetime): ?Carbon
    {
        if (empty($datetime)) {
            return null;
        }

        try {
            return Carbon::parse($datetime);
        } catch (Exception $e) {
            Log::warning('Failed to parse datetime', [
                'datetime' => $datetime,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Check if a message looks like an order attempt.
     */
    public function isOrderAttempt(string $message): bool
    {
        // Look for patterns that suggest an order
        $orderPatterns = [
            '/\bx\d+/i',  // e.g., x2, x3
            '/\d+\s*(pcs?|pieces?|units?)/i',
            '/delivery\s*address/i',
            '/pickup/i',
            '/special\s*note/i',
            '/product.*order/i',
            '/order.*product/i',
            '/\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4}/i',  // Date patterns
            '/\d{1,2}[:.]\d{2}\s*(am|pm)?/i',  // Time patterns
        ];

        foreach ($orderPatterns as $pattern) {
            if (preg_match($pattern, $message)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Get orders by conversation ID.
     */
    public function getOrdersByConversation(int $conversationId): \Illuminate\Support\Collection
    {
        return Order::where('conversation_id', $conversationId)
            ->whereNotIn('status', [Order::STATUS_CANCELLED, Order::STATUS_COMPLETED])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Get orders by customer phone number.
     */
    public function getCustomerOrders(string $phone, ?int $userId = null): \Illuminate\Support\Collection
    {
        $query = Order::where('customer_phone', $phone)
            ->whereNotIn('status', [Order::STATUS_CANCELLED, Order::STATUS_COMPLETED])
            ->orderBy('created_at', 'desc');

        if ($userId) {
            $query->where('user_id', $userId);
        }

        return $query->get();
    }

    /**
     * Parse order changes from customer message using AI.
     */
    public function parseOrderChanges(string $message, Order $order, Conversation $conversation): array
    {
        $order->load('items');

        $currentOrderInfo = "Current order details:\n";
        $currentOrderInfo .= "- Order ID: #{$order->id}\n";
        $currentOrderInfo .= "- Items: " . $order->items->map(fn($i) => "{$i->product_name} x{$i->quantity}")->implode(', ') . "\n";
        $currentOrderInfo .= "- Requested datetime: " . ($order->requested_datetime?->format('Y-m-d H:i') ?? 'Not set') . "\n";
        $currentOrderInfo .= "- Fulfillment: {$order->fulfillment_type}\n";
        if ($order->delivery_address) {
            $currentOrderInfo .= "- Delivery address: {$order->delivery_address}\n";
        }

        $conversationHistory = $this->getConversationHistoryForContext($conversation);

        $prompt = <<<PROMPT
You are helping a customer modify their order.

{$currentOrderInfo}

Conversation history:
{$conversationHistory}

Customer's modification request:
"{$message}"

Current date/time: {now}

Extract ONLY the NEW details the customer wants to change. Return a JSON object with:
- datetime: new datetime in "YYYY-MM-DD HH:mm" format (only if customer specified a new time)
- delivery_address: new address (only if customer wants to change delivery location)
- fulfillment_type: "pickup" or "delivery" (only if customer wants to change)
- special_notes: additional notes (only if customer mentioned new notes)
- add_items: array of {name: string, quantity: number} to add
- remove_items: array of product names to remove

Only include fields that the customer explicitly mentioned changing. Use null for unchanged fields.
If the customer is just asking what can be changed or asking about their order without providing new details, return all nulls.

Return ONLY valid JSON, no markdown.
PROMPT;

        $prompt = str_replace('{now}', now()->format('Y-m-d H:i'), $prompt);

        try {
            $response = $this->openAI->chat([
                ['role' => 'user', 'content' => $prompt]
            ]);

            $response = preg_replace('/```json\s*/', '', $response);
            $response = preg_replace('/```\s*/', '', $response);
            $response = trim($response);

            $parsed = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                Log::warning('Failed to parse AI order change response', [
                    'response' => $response,
                    'error' => json_last_error_msg(),
                ]);
                return [];
            }

            // Filter out null values
            return array_filter($parsed, fn($v) => $v !== null && $v !== '' && (!is_array($v) || !empty($v)));
        } catch (Exception $e) {
            Log::error('Failed to parse order changes with AI', [
                'error' => $e->getMessage(),
            ]);
            return [];
        }
    }

    /**
     * Get conversation history for AI context.
     */
    protected function getConversationHistoryForContext(Conversation $conversation): string
    {
        $messages = $conversation->messages()
            ->orderBy('created_at', 'desc')
            ->take(10)
            ->get()
            ->reverse();

        $history = "";
        foreach ($messages as $msg) {
            $role = $msg->direction === 'inbound' ? 'Customer' : 'Assistant';
            $history .= "{$role}: {$msg->content}\n";
        }

        return $history;
    }

    /**
     * Modify an existing order.
     */
    public function modifyOrder(Order $order, array $changes): Order
    {
        $updateData = [];

        if (isset($changes['datetime'])) {
            $updateData['requested_datetime'] = Carbon::parse($changes['datetime']);
        }

        if (isset($changes['delivery_address'])) {
            $updateData['delivery_address'] = $changes['delivery_address'];
            $updateData['fulfillment_type'] = 'delivery';
        }

        if (isset($changes['fulfillment_type'])) {
            $updateData['fulfillment_type'] = $changes['fulfillment_type'];
            if ($changes['fulfillment_type'] === 'pickup') {
                $updateData['delivery_address'] = null;
            }
        }

        if (isset($changes['special_notes'])) {
            $existingNotes = $order->notes ?? '';
            $updateData['notes'] = trim($existingNotes . "\n" . $changes['special_notes']);
        }

        if (!empty($updateData)) {
            $order->update($updateData);
        }

        // Handle adding items
        if (!empty($changes['add_items'])) {
            $merchant = $order->user;
            foreach ($changes['add_items'] as $itemData) {
                $productName = $itemData['name'];
                $quantity = (int) ($itemData['quantity'] ?? 1);

                $product = $merchant->products()
                    ->where('name', 'LIKE', "%{$productName}%")
                    ->active()
                    ->first();

                $unitPrice = $product?->price ?? 0;
                $subtotal = $unitPrice * $quantity;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product?->id,
                    'product_name' => $product?->name ?? $productName,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                    'subtotal' => $subtotal,
                ]);
            }

            // Recalculate total
            $order->update([
                'total_amount' => $order->items()->sum('subtotal')
            ]);
        }

        // Handle removing items
        if (!empty($changes['remove_items'])) {
            foreach ($changes['remove_items'] as $productName) {
                $order->items()
                    ->where('product_name', 'LIKE', "%{$productName}%")
                    ->delete();
            }

            // Recalculate total
            $order->update([
                'total_amount' => $order->items()->sum('subtotal')
            ]);
        }

        Log::info('Order modified', [
            'order_id' => $order->id,
            'changes' => $changes,
        ]);

        return $order->fresh(['items']);
    }

    /**
     * Cancel an order.
     */
    public function cancelOrder(Order $order): Order
    {
        $order->update([
            'status' => Order::STATUS_CANCELLED,
        ]);

        Log::info('Order cancelled', [
            'order_id' => $order->id,
        ]);

        return $order->fresh();
    }

    /**
     * Generate order reminder message.
     * Uses custom template from settings if set, otherwise falls back to default.
     */
    public function getOrderReminderMessage(Order $order): string
    {
        $order->load(['items', 'user.merchantSettings']);

        $itemsList = $order->items->map(function ($item) {
            return "• {$item->product_name} x{$item->quantity}";
        })->implode("\n");

        $fulfillment = $order->fulfillment_type === 'pickup'
            ? '🏪 Pickup'
            : "🚚 Delivery to: {$order->delivery_address}";

        // Check for custom template
        $setting = $order->user?->merchantSettings;
        if ($setting && !empty($setting->reminder_template)) {
            $template = $setting->reminder_template;
            $replacements = [
                '{name}' => $order->customer_name,
                '{order_code}' => $order->code,
                '{total}' => 'RM' . $order->formatted_total,
                '{items}' => $itemsList,
                '{datetime}' => $order->requested_datetime?->format('d M Y, g:i A') ?? 'TBD',
                '{fulfillment}' => $fulfillment,
                '{phone}' => $order->customer_phone,
            ];

            return str_replace(array_keys($replacements), array_values($replacements), $template);
        }

        // Default template
        return <<<MESSAGE
⏰ *Order Reminder*

Hi {$order->customer_name}!

This is a friendly reminder about your upcoming order:

Order #{$order->code}
📅 *Scheduled for:* {$order->requested_datetime->format('d M Y, g:i A')}
{$fulfillment}

*Items:*
{$itemsList}

💰 *Total: RM{$order->formatted_total}*

See you soon! 🙏
MESSAGE;
    }
}
