<?php

return [
    /*
    |--------------------------------------------------------------------------
    | OpenAI API Key
    |--------------------------------------------------------------------------
    |
    | Your OpenAI API key for accessing GPT and embedding models.
    |
    */
    'api_key' => env('OPENAI_API_KEY'),

    /*
    |--------------------------------------------------------------------------
    | Embedding Model
    |--------------------------------------------------------------------------
    |
    | The model used for generating text embeddings.
    | text-embedding-3-small produces 1536-dimensional vectors.
    |
    */
    'embedding_model' => env('OPENAI_EMBEDDING_MODEL', 'text-embedding-3-small'),

    /*
    |--------------------------------------------------------------------------
    | Chat Model
    |--------------------------------------------------------------------------
    |
    | The model used for generating chat responses.
    |
    */
    'chat_model' => env('OPENAI_CHAT_MODEL', 'gpt-4o-mini'),

    /*
    |--------------------------------------------------------------------------
    | Confidence Threshold
    |--------------------------------------------------------------------------
    |
    | The minimum similarity score (0-1) required for the AI to consider
    | a knowledge base match as relevant. Lower values = more lenient.
    |
    */
    'confidence_threshold' => env('AI_CONFIDENCE_THRESHOLD', 0.2),

    /*
    |--------------------------------------------------------------------------
    | Embedding Dimensions
    |--------------------------------------------------------------------------
    |
    | The number of dimensions in the embedding vectors.
    | text-embedding-3-small uses 1536 dimensions.
    |
    */
    'embedding_dimensions' => 1536,

    /*
    |--------------------------------------------------------------------------
    | Max Tokens
    |--------------------------------------------------------------------------
    |
    | Maximum tokens for chat completion responses.
    |
    */
    'max_tokens' => env('OPENAI_MAX_TOKENS', 1000),
];
