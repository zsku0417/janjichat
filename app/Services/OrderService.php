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
     */
    public function getOrderFormTemplate(User $merchant): string
    {
        $businessName = $merchant->name ?? 'Our Store';

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

                // Create the order
                $order = Order::create([
                    'user_id' => $merchant->id,
                    'conversation_id' => $conversation->id,
                    'customer_name' => $conversation->customer_name ?? 'Customer',
                    'customer_phone' => $conversation->phone_number ?? $conversation->whatsapp_id,
                    'fulfillment_type' => $fulfillmentType,
                    'delivery_address' => $orderData['delivery_address'] ?? null,
                    'requested_datetime' => $requestedDatetime,
                    'special_notes' => $orderData['special_notes'] ?? null,
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
     */
    public function getOrderConfirmationMessage(Order $order): string
    {
        $order->load('items');

        $itemsList = $order->items->map(function ($item) {
            return "• {$item->product_name} x{$item->quantity} - RM" . number_format($item->subtotal, 2);
        })->implode("\n");

        $fulfillment = $order->fulfillment_type === 'pickup'
            ? '🏪 Pickup'
            : "🚚 Delivery to: {$order->delivery_address}";

        $notes = $order->special_notes ? "\n📝 Notes: {$order->special_notes}" : '';

        return <<<MESSAGE
✅ *Order Confirmed!*

Order #{$order->id}

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
}
