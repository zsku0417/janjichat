<?php

namespace App\Http\Controllers;

use App\Models\Document;
use App\Services\DocumentService;
use App\Jobs\ProcessDocumentJob;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;

class DocumentController extends Controller
{
    protected DocumentService $documentService;

    public function __construct(DocumentService $documentService)
    {
        $this->documentService = $documentService;
    }

    /**
     * Display all documents in the knowledge base.
     */
    public function index(): Response
    {
        $documents = Document::orderBy('created_at', 'desc')
            ->get()
            ->map(function ($document) {
                return [
                    'id' => $document->id,
                    'original_name' => $document->original_name,
                    'file_type' => strtoupper($document->file_type),
                    'file_size' => $this->formatFileSize($document->file_size),
                    'status' => $document->status,
                    'chunks_count' => $document->chunks_count,
                    'error_message' => $document->error_message,
                    'created_at' => $document->created_at->format('M j, Y g:i A'),
                ];
            });

        return Inertia::render('Documents/Index', [
            'documents' => $documents,
        ]);
    }

    /**
     * Upload a new document.
     */
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:pdf,docx,doc,txt|max:51200', // 50MB max
        ]);

        $document = $this->documentService->uploadDocument($request->file('file'));

        // Dispatch async processing job
        ProcessDocumentJob::dispatch($document);

        return back()->with('success', 'Document uploaded!');
    }

    /**
     * Delete a document.
     */
    public function destroy(Document $document): RedirectResponse
    {
        $this->documentService->deleteDocument($document);

        return back()->with('success', 'Document deleted successfully!');
    }

    /**
     * Reprocess a failed document.
     */
    public function reprocess(Document $document): RedirectResponse
    {
        if ($document->status !== 'failed') {
            return back()->with('error', 'Only failed documents can be reprocessed.');
        }

        $document->update([
            'status' => 'pending',
            'error_message' => null,
        ]);

        ProcessDocumentJob::dispatch($document);

        return back()->with('success', 'Document queued for reprocessing!');
    }

    /**
     * Get document content for viewing.
     */
    public function show(Document $document)
    {
        $chunks = $document->chunks()
            ->orderBy('chunk_index')
            ->get()
            ->map(function ($chunk) {
                return [
                    'id' => $chunk->id,
                    'index' => $chunk->chunk_index,
                    'content' => $chunk->content,
                ];
            });

        return response()->json([
            'id' => $document->id,
            'original_name' => $document->original_name,
            'file_type' => $document->file_type,
            'status' => $document->status,
            'chunks' => $chunks,
            'chunks_count' => $chunks->count(),
        ]);
    }

    /**
     * Format file size for display.
     */
    protected function formatFileSize(int $bytes): string
    {
        if ($bytes >= 1048576) {
            return round($bytes / 1048576, 2) . ' MB';
        } elseif ($bytes >= 1024) {
            return round($bytes / 1024, 2) . ' KB';
        }
        return $bytes . ' bytes';
    }
}
