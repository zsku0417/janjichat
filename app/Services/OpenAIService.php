<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class OpenAIService
{
    protected string $apiKey;
    protected string $embeddingModel;
    protected string $chatModel;
    protected int $maxTokens;

    public function __construct()
    {
        $this->apiKey = config('openai.api_key');
        $this->embeddingModel = config('openai.embedding_model');
        $this->chatModel = config('openai.chat_model');
        $this->maxTokens = config('openai.max_tokens');
    }

    /**
     * Generate embedding vector for the given text.
     *
     * @param string $text
     * @return array The 1536-dimensional embedding vector
     * @throws Exception
     */
    public function createEmbedding(string $text): array
    {
        $response = Http::withToken($this->apiKey)
            ->timeout(30)
            ->post('https://api.openai.com/v1/embeddings', [
                'model' => $this->embeddingModel,
                'input' => $text,
            ]);

        if ($response->failed()) {
            Log::error('OpenAI embedding failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            throw new Exception('Failed to create embedding: ' . $response->body());
        }

        $data = $response->json();
        return $data['data'][0]['embedding'];
    }

    /**
     * Generate a chat completion response.
     *
     * @param array $messages Array of messages with 'role' and 'content'
     * @param string|null $systemPrompt Optional system prompt
     * @return string The assistant's response
     * @throws Exception
     */
    public function chat(array $messages, ?string $systemPrompt = null): string
    {
        $allMessages = [];

        // Add system prompt if provided
        if ($systemPrompt) {
            $allMessages[] = [
                'role' => 'system',
                'content' => $systemPrompt,
            ];
        }

        // Add conversation messages
        $allMessages = array_merge($allMessages, $messages);

        $response = Http::withToken($this->apiKey)
            ->timeout(60)
            ->post('https://api.openai.com/v1/chat/completions', [
                'model' => $this->chatModel,
                'messages' => $allMessages,
                'max_tokens' => $this->maxTokens,
                'temperature' => 0.7,
            ]);

        if ($response->failed()) {
            Log::error('OpenAI chat failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            throw new Exception('Failed to generate chat response: ' . $response->body());
        }

        $data = $response->json();
        return $data['choices'][0]['message']['content'];
    }

    /**
     * Generate a chat completion with JSON response.
     *
     * @param array $messages
     * @param string|null $systemPrompt
     * @return array The parsed JSON response
     * @throws Exception
     */
    public function chatJson(array $messages, ?string $systemPrompt = null): array
    {
        $allMessages = [];

        if ($systemPrompt) {
            $allMessages[] = [
                'role' => 'system',
                'content' => $systemPrompt . "\n\nRespond with valid JSON only.",
            ];
        }

        $allMessages = array_merge($allMessages, $messages);

        $response = Http::withToken($this->apiKey)
            ->timeout(60)
            ->post('https://api.openai.com/v1/chat/completions', [
                'model' => $this->chatModel,
                'messages' => $allMessages,
                'max_tokens' => $this->maxTokens,
                'temperature' => 0.3,
                'response_format' => ['type' => 'json_object'],
            ]);

        if ($response->failed()) {
            Log::error('OpenAI chat JSON failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            throw new Exception('Failed to generate JSON response: ' . $response->body());
        }

        $data = $response->json();
        $content = $data['choices'][0]['message']['content'];

        return json_decode($content, true) ?? [];
    }

    /**
     * Test the OpenAI connection.
     *
     * @return bool
     */
    public function testConnection(): bool
    {
        try {
            $response = Http::withToken($this->apiKey)
                ->timeout(10)
                ->get('https://api.openai.com/v1/models');

            if ($response->successful()) {
                Log::info('OpenAI connection test successful');
                return true;
            }

            Log::error('OpenAI connection test failed', [
                'status' => $response->status(),
            ]);
            return false;
        } catch (Exception $e) {
            Log::error('OpenAI connection test exception', [
                'message' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Estimate token count for a string (rough approximation).
     *
     * @param string $text
     * @return int
     */
    public function estimateTokens(string $text): int
    {
        // Rough estimate: ~4 characters per token for English
        return (int) ceil(strlen($text) / 4);
    }

    /**
     * Analyze an image using GPT-4 Vision to determine if it's a payment proof.
     *
     * @param string $imageUrl The URL of the image to analyze
     * @return array ['is_payment_proof' => bool, 'confidence' => float, 'description' => string]
     */
    public function analyzePaymentProof(string $imageUrl): array
    {
        try {
            $response = Http::withToken($this->apiKey)
                ->timeout(60)
                ->post('https://api.openai.com/v1/chat/completions', [
                    'model' => 'gpt-4o-mini', // Vision-capable model
                    'messages' => [
                        [
                            'role' => 'system',
                            'content' => 'You are an image analysis assistant. Analyze images and determine if they are payment receipts, bank transfer screenshots, or transaction proofs. Be strict: only mark as payment proof if it clearly shows transaction details like amount, date, reference number, bank name, or recipient details.'
                        ],
                        [
                            'role' => 'user',
                            'content' => [
                                [
                                    'type' => 'text',
                                    'text' => 'Analyze this image. Is it a payment receipt, bank transfer screenshot, or transaction proof? Return JSON: {"is_payment_proof": true/false, "confidence": 0.0-1.0, "description": "brief description of what you see"}'
                                ],
                                [
                                    'type' => 'image_url',
                                    'image_url' => [
                                        'url' => $imageUrl,
                                        'detail' => 'low' // Use low detail to reduce cost
                                    ]
                                ]
                            ]
                        ]
                    ],
                    'max_tokens' => 200,
                    'temperature' => 0.2,
                ]);

            if ($response->failed()) {
                Log::error('OpenAI Vision API failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
                // Default to not a payment proof on error
                return [
                    'is_payment_proof' => false,
                    'confidence' => 0,
                    'description' => 'Failed to analyze image',
                ];
            }

            $data = $response->json();
            $content = $data['choices'][0]['message']['content'] ?? '';

            // Try to parse JSON from response
            $content = preg_replace('/```json\s*/', '', $content);
            $content = preg_replace('/```\s*/', '', $content);
            $content = trim($content);

            $parsed = json_decode($content, true);

            if (!$parsed) {
                Log::warning('Could not parse Vision API response', ['content' => $content]);
                return [
                    'is_payment_proof' => false,
                    'confidence' => 0,
                    'description' => 'Could not parse analysis result',
                ];
            }

            Log::info('Payment proof analysis complete', [
                'is_payment_proof' => $parsed['is_payment_proof'] ?? false,
                'confidence' => $parsed['confidence'] ?? 0,
            ]);

            return [
                'is_payment_proof' => $parsed['is_payment_proof'] ?? false,
                'confidence' => (float) ($parsed['confidence'] ?? 0),
                'description' => $parsed['description'] ?? '',
            ];

        } catch (Exception $e) {
            Log::error('Exception in Vision API analysis', [
                'error' => $e->getMessage(),
            ]);
            return [
                'is_payment_proof' => false,
                'confidence' => 0,
                'description' => 'Error analyzing image',
            ];
        }
    }
}
