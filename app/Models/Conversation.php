<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Carbon\Carbon;

class Conversation extends Model
{
    use HasFactory;

    protected $fillable = [
        'whatsapp_id',
        'phone_number',
        'customer_name',
        'mode',
        'status',
        'needs_reply',
        'escalation_reason',
        'last_message_at',
        'context_type',
        'context_data',
        'context_expires_at',
    ];

    protected $casts = [
        'needs_reply' => 'boolean',
        'last_message_at' => 'datetime',
        'context_data' => 'array',
        'context_expires_at' => 'datetime',
    ];

    // Context types - Restaurant
    const CONTEXT_AWAITING_BOOKING_CONFIRMATION = 'awaiting_booking_confirmation';
    const CONTEXT_BOOKING_FLOW = 'booking_flow';
    const CONTEXT_AWAITING_CANCELLATION_CONFIRMATION = 'awaiting_cancellation_confirmation';
    const CONTEXT_BOOKING_SELECTION = 'booking_selection'; // When user must select from multiple bookings

    // Context types - Order Tracking
    const CONTEXT_ORDER_FLOW = 'order_flow';
    const CONTEXT_AWAITING_ORDER_CONFIRMATION = 'awaiting_order_confirmation';

    /**
     * Get all messages in this conversation.
     */
    public function messages(): HasMany
    {
        return $this->hasMany(Message::class)->orderBy('created_at', 'asc');
    }

    /**
     * Get all bookings linked to this conversation.
     */
    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    /**
     * Get all orders linked to this conversation.
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Check if this conversation is in AI mode.
     */
    public function isAiMode(): bool
    {
        return $this->mode === 'ai';
    }

    /**
     * Check if this conversation is in admin mode.
     */
    public function isAdminMode(): bool
    {
        return $this->mode === 'admin';
    }

    /**
     * Switch conversation to admin mode.
     */
    public function escalateToAdmin(string $reason): void
    {
        $this->update([
            'mode' => 'admin',
            'needs_reply' => true,
            'escalation_reason' => $reason,
        ]);
    }

    /**
     * Switch conversation back to AI mode.
     */
    public function switchToAiMode(): void
    {
        $this->update([
            'mode' => 'ai',
            'needs_reply' => false,
            'escalation_reason' => null,
        ]);
    }

    /**
     * Set a conversation context for flow continuity.
     * Context never expires by default - it persists until explicitly cleared or replaced.
     */
    public function setContext(string $type, array $data = []): void
    {
        $this->update([
            'context_type' => $type,
            'context_data' => $data,
            'context_expires_at' => null, // Never expires
        ]);
    }

    /**
     * Get the current context.
     * Context persists indefinitely until cleared or replaced.
     */
    public function getContext(): ?array
    {
        if (!$this->context_type) {
            return null;
        }

        return [
            'type' => $this->context_type,
            'data' => $this->context_data ?? [],
        ];
    }

    /**
     * Check if the conversation has a specific context type.
     */
    public function hasContext(string $type): bool
    {
        $context = $this->getContext();
        return $context && $context['type'] === $type;
    }

    /**
     * Clear the conversation context.
     */
    public function clearContext(): void
    {
        $this->update([
            'context_type' => null,
            'context_data' => null,
            'context_expires_at' => null,
        ]);
    }

    /**
     * Scope to get conversations needing admin reply.
     */
    public function scopeNeedsReply($query)
    {
        return $query->where('needs_reply', true);
    }

    /**
     * Scope to get active conversations.
     */
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    /**
     * Helper method to format the last message timestamp.
     */
    public function getFormattedLastMessageAtAttribute(): ?string
    {
        if (!$this->last_message_at) {
            return null;
        }

        $date = $this->last_message_at;
        $now = now();

        if ($date->isToday()) {
            return $date->format('g:i A'); // e.g., "2:30 PM"
        }

        if ($date->isYesterday()) {
            return 'Yesterday';
        }

        if ($date->greaterThan($now->subDays(5))) {
            return $date->format('l'); // e.g., "Monday"
        }

        return $date->format('M j, Y'); // e.g., "Dec 10, 2025"
    }
}
