<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable;

    // Role constants
    const ROLE_ADMIN = 'admin';
    const ROLE_MERCHANT = 'merchant';

    // Business type constants
    const BUSINESS_RESTAURANT = 'restaurant';
    const BUSINESS_ORDER_TRACKING = 'order_tracking';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'business_type',
        'whatsapp_phone_number_id',
        'whatsapp_phone_number',
        'whatsapp_access_token',
        'email_verified',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'whatsapp_access_token', // Hide sensitive token
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'email_verified' => 'boolean',
            'whatsapp_phone_number_id' => 'encrypted',
            'whatsapp_access_token' => 'encrypted',
        ];
    }

    /**
     * Check if user is an admin.
     */
    public function isAdmin(): bool
    {
        return $this->role === self::ROLE_ADMIN;
    }

    /**
     * Check if user is a merchant.
     */
    public function isMerchant(): bool
    {
        return $this->role === self::ROLE_MERCHANT;
    }

    /**
     * Check if merchant has WhatsApp configured.
     */
    public function hasWhatsAppConfigured(): bool
    {
        return !empty($this->whatsapp_phone_number_id) && !empty($this->whatsapp_access_token);
    }

    /**
     * Get available business types.
     */
    public static function getBusinessTypes(): array
    {
        return [
            self::BUSINESS_RESTAURANT => 'Restaurant Booking',
            self::BUSINESS_ORDER_TRACKING => 'Order Tracking',
        ];
    }

    /**
     * Check if user is a restaurant business.
     */
    public function isRestaurant(): bool
    {
        return $this->business_type === self::BUSINESS_RESTAURANT;
    }

    /**
     * Check if user is an order tracking business.
     */
    public function isOrderTracking(): bool
    {
        return $this->business_type === self::BUSINESS_ORDER_TRACKING;
    }

    /**
     * Get the products for order tracking merchants.
     */
    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /**
     * Get the orders for order tracking merchants.
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Get the bookings for restaurant businesses.
     */
    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    /**
     * Get the conversations for this user/merchant.
     */
    public function conversations(): HasMany
    {
        return $this->hasMany(Conversation::class);
    }

    /**
     * Get the documents for this user.
     */
    public function documents(): HasMany
    {
        return $this->hasMany(Document::class);
    }

    /**
     * Get the merchant settings for this user.
     */
    public function merchantSettings(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(MerchantSetting::class);
    }

    /**
     * Get the restaurant settings for this user.
     */
    public function restaurantSetting(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(RestaurantSetting::class);
    }

    /**
     * Get the order tracking settings for this user.
     */
    public function orderTrackingSetting(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(OrderTrackingSetting::class);
    }

    /**
     * Get the tables for restaurant businesses.
     */
    public function tables(): HasMany
    {
        return $this->hasMany(Table::class);
    }
}
