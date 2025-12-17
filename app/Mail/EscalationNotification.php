<?php

namespace App\Mail;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class EscalationNotification extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public Conversation $conversation;
    public string $reason;
    public array $messages;
    public string $conversationUrl;
    public string $customerName;
    public string $customerPhone;

    /**
     * Create a new message instance.
     */
    public function __construct(Conversation $conversation, string $reason)
    {
        $this->conversation = $conversation;
        $this->reason = $reason;
        $this->customerName = $conversation->customer_name ?? 'Unknown';
        $this->customerPhone = $conversation->phone_number ?? 'Unknown';

        // Get last 10 messages - using raw query to bypass model's default ordering
        $this->messages = Message::where('conversation_id', $conversation->id)
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get()
            ->sortBy('created_at')  // Re-sort in chronological order for display
            ->values()
            ->map(function ($msg) {
                return [
                    'direction' => $msg->direction,
                    'sender_type' => $msg->sender_type,
                    'content' => $msg->content,
                    'created_at' => $msg->created_at->format('M j, g:i A'),
                ];
            })
            ->toArray();

        // Generate conversation URL
        $this->conversationUrl = url("/conversations?selected={$conversation->id}");
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "⚠️ Customer Needs Attention: {$this->customerName}",
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.escalation',
        );
    }

    /**
     * Get the attachments for the message.
     */
    public function attachments(): array
    {
        return [];
    }
}
