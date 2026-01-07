<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Models\Message;
use App\Services\ConversationHandler;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;

class ConversationController extends Controller
{
    protected ConversationHandler $conversationHandler;

    public function __construct(ConversationHandler $conversationHandler)
    {
        $this->conversationHandler = $conversationHandler;
    }

    /**
     * Display a listing of all conversations.
     */
    public function index(Request $request): Response
    {
        $user = auth()->user();

        $query = Conversation::with([
            'messages' => function ($query) {
                $query->orderBy('created_at', 'desc');
            }
        ]);

        // Multi-tenant: Merchants see only their conversations
        if ($user->isMerchant()) {
            $query->where('user_id', $user->id);
        }

        // Search by phone number or customer name
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('phone_number', 'like', "%{$search}%")
                    ->orWhere('customer_name', 'like', "%{$search}%");
            });
        }

        // Filter by status
        if ($request->has('filter')) {
            match ($request->filter) {
                'needs_reply' => $query->needsReply(),
                'ai_mode' => $query->where('mode', 'ai'),
                'admin_mode' => $query->where('mode', 'admin'),
                default => null,
            };
        }

        $conversations = $query->orderBy('last_message_at', 'desc')
            ->paginate(20)
            ->through(function ($conversation) {
                $lastMessage = $conversation->messages->last();
                return [
                    'id' => $conversation->id,
                    'customer_name' => $conversation->customer_name ?? 'Unknown',
                    'phone_number' => $conversation->phone_number,
                    'mode' => $conversation->mode,
                    'needs_reply' => $conversation->needs_reply,
                    'escalation_reason' => $conversation->escalation_reason,
                    'last_message' => $lastMessage?->content ?? '',
                    'last_message_direction' => $lastMessage?->direction ?? 'inbound',
                    'last_message_sender' => $lastMessage?->sender_type ?? 'customer',
                    'last_message_at' => $conversation->formatted_last_message_at,
                    'status' => $conversation->status,
                ];
            });

        return Inertia::render('Conversations/Index', [
            'conversations' => $conversations,
            'filter' => $request->filter ?? 'all',
            'search' => $request->search ?? '',
            'selected' => $request->selected ?? null,
        ]);
    }

    /**
     * Display a specific conversation with all messages.
     */
    public function show(Conversation $conversation): Response
    {
        $messages = $conversation->messages()
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function ($message) {
                return [
                    'id' => $message->id,
                    'direction' => $message->direction,
                    'sender_type' => $message->sender_type,
                    'message_type' => $message->message_type,
                    'content' => $message->content,
                    'status' => $message->status,
                    'media_url' => $message->media_url,
                    'created_at' => $message->created_at->format('M j, g:i A'),
                ];
            });

        return Inertia::render('Conversations/Show', [
            'conversation' => [
                'id' => $conversation->id,
                'customer_name' => $conversation->customer_name ?? 'Unknown',
                'phone_number' => $conversation->phone_number,
                'mode' => $conversation->mode,
                'needs_reply' => $conversation->needs_reply,
                'escalation_reason' => $conversation->escalation_reason,
                'status' => $conversation->status,
            ],
            'messages' => $messages,
        ]);
    }

    /**
     * Get messages for a conversation (JSON API for AJAX requests).
     */
    public function messages(Conversation $conversation)
    {
        $messages = $conversation->messages()
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function ($message) {
                return [
                    'id' => $message->id,
                    'direction' => $message->direction,
                    'sender_type' => $message->sender_type,
                    'message_type' => $message->message_type,
                    'content' => $message->content,
                    'status' => $message->status,
                    'media_url' => $message->media_url,
                    'created_at' => $message->created_at->format('M j, g:i A'),
                ];
            });

        $lastMessage = $messages->last();

        return response()->json([
            'conversation' => [
                'id' => $conversation->id,
                'customer_name' => $conversation->customer_name ?? 'Unknown',
                'phone_number' => $conversation->phone_number,
                'mode' => $conversation->mode,
                'needs_reply' => $conversation->needs_reply,
                'escalation_reason' => $conversation->escalation_reason,
                'status' => $conversation->status,
                'last_message' => $lastMessage['content'] ?? '',
                'last_message_direction' => $lastMessage['direction'] ?? 'inbound',
                'last_message_sender' => $lastMessage['sender_type'] ?? 'customer',
                'last_message_at' => $conversation->formatted_last_message_at,
            ],
            'messages' => $messages,
        ]);
    }

    /**
     * Send a reply to a conversation.
     */
    public function reply(Request $request, Conversation $conversation): RedirectResponse
    {
        $request->validate([
            'message' => 'required|string|max:4096',
        ]);

        $this->conversationHandler->sendAdminReply($conversation, $request->message);

        return back()->with('success', 'Message sent successfully!');
    }

    /**
     * Toggle conversation mode between AI and Admin.
     */
    public function toggleMode(Conversation $conversation): RedirectResponse
    {
        if ($conversation->isAiMode()) {
            $conversation->update([
                'mode' => 'admin',
                'needs_reply' => true,
            ]);
        } else {
            $conversation->switchToAiMode();
        }

        return back()->with('success', 'Conversation mode updated!');
    }

    /**
     * Delete a conversation and all its messages.
     */
    public function destroy(Conversation $conversation): RedirectResponse
    {
        // Delete all related messages first
        $conversation->messages()->delete();

        // Clear any context data
        $conversation->clearContext();

        // Delete the conversation
        $conversation->delete();

        return redirect()->route('conversations.index')
            ->with('success', 'Conversation deleted successfully!');
    }
}

