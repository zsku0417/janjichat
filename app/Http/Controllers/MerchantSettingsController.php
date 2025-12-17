<?php

namespace App\Http\Controllers;

use App\Models\MerchantSetting;
use App\Models\RestaurantSetting;
use App\Models\OrderTrackingSetting;
use App\Models\Table;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;

class MerchantSettingsController extends Controller
{
    /**
     * Display the settings page based on business type.
     */
    public function index(): Response
    {
        $user = auth()->user();

        // Get or create merchant settings
        $merchantSetting = MerchantSetting::firstOrCreate(
            ['user_id' => $user->id],
            [
                'business_name' => $user->name,
                'greeting_message' => 'Hello! How can I help you today?',
                'ai_tone' => 'friendly and professional',
                'reminder_hours_before' => 24,
            ]
        );

        $data = [
            'businessType' => $user->business_type,
            'merchantSettings' => [
                'business_name' => $merchantSetting->business_name,
                'greeting_message' => $merchantSetting->greeting_message,
                'ai_tone' => $merchantSetting->ai_tone,
                'booking_form_template' => $merchantSetting->booking_form_template,
                'confirmation_template' => $merchantSetting->confirmation_template,
                'reminder_template' => $merchantSetting->reminder_template,
                'reminder_hours_before' => $merchantSetting->reminder_hours_before,
            ],
        ];

        // Add restaurant-specific settings
        if ($user->business_type === 'restaurant') {
            $restaurantSetting = RestaurantSetting::firstOrCreate(
                ['user_id' => $user->id],
                [
                    'opening_time' => '09:00',
                    'closing_time' => '22:00',
                    'slot_duration_minutes' => 60,
                ]
            );

            $data['restaurantSettings'] = [
                'opening_time' => $restaurantSetting->opening_time,
                'closing_time' => $restaurantSetting->closing_time,
                'slot_duration_minutes' => $restaurantSetting->slot_duration_minutes,
            ];

            $data['tables'] = Table::where('user_id', $user->id)
                ->orderBy('name')
                ->get()
                ->map(fn($table) => [
                    'id' => $table->id,
                    'name' => $table->name,
                    'capacity' => $table->capacity,
                    'is_active' => $table->is_active,
                ]);
        }

        // Add order tracking-specific settings
        if ($user->business_type === 'order_tracking') {
            $orderTrackingSetting = OrderTrackingSetting::firstOrCreate(
                ['user_id' => $user->id],
                [
                    'pickup_address' => '',
                    'order_prefix' => 'ORD',
                ]
            );

            $data['orderTrackingSettings'] = [
                'pickup_address' => $orderTrackingSetting->pickup_address,
                'order_prefix' => $orderTrackingSetting->order_prefix,
            ];
        }

        return Inertia::render('Settings/Index', $data);
    }

    /**
     * Update merchant settings (shared by all business types).
     */
    public function updateMerchantSettings(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'business_name' => 'required|string|max:255',
            'greeting_message' => 'nullable|string|max:2000',
            'ai_tone' => 'nullable|string|max:2000',
            'booking_form_template' => 'nullable|string|max:2000',
            'confirmation_template' => 'nullable|string|max:2000',
            'reminder_template' => 'nullable|string|max:2000',
            'reminder_hours_before' => 'nullable|integer|min:1|max:168',
        ]);

        $user = auth()->user();

        MerchantSetting::updateOrCreate(
            ['user_id' => $user->id],
            $validated
        );

        return back()->with('success', 'Merchant settings updated successfully!');
    }

    /**
     * Update restaurant-specific settings.
     */
    public function updateRestaurantSettings(Request $request): RedirectResponse
    {
        $user = auth()->user();

        if ($user->business_type !== 'restaurant') {
            return back()->with('error', 'This action is only available for restaurant businesses.');
        }

        $validated = $request->validate([
            'opening_time' => 'required|date_format:H:i,H:i:s',
            'closing_time' => 'required|date_format:H:i,H:i:s',
            'slot_duration_minutes' => 'required|integer|min:15|max:480',
        ]);

        RestaurantSetting::updateOrCreate(
            ['user_id' => $user->id],
            $validated
        );

        return back()->with('success', 'Restaurant settings updated successfully!');
    }

    /**
     * Update order tracking-specific settings.
     */
    public function updateOrderTrackingSettings(Request $request): RedirectResponse
    {
        $user = auth()->user();

        if ($user->business_type !== 'order_tracking') {
            return back()->with('error', 'This action is only available for order tracking businesses.');
        }

        $validated = $request->validate([
            'pickup_address' => 'nullable|string|max:500',
            'order_prefix' => 'required|string|max:10',
        ]);

        OrderTrackingSetting::updateOrCreate(
            ['user_id' => $user->id],
            $validated
        );

        return back()->with('success', 'Order tracking settings updated successfully!');
    }

    /**
     * Create a new table (restaurant only).
     */
    public function storeTable(Request $request): RedirectResponse
    {
        $user = auth()->user();

        if ($user->business_type !== 'restaurant') {
            return back()->with('error', 'This action is only available for restaurant businesses.');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'capacity' => 'required|integer|min:1|max:50',
        ]);

        // Check for duplicate name for this user
        if (Table::where('user_id', $user->id)->where('name', $validated['name'])->exists()) {
            return back()->with('error', 'A table with this name already exists.');
        }

        Table::create([
            'user_id' => $user->id,
            'name' => $validated['name'],
            'capacity' => $validated['capacity'],
            'is_active' => true,
        ]);

        return back()->with('success', 'Table created successfully!');
    }

    /**
     * Update a table (restaurant only).
     */
    public function updateTable(Request $request, Table $table): RedirectResponse
    {
        $user = auth()->user();

        if ($user->business_type !== 'restaurant') {
            return back()->with('error', 'This action is only available for restaurant businesses.');
        }

        // Ensure table belongs to this user
        if ($table->user_id !== $user->id) {
            abort(403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'capacity' => 'required|integer|min:1|max:50',
            'is_active' => 'boolean',
        ]);

        // Check for duplicate name for this user (excluding current table)
        if (
            Table::where('user_id', $user->id)
                ->where('name', $validated['name'])
                ->where('id', '!=', $table->id)
                ->exists()
        ) {
            return back()->with('error', 'A table with this name already exists.');
        }

        $table->update($validated);

        return back()->with('success', 'Table updated successfully!');
    }

    /**
     * Delete a table (restaurant only).
     */
    public function destroyTable(Table $table): RedirectResponse
    {
        $user = auth()->user();

        if ($user->business_type !== 'restaurant') {
            return back()->with('error', 'This action is only available for restaurant businesses.');
        }

        // Ensure table belongs to this user
        if ($table->user_id !== $user->id) {
            abort(403);
        }

        // Check if table has upcoming bookings
        if ($table->bookings()->where('status', 'confirmed')->where('booking_date', '>=', now()->toDateString())->exists()) {
            return back()->with('error', 'Cannot delete table with upcoming bookings.');
        }

        $table->delete();

        return back()->with('success', 'Table deleted successfully!');
    }
}
