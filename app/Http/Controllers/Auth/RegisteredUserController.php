<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Mail\VerificationCodeMail;
use App\Models\EmailVerification;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rules;
use Inertia\Inertia;
use Inertia\Response;

class RegisteredUserController extends Controller
{
    /**
     * Display the registration view.
     */
    public function create(): Response
    {
        return Inertia::render('Auth/Register', [
            'businessTypes' => [
                ['value' => 'restaurant', 'label' => 'Restaurant Booking'],
                ['value' => 'order_tracking', 'label' => 'Order Tracking'],
            ],
        ]);
    }

    /**
     * Handle an incoming registration request.
     * Step 1: Validate, create verification record, send email.
     */
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|lowercase|email|max:255|unique:users,email',
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
            'business_type' => 'required|string|in:restaurant,order_tracking',
        ]);

        // Check if email already exists in users table
        if (User::where('email', $request->email)->exists()) {
            return back()->withErrors(['email' => 'This email is already registered.']);
        }

        // Delete any existing verification for this email
        EmailVerification::where('email', $request->email)->delete();

        // Generate 6-digit code
        $code = EmailVerification::generateCode();

        // Create verification record
        EmailVerification::create([
            'email' => $request->email,
            'name' => $request->name,
            'password' => Hash::make($request->password),
            'business_type' => $request->business_type,
            'code' => $code,
            'expires_at' => now()->addMinutes(10),
        ]);

        // Send verification email
        Mail::to($request->email)->send(new VerificationCodeMail($code, $request->name));

        // Redirect to verification page
        return redirect()->route('verify.code.show', ['email' => $request->email]);
    }

    /**
     * Display the verification code input page.
     */
    public function showVerifyCode(Request $request): Response|RedirectResponse
    {
        $email = $request->query('email');

        if (!$email || !EmailVerification::where('email', $email)->exists()) {
            return redirect()->route('register');
        }

        return Inertia::render('Auth/VerifyCode', [
            'email' => $email,
        ]);
    }

    /**
     * Verify the code and create the user.
     */
    public function verifyCode(Request $request): RedirectResponse
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:6',
        ]);

        $verification = EmailVerification::where('email', $request->email)->first();

        if (!$verification) {
            return back()->withErrors(['code' => 'Verification session expired. Please register again.']);
        }

        if ($verification->isExpired()) {
            $verification->delete();
            return back()->withErrors(['code' => 'Verification code has expired. Please register again.']);
        }

        if (!$verification->verifyCode($request->code)) {
            return back()->withErrors(['code' => 'Invalid verification code. Please try again.']);
        }

        // Create the user
        $user = User::create([
            'name' => $verification->name,
            'email' => $verification->email,
            'password' => $verification->password, // Already hashed
            'business_type' => $verification->business_type,
            'email_verified' => true,
        ]);

        // Delete the verification record
        $verification->delete();

        event(new Registered($user));

        // Auto-login
        Auth::login($user);

        return redirect()->route('dashboard')->with('success', 'Welcome to Janji Chat! Your account has been created successfully.');
    }

    /**
     * Resend verification code.
     */
    public function resendCode(Request $request): RedirectResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $verification = EmailVerification::where('email', $request->email)->first();

        if (!$verification) {
            return redirect()->route('register');
        }

        // Generate new code
        $code = EmailVerification::generateCode();
        $verification->update([
            'code' => $code,
            'expires_at' => now()->addMinutes(10),
        ]);

        // Send new email
        Mail::to($request->email)->send(new VerificationCodeMail($code, $verification->name));

        return back()->with('success', 'A new verification code has been sent to your email.');
    }
}
