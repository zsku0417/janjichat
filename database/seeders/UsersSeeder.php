<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UsersSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create super admin user
        User::updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Super Admin',
                'password' => Hash::make('password'),
                'role' => User::ROLE_ADMIN,
                // Admin will have default business_type (restaurant) but won't use it
                'email_verified_at' => now(),
                'email_verified' => true,
            ]
        );

        // Create demo merchant
        User::updateOrCreate(
            ['email' => 'merchant@example.com'],
            [
                'name' => 'Demo Merchant',
                'password' => Hash::make('password'),
                'role' => User::ROLE_MERCHANT,
                'business_type' => User::BUSINESS_RESTAURANT,
                'email_verified_at' => now(),
                'email_verified' => true,
                // WhatsApp credentials will be configured via admin panel
                'whatsapp_phone_number_id' => null,
                'whatsapp_access_token' => null,
            ]
        );

        $this->command->info('Users created successfully!');
        $this->command->info('');
        $this->command->info('Admin login: admin@example.com / password');
        $this->command->info('Merchant login: merchant@example.com / password');
    }
}