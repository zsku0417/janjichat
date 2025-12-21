<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     * 
     * This adds a morph relationship to Media for products.
     * Uses mediable_id and mediable_type for polymorphic relationship.
     */
    public function up(): void
    {
        Schema::table('media', function (Blueprint $table) {
            $table->nullableMorphs('mediable');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('media', function (Blueprint $table) {
            $table->dropMorphs('mediable');
        });
    }
};
