<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class MerchantVerificationController extends Controller
{
    /**
     * Verify the merchant's email address via signed URL.
     */
    public function verify(Request $request, int $id, string $hash): RedirectResponse
    {
        $user = User::findOrFail($id);

        // Verify the hash matches the user's email
        if (!hash_equals(sha1($user->email), $hash)) {
            abort(403, 'Invalid verification link.');
        }

        // Check if already verified
        if ($user->email_verified_at) {
            return redirect()->route('login')
                ->with('info', 'Your email is already verified. Please log in.');
        }

        // Mark as verified
        $user->email_verified_at = now();
        $user->save();

        return redirect()->route('login')
            ->with('success', 'Your email has been verified! You can now log in with your credentials.');
    }
}
