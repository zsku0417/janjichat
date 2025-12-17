<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Check if column already exists (in case of partial migration)
        if (!Schema::hasColumn('conversations', 'user_id')) {
            Schema::table('conversations', function (Blueprint $table) {
                $table->unsignedBigInteger('user_id')->nullable()->after('id');
                $table->index('user_id');
            });
        }

        // Get the first merchant to assign to existing conversations
        $firstMerchant = DB::table('users')->where('role', 'merchant')->first();

        if ($firstMerchant) {
            // Update existing conversations with the first merchant's ID
            DB::table('conversations')
                ->whereNull('user_id')
                ->update(['user_id' => $firstMerchant->id]);
        }

        // Try to add foreign key - wrap in try/catch in case it already exists
        try {
            Schema::table('conversations', function (Blueprint $table) {
                $table->foreign('user_id')
                    ->references('id')
                    ->on('users')
                    ->onDelete('cascade');
            });
        } catch (\Exception $e) {
            // Foreign key might already exist, ignore
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('conversations', 'user_id')) {
            Schema::table('conversations', function (Blueprint $table) {
                try {
                    $table->dropForeign(['user_id']);
                } catch (\Exception $e) {
                    // Ignore if foreign key doesn't exist
                }
                $table->dropColumn('user_id');
            });
        }
    }
};
