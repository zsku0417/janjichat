<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RestaurantSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'opening_time',
        'closing_time',
        'slot_duration_minutes',
    ];

    protected $casts = [
        'slot_duration_minutes' => 'integer',
    ];

    /**
     * Get the merchant (user) who owns this settings.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get settings for a specific merchant.
     */
    public static function getForMerchant(int $userId): ?self
    {
        return self::where('user_id', $userId)->first();
    }

    /**
     * Get settings for the currently authenticated user.
     * Falls back to first merchant if not authenticated (webhook context).
     */
    public static function getInstance(): ?self
    {
        $userId = auth()->id();

        // If authenticated, get settings for that user
        if ($userId) {
            return self::getForMerchant($userId);
        }

        // For webhook context (no auth), get settings for first merchant
        // TODO: In true multi-tenant, pass merchant ID through the request
        $merchant = User::where('role', User::ROLE_MERCHANT)->first();
        if ($merchant) {
            return self::getForMerchant($merchant->id);
        }

        return null;
    }

    /**
     * Get formatted opening time.
     */
    public function getFormattedOpeningTimeAttribute(): string
    {
        return date('g:i A', strtotime($this->opening_time));
    }

    /**
     * Get formatted closing time.
     */
    public function getFormattedClosingTimeAttribute(): string
    {
        return date('g:i A', strtotime($this->closing_time));
    }
}
