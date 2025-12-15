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
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->index(); // Merchant owner
            $table->string('whatsapp_id')->unique()->index();
            $table->string('phone_number');
            $table->string('customer_name')->nullable();
            $table->enum('mode', ['ai', 'admin'])->default('ai');
            $table->enum('status', ['active', 'closed'])->default('active');
            $table->boolean('needs_reply')->default(false);
            $table->text('escalation_reason')->nullable();
            $table->timestamp('last_message_at')->nullable();

            // Conversation context for multi-turn flows
            $table->string('context_type')->nullable();
            $table->json('context_data')->nullable();
            $table->timestamp('context_expires_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'needs_reply']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};
