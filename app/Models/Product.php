<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'price',
        'description',
        'is_active',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    protected $appends = ['image_urls', 'primary_image_url', 'total_sales'];

    /**
     * Get the merchant (user) that owns this product.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the order items for this product.
     */
    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Get the media (images) for this product.
     */
    public function media(): MorphMany
    {
        return $this->morphMany(Media::class, 'mediable');
    }

    /**
     * Get all image URLs for this product.
     */
    public function getImageUrlsAttribute(): array
    {
        return $this->media->map(fn($m) => $m->url)->toArray();
    }

    /**
     * Get the primary (first) image URL.
     */
    public function getPrimaryImageUrlAttribute(): ?string
    {
        return $this->media->first()?->url;
    }

    /**
     * Get total sales count (sum of quantities from all order items).
     */
    public function getTotalSalesAttribute(): int
    {
        return (int) $this->orderItems()->sum('quantity');
    }

    /**
     * Scope to get only active products.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Get the formatted price.
     */
    public function getFormattedPriceAttribute(): string
    {
        return 'RM ' . number_format((float) $this->price, 2);
    }
}

