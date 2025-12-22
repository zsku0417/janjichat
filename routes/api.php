<?php

use App\Http\Controllers\Api\LandingChatController;
use App\Http\Controllers\Api\WhatsAppWebhookController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application.
|
*/

// WhatsApp Webhook Routes
Route::prefix('webhook')->group(function () {
    // Webhook verification (GET request from Meta)
    Route::get('whatsapp', [WhatsAppWebhookController::class, 'verify']);

    // Incoming webhook events (POST request from Meta)
    Route::post('whatsapp', [WhatsAppWebhookController::class, 'handle']);
});

// Landing Page Chat (Public)
Route::post('landing/chat', [LandingChatController::class, 'chat']);
