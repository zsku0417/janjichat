<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\OrderTrackingSetting;
use App\Models\MerchantSetting;
use Inertia\Inertia;
use Inertia\Response;

class PublicProductController extends Controller
{
    /**
     * Display the white-label product page for a merchant.
     */
    public function show(User $merchant): Response
    {
        // Ensure this is an order tracking business
        if ($merchant->business_type !== 'order_tracking' || !$merchant->is_active) {
            abort(404);
        }

        // Get settings
        $orderSettings = OrderTrackingSetting::where('user_id', $merchant->id)->first();
        $merchantSettings = MerchantSetting::where('user_id', $merchant->id)->first();

        // Get active products
        $products = $merchant->products()
            ->with('media')
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(fn($product) => [
                'id' => $product->id,
                'name' => $product->name,
                'description' => $product->description,
                'price' => $product->price,
                'formatted_price' => 'RM ' . number_format($product->price, 2),
                'image_urls' => $product->image_urls,
            ]);

        return Inertia::render('Shop', [
            'merchant' => [
                'id' => $merchant->id,
                'whatsapp_phone_number' => $merchant->whatsapp_phone_number,
                'name' => $merchantSettings?->business_name ?? $merchant->name,
                'logo_url' => $orderSettings?->logo_url,
            ],
            'products' => $products,
        ]);
    }
}
