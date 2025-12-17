<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class Booking extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'conversation_id',
        'table_id',
        'customer_name',
        'customer_phone',
        'booking_date',
        'booking_time',
        'end_time',
        'pax',
        'special_request',
        'status',
        'reminder_sent',
        'created_by',
    ];

    protected $casts = [
        'booking_date' => 'date',
        'pax' => 'integer',
        'reminder_sent' => 'boolean',
    ];

    /**
     * Get the conversation this booking is linked to.
     */
    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    /**
     * Get the table for this booking.
     */
    public function table(): BelongsTo
    {
        return $this->belongsTo(Table::class);
    }

    /**
     * Check if booking is confirmed.
     */
    public function isConfirmed(): bool
    {
        return $this->status === 'confirmed';
    }

    /**
     * Check if booking is cancelled.
     */
    public function isCancelled(): bool
    {
        return $this->status === 'cancelled';
    }

    /**
     * Get booking datetime as Carbon instance.
     */
    public function getBookingDateTimeAttribute(): Carbon
    {
        return Carbon::parse($this->booking_date->format('Y-m-d') . ' ' . $this->booking_time);
    }

    /**
     * Get end datetime as Carbon instance.
     */
    public function getEndDateTimeAttribute(): Carbon
    {
        return Carbon::parse($this->booking_date->format('Y-m-d') . ' ' . $this->end_time);
    }

    /**
     * Check if reminder should be sent.
     */
    public function shouldSendReminder(): bool
    {
        if ($this->reminder_sent || !$this->isConfirmed()) {
            return false;
        }

        // Get reminder_hours_before from MerchantSetting via conversation
        $merchant = $this->conversation?->merchant;
        $merchantSettings = $merchant ? MerchantSetting::where('user_id', $merchant->id)->first() : null;
        $reminderHours = $merchantSettings?->reminder_hours_before ?? 24;
        $reminderTime = $this->booking_date_time->subHours($reminderHours);

        return now()->gte($reminderTime) && now()->lt($this->booking_date_time);
    }

    /**
     * Scope to get upcoming bookings.
     */
    public function scopeUpcoming($query)
    {
        return $query->where('booking_date', '>=', now()->toDateString())
            ->where('status', 'confirmed')
            ->orderBy('booking_date')
            ->orderBy('booking_time');
    }

    /**
     * Scope to get today's bookings.
     */
    public function scopeToday($query)
    {
        return $query->whereDate('booking_date', now()->toDateString());
    }

    /**
     * Scope to get bookings needing reminders.
     */
    public function scopeNeedsReminder($query)
    {
        return $query->where('reminder_sent', false)
            ->where('status', 'confirmed');
    }
}
