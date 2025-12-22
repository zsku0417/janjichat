<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\LandingChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LandingChatController extends Controller
{
    protected LandingChatService $chatService;

    public function __construct(LandingChatService $chatService)
    {
        $this->chatService = $chatService;
    }

    /**
     * Handle landing page chat messages.
     */
    public function chat(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'message' => 'required|string|max:1000',
            'history' => 'nullable|array|max:20',
            'history.*.role' => 'required_with:history|string|in:user,assistant',
            'history.*.content' => 'required_with:history|string',
        ]);

        $result = $this->chatService->generateResponse(
            $validated['message'],
            $validated['history'] ?? []
        );

        return response()->json([
            'success' => $result['success'],
            'response' => $result['response'],
        ]);
    }
}
