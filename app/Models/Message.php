<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'conversation_id',
        'direction',
        'sender_type',
        'message_type',
        'content',
        'whatsapp_message_id',
        'status',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
    ];

    /**
     * Get the conversation this message belongs to.
     */
    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    /**
     * Check if this is an inbound message (from customer).
     */
    public function isInbound(): bool
    {
        return $this->direction === 'inbound';
    }

    /**
     * Check if this is an outbound message (to customer).
     */
    public function isOutbound(): bool
    {
        return $this->direction === 'outbound';
    }

    /**
     * Check if this is a text message.
     */
    public function isText(): bool
    {
        return $this->message_type === 'text';
    }

    /**
     * Check if message was sent by AI.
     */
    public function isSentByAi(): bool
    {
        return $this->sender_type === 'ai';
    }

    /**
     * Check if message was sent by admin.
     */
    public function isSentByAdmin(): bool
    {
        return $this->sender_type === 'admin';
    }

    /**
     * Scope to get only text messages.
     */
    public function scopeTextOnly($query)
    {
        return $query->where('message_type', 'text');
    }
}
