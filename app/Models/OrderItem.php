<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'product_id',
        'product_name',
        'quantity',
        'unit_price',
        'subtotal',
    ];

    protected $casts = [
        'quantity' => 'integer',
        'unit_price' => 'decimal:2',
        'subtotal' => 'decimal:2',
    ];

    /**
     * Get the order this item belongs to.
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Get the product (may be null if product was deleted).
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Get formatted unit price.
     */
    public function getFormattedPriceAttribute(): string
    {
        return 'RM ' . number_format($this->unit_price, 2);
    }

    /**
     * Get formatted subtotal.
     */
    public function getFormattedSubtotalAttribute(): string
    {
        return 'RM ' . number_format($this->subtotal, 2);
    }

    /**
     * Calculate subtotal based on quantity and unit price.
     */
    public function calculateSubtotal(): void
    {
        $this->subtotal = $this->quantity * $this->unit_price;
    }

    /**
     * Boot method to auto-calculate subtotal.
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($item) {
            if (!$item->subtotal) {
                $item->subtotal = $item->quantity * $item->unit_price;
            }
        });

        static::updating(function ($item) {
            $item->subtotal = $item->quantity * $item->unit_price;
        });
    }
}
