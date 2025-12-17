<?php

namespace App\Services;

use App\Models\Document;
use App\Models\DocumentChunk;
use Smalot\PdfParser\Parser as PdfParser;
use PhpOffice\PhpWord\IOFactory as WordIOFactory;
use Illuminate\Support\Facades\Log;
use Exception;

class DocumentService
{
    protected OpenAIService $openAI;
    protected MediaService $mediaService;
    protected int $chunkSize = 500; // tokens per chunk
    protected int $chunkOverlap = 50; // overlap between chunks

    public function __construct(OpenAIService $openAI, MediaService $mediaService)
    {
        $this->openAI = $openAI;
        $this->mediaService = $mediaService;
    }

    /**
     * Upload and store a document to Cloudinary via MediaService.
     *
     * @param \Illuminate\Http\UploadedFile $file
     * @param int $userId
     * @return Document
     */
    public function uploadDocument(\Illuminate\Http\UploadedFile $file, int $userId): Document
    {
        // Upload to Cloudinary via MediaService
        $media = $this->mediaService->uploadDocument($file, $userId);

        // Create Document record referencing the media
        $document = Document::create([
            'user_id' => $userId,
            'media_id' => $media->id,
            'original_name' => $file->getClientOriginalName(),
            'status' => 'pending',
        ]);

        return $document;
    }

    /**
     * Process a document: extract text, chunk, and generate embeddings.
     *
     * @param Document $document
     * @return void
     */
    public function processDocument(Document $document): void
    {
        try {
            $document->update(['status' => 'processing']);

            // Step 1: Extract text
            $text = $this->extractText($document);

            if (empty(trim($text))) {
                throw new Exception('No text content could be extracted from the document.');
            }

            // Step 2: Chunk the text
            $chunks = $this->chunkText($text);

            // Step 3: Generate embeddings and store chunks
            $this->storeChunksWithEmbeddings($document, $chunks);

            $document->update([
                'status' => 'completed',
                'chunks_count' => count($chunks),
            ]);

            // Clean up local file after processing (Cloudinary has the permanent copy)
            if ($document->media) {
                $this->mediaService->cleanupLocalFile($document->media);
            }

            Log::info('Document processed successfully', [
                'document_id' => $document->id,
                'chunks' => count($chunks),
            ]);

        } catch (Exception $e) {
            Log::error('Document processing failed', [
                'document_id' => $document->id,
                'error' => $e->getMessage(),
            ]);

            $document->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    /**
     * Extract text content from a document.
     *
     * @param Document $document
     * @return string
     */
    public function extractText(Document $document): string
    {
        $media = $document->media;

        if (!$media) {
            throw new Exception('Document has no associated media file.');
        }

        // Get local file path via MediaService
        $fullPath = $this->mediaService->getLocalPath($media);

        return match ($media->file_type) {
            'pdf' => $this->extractFromPdf($fullPath),
            'docx' => $this->extractFromDocx($fullPath),
            'txt', 'md' => $this->extractFromTxt($fullPath),
            default => throw new Exception("Unsupported file type: {$media->file_type}"),
        };
    }

    /**
     * Extract text from PDF file.
     */
    protected function extractFromPdf(string $path): string
    {
        $parser = new PdfParser();
        $pdf = $parser->parseFile($path);
        return $pdf->getText();
    }

    /**
     * Extract text from DOCX file.
     */
    protected function extractFromDocx(string $path): string
    {
        $phpWord = WordIOFactory::load($path);
        $text = '';

        foreach ($phpWord->getSections() as $section) {
            foreach ($section->getElements() as $element) {
                if (method_exists($element, 'getText')) {
                    $text .= $element->getText() . "\n";
                } elseif (method_exists($element, 'getElements')) {
                    foreach ($element->getElements() as $childElement) {
                        if (method_exists($childElement, 'getText')) {
                            $text .= $childElement->getText() . "\n";
                        }
                    }
                }
            }
        }

        return $text;
    }

    /**
     * Extract text from TXT file.
     */
    protected function extractFromTxt(string $path): string
    {
        return file_get_contents($path);
    }

    /**
     * Split text into chunks for embedding.
     *
     * @param string $text
     * @return array Array of chunk strings
     */
    public function chunkText(string $text): array
    {
        // Clean up the text
        $text = preg_replace('/\s+/', ' ', $text);
        $text = trim($text);

        // Split into sentences
        $sentences = preg_split('/(?<=[.!?])\s+/', $text);

        $chunks = [];
        $currentChunk = '';
        $currentTokens = 0;

        foreach ($sentences as $sentence) {
            $sentenceTokens = $this->openAI->estimateTokens($sentence);

            // If adding this sentence would exceed chunk size
            if ($currentTokens + $sentenceTokens > $this->chunkSize && !empty($currentChunk)) {
                $chunks[] = trim($currentChunk);

                // Start new chunk with overlap (last part of previous chunk)
                $words = explode(' ', $currentChunk);
                $overlapWords = array_slice($words, -20); // ~50 tokens overlap
                $currentChunk = implode(' ', $overlapWords) . ' ' . $sentence;
                $currentTokens = $this->openAI->estimateTokens($currentChunk);
            } else {
                $currentChunk .= ' ' . $sentence;
                $currentTokens += $sentenceTokens;
            }
        }

        // Don't forget the last chunk
        if (!empty(trim($currentChunk))) {
            $chunks[] = trim($currentChunk);
        }

        return $chunks;
    }

    /**
     * Store chunks with their embeddings.
     */
    protected function storeChunksWithEmbeddings(Document $document, array $chunks): void
    {
        foreach ($chunks as $index => $chunkText) {
            // Generate embedding
            $embedding = $this->openAI->createEmbedding($chunkText);

            // Create chunk record
            DocumentChunk::create([
                'document_id' => $document->id,
                'content' => $chunkText,
                'embedding' => $embedding,
                'chunk_index' => $index,
                'tokens_count' => $this->openAI->estimateTokens($chunkText),
            ]);
        }
    }

    /**
     * Delete a document and its media.
     *
     * @param Document $document
     * @return void
     */
    public function deleteDocument(Document $document): void
    {
        $media = $document->media;

        // Delete the document (chunks will be deleted via cascade)
        $document->delete();

        // Delete the media record and Cloudinary file via MediaService
        if ($media) {
            $this->mediaService->delete($media);
        }
    }
}
