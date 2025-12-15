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
        Schema::create('merchant_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('business_name');
            $table->text('greeting_message')->nullable();
            $table->text('ai_tone')->nullable();
            $table->text('booking_form_template')->nullable();
            $table->text('confirmation_template')->nullable();
            $table->text('reminder_template')->nullable();
            $table->unsignedInteger('reminder_hours_before')->default(24);
            $table->timestamps();

            $table->unique('user_id'); // One settings per merchant
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('merchant_settings');
    }
};
