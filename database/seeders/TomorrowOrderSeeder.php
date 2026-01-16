<?php

namespace Database\Seeders;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use App\Models\Conversation;
use Illuminate\Database\Seeder;

class TomorrowOrderSeeder extends Seeder
{
    /**
     * Create an order for tomorrow with a specific phone number.
     * Used for testing order reminder functionality.
     */
    public function run(): void
    {
        // Find the shop merchant (order_tracking business type)
        $merchant = User::where('business_type', User::BUSINESS_ORDER_TRACKING)->first();

        if (!$merchant) {
            $this->command->error('No order_tracking merchant found. Please run UsersSeeder first.');
            return;
        }

        // Create or get conversation for this phone number
        $conversation = Conversation::firstOrCreate(
            [
                'user_id' => $merchant->id,
                'phone_number' => '60167763663',
            ],
            [
                'whatsapp_id' => '60167763663',
                'customer_name' => 'Test Customer',
                'mode' => 'ai',
                'status' => 'active',
                'needs_reply' => false,
                'last_message_at' => now(),
            ]
        );

        // Generate order code
        $lastOrder = Order::where('user_id', $merchant->id)
            ->orderBy('id', 'desc')
            ->first();

        $orderPrefix = $merchant->orderTrackingSetting?->order_prefix ?? 'ORD';
        $lastNumber = 0;
        if ($lastOrder && $lastOrder->code) {
            $numericPart = preg_replace('/^[A-Za-z]+-/', '', $lastOrder->code);
            $lastNumber = (int) $numericPart;
        }
        $nextNumber = $lastNumber + 1;
        $orderCode = $orderPrefix . '-' . str_pad($nextNumber, 4, '0', STR_PAD_LEFT);

        // Create order for tomorrow at 3pm
        $order = Order::create([
            'user_id' => $merchant->id,
            'conversation_id' => $conversation->id,
            'code' => $orderCode,
            'customer_name' => 'Test Customer',
            'customer_phone' => '60167763663',
            'fulfillment_type' => 'pickup',
            'delivery_address' => null,
            'requested_datetime' => now()->addDay()->setHour(15)->setMinute(0)->setSecond(0),
            'notes' => 'Test order for reminder system',
            'status' => Order::STATUS_PROCESSING,
            'total_amount' => 0,
            'reminder_sent' => false,
        ]);

        // Add some items to the order
        $products = Product::where('user_id', $merchant->id)->limit(2)->get();
        $total = 0;

        foreach ($products as $product) {
            $quantity = 2;
            $subtotal = $product->price * $quantity;
            $total += $subtotal;

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'product_name' => $product->name,
                'quantity' => $quantity,
                'unit_price' => $product->price,
                'subtotal' => $subtotal,
            ]);
        }

        // Update total
        $order->update(['total_amount' => $total]);

        $this->command->info('');
        $this->command->info('✅ Tomorrow order created successfully!');
        $this->command->info('');
        $this->command->info('📋 Order Details:');
        $this->command->info("   Order Code: {$order->code}");
        $this->command->info("   Customer Phone: {$order->customer_phone}");
        $this->command->info("   Scheduled For: {$order->requested_datetime->format('d M Y, g:i A')}");
        $this->command->info("   Total: RM " . number_format($order->total_amount, 2));
        $this->command->info('');
        $this->command->info('💡 Run the reminder job with:');
        $this->command->info('   php artisan order:send-reminders');
    }
}
