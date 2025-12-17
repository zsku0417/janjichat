<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Document extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'media_id',
        'original_name',
        'status',
        'chunks_count',
        'error_message',
    ];

    protected $casts = [
        'chunks_count' => 'integer',
    ];

    /**
     * Get the user/merchant who owns this document.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the media file for this document.
     */
    public function media(): BelongsTo
    {
        return $this->belongsTo(Media::class);
    }

    /**
     * Get the chunks for this document.
     */
    public function chunks(): HasMany
    {
        return $this->hasMany(DocumentChunk::class);
    }

    /**
     * Check if document processing is complete.
     */
    public function isProcessed(): bool
    {
        return $this->status === 'completed';
    }

    /**
     * Check if document processing failed.
     */
    public function hasFailed(): bool
    {
        return $this->status === 'failed';
    }

    /**
     * Get file URL from media.
     */
    public function getFileUrlAttribute(): ?string
    {
        return $this->media?->url;
    }

    /**
     * Get file type from media.
     */
    public function getFileTypeAttribute(): ?string
    {
        return $this->media?->file_type;
    }

    /**
     * Get file size from media.
     */
    public function getFileSizeAttribute(): ?int
    {
        return $this->media?->file_size;
    }

    /**
     * Get formatted file size from media.
     */
    public function getFormattedFileSizeAttribute(): ?string
    {
        return $this->media?->formatted_size;
    }
}
