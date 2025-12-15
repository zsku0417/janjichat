<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentChunk extends Model
{
    use HasFactory;

    protected $fillable = [
        'document_id',
        'content',
        'embedding',
        'chunk_index',
        'tokens_count',
    ];

    protected $casts = [
        'chunk_index' => 'integer',
        'tokens_count' => 'integer',
    ];

    /**
     * Get the document that owns this chunk.
     */
    public function document(): BelongsTo
    {
        return $this->belongsTo(Document::class);
    }

    /**
     * Set the embedding as a PostgreSQL vector.
     */
    public function setEmbeddingAttribute($value): void
    {
        if (is_array($value)) {
            $this->attributes['embedding'] = '[' . implode(',', $value) . ']';
        } else {
            $this->attributes['embedding'] = $value;
        }
    }

    /**
     * Get the embedding as an array.
     */
    public function getEmbeddingAttribute($value): ?array
    {
        if ($value === null) {
            return null;
        }

        // Parse PostgreSQL vector format [1,2,3]
        $value = trim($value, '[]');
        return array_map('floatval', explode(',', $value));
    }
}
