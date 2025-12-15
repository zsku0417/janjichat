<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    use HasFactory;

    // Status constants
    const STATUS_PENDING_PAYMENT = 'pending_payment';
    const STATUS_PROCESSING = 'processing';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    // Fulfillment type constants
    const FULFILLMENT_PICKUP = 'pickup';
    const FULFILLMENT_DELIVERY = 'delivery';

    protected $fillable = [
        'user_id',
        'conversation_id',
        'customer_name',
        'customer_phone',
        'fulfillment_type',
        'delivery_address',
        'requested_datetime',
        'special_notes',
        'status',
        'total_amount',
    ];

    protected $casts = [
        'requested_datetime' => 'datetime',
        'total_amount' => 'decimal:2',
    ];

    /**
     * Get the merchant (user) that owns this order.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the conversation associated with this order.
     */
    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    /**
     * Get the items in this order.
     */
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Get all possible statuses.
     */
    public static function getStatuses(): array
    {
        return [
            self::STATUS_PENDING_PAYMENT => 'Pending Verify Payment',
            self::STATUS_PROCESSING => 'Processing',
            self::STATUS_COMPLETED => 'Completed',
            self::STATUS_CANCELLED => 'Cancelled',
        ];
    }

    /**
     * Get the status label.
     */
    public function getStatusLabelAttribute(): string
    {
        return self::getStatuses()[$this->status] ?? $this->status;
    }

    /**
     * Get the formatted total amount.
     */
    public function getFormattedTotalAttribute(): string
    {
        return 'RM ' . number_format($this->total_amount, 2);
    }

    /**
     * Check if order is for delivery.
     */
    public function isDelivery(): bool
    {
        return $this->fulfillment_type === self::FULFILLMENT_DELIVERY;
    }

    /**
     * Check if order is for pickup.
     */
    public function isPickup(): bool
    {
        return $this->fulfillment_type === self::FULFILLMENT_PICKUP;
    }

    /**
     * Calculate and update total amount from items.
     */
    public function calculateTotal(): void
    {
        $this->total_amount = $this->items()->sum('subtotal');
        $this->save();
    }

    /**
     * Scope to filter by status.
     */
    public function scopeStatus($query, string $status)
    {
        return $query->where('status', $status);
    }

    /**
     * Scope to get pending orders.
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING_PAYMENT);
    }
}
