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
     */
    public static function getInstance(): ?self
    {
        $userId = auth()->id();
        if (!$userId) {
            return null;
        }

        return self::getForMerchant($userId);
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
