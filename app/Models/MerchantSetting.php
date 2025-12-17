<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MerchantSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'business_name',
        'greeting_message',
        'ai_tone',
        'booking_form_template',
        'confirmation_template',
        'reminder_template',
        'reminder_hours_before',
        'email_on_escalation',
        'notification_email',
    ];

    protected $casts = [
        'reminder_hours_before' => 'integer',
        'email_on_escalation' => 'boolean',
    ];

    /**
     * Get the merchant (user) who owns this settings.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
