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
        Schema::table('merchant_settings', function (Blueprint $table) {
            $table->boolean('email_on_escalation')->default(true)->after('reminder_hours_before');
            $table->string('notification_email')->nullable()->after('email_on_escalation');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('merchant_settings', function (Blueprint $table) {
            $table->dropColumn(['email_on_escalation', 'notification_email']);
        });
    }
};
