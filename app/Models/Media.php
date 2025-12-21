<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Media extends Model
{
    use HasFactory;

    protected $table = 'media';

    protected $fillable = [
        'user_id',
        'disk',
        'path',
        'original_name',
        'file_type',
        'mime_type',
        'file_size',
        'cloudinary_public_id',
        'metadata',
        'mediable_id',
        'mediable_type',
    ];

    protected $casts = [
        'file_size' => 'integer',
        'metadata' => 'array',
    ];

    /**
     * Get the parent mediable model (Product, etc.).
     */
    public function mediable()
    {
        return $this->morphTo();
    }

    /**
     * Get the user who owns this media.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the full URL for this media file.
     */
    public function getUrlAttribute(): ?string
    {
        if ($this->disk === 'cloudinary') {
            // First try secure_url from metadata (set during upload)
            if (!empty($this->metadata['secure_url'])) {
                return $this->metadata['secure_url'];
            }

            // Fallback: construct URL from config
            $cloudName = config('filesystems.disks.cloudinary.cloud');
            $resourceType = $this->metadata['resource_type'] ?? 'raw';

            return "https://res.cloudinary.com/{$cloudName}/{$resourceType}/upload/{$this->cloudinary_public_id}";
        }

        // For local disk, use storage URL
        if ($this->disk === 'local') {
            return asset('storage/' . $this->path);
        }

        return $this->path;
    }

    /**
     * Get formatted file size.
     */
    public function getFormattedSizeAttribute(): string
    {
        $bytes = $this->file_size;

        if ($bytes >= 1048576) {
            return round($bytes / 1048576, 2) . ' MB';
        } elseif ($bytes >= 1024) {
            return round($bytes / 1024, 2) . ' KB';
        }

        return $bytes . ' bytes';
    }
}
