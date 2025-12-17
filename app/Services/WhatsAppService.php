<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class WhatsAppService
{
    protected ?string $phoneNumberId;
    protected ?string $accessToken;
    protected string $apiVersion;
    protected string $baseUrl;
    protected ?User $activeMerchant = null;

    public function __construct()
    {
        $this->apiVersion = config('whatsapp.api_version');
        $this->baseUrl = config('whatsapp.api_base_url');

        // Try to load credentials from active merchant first
        $this->loadMerchantCredentials();
    }

    /**
     * Load WhatsApp credentials from the active merchant (first merchant with configured WhatsApp).
     * Falls back to .env config if no merchant has WhatsApp configured.
     */
    protected function loadMerchantCredentials(): void
    {
        // Find first merchant with WhatsApp configured
        $merchant = User::where('role', User::ROLE_MERCHANT)
            ->whereNotNull('whatsapp_phone_number_id')
            ->whereNotNull('whatsapp_access_token')
            ->first();

        if ($merchant && $merchant->hasWhatsAppConfigured()) {
            $this->activeMerchant = $merchant;
            $this->phoneNumberId = $merchant->whatsapp_phone_number_id;
            $this->accessToken = $merchant->whatsapp_access_token;

            // Log::debug('WhatsApp credentials loaded from merchant', [
            //     'merchant_id' => $merchant->id,
            //     'merchant_name' => $merchant->name,
            // ]);
        } else {
            // Fallback to .env config
            $this->phoneNumberId = config('whatsapp.phone_number_id');
            $this->accessToken = config('whatsapp.access_token');

            Log::debug('WhatsApp credentials loaded from .env config');
        }
    }

    /**
     * Get the active merchant (if loaded from database).
     */
    public function getActiveMerchant(): ?User
    {
        return $this->activeMerchant;
    }

    /**
     * Check if WhatsApp is properly configured.
     */
    public function isConfigured(): bool
    {
        return !empty($this->phoneNumberId) && !empty($this->accessToken);
    }

    /**
     * Send a text message to a WhatsApp number.
     *
     * @param string $to Phone number in international format (e.g., 60123456789)
     * @param string $message The text message to send
     * @return array Response from WhatsApp API
     * @throws Exception
     */
    public function sendMessage(string $to, string $message): array
    {
        $url = "{$this->baseUrl}/{$this->apiVersion}/{$this->phoneNumberId}/messages";

        $response = Http::withToken($this->accessToken)
            ->timeout(30)
            ->post($url, [
                'messaging_product' => 'whatsapp',
                'recipient_type' => 'individual',
                'to' => $this->formatPhoneNumber($to),
                'type' => 'text',
                'text' => [
                    'preview_url' => false,
                    'body' => $message,
                ],
            ]);

        if ($response->failed()) {
            Log::error('WhatsApp send message failed', [
                'to' => $to,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            throw new Exception('Failed to send WhatsApp message: ' . $response->body());
        }

        $data = $response->json();

        Log::info('WhatsApp message sent', [
            'to' => $to,
            'message_id' => $data['messages'][0]['id'] ?? null,
        ]);

        return $data;
    }

    /**
     * Mark a message as read.
     *
     * @param string $messageId The WhatsApp message ID
     * @return void
     */
    public function markAsRead(string $messageId): void
    {
        $url = "{$this->baseUrl}/{$this->apiVersion}/{$this->phoneNumberId}/messages";

        try {
            Http::withToken($this->accessToken)
                ->timeout(10)
                ->post($url, [
                    'messaging_product' => 'whatsapp',
                    'status' => 'read',
                    'message_id' => $messageId,
                ]);
        } catch (Exception $e) {
            Log::warning('Failed to mark message as read', [
                'message_id' => $messageId,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Parse incoming webhook payload from WhatsApp.
     *
     * @param array $payload The raw webhook payload
     * @return array|null Parsed message data or null if not a message
     */
    public function parseWebhookPayload(array $payload): ?array
    {
        try {
            // Extract the entry
            $entry = $payload['entry'][0] ?? null;
            if (!$entry) {
                return null;
            }

            // Extract changes
            $changes = $entry['changes'][0] ?? null;
            if (!$changes || $changes['field'] !== 'messages') {
                return null;
            }

            $value = $changes['value'] ?? null;
            if (!$value) {
                return null;
            }

            // Extract the phone_number_id from metadata (identifies which merchant's WhatsApp)
            $phoneNumberId = $value['metadata']['phone_number_id'] ?? null;

            // Check for messages
            $messages = $value['messages'] ?? null;
            if (!$messages || empty($messages)) {
                // This might be a status update
                $statusData = $this->parseStatusUpdate($value);
                if ($statusData) {
                    $statusData['phone_number_id'] = $phoneNumberId;
                }
                return $statusData;
            }

            $message = $messages[0];
            $contact = $value['contacts'][0] ?? [];

            return [
                'type' => 'message',
                'message_id' => $message['id'],
                'from' => $message['from'],
                'timestamp' => $message['timestamp'],
                'message_type' => $message['type'],
                'content' => $this->extractMessageContent($message),
                'contact_name' => $contact['profile']['name'] ?? null,
                'metadata' => $this->extractMetadata($message),
                'phone_number_id' => $phoneNumberId, // Add this for multi-tenant detection
            ];

        } catch (Exception $e) {
            Log::error('Failed to parse WhatsApp webhook payload', [
                'error' => $e->getMessage(),
                'payload' => $payload,
            ]);
            return null;
        }
    }

    /**
     * Parse status update from webhook.
     */
    protected function parseStatusUpdate(array $value): ?array
    {
        $statuses = $value['statuses'] ?? null;
        if (!$statuses || empty($statuses)) {
            return null;
        }

        $status = $statuses[0];

        return [
            'type' => 'status',
            'message_id' => $status['id'],
            'recipient_id' => $status['recipient_id'],
            'status' => $status['status'], // sent, delivered, read, failed
            'timestamp' => $status['timestamp'],
        ];
    }

    /**
     * Extract message content based on message type.
     */
    protected function extractMessageContent(array $message): ?string
    {
        return match ($message['type']) {
            'text' => $message['text']['body'] ?? null,
            'image' => '[Image received]',
            'audio' => '[Audio message received]',
            'video' => '[Video received]',
            'document' => '[Document received]',
            'sticker' => '[Sticker received]',
            'location' => '[Location shared]',
            'contacts' => '[Contact shared]',
            default => '[Unsupported message type]',
        };
    }

    /**
     * Extract additional metadata for non-text messages.
     */
    protected function extractMetadata(array $message): ?array
    {
        $type = $message['type'];

        if ($type === 'text') {
            return null;
        }

        $mediaData = $message[$type] ?? [];

        return [
            'media_id' => $mediaData['id'] ?? null,
            'mime_type' => $mediaData['mime_type'] ?? null,
            'filename' => $mediaData['filename'] ?? null,
            'caption' => $mediaData['caption'] ?? null,
        ];
    }

    /**
     * Format phone number for WhatsApp API.
     * Removes any non-numeric characters and ensures correct format.
     */
    protected function formatPhoneNumber(string $phone): string
    {
        // Remove all non-numeric characters
        $phone = preg_replace('/[^0-9]/', '', $phone);

        // If starts with 0, assume Malaysian number and add 60
        if (str_starts_with($phone, '0')) {
            $phone = '60' . substr($phone, 1);
        }

        return $phone;
    }

    /**
     * Verify webhook callback from Meta.
     *
     * @param string|null $mode
     * @param string|null $token
     * @param string|null $challenge
     * @return string|null The challenge string if verified, null otherwise
     */
    public function verifyWebhook(?string $mode, ?string $token, ?string $challenge): ?string
    {
        $verifyToken = config('whatsapp.verify_token');

        if ($mode === 'subscribe' && $token === $verifyToken) {
            Log::info('WhatsApp webhook verified successfully');
            return $challenge;
        }

        Log::warning('WhatsApp webhook verification failed', [
            'mode' => $mode,
            'token_match' => $token === $verifyToken,
        ]);

        return null;
    }

    /**
     * Test the WhatsApp connection by sending a test message.
     *
     * @param string $to Phone number to send test message to
     * @return bool
     */
    public function testConnection(string $to): bool
    {
        try {
            $this->sendMessage($to, 'Test message from WhatsApp AI Chatbot 🤖');
            return true;
        } catch (Exception $e) {
            Log::error('WhatsApp connection test failed', [
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }
}
