<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     * Changes the embedding column from JSON to proper pgvector type.
     * WARNING: This will clear all existing embeddings. You'll need to re-process documents.
     */
    public function up(): void
    {
        // First, ensure pgvector extension is enabled
        DB::statement('CREATE EXTENSION IF NOT EXISTS vector');

        // Drop the old JSON column
        Schema::table('document_chunks', function ($table) {
            $table->dropColumn('embedding');
        });

        // Add new vector column (1536 dimensions for OpenAI text-embedding-ada-002)
        DB::statement('ALTER TABLE document_chunks ADD COLUMN embedding vector(1536)');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop vector column and add back json column
        Schema::table('document_chunks', function ($table) {
            $table->dropColumn('embedding');
        });

        Schema::table('document_chunks', function ($table) {
            $table->json('embedding')->nullable();
        });
    }
};
