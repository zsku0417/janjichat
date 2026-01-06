<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ConversationController;
use App\Http\Controllers\DocumentController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\MerchantSettingsController;
use App\Http\Controllers\DevelopmentController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\PublicProductController;
use App\Http\Controllers\Admin\AdminMerchantController;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('Landing');
})->name('landing');

// Public shop page (white-label)
Route::get('/shop/{merchant}', [PublicProductController::class, 'show'])->name('shop.show');

// Authenticated routes
Route::middleware(['auth', 'verified'])->group(function () {
    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // Conversations (shared by all business types)
    Route::get('/conversations', [ConversationController::class, 'index'])->name('conversations.index');
    Route::get('/conversations/{conversation}', [ConversationController::class, 'show'])->name('conversations.show');
    Route::get('/conversations/{conversation}/messages', [ConversationController::class, 'messages'])->name('conversations.messages');
    Route::post('/conversations/{conversation}/reply', [ConversationController::class, 'reply'])->name('conversations.reply');
    Route::post('/conversations/{conversation}/toggle-mode', [ConversationController::class, 'toggleMode'])->name('conversations.toggle-mode');

    // Documents / Knowledge Base (shared by all business types)
    Route::get('/documents', [DocumentController::class, 'index'])->name('documents.index');
    Route::get('/documents/{document}', [DocumentController::class, 'show'])->name('documents.show');
    Route::post('/documents', [DocumentController::class, 'store'])->name('documents.store');
    Route::delete('/documents/{document}', [DocumentController::class, 'destroy'])->name('documents.destroy');
    Route::post('/documents/{document}/reprocess', [DocumentController::class, 'reprocess'])->name('documents.reprocess');

    // ===== RESTAURANT BUSINESS TYPE ROUTES =====
    // Bookings
    Route::get('/bookings', [BookingController::class, 'index'])->name('bookings.index');
    Route::get('/bookings/calendar', [BookingController::class, 'calendar'])->name('bookings.calendar');
    Route::post('/bookings', [BookingController::class, 'store'])->name('bookings.store');
    Route::patch('/bookings/{booking}', [BookingController::class, 'update'])->name('bookings.update');
    Route::post('/bookings/{booking}/cancel', [BookingController::class, 'cancel'])->name('bookings.cancel');
    Route::delete('/bookings/{booking}', [BookingController::class, 'destroy'])->name('bookings.destroy');

    // Settings (all merchants)
    Route::get('/settings', [MerchantSettingsController::class, 'index'])->name('settings.index');
    Route::patch('/settings/merchant', [MerchantSettingsController::class, 'updateMerchantSettings'])->name('settings.merchant.update');
    Route::patch('/settings/restaurant', [MerchantSettingsController::class, 'updateRestaurantSettings'])->name('settings.restaurant.update');
    Route::patch('/settings/order-tracking', [MerchantSettingsController::class, 'updateOrderTrackingSettings'])->name('settings.order-tracking.update');
    Route::post('/settings/tables', [MerchantSettingsController::class, 'storeTable'])->name('settings.tables.store');
    Route::patch('/settings/tables/{table}', [MerchantSettingsController::class, 'updateTable'])->name('settings.tables.update');
    Route::delete('/settings/tables/{table}', [MerchantSettingsController::class, 'destroyTable'])->name('settings.tables.destroy');

    // ===== ORDER TRACKING BUSINESS TYPE ROUTES =====
    // Products
    Route::get('/products', [ProductController::class, 'index'])->name('products.index');
    Route::get('/products/create', [ProductController::class, 'create'])->name('products.create');
    Route::post('/products', [ProductController::class, 'store'])->name('products.store');
    Route::get('/products/{product}/edit', [ProductController::class, 'edit'])->name('products.edit');
    Route::patch('/products/{product}', [ProductController::class, 'update'])->name('products.update');
    Route::delete('/products/{product}', [ProductController::class, 'destroy'])->name('products.destroy');
    Route::post('/products/{product}/toggle-active', [ProductController::class, 'toggleActive'])->name('products.toggle-active');
    Route::post('/products/{product}/images', [ProductController::class, 'uploadImages'])->name('products.images.upload');
    Route::delete('/products/{product}/images/{media}', [ProductController::class, 'deleteImage'])->name('products.images.delete');
    Route::get('/products/{product}/orders', [ProductController::class, 'getOrders'])->name('products.orders');
    Route::get('/products/{product}/orders/export', [ProductController::class, 'exportOrders'])->name('products.orders.export');

    // Orders
    Route::get('/orders', [OrderController::class, 'index'])->name('orders.index');
    Route::post('/orders', [OrderController::class, 'store'])->name('orders.store');
    Route::get('/orders/{order}', [OrderController::class, 'show'])->name('orders.show');
    Route::put('/orders/{order}', [OrderController::class, 'update'])->name('orders.update');
    Route::patch('/orders/{order}/status', [OrderController::class, 'updateStatus'])->name('orders.update-status');
    Route::post('/orders/{order}/cancel', [OrderController::class, 'cancel'])->name('orders.cancel');
    Route::delete('/orders/{order}', [OrderController::class, 'destroy'])->name('orders.destroy');

    // Profile
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');

    // Development Tools (for testing without real webhooks)
    Route::get('/dev/simulator', [DevelopmentController::class, 'simulator'])->name('dev.simulator');
    Route::post('/dev/simulate', [DevelopmentController::class, 'simulateMessage'])->name('dev.simulate');
    Route::get('/dev/messages', [DevelopmentController::class, 'getMessages'])->name('dev.messages');
    Route::post('/dev/clear', [DevelopmentController::class, 'clearConversation'])->name('dev.clear');
});

// Admin routes (admin role only)
Route::middleware(['auth', 'verified', 'admin'])->prefix('admin')->name('admin.')->group(function () {
    // Merchants CRUD (using modals in Index page)
    Route::get('/merchants', [AdminMerchantController::class, 'index'])->name('merchants.index');
    Route::post('/merchants', [AdminMerchantController::class, 'store'])->name('merchants.store');
    Route::patch('/merchants/{merchant}', [AdminMerchantController::class, 'update'])->name('merchants.update');
    Route::patch('/merchants/{merchant}/toggle-active', [AdminMerchantController::class, 'toggleActive'])->name('merchants.toggle-active');
    Route::post('/merchants/{merchant}/resend-email', [AdminMerchantController::class, 'resendWelcomeEmail'])->name('merchants.resend-email');
    Route::delete('/merchants/{merchant}', [AdminMerchantController::class, 'destroy'])->name('merchants.destroy');
});

require __DIR__ . '/auth.php';
