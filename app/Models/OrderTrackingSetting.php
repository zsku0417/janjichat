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
    ];

    /**
     * Get the merchant (user) who owns this settings.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
