<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class LandingChatService
{
    protected OpenAIService $openAI;
    protected float $confidenceThreshold;

    public function __construct(OpenAIService $openAI)
    {
        $this->openAI = $openAI;
        $this->confidenceThreshold = config('openai.confidence_threshold', 0.2);
    }

    /**
     * Generate a response for landing page chat.
     *
     * @param string $message The user's message
     * @param array $sessionHistory Previous messages in format [['role' => 'user'|'assistant', 'content' => string], ...]
     * @return array ['response' => string, 'success' => bool]
     */
    public function generateResponse(string $message, array $sessionHistory = []): array
    {
        try {
            // Search admin knowledge base for relevant content
            $context = $this->searchAdminKnowledgeBase($message);

            // Build conversation history for OpenAI
            $messages = $this->buildMessages($sessionHistory, $message);

            // Generate response
            $response = $this->generateWithContext($messages, $context);

            return [
                'response' => $response,
                'success' => true,
            ];
        } catch (\Exception $e) {
            Log::error('Landing chat error', [
                'message' => $message,
                'error' => $e->getMessage(),
            ]);

            return [
                'response' => "I'm sorry, I'm having trouble processing your request. Please try again or contact us directly for assistance.",
                'success' => false,
            ];
        }
    }

    /**
     * Search the admin knowledge base for relevant content.
     */
    protected function searchAdminKnowledgeBase(string $query, int $limit = 5): string
    {
        // Get admin user IDs
        $adminIds = User::where('role', User::ROLE_ADMIN)->pluck('id')->toArray();

        if (empty($adminIds)) {
            return "No knowledge base available.";
        }

        // Generate embedding for the query
        $queryEmbedding = $this->openAI->createEmbedding($query);
        $embeddingString = '[' . implode(',', $queryEmbedding) . ']';

        // Search admin documents using vector similarity
        $placeholders = implode(',', array_fill(0, count($adminIds), '?'));
        $params = array_merge([$embeddingString], $adminIds, [$embeddingString, $limit]);

        $results = DB::select("
            SELECT 
                dc.id,
                dc.document_id,
                dc.content,
                dc.chunk_index,
                d.original_name as document_name,
                1 - (dc.embedding <=> ?::vector) as similarity
            FROM document_chunks dc
            JOIN documents d ON d.id = dc.document_id
            WHERE d.status = 'completed'
            AND d.user_id IN ({$placeholders})
            ORDER BY dc.embedding <=> ?::vector
            LIMIT ?
        ", $params);

        if (empty($results)) {
            return "No relevant information found in knowledge base.";
        }

        // Build context from results
        $context = "Relevant information from knowledge base:\n\n";
        foreach ($results as $result) {
            if ($result->similarity >= $this->confidenceThreshold) {
                $context .= "--- Source: {$result->document_name} ---\n";
                $context .= $result->content . "\n\n";
            }
        }

        return $context;
    }

    /**
     * Build messages array for OpenAI.
     */
    protected function buildMessages(array $sessionHistory, string $currentMessage): array
    {
        $messages = [];

        // Add previous messages from session
        foreach ($sessionHistory as $msg) {
            if (isset($msg['role']) && isset($msg['content'])) {
                $messages[] = [
                    'role' => $msg['role'] === 'user' ? 'user' : 'assistant',
                    'content' => $msg['content'],
                ];
            }
        }

        // Add current message
        $messages[] = [
            'role' => 'user',
            'content' => $currentMessage,
        ];

        return $messages;
    }

    /**
     * Generate response with knowledge base context.
     */
    protected function generateWithContext(array $messages, string $context): string
    {
        $systemPrompt = $this->buildSystemPrompt($context);

        $response = $this->openAI->chat($messages, $systemPrompt);

        return trim($response);
    }

    /**
     * Build the system prompt for landing page chat.
     */
    protected function buildSystemPrompt(string $context): string
    {
        return <<<PROMPT
You are Janji, a friendly AI assistant for Janji Chat - an AI-powered WhatsApp chatbot platform.

Your role is to help visitors learn about Janji Chat's features, capabilities, and how it can benefit their business.

KNOWLEDGE BASE CONTEXT:
{$context}

GUIDELINES:
1. Be friendly, helpful, and professional
2. Answer questions based on the knowledge base context when available
3. If you don't have specific information, provide general guidance about the platform's capabilities
4. Encourage visitors to sign up or login to try the platform
5. Keep responses concise but informative
6. Use appropriate emojis sparingly to be friendly 😊
7. Detect and respond in the same language the visitor uses

ABOUT JANJI CHAT:
- AI-powered WhatsApp chatbot platform
- Supports restaurant booking management
- Supports order tracking for e-commerce
- Uses knowledge base (RAG) for intelligent responses
- Available 24/7 for customer service automation
- Multi-language support
- Smart escalation to human agents when needed

If asked about pricing, features not in the knowledge base, or technical details you're unsure about, politely suggest they sign up for a free account or contact support for more details.
PROMPT;
    }
}
