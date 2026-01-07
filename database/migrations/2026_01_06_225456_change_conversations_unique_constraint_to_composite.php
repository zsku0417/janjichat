<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     * 
     * Changes the unique constraint from whatsapp_id alone to a composite
     * unique constraint on (whatsapp_id, user_id) to support multi-tenant
     * conversations where the same customer can have separate conversations
     * with different merchants.
     */
    public function up(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            // Drop the existing unique constraint on whatsapp_id
            $table->dropUnique('conversations_whatsapp_id_unique');

            // Add composite unique constraint on whatsapp_id + user_id
            // This allows the same customer to have conversations with different merchants
            $table->unique(['whatsapp_id', 'user_id'], 'conversations_whatsapp_id_user_id_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            // Drop the composite unique constraint
            $table->dropUnique('conversations_whatsapp_id_user_id_unique');

            // Restore the original unique constraint on whatsapp_id
            $table->unique('whatsapp_id', 'conversations_whatsapp_id_unique');
        });
    }
};
