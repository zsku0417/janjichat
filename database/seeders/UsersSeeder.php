<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\MerchantSetting;
use App\Models\RestaurantSetting;
use App\Models\OrderTrackingSetting;
use App\Models\Table;
use App\Models\Product;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Booking;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UsersSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // ========================================
        // User Id-1. Create Super Admin
        // ========================================
        User::updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Super Admin',
                'password' => Hash::make('password'),
                'role' => User::ROLE_ADMIN,
                'email_verified_at' => now(),
                'email_verified' => true,
            ]
        );

        // ========================================
        // User Id-2. Create Restaurant Merchant + Data
        // ========================================
        $restaurantMerchant = User::updateOrCreate(
            ['email' => 'restaurant@example.com'],
            [
                'name' => 'Bonne Bouche Café',
                'password' => Hash::make('password'),
                'role' => User::ROLE_MERCHANT,
                'business_type' => User::BUSINESS_RESTAURANT,
                'email_verified_at' => now(),
                'email_verified' => true,
                'is_active' => true,
                'whatsapp_phone_number_id' => 897500416781495,
                'whatsapp_access_token' => 'EAA4FAbJVoycBQKGodDRl4SRKy3ZCYwF42E2AYj9C9NCyIZC02CgcBYdAsRsJZBHBKsMqZBv83QhJ376IZCXFppzniLZBb0tCFK7DOXeJrhq2tJCVSFEsolZCGAk0cavWd5A9ZAhuq7VtKAZBG83CvHNQ3gLagWfKlTBMAWhEYmssEdh5JZAtW871XmImmazFSYRgGhRQZDZD',
            ]
        );

        $this->seedRestaurantData($restaurantMerchant);

        // ========================================
        // User Id-3. Create Shop/Order Tracking Merchant + Data
        // ========================================
        $shopMerchant = User::updateOrCreate(
            ['email' => 'shop@example.com'],
            [
                'name' => 'J.Q Patisserie',
                'password' => Hash::make('password'),
                'role' => User::ROLE_MERCHANT,
                'business_type' => User::BUSINESS_ORDER_TRACKING,
                'email_verified_at' => now(),
                'email_verified' => true,
                'is_active' => true,
                'whatsapp_phone_number_id' => 89750041678149500,
                'whatsapp_access_token' => 'EAA4FAbJVoycBQKGodDRl4SRKy3ZCYwF42E2AYj9C9NCyIZC02CgcBYdAsRsJZBHBKsMqZBv83QhJ376IZCXFppzniLZBb0tCFK7DOXeJrhq2tJCVSFEsolZCGAk0cavWd5A9ZAhuq7VtKAZBG83CvHNQ3gLagWfKlTBMAWhEYmssEdh5JZAtW871XmImmazFSYRgGhRQZDZD',
            ]
        );

        $this->seedShopData($shopMerchant);

        // ========================================
        // Output
        // ========================================
        $this->command->info('');
        $this->command->info('✅ Users and data seeded successfully!');
        $this->command->info('');
        $this->command->info('📋 Login Credentials:');
        $this->command->info('   Admin:      admin@example.com / password');
        $this->command->info('   Restaurant: restaurant@example.com / password');
        $this->command->info('   Shop:       shop@example.com / password');
    }

    /**
     * Seed data for Restaurant merchant.
     */
    protected function seedRestaurantData(User $merchant): void
    {
        // Merchant Settings
        MerchantSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'business_name' => 'Bonne Bouche Café',
                'greeting_message' => "Hi there! Welcome to Bonne Bouche Café 🍽️😊\n\nI'm a 24/7 auto-reply chatbot 🤖—always here to help, anytime!\n\nWhat would you like to do today?\n• Make a reservation 📅 (just send your date, time, number of guests, name & phone number)\n• Check your booking 🔍 (just ask!)\n\nIf you'd like to talk to a real person, just type \"human\", \"admin\", or \"staff\" and we'll assist you as soon as possible 💬",
                'ai_tone' => 'You are a friendly and always-available café chatbot. Communicate in a warm, casual, and helpful tone, use simple language and light emojis, and make customers feel welcome at any time of the day.',
                'booking_form_template' => "📅 Please provide your booking details:\n• Date: \n• Time: \n• Number of guests:\n• Name:\n• Phone:",
                'confirmation_template' => "✅ Your booking is confirmed!\n\n📅 Date: {date}\n⏰ Time: {time}\n👥 Guests: {pax}\n\nSee you soon! 🎉",
                'reminder_template' => "⏰ Reminder: Your reservation is tomorrow!\n\n📅 {date} at {time}\n👥 {pax} guests\n\nWe look forward to seeing you!",
                'reminder_hours_before' => 24,
                'email_on_escalation' => true,
                'notification_email' => null,
            ]
        );

        // Restaurant Settings
        RestaurantSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'opening_time' => '11:00',
                'closing_time' => '22:00',
                'slot_duration_minutes' => 120,
            ]
        );

        // Tables
        $tables = [
            ['name' => 'Table A1', 'capacity' => 2],
            ['name' => 'Table A2', 'capacity' => 2],
            ['name' => 'Table B1', 'capacity' => 4],
            ['name' => 'Table B2', 'capacity' => 4],
            ['name' => 'Table B3', 'capacity' => 4],
            ['name' => 'Table C1', 'capacity' => 6],
            ['name' => 'Table C2', 'capacity' => 8],
            ['name' => 'Table D1', 'capacity' => 10],
        ];

        foreach ($tables as $table) {
            Table::updateOrCreate(
                ['user_id' => $merchant->id, 'name' => $table['name']],
                [
                    'capacity' => $table['capacity'],
                    'is_active' => true,
                ]
            );
        }

        // Conversations
        $this->seedRestaurantConversations($merchant);

        // Bookings with different statuses
        $this->seedRestaurantBookings($merchant);

        $this->command->info('   → Restaurant: Settings + ' . count($tables) . ' tables + 3 conversations + 6 bookings seeded');
    }

    /**
     * Seed conversations for Restaurant merchant.
     */
    protected function seedRestaurantConversations(User $merchant): void
    {
        // Conversation 1: Completed booking
        $conv1 = Conversation::updateOrCreate(
            ['user_id' => $merchant->id, 'phone_number' => '60123456789'],
            [
                'whatsapp_id' => '60123456789',
                'customer_name' => 'John Tan',
                'mode' => 'ai',
                'status' => 'active',
                'needs_reply' => false,
                'last_message_at' => now()->subHours(2),
            ]
        );

        $this->createMessages($conv1, [
            ['inbound', 'customer', 'Hi, I want to make a booking for tonight'],
            ['outbound', 'ai', "Welcome to Fine Dining Restaurant! 🍽️\n\nI'd be happy to help you with a reservation!\n\n📅 Please share:\n• Time: What time would you like?\n• Guests: How many people?"],
            ['inbound', 'customer', '7pm for 4 people please'],
            ['outbound', 'ai', "Perfect! Let me confirm:\n\n📅 Date: Today\n⏰ Time: 7:00 PM\n👥 Guests: 4\n\nShould I confirm this booking?"],
            ['inbound', 'customer', 'Yes please'],
            ['outbound', 'ai', "✅ Your booking is confirmed!\n\n📅 Date: Today\n⏰ Time: 7:00 PM\n👥 Guests: 4\n🪑 Table: Table B1\n\nSee you tonight! 🎉"],
        ]);

        // Conversation 2: Escalated
        $conv2 = Conversation::updateOrCreate(
            ['user_id' => $merchant->id, 'phone_number' => '60198765432'],
            [
                'whatsapp_id' => '60198765432',
                'customer_name' => 'Sarah Lee',
                'mode' => 'admin',
                'status' => 'active',
                'needs_reply' => true,
                'escalation_reason' => 'Customer requested to talk to a human',
                'last_message_at' => now()->subMinutes(30),
            ]
        );

        $this->createMessages($conv2, [
            ['inbound', 'customer', 'Hello, do you have any special menu for vegetarians?'],
            ['outbound', 'ai', "Yes! We have a lovely vegetarian menu with various options including:\n• Garden Fresh Salad\n• Mushroom Risotto\n• Veggie Pasta\n\nWould you like to make a reservation?"],
            ['inbound', 'customer', 'I want to talk to someone about allergies'],
            ['outbound', 'ai', "I'll connect you with our team. Someone will be with you shortly."],
        ]);

        // Conversation 3: Inquiry
        $conv3 = Conversation::updateOrCreate(
            ['user_id' => $merchant->id, 'phone_number' => '60112223344'],
            [
                'whatsapp_id' => '60112223344',
                'customer_name' => 'Ahmad bin Ali',
                'mode' => 'ai',
                'status' => 'active',
                'needs_reply' => false,
                'last_message_at' => now()->subDays(1),
            ]
        );

        $this->createMessages($conv3, [
            ['inbound', 'customer', 'What are your opening hours?'],
            ['outbound', 'ai', "We're open daily from 11:00 AM to 10:00 PM! 🕐\n\nWould you like to make a reservation?"],
            ['inbound', 'customer', 'Thank you, I will come tomorrow'],
            ['outbound', 'ai', "You're welcome! Looking forward to seeing you. 😊"],
        ]);
    }

    /**
     * Seed bookings for Restaurant merchant with different statuses.
     */
    protected function seedRestaurantBookings(User $merchant): void
    {
        // Get tables
        $tableA1 = Table::where('user_id', $merchant->id)->where('name', 'Table A1')->first();
        $tableB1 = Table::where('user_id', $merchant->id)->where('name', 'Table B1')->first();
        $tableB2 = Table::where('user_id', $merchant->id)->where('name', 'Table B2')->first();
        $tableC1 = Table::where('user_id', $merchant->id)->where('name', 'Table C1')->first();
        $conv1 = Conversation::where('user_id', $merchant->id)->first();

        // Booking 1: Confirmed - Today evening
        Booking::updateOrCreate(
            ['user_id' => $merchant->id, 'customer_phone' => '60123456789', 'booking_date' => now()->format('Y-m-d'), 'booking_time' => '19:00'],
            [
                'conversation_id' => $conv1?->id,
                'table_id' => $tableB1?->id,
                'customer_name' => 'John Tan',
                'pax' => 4,
                'end_time' => '21:00',
                'status' => 'confirmed',
                'special_request' => 'Window seat preferred',
                'reminder_sent' => false,
                'created_by' => 'ai',
            ]
        );

        // Booking 2: Confirmed - Tomorrow lunch
        Booking::updateOrCreate(
            ['user_id' => $merchant->id, 'customer_phone' => '60111222333', 'booking_date' => now()->addDay()->format('Y-m-d'), 'booking_time' => '12:30'],
            [
                'table_id' => $tableA1?->id,
                'customer_name' => 'Emily Wong',
                'pax' => 2,
                'end_time' => '14:30',
                'status' => 'confirmed',
                'special_request' => 'Anniversary celebration - please prepare a small cake',
                'reminder_sent' => false,
                'created_by' => 'admin',
            ]
        );

        // Booking 3: Pending - This weekend
        Booking::updateOrCreate(
            ['user_id' => $merchant->id, 'customer_phone' => '60144455566', 'booking_date' => now()->next('Saturday')->format('Y-m-d'), 'booking_time' => '18:00'],
            [
                'table_id' => $tableC1?->id,
                'customer_name' => 'Ahmad Yusof',
                'pax' => 6,
                'end_time' => '20:00',
                'status' => 'pending',
                'special_request' => 'Need halal options',
                'reminder_sent' => false,
                'created_by' => 'ai',
            ]
        );

        // Booking 4: Cancelled - Was for yesterday
        Booking::updateOrCreate(
            ['user_id' => $merchant->id, 'customer_phone' => '60177788899', 'booking_date' => now()->subDay()->format('Y-m-d'), 'booking_time' => '20:00'],
            [
                'table_id' => $tableB2?->id,
                'customer_name' => 'Lee Wei Ming',
                'pax' => 4,
                'end_time' => '22:00',
                'status' => 'cancelled',
                'special_request' => null,
                'reminder_sent' => false,
                'created_by' => 'ai',
            ]
        );

        // Booking 5: Completed - Last week
        Booking::updateOrCreate(
            ['user_id' => $merchant->id, 'customer_phone' => '60188899900', 'booking_date' => now()->subWeek()->format('Y-m-d'), 'booking_time' => '19:30'],
            [
                'table_id' => $tableB1?->id,
                'customer_name' => 'Siti Aminah',
                'pax' => 3,
                'end_time' => '21:30',
                'status' => 'completed',
                'special_request' => 'Birthday dinner',
                'reminder_sent' => true,
                'created_by' => 'admin',
            ]
        );

        // Booking 6: Confirmed - Next week
        Booking::updateOrCreate(
            ['user_id' => $merchant->id, 'customer_phone' => '60199900011', 'booking_date' => now()->addWeek()->format('Y-m-d'), 'booking_time' => '13:00'],
            [
                'table_id' => $tableA1?->id,
                'customer_name' => 'David Chen',
                'pax' => 2,
                'end_time' => '15:00',
                'status' => 'confirmed',
                'special_request' => 'Business lunch',
                'reminder_sent' => false,
                'created_by' => 'ai',
            ]
        );
    }

    /**
     * Seed data for J.Q Patisserie merchant.
     */
    protected function seedShopData(User $merchant): void
    {
        // Merchant Settings (with all templates)
        MerchantSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'business_name' => 'J.Q Patisserie',
                'greeting_message' => "Hi there! Welcome to J.Q Patisserie😊\n\nI'm a 24/7 auto-reply chatbot 🤖—always here to help, anytime!\nWhat would you like to do today?\n- Place an order 📦 (just send what you want to buy with quantity!)\n- Check your order status 🔍 (just ask!)\n- Browse our products 📋 (just ask what we have!)\n\nIf you'd like to talk to a real person, just type \"human\", \"admin\", or \"staff\" and we'll assist you as soon as possible 💬",
                'ai_tone' => 'You are a friendly and always-available shop assistant chatbot. Communicate in a warm, helpful, and efficient tone. Use simple language and light emojis to make customers feel welcome. Be clear about order details, pricing, and delivery/pickup options. Always confirm orders accurately and provide helpful suggestions.',
                'booking_form_template' => "Great! Let's place your order 📦\n\nPlease fill in the details below:\n\n📦 *Products you want to order:*\n(e.g.:\nProduct A x2\nProduct B x3)\n\n📅 *When do you need it?* (e.g. 25-12-2024, 3:00pm):\n\n📍 *Delivery Address:*\n(Leave blank for self-pickup)\n\n📝 *Special Notes:* (optional)\n\n---\nJust copy, fill in, and send it back to me! 😊",
                'confirmation_template' => "✅ *Order Confirmed!* Thank you, {name}! 🎉\n\nYour order details:\n📦 Order #{order_code}\n\n*Items:*\n{items}\n\n💰 *Total: {total}*\n\n📅 *Scheduled: {datetime}*\n{fulfillment}\n{notes}\n\n---\nWe'll notify you once your order is ready. Thank you for choosing us! 🙏",
                'reminder_template' => "⏰ *Friendly Reminder!*\n\nHi {name}! 👋\n\nYour order #{order_code} is scheduled for *{datetime}*.\n\n{fulfillment}\n\n💰 *Total: {total}*\n\nSee you soon! 😊🙏",
                'reminder_hours_before' => 24,
                'email_on_escalation' => true,
                'notification_email' => 'hello@jqpatisserie.com',
            ]
        );

        // Order Tracking Settings
        OrderTrackingSetting::updateOrCreate(
            ['user_id' => $merchant->id],
            [
                'pickup_address' => '173, Jalan Paya 3/1, Kampung Paya, 86000 Kluang, Johor, Malaysia',
                'order_prefix' => 'JQP',
            ]
        );

        // Products - J.Q Patisserie Menu
        $products = [
            [
                'name' => 'Mille-Feuille',
                'description' => 'Classic Napoleon with crispy puff pastry layers and vanilla diplomat cream.',
                'price' => 18.90,
            ],
            [
                'name' => 'Chocolate Éclair',
                'description' => 'Choux pastry filled with chocolate cream, topped with dark chocolate glaze.',
                'price' => 12.90,
            ],
            [
                'name' => 'Coffee Éclair',
                'description' => 'Choux pastry filled with coffee cream, topped with coffee glaze.',
                'price' => 12.90,
            ],
            [
                'name' => 'Tarte aux Fruits',
                'description' => 'Buttery tart shell with vanilla custard and fresh seasonal fruits.',
                'price' => 15.90,
            ],
            [
                'name' => 'Tarte au Citron',
                'description' => 'Tangy lemon curd tart with torched Italian meringue.',
                'price' => 13.90,
            ],
            [
                'name' => 'Canelé',
                'description' => 'Bordeaux specialty with rum and vanilla, caramelized crust.',
                'price' => 8.90,
            ],
            [
                'name' => 'Financier',
                'description' => 'Traditional French almond tea cake with brown butter.',
                'price' => 6.90,
            ],
            [
                'name' => 'Madeleines (3 pcs)',
                'description' => 'Classic shell-shaped French butter cakes.',
                'price' => 9.90,
            ],
            [
                'name' => 'Classic Butter Croissant',
                'description' => 'Flaky, buttery croissant made with 48-hour laminated dough.',
                'price' => 8.90,
            ],
            [
                'name' => 'Almond Croissant',
                'description' => 'Butter croissant filled with almond frangipane, topped with sliced almonds.',
                'price' => 12.90,
            ],
            [
                'name' => 'Burnt Basque Cheesecake 6"',
                'description' => 'Creamy Basque-style cheesecake with caramelized top. Serves 6-8 pax.',
                'price' => 85.00,
            ],
            [
                'name' => 'Strawberry Shortcake 6"',
                'description' => 'Light vanilla sponge with fresh strawberries and Chantilly cream. Serves 6-8 pax.',
                'price' => 110.00,
            ],
            [
                'name' => 'Assorted Macarons (6 pcs)',
                'description' => 'Box of 6 French macarons in assorted flavours.',
                'price' => 32.00,
            ],
        ];

        foreach ($products as $product) {
            Product::updateOrCreate(
                ['user_id' => $merchant->id, 'name' => $product['name']],
                [
                    'description' => $product['description'],
                    'price' => $product['price'],
                    'is_active' => true,
                ]
            );
        }

        // Conversations
        $this->seedShopConversations($merchant);

        // Orders with different statuses
        $this->seedShopOrders($merchant);

        $this->command->info('   → J.Q Patisserie: Settings + ' . count($products) . ' products + 4 conversations + 6 orders seeded');
    }

    /**
     * Seed conversations for J.Q Patisserie merchant.
     */
    protected function seedShopConversations(User $merchant): void
    {
        // Conversation 1: Product inquiry about cakes
        $conv1 = Conversation::updateOrCreate(
            ['user_id' => $merchant->id, 'phone_number' => '60177778888'],
            [
                'whatsapp_id' => '60177778888',
                'customer_name' => 'Michelle Tan',
                'mode' => 'ai',
                'status' => 'active',
                'needs_reply' => false,
                'last_message_at' => now()->subHours(5),
            ]
        );

        $this->createMessages($conv1, [
            ['inbound', 'customer', 'Hi, do you have any cheesecake available?'],
            ['outbound', 'ai', "Hi! Yes, we do! 🧀\n\nOur signature Burnt Basque Cheesecake is available:\n\n• 6\" (serves 6-8) - RM85\n• 8\" (serves 10-12) - RM120\n• Slice - RM15.90\n\nIt's creamy with a beautiful caramelized top! Would you like to order?"],
            ['inbound', 'customer', 'What other cakes do you have?'],
            ['outbound', 'ai', "We have a lovely selection! 🎂\n\n• Chocolate Ganache Cake (6\") - RM95\n• Strawberry Shortcake (6\") - RM110\n• Tiramisu Cake (6\") - RM98\n• Ondeh-Ondeh Cake (6\") - RM100\n• Durian Crepe Cake (6\") - RM130\n\nAll whole cakes require 3 days advance order. Slices are available daily while stocks last!\n\nWhich one catches your eye? 😊"],
            ['inbound', 'customer', 'I will come by this weekend to try some slices first, thanks!'],
            ['outbound', 'ai', "Sounds great! 🥐\n\nWe're open:\n• Saturday: 9am - 8pm\n• Sunday: 9am - 8pm\n\n📍 173, Jalan Paya 3/1, Kampung Paya, 86000 Kluang\n\nSee you this weekend! Our slices sell out fast, so come early for the best selection 😊"],
        ]);

        // Conversation 2: Custom cake order placed
        $conv2 = Conversation::updateOrCreate(
            ['user_id' => $merchant->id, 'phone_number' => '60133334444'],
            [
                'whatsapp_id' => '60133334444',
                'customer_name' => 'Ahmad Rizal',
                'mode' => 'ai',
                'status' => 'active',
                'needs_reply' => false,
                'last_message_at' => now()->subHours(1),
            ]
        );

        $this->createMessages($conv2, [
            ['inbound', 'customer', 'Hi, I want to order a birthday cake for my wife this Saturday'],
            ['outbound', 'ai', "Happy to help with that! 🎂\n\nFor custom birthday cakes, please share:\n• Preferred cake flavour\n• Size (6\" or 8\")\n• Any design/message you'd like\n• Collection date & time\n\nWhat flavour does your wife like?"],
            ['inbound', 'customer', 'She loves strawberry. 6 inch is fine. Can you write \"Happy Birthday Aishah\" on it?'],
            ['outbound', 'ai', "Lovely choice! 🍓\n\nHere's your order summary:\n\n🎂 Strawberry Shortcake 6\"\n✍️ Message: \"Happy Birthday Aishah\"\n📅 Collection: Saturday\n💰 Total: RM110\n\nWe'll need a 50% deposit (RM55) to confirm. What time would you like to collect on Saturday?"],
            ['inbound', 'customer', 'Around 2pm. I can bank transfer the deposit now'],
            ['outbound', 'ai', "✅ Order confirmed!\n\n🧁 Order ID: JQP-00001\n🎂 Strawberry Shortcake 6\" with \"Happy Birthday Aishah\"\n💰 Total: RM110 (RM55 deposit received)\n📅 Collection: Saturday, 2:00 PM\n📍 173, Jalan Paya 3/1, Kampung Paya, 86000 Kluang\n\nWe'll send a reminder on Saturday morning! Thank you for choosing J.Q Patisserie 🥐🎉"],
        ]);

        // Conversation 3: Bulk order inquiry - escalated
        $conv3 = Conversation::updateOrCreate(
            ['user_id' => $merchant->id, 'phone_number' => '60155556666'],
            [
                'whatsapp_id' => '60155556666',
                'customer_name' => 'Siti Nurhaliza',
                'mode' => 'admin',
                'status' => 'active',
                'needs_reply' => true,
                'escalation_reason' => 'Corporate bulk order inquiry - needs custom quotation',
                'last_message_at' => now()->subMinutes(15),
            ]
        );

        $this->createMessages($conv3, [
            ['inbound', 'customer', 'Hi, I\'m from ABC Company. We need pastries for our company event next month - around 100 pax'],
            ['outbound', 'ai', "Thank you for considering J.Q Patisserie for your corporate event! 🏢\n\nFor bulk orders of 100 pax, we can offer:\n• Assorted croissants\n• Mini tarts\n• Macarons\n• Cookie boxes\n\nCould you share:\n• Event date\n• Budget per pax\n• Any dietary restrictions?"],
            ['inbound', 'customer', 'It\'s on 15th January. Budget around RM15-20 per pax. Some staff are vegetarian. Can we get a formal quotation?'],
            ['outbound', 'ai', "Absolutely! For a formal quotation and corporate bulk orders, let me connect you with our team who can provide:\n\n• Customized package options\n• Corporate pricing\n• Invoice & receipt\n\nSomeone will get back to you shortly! 😊"],
        ]);

        // Conversation 4: Delivery order
        $conv4 = Conversation::updateOrCreate(
            ['user_id' => $merchant->id, 'phone_number' => '60199887766'],
            [
                'whatsapp_id' => '60199887766',
                'customer_name' => 'Jenny Lim',
                'mode' => 'ai',
                'status' => 'active',
                'needs_reply' => false,
                'last_message_at' => now()->subHours(3),
            ]
        );

        $this->createMessages($conv4, [
            ['inbound', 'customer', 'Can I order 2 boxes of macarons and 6 croissants for delivery tomorrow?'],
            ['outbound', 'ai', "Of course! 🥐\n\nLet me confirm your order:\n\n• 2x Assorted Macarons (6 pcs) - RM64\n• 6x Classic Butter Croissant - RM53.40\n\n💰 Subtotal: RM117.40\n🚚 Delivery fee: RM10 (within Kluang)\n💰 Total: RM127.40\n\nPlease share your delivery address and preferred time tomorrow!"],
            ['inbound', 'customer', '25 Jalan Melor, Taman Kluang Baru. Anytime before 12pm is fine'],
            ['outbound', 'ai', "✅ Order confirmed!\n\n🧁 Order ID: JQP-00002\n📦 Items:\n  • 2x Assorted Macarons (6 pcs)\n  • 6x Classic Butter Croissant\n💰 Total: RM127.40\n🚚 Delivery: Tomorrow before 12pm\n📍 25 Jalan Melor, Taman Kluang Baru\n\nPayment upon delivery (cash/e-wallet accepted).\n\nThank you for your order! 🎉"],
        ]);
    }

    /**
     * Create messages for a conversation.
     */
    protected function createMessages(Conversation $conversation, array $messages): void
    {
        $baseTime = now()->subMinutes(count($messages) * 5);

        foreach ($messages as $index => $msg) {
            Message::updateOrCreate(
                [
                    'conversation_id' => $conversation->id,
                    'content' => $msg[2],
                ],
                [
                    'direction' => $msg[0],
                    'sender_type' => $msg[1],
                    'message_type' => 'text',
                    'status' => 'delivered',
                    'created_at' => $baseTime->copy()->addMinutes($index * 2),
                    'updated_at' => $baseTime->copy()->addMinutes($index * 2),
                ]
            );
        }
    }

    /**
     * Seed orders for J.Q Patisserie with different statuses.
     */
    protected function seedShopOrders(User $merchant): void
    {
        // Get products
        $milleFeuille = Product::where('user_id', $merchant->id)->where('name', 'Mille-Feuille')->first();
        $eclair = Product::where('user_id', $merchant->id)->where('name', 'Chocolate Éclair')->first();
        $tarteFruits = Product::where('user_id', $merchant->id)->where('name', 'Tarte aux Fruits')->first();
        $canele = Product::where('user_id', $merchant->id)->where('name', 'Canelé')->first();
        $financier = Product::where('user_id', $merchant->id)->where('name', 'Financier')->first();
        $madeleines = Product::where('user_id', $merchant->id)->where('name', 'Madeleines (3 pcs)')->first();
        $croissant = Product::where('user_id', $merchant->id)->where('name', 'Classic Butter Croissant')->first();
        $macarons = Product::where('user_id', $merchant->id)->where('name', 'Assorted Macarons (6 pcs)')->first();
        $strawberryCake = Product::where('user_id', $merchant->id)->where('name', 'Strawberry Shortcake 6"')->first();

        $conv2 = Conversation::where('user_id', $merchant->id)->where('phone_number', '60133334444')->first();
        $conv4 = Conversation::where('user_id', $merchant->id)->where('phone_number', '60199887766')->first();

        // Order 1: Processing - Birthday cake pickup tomorrow (from conversation)
        $order1 = Order::updateOrCreate(
            ['user_id' => $merchant->id, 'code' => 'JQP-00001'],
            [
                'conversation_id' => $conv2?->id,
                'customer_name' => 'Ahmad Rizal',
                'customer_phone' => '60133334444',
                'fulfillment_type' => 'pickup',
                'delivery_address' => null,
                'requested_datetime' => now()->next('Saturday')->setHour(14)->setMinute(0),
                'notes' => 'Strawberry Shortcake 6" with "Happy Birthday Aishah". Deposit RM55 paid.',
                'status' => 'processing',
                'total_amount' => 110.00,
            ]
        );

        // Order 2: Completed - Delivery order (from conversation)
        $order2 = Order::updateOrCreate(
            ['user_id' => $merchant->id, 'code' => 'JQP-00002'],
            [
                'conversation_id' => $conv4?->id,
                'customer_name' => 'Jenny Lim',
                'customer_phone' => '60199887766',
                'fulfillment_type' => 'delivery',
                'delivery_address' => '25 Jalan Melor, Taman Kluang Baru',
                'requested_datetime' => now()->subDay()->setHour(11)->setMinute(0),
                'notes' => 'Deliver before 12pm. COD.',
                'status' => 'completed',
                'total_amount' => 127.40,
            ]
        );

        // Order 3: Pending payment - New order today
        $order3 = Order::updateOrCreate(
            ['user_id' => $merchant->id, 'code' => 'JQP-00003'],
            [
                'customer_name' => 'Kevin Ong',
                'customer_phone' => '60166677788',
                'fulfillment_type' => 'pickup',
                'delivery_address' => null,
                'requested_datetime' => now()->addDays(2)->setHour(10)->setMinute(0),
                'notes' => 'For office meeting',
                'status' => 'pending_payment',
                'total_amount' => 89.60,
            ]
        );

        // Order 4: Cancelled - Customer cancelled
        $order4 = Order::updateOrCreate(
            ['user_id' => $merchant->id, 'code' => 'JQP-00004'],
            [
                'customer_name' => 'Sarah Tan',
                'customer_phone' => '60177788899',
                'fulfillment_type' => 'delivery',
                'delivery_address' => '88 Jalan Bunga, Kluang',
                'requested_datetime' => now()->subDays(3)->setHour(15)->setMinute(0),
                'notes' => 'Cancelled due to change of plans',
                'status' => 'cancelled',
                'total_amount' => 65.70,
            ]
        );

        // Order 5: Completed - Last week
        $order5 = Order::updateOrCreate(
            ['user_id' => $merchant->id, 'code' => 'JQP-00005'],
            [
                'customer_name' => 'Lisa Chen',
                'customer_phone' => '60188899911',
                'fulfillment_type' => 'pickup',
                'delivery_address' => null,
                'requested_datetime' => now()->subWeek()->setHour(16)->setMinute(30),
                'notes' => 'Regular customer - birthday treats',
                'status' => 'completed',
                'total_amount' => 156.40,
            ]
        );

        // Order 6: Processing - Weekend order
        $order6 = Order::updateOrCreate(
            ['user_id' => $merchant->id, 'code' => 'JQP-00006'],
            [
                'customer_name' => 'Alex Yap',
                'customer_phone' => '60199900022',
                'fulfillment_type' => 'delivery',
                'delivery_address' => '15 Lorong Mawar, Simpang Renggam',
                'requested_datetime' => now()->next('Saturday')->setHour(11)->setMinute(0),
                'notes' => 'Party order - call before delivery',
                'status' => 'processing',
                'total_amount' => 245.60,
            ]
        );

        // Create order items
        if ($order1 && $strawberryCake) {
            $this->createOrderItems($order1, [
                ['product' => $strawberryCake, 'quantity' => 1, 'price' => 110.00],
            ]);
        }

        if ($order2 && $macarons && $croissant) {
            $this->createOrderItems($order2, [
                ['product' => $macarons, 'quantity' => 2, 'price' => 32.00],
                ['product' => $croissant, 'quantity' => 6, 'price' => 8.90],
            ]);
        }

        if ($order3 && $eclair && $financier) {
            $this->createOrderItems($order3, [
                ['product' => $eclair, 'quantity' => 4, 'price' => 12.90],
                ['product' => $financier, 'quantity' => 6, 'price' => 6.90],
            ]);
        }

        if ($order5 && $tarteFruits && $milleFeuille && $canele) {
            $this->createOrderItems($order5, [
                ['product' => $tarteFruits, 'quantity' => 2, 'price' => 15.90],
                ['product' => $milleFeuille, 'quantity' => 4, 'price' => 18.90],
                ['product' => $canele, 'quantity' => 8, 'price' => 8.90],
            ]);
        }

        if ($order6 && $tarteFruits && $eclair && $canele && $financier) {
            $this->createOrderItems($order6, [
                ['product' => $tarteFruits, 'quantity' => 4, 'price' => 15.90],
                ['product' => $eclair, 'quantity' => 6, 'price' => 12.90],
                ['product' => $canele, 'quantity' => 10, 'price' => 8.90],
                ['product' => $financier, 'quantity' => 8, 'price' => 6.90],
            ]);
        }
    }

    /**
     * Create order items for an order.
     */
    protected function createOrderItems(Order $order, array $items): void
    {
        // Clear existing items for this order
        OrderItem::where('order_id', $order->id)->delete();

        foreach ($items as $item) {
            if ($item['product']) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product']->id,
                    'product_name' => $item['product']->name,
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['price'],
                    'subtotal' => $item['quantity'] * $item['price'],
                ]);
            }
        }
    }
}