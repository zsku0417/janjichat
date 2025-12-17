<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\MerchantSetting;
use App\Models\RestaurantSetting;
use App\Models\Table;
use App\Models\Booking;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class RestaurantSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Creates restaurant-related data for the demo merchant.
     */
    public function run(): void
    {
        $merchant = User::where('email', 'merchant@example.com')->first();

        if (!$merchant) {
            $this->command->error('Merchant not found! Run UsersSeeder first.');
            return;
        }

        // Create merchant settings
        MerchantSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'business_name' => 'Demo Restaurant',
                'greeting_message' => "Welcome to Demo Restaurant! 🍽️\n\nHow can I help you today?\n• Make a reservation\n• View our menu\n• Ask about our hours",
                'ai_tone' => 'You are a friendly and professional restaurant assistant. Be helpful, warm, and concise in your responses. Use emojis sparingly to add personality.',
                'booking_form_template' => "Great! I'd be happy to help you make a reservation.\n\nPlease provide:\n• Date (e.g., tomorrow, Dec 20)\n• Time (e.g., 7pm)\n• Number of guests",
                'confirmation_template' => "Your booking is confirmed! 🎉\n\n📅 Date: {date}\n⏰ Time: {time}\n👥 Guests: {pax}\n\nWe look forward to seeing you!",
                'reminder_template' => "Hi {name}! 👋\n\nThis is a reminder about your booking tomorrow:\n\n📅 Date: {date}\n⏰ Time: {time}\n👥 Guests: {pax}\n\nSee you soon!",
                'reminder_hours_before' => 24,
            ]
        );

        // Create restaurant settings
        RestaurantSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'opening_time' => '10:00:00',
                'closing_time' => '22:00:00',
                'slot_duration_minutes' => 120,
            ]
        );

        // Create tables
        $tables = [
            ['name' => 'Table 1', 'capacity' => 2],
            ['name' => 'Table 2', 'capacity' => 2],
            ['name' => 'Table 3', 'capacity' => 4],
            ['name' => 'Table 4', 'capacity' => 4],
            ['name' => 'Table 5', 'capacity' => 6],
            ['name' => 'Table 6', 'capacity' => 8],
        ];

        foreach ($tables as $tableData) {
            Table::updateOrCreate(
                ['user_id' => $merchant->id, 'name' => $tableData['name']],
                ['capacity' => $tableData['capacity'], 'is_active' => true]
            );
        }

        // Create sample bookings
        $table = Table::where('user_id', $merchant->id)->first();

        $bookings = [
            [
                'customer_name' => 'John Doe',
                'customer_phone' => '60123456789',
                'booking_date' => Carbon::tomorrow(),
                'booking_time' => '19:00:00',
                'pax' => 4,
                'status' => 'confirmed',
            ],
            [
                'customer_name' => 'Jane Smith',
                'customer_phone' => '60198765432',
                'booking_date' => Carbon::tomorrow()->addDays(2),
                'booking_time' => '12:30:00',
                'pax' => 2,
                'status' => 'confirmed',
            ],
        ];

        foreach ($bookings as $bookingData) {
            Booking::updateOrCreate(
                [
                    'user_id' => $merchant->id,
                    'customer_phone' => $bookingData['customer_phone'],
                    'booking_date' => $bookingData['booking_date'],
                ],
                array_merge($bookingData, [
                    'user_id' => $merchant->id,
                    'table_id' => $table->id,
                ])
            );
        }

        $this->command->info('Restaurant data seeded successfully!');
        $this->command->info('- Merchant settings created');
        $this->command->info('- Restaurant settings created');
        $this->command->info('- 6 tables created');
        $this->command->info('- 2 sample bookings created');
    }
}
