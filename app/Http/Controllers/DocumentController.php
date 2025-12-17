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
        $user = auth()->user();
        $documents = Document::where('user_id', $user->id)
            ->with('media')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($document) {
                return [
                    'id' => $document->id,
                    'original_name' => $document->original_name,
                    'file_type' => strtoupper($document->file_type ?? 'N/A'),
                    'file_size' => $document->formatted_file_size ?? 'N/A',
                    'file_url' => $document->file_url,
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
            'file' => 'required|file|mimes:pdf,docx,doc,txt,md|max:51200', // 50MB max
        ]);

        $document = $this->documentService->uploadDocument($request->file('file'), auth()->id());

        // Dispatch async processing job
        ProcessDocumentJob::dispatch($document);

        return back()->with('success', 'Document uploaded!');
    }

    /**
     * Delete a document.
     */
    public function destroy(Document $document): RedirectResponse
    {
        // Ensure user owns this document
        if ($document->user_id !== auth()->id()) {
            abort(403, 'Unauthorized');
        }

        $this->documentService->deleteDocument($document);

        return back()->with('success', 'Document deleted successfully!');
    }

    /**
     * Reprocess a failed document.
     */
    public function reprocess(Document $document): RedirectResponse
    {
        // Ensure user owns this document
        if ($document->user_id !== auth()->id()) {
            abort(403, 'Unauthorized');
        }

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
        // Ensure user owns this document
        if ($document->user_id !== auth()->id()) {
            abort(403, 'Unauthorized');
        }

        // Load media relationship
        $document->load('media');

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
            'file_size' => $document->formatted_file_size,
            'file_url' => $document->file_url,
            'status' => $document->status,
            'chunks' => $chunks,
            'chunks_count' => $chunks->count(),
        ]);
    }
}
