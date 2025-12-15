<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\WhatsAppService;
use App\Services\ConversationHandler;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;

class WhatsAppWebhookController extends Controller
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
     * Handle webhook verification from Meta.
     * This is called when setting up the webhook in Meta's developer portal.
     *
     * GET /api/webhook/whatsapp
     */
    public function verify(Request $request): Response
    {
        $mode = $request->query('hub_mode');
        $token = $request->query('hub_verify_token');
        $challenge = $request->query('hub_challenge');

        Log::info('WhatsApp webhook verification attempt', [
            'mode' => $mode,
            'token' => $token ? 'provided' : 'missing',
        ]);

        $result = $this->whatsApp->verifyWebhook($mode, $token, $challenge);

        if ($result !== null) {
            return response($result, 200);
        }

        return response('Verification failed', 403);
    }

    /**
     * Handle incoming webhook events from WhatsApp.
     *
     * POST /api/webhook/whatsapp
     */
    public function handle(Request $request): Response
    {
        $payload = $request->all();

        Log::debug('WhatsApp webhook received', [
            'payload' => $payload,
        ]);

        // Parse the webhook payload
        $parsedData = $this->whatsApp->parseWebhookPayload($payload);

        if ($parsedData === null) {
            Log::debug('Ignoring non-message webhook event');
            return response('OK', 200);
        }

        // Handle based on event type
        switch ($parsedData['type']) {
            case 'message':
                $this->conversationHandler->handleIncomingMessage($parsedData);
                break;

            case 'status':
                $this->conversationHandler->handleStatusUpdate($parsedData);
                break;
        }

        // Always return 200 to acknowledge receipt
        return response('OK', 200);
    }
}
