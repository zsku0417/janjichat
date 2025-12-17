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
        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('disk')->default('cloudinary'); // cloudinary, local, s3, etc.
            $table->string('path'); // Relative path: documents/2/files/filename.pdf
            $table->string('original_name');
            $table->string('file_type'); // pdf, docx, txt, md, jpg, png, etc.
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('file_size'); // bytes
            $table->string('cloudinary_public_id')->nullable();
            $table->json('metadata')->nullable(); // Additional metadata like dimensions, duration, etc.
            $table->timestamps();

            $table->index('user_id');
            $table->index('disk');
            $table->index('file_type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('media');
    }
};
