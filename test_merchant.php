<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

// Simulate what happens in RestaurantHandler
$merchant = App\Models\User::where('role', 'merchant')->first();
echo "Merchant: {$merchant->name} (ID: {$merchant->id})\n\n";

// Try the relationship
$merchantSettings = $merchant->merchantSettings;
echo "merchantSettings via relationship: " . ($merchantSettings ? 'FOUND' : 'NULL') . "\n";

if ($merchantSettings) {
    echo "- business_name: {$merchantSettings->business_name}\n";
    echo "- booking_form_template: " . (empty($merchantSettings->booking_form_template) ? 'EMPTY' : 'SET (length: ' . strlen($merchantSettings->booking_form_template) . ')') . "\n";
    echo "\nActual booking_form_template content:\n";
    echo "---\n" . $merchantSettings->booking_form_template . "\n---\n";
}
