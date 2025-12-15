<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\MerchantSetting;
use App\Models\OrderTrackingSetting;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Database\Seeder;

class OrderTrackingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Creates order tracking-related data for the demo merchant.
     */
    public function run(): void
    {
        $merchant = User::where('email', 'merchant@example.com')->first();

        if (!$merchant) {
            $this->command->error('Merchant not found! Run UsersSeeder first.');
            return;
        }

        // Create merchant settings (if not exists)
        MerchantSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'business_name' => 'Demo Store',
                'greeting_message' => "Welcome to Demo Store! 🛍️\n\nHow can I help you today?\n• Check order status\n• Browse products\n• Track delivery",
                'ai_tone' => 'You are a friendly and helpful store assistant. Be professional, efficient, and helpful in your responses.',
                'booking_form_template' => null,
                'confirmation_template' => "Your order has been placed! 🎉\n\nOrder: {order_code}\n📦 Items: {items}\n💰 Total: RM{total}\n\nWe'll notify you when it's ready!",
                'reminder_template' => null,
                'reminder_hours_before' => 24,
            ]
        );

        // Create order tracking settings
        OrderTrackingSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'pickup_address' => '123 Demo Street, Kuala Lumpur, Malaysia',
                'order_prefix' => 'ORD-',
            ]
        );

        // Create sample products
        $products = [
            ['name' => 'Product A', 'description' => 'High quality product A', 'price' => 29.90, 'sku' => 'PROD-A'],
            ['name' => 'Product B', 'description' => 'Premium product B', 'price' => 49.90, 'sku' => 'PROD-B'],
            ['name' => 'Product C', 'description' => 'Budget-friendly product C', 'price' => 19.90, 'sku' => 'PROD-C'],
            ['name' => 'Product D', 'description' => 'Deluxe product D', 'price' => 99.90, 'sku' => 'PROD-D'],
        ];

        foreach ($products as $productData) {
            Product::updateOrCreate(
                ['user_id' => $merchant->id, 'sku' => $productData['sku']],
                array_merge($productData, ['user_id' => $merchant->id, 'is_active' => true])
            );
        }

        // Create sample orders
        $productA = Product::where('user_id', $merchant->id)->where('sku', 'PROD-A')->first();
        $productB = Product::where('user_id', $merchant->id)->where('sku', 'PROD-B')->first();

        $orders = [
            [
                'code' => '001',
                'customer_name' => 'Alice Wong',
                'customer_phone' => '60111222333',
                'fulfillment_type' => 'pickup',
                'status' => 'processing',
            ],
            [
                'code' => '002',
                'customer_name' => 'Bob Tan',
                'customer_phone' => '60444555666',
                'fulfillment_type' => 'delivery',
                'delivery_address' => '456 Customer Road, Petaling Jaya',
                'status' => 'pending_payment',
            ],
        ];

        foreach ($orders as $orderData) {
            $order = Order::updateOrCreate(
                ['user_id' => $merchant->id, 'code' => $orderData['code']],
                array_merge($orderData, ['user_id' => $merchant->id, 'total_amount' => 0])
            );

            // Add items to first order
            if ($orderData['code'] === '001' && $productA && $productB) {
                OrderItem::updateOrCreate(
                    ['order_id' => $order->id, 'product_id' => $productA->id],
                    [
                        'product_name' => $productA->name,
                        'unit_price' => $productA->price,
                        'quantity' => 2,
                        'subtotal' => $productA->price * 2,
                    ]
                );
                OrderItem::updateOrCreate(
                    ['order_id' => $order->id, 'product_id' => $productB->id],
                    [
                        'product_name' => $productB->name,
                        'unit_price' => $productB->price,
                        'quantity' => 1,
                        'subtotal' => $productB->price,
                    ]
                );
                $order->update(['total_amount' => $productA->price * 2 + $productB->price]);
            }
        }

        $this->command->info('Order tracking data seeded successfully!');
        $this->command->info('- Merchant settings updated');
        $this->command->info('- Order tracking settings created');
        $this->command->info('- 4 products created');
        $this->command->info('- 2 sample orders created');
    }
}
