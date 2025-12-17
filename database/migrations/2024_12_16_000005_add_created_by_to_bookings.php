<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     * Adds created_by and reminder_sent columns to bookings table.
     */
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            // Who created the booking: 'customer' or 'merchant'
            $table->string('created_by')->default('customer')->after('status');
            // Whether reminder was sent
            $table->boolean('reminder_sent')->default(false)->after('created_by');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(['created_by', 'reminder_sent']);
        });
    }
};
