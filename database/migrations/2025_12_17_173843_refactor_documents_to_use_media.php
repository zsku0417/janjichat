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
        Schema::table('documents', function (Blueprint $table) {
            // Add media_id foreign key
            $table->foreignId('media_id')->nullable()->after('user_id')->constrained('media')->onDelete('set null');

            // Drop file-related columns (now stored in media table)
            $table->dropColumn([
                'filename',
                'file_path',
                'cloudinary_public_id',
                'file_url',
                'file_type',
                'file_size',
            ]);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('documents', function (Blueprint $table) {
            // Re-add file-related columns
            $table->string('filename')->after('user_id');
            $table->string('file_path')->after('original_name');
            $table->string('cloudinary_public_id')->nullable()->after('file_path');
            $table->string('file_url')->nullable()->after('cloudinary_public_id');
            $table->string('file_type')->after('file_url');
            $table->unsignedInteger('file_size')->after('file_type');

            // Drop media_id
            $table->dropForeign(['media_id']);
            $table->dropColumn('media_id');
        });
    }
};
