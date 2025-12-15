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
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Merchant
            $table->foreignId('conversation_id')->nullable()->constrained()->onDelete('set null');
            $table->string('code'); // Order code (e.g., "001") - combined with prefix for display
            $table->string('customer_name');
            $table->string('customer_phone');
            $table->enum('fulfillment_type', ['pickup', 'delivery'])->default('pickup');
            $table->text('delivery_address')->nullable();
            $table->timestamp('requested_datetime')->nullable();
            $table->decimal('total_amount', 10, 2)->default(0);
            $table->enum('status', ['pending_payment', 'processing', 'completed', 'cancelled'])->default('pending_payment');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'created_at']);
            $table->unique(['user_id', 'code']); // Code unique per merchant
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
