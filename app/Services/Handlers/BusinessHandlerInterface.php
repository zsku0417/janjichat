<?php

namespace App\Services\Handlers;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;

/**
 * Interface that all business-type handlers must implement.
 * This enables the ConversationHandler to delegate business-specific
 * logic to the appropriate handler based on the merchant's business type.
 */
interface BusinessHandlerInterface
{
    /**
     * Process an incoming message based on detected intent.
     *
     * @param Conversation $conversation
     * @param Message $message
     * @param string $content The message text
     * @param User $merchant The merchant (business owner)
     * @return void
     */
    public function processMessage(Conversation $conversation, Message $message, string $content, User $merchant): void;

    /**
     * Handle greeting/welcome message for this business type.
     *
     * @param Conversation $conversation
     * @param User $merchant
     * @return void
     */
    public function handleGreeting(Conversation $conversation, User $merchant): void;

    /**
     * Handle contextual responses specific to this business type.
     * Returns true if the context was handled, false otherwise.
     *
     * @param Conversation $conversation
     * @param string $content
     * @param array $context
     * @return bool
     */
    public function handleContextualResponse(Conversation $conversation, string $content, array $context): bool;
}
