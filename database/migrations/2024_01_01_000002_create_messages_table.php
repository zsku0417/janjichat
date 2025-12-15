<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->onDelete('cascade');
            $table->enum('direction', ['inbound', 'outbound']);
            $table->enum('sender_type', ['customer', 'ai', 'admin']);
            $table->enum('message_type', ['text', 'image', 'audio', 'video', 'document', 'location', 'contact', 'sticker', 'interactive']);
            $table->text('content')->nullable();
            $table->string('whatsapp_message_id')->nullable()->index();
            $table->string('status')->default('pending'); // pending, sent, delivered, read, failed
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['conversation_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
