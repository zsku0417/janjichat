<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Services\ConversationHandler;
use App\Services\WhatsAppService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Inertia\Inertia;

/**
 * Development-only controller for testing webhook functionality.
 * This controller simulates incoming WhatsApp messages for development purposes.
 */
class DevelopmentController extends Controller
{
    protected WhatsAppService $whatsApp;
    protected ConversationHandler $conversationHandler;

    public function __construct(
        WhatsAppService $whatsApp,
        ConversationHandler $conversationHandler
    ) {
        $this->whatsApp = $whatsApp;
        $this->conversationHandler = $conversationHandler;
    }

    /**
     * Show the webhook simulator page.
     */
    public function simulator(Request $request)
    {
        $phone = $request->query('phone', '60108685352');

        // Get existing conversation for this phone if any
        $conversation = Conversation::where('phone_number', $phone)->first();
        $messages = [];

        if ($conversation) {
            $messages = $conversation->messages()
                ->orderBy('created_at', 'asc')
                ->get()
                ->map(function ($message) {
                    return [
                        'id' => $message->id,
                        'direction' => $message->direction,
                        'sender_type' => $message->sender_type,
                        'content' => $message->content,
                        'created_at' => $message->created_at->format('g:i A'),
                        'created_at_full' => $message->created_at->format('M j, g:i A'),
                    ];
                });
        }

        return Inertia::render('Development/Simulator', [
            'initialMessages' => $messages,
            'conversationId' => $conversation?->id,
            'initialPhone' => $phone,
        ]);
    }

    /**
     * Simulate an incoming WhatsApp webhook message.
     */
    public function simulateMessage(Request $request)
    {
        $request->validate([
            'phone_number' => 'required|string',
            'name' => 'required|string',
            'message' => 'required|string',
        ]);

        $phone = preg_replace('/[^0-9]/', '', $request->phone_number);
        $name = $request->name;
        $messageText = $request->message;

        // Create a webhook payload that mimics Meta's format
        $payload = [
            'object' => 'whatsapp_business_account',
            'entry' => [
                [
                    'id' => '123456789',
                    'changes' => [
                        [
                            'value' => [
                                'messaging_product' => 'whatsapp',
                                'metadata' => [
                                    'display_phone_number' => config('whatsapp.test_phone'),
                                    'phone_number_id' => config('whatsapp.phone_number_id'),
                                ],
                                'contacts' => [
                                    [
                                        'profile' => [
                                            'name' => $name,
                                        ],
                                        'wa_id' => $phone,
                                    ],
                                ],
                                'messages' => [
                                    [
                                        'from' => $phone,
                                        'id' => 'simulated_' . uniqid(),
                                        'timestamp' => (string) time(),
                                        'text' => [
                                            'body' => $messageText,
                                        ],
                                        'type' => 'text',
                                    ],
                                ],
                            ],
                            'field' => 'messages',
                        ],
                    ],
                ],
            ],
        ];

        Log::info('Simulating webhook message', [
            'from' => $phone,
            'message' => $messageText,
        ]);

        // Parse the payload using the WhatsApp service
        $parsedData = $this->whatsApp->parseWebhookPayload($payload);

        if ($parsedData && $parsedData['type'] === 'message') {
            // Handle the message using the conversation handler
            $this->conversationHandler->handleIncomingMessage($parsedData);
        }

        return redirect()->back()->with('success', 'Message sent!');
    }

    /**
     * Get messages for a conversation (AJAX endpoint for real-time updates).
     */
    public function getMessages(Request $request)
    {
        $phone = preg_replace('/[^0-9]/', '', $request->phone);

        $conversation = Conversation::where('phone_number', $phone)->first();

        if (!$conversation) {
            return response()->json([
                'messages' => [],
                'conversation_id' => null,
            ]);
        }

        $messages = $conversation->messages()
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function ($message) {
                return [
                    'id' => $message->id,
                    'direction' => $message->direction,
                    'sender_type' => $message->sender_type,
                    'content' => $message->content,
                    'created_at' => $message->created_at->format('g:i A'),
                    'created_at_full' => $message->created_at->format('M j, g:i A'),
                ];
            });

        return response()->json([
            'messages' => $messages,
            'conversation_id' => $conversation->id,
            'mode' => $conversation->mode,
            'customer_name' => $conversation->customer_name,
        ]);
    }

    /**
     * Clear a conversation for fresh testing.
     */
    public function clearConversation(Request $request)
    {
        $phone = preg_replace('/[^0-9]/', '', $request->phone);

        $conversation = Conversation::where('phone_number', $phone)->first();

        if ($conversation) {
            $conversation->messages()->delete();
            $conversation->clearContext();
            $conversation->update([
                'mode' => 'ai',
                'needs_reply' => false,
                'escalation_reason' => null,
            ]);
        }

        return response()->json(['success' => true]);
    }
}
