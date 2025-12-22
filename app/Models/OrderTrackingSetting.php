<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderTrackingSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'pickup_address',
        'order_prefix',
        'payment_message',
        'logo_media_id',
    ];

    protected $appends = ['logo_url'];

    /**
     * Get the merchant (user) who owns this settings.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the logo media.
     */
    public function logoMedia(): BelongsTo
    {
        return $this->belongsTo(Media::class, 'logo_media_id');
    }

    /**
     * Get the logo URL.
     */
    public function getLogoUrlAttribute(): ?string
    {
        return $this->logoMedia?->url;
    }
}
