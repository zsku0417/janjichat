<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Booking;
use App\Models\Conversation;
use App\Models\Document;
use App\Models\DocumentChunk;
use App\Models\Message;
use App\Models\Order;
use App\Models\OrderItem;
use App\Mail\MerchantWelcomeMail;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class AdminMerchantController extends Controller
{
    /**
     * Display list of all merchants with pagination, search, and sorting.
     */
    public function index(Request $request): Response
    {
        $query = User::where('role', User::ROLE_MERCHANT);

        // Search
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        // Filter by status
        if ($status = $request->input('status')) {
            if ($status === 'active') {
                $query->where('is_active', true);
            } elseif ($status === 'inactive') {
                $query->where('is_active', false);
            } elseif ($status === 'verified') {
                $query->whereNotNull('email_verified_at');
            } elseif ($status === 'pending') {
                $query->whereNull('email_verified_at');
            }
        }

        // Sorting - default to updated_at desc (most recently updated first)
        $sortKey = $request->input('sort_key', 'updated_at');
        $sortOrder = $request->input('sort_order', 'desc');

        $allowedSortKeys = ['name', 'email', 'business_type', 'created_at', 'updated_at', 'is_active'];
        if (in_array($sortKey, $allowedSortKeys)) {
            $query->orderBy($sortKey, $sortOrder === 'asc' ? 'asc' : 'desc');
        }

        // Paginate
        $merchants = $query->paginate(10)->through(function ($merchant) {
            return [
                'id' => $merchant->id,
                'name' => $merchant->name,
                'email' => $merchant->email,
                'business_type' => $merchant->business_type,
                'business_type_label' => User::getBusinessTypes()[$merchant->business_type] ?? 'Unknown',
                'has_whatsapp' => $merchant->hasWhatsAppConfigured(),
                'whatsapp_phone_number_id' => $merchant->whatsapp_phone_number_id,
                'whatsapp_phone_number' => $merchant->whatsapp_phone_number,
                'email_verified' => !is_null($merchant->email_verified_at),
                'is_active' => $merchant->is_active ?? true,
                'created_at' => $merchant->created_at->format('M j, Y'),
                // Additional data for ViewModal
                'documents_count' => $merchant->documents()->count(),
                'chunks_count' => \App\Models\DocumentChunk::whereIn('document_id', $merchant->documents()->pluck('id'))->count(),
                'conversations_count' => $merchant->conversations()->count(),
                'messages_count' => \App\Models\Message::whereIn('conversation_id', $merchant->conversations()->pluck('id'))->count(),
                'documents' => $merchant->documents()->get()->map(function ($doc) {
                    return [
                        'id' => $doc->id,
                        'filename' => $doc->filename,
                        'status' => $doc->status,
                        'chunks_count' => $doc->chunks()->count(),
                    ];
                }),
            ];
        });

        return Inertia::render('Admin/Merchants/Index', [
            'merchants' => $merchants,
            'businessTypes' => User::getBusinessTypes(),
            'filters' => [
                'search' => $request->input('search', ''),
                'status' => $request->input('status', 'all'),
                'sort_key' => $sortKey,
                'sort_order' => $sortOrder,
            ],
        ]);
    }


    /**
     * Store a new merchant.
     */
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'business_type' => ['required', Rule::in(array_keys(User::getBusinessTypes()))],
            'whatsapp_phone_number_id' => 'required|string',
            'whatsapp_phone_number' => 'required|string|max:20',
            'whatsapp_access_token' => 'required|string',
        ]);

        // Store plain password for email before hashing
        $plainPassword = $validated['password'];

        $merchant = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => User::ROLE_MERCHANT,
            'business_type' => $validated['business_type'],
            'whatsapp_phone_number_id' => $validated['whatsapp_phone_number_id'],
            'whatsapp_phone_number' => $validated['whatsapp_phone_number'],
            'whatsapp_access_token' => $validated['whatsapp_access_token'],
            'email_verified_at' => null,
            'is_active' => true,
        ]);

        // Send welcome email with credentials and verification link
        Mail::to($merchant->email)->send(new MerchantWelcomeMail($merchant, $plainPassword));

        Log::info('Merchant created and welcome email sent', ['merchant_id' => $merchant->id]);

        return back()->with('success', 'Merchant created successfully. A welcome email has been sent.');
    }

    /**
     * Update a merchant.
     * Note: business_type cannot be changed - must delete and recreate merchant.
     */
    public function update(Request $request, User $merchant): RedirectResponse
    {
        if (!$merchant->isMerchant()) {
            abort(404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => ['required', 'email', Rule::unique('users')->ignore($merchant->id)],
            'password' => 'nullable|string|min:8',
            'whatsapp_phone_number_id' => 'required|string',
            'whatsapp_phone_number' => 'required|string|max:20',
            'whatsapp_access_token' => 'nullable|string',
        ]);

        // Update basic info (business_type is NOT editable)
        $merchant->name = $validated['name'];
        $merchant->email = $validated['email'];
        $merchant->whatsapp_phone_number_id = $validated['whatsapp_phone_number_id'];
        $merchant->whatsapp_phone_number = $validated['whatsapp_phone_number'];

        if (!empty($validated['password'])) {
            $merchant->password = Hash::make($validated['password']);
        }

        if (!empty($validated['whatsapp_access_token'])) {
            $merchant->whatsapp_access_token = $validated['whatsapp_access_token'];
        }

        $merchant->save();

        return back()->with('success', 'Merchant updated successfully.');
    }

    /**
     * Toggle merchant active status.
     */
    public function toggleActive(User $merchant): RedirectResponse
    {
        if (!$merchant->isMerchant()) {
            abort(404);
        }

        $merchant->is_active = !$merchant->is_active;
        $merchant->save();

        $status = $merchant->is_active ? 'activated' : 'deactivated';
        Log::info("Merchant {$status}", ['merchant_id' => $merchant->id]);

        return back()->with('success', "Merchant {$status} successfully.");
    }

    /**
     * Resend welcome email to merchant.
     */
    public function resendWelcomeEmail(Request $request, User $merchant): RedirectResponse
    {
        if (!$merchant->isMerchant()) {
            abort(404);
        }

        // Generate a new random password
        $plainPassword = \Illuminate\Support\Str::random(12);
        $merchant->password = Hash::make($plainPassword);
        $merchant->email_verified_at = null;
        $merchant->save();

        // Send welcome email
        Mail::to($merchant->email)->send(new MerchantWelcomeMail($merchant, $plainPassword));

        Log::info('Welcome email resent to merchant', ['merchant_id' => $merchant->id]);

        return back()->with('success', 'Welcome email resent with new password.');
    }

    /**
     * Delete a merchant.
     */
    public function destroy(User $merchant): RedirectResponse
    {
        if (!$merchant->isMerchant()) {
            abort(404);
        }

        // Clear all data before deleting
        $this->clearMerchantData($merchant);

        $merchant->delete();

        Log::info('Merchant deleted', ['merchant_id' => $merchant->id]);

        return back()->with('success', 'Merchant deleted successfully.');
    }

    /**
     * Clear all data associated with a merchant.
     */
    protected function clearMerchantData(User $merchant): void
    {
        // Get conversation IDs for this merchant
        $conversationIds = Conversation::where('user_id', $merchant->id)->pluck('id');

        // Delete messages
        Message::whereIn('conversation_id', $conversationIds)->delete();

        // Delete bookings (for restaurant)
        Booking::whereIn('conversation_id', $conversationIds)->delete();
        Booking::where('user_id', $merchant->id)->delete();

        // Delete orders and items (for order tracking)
        $orderIds = Order::where('user_id', $merchant->id)->pluck('id');
        OrderItem::whereIn('order_id', $orderIds)->delete();
        Order::where('user_id', $merchant->id)->delete();

        // Delete conversations
        Conversation::where('user_id', $merchant->id)->delete();

        // Delete documents and chunks
        $documentIds = Document::where('user_id', $merchant->id)->pluck('id');
        DocumentChunk::whereIn('document_id', $documentIds)->delete();
        Document::where('user_id', $merchant->id)->delete();

        // Delete tables (for restaurant)
        \App\Models\Table::where('user_id', $merchant->id)->delete();

        // Delete products (for order tracking)
        \App\Models\Product::where('user_id', $merchant->id)->delete();

        // Delete settings
        \App\Models\MerchantSetting::where('user_id', $merchant->id)->delete();
        \App\Models\RestaurantSetting::where('user_id', $merchant->id)->delete();
        \App\Models\OrderTrackingSetting::where('user_id', $merchant->id)->delete();

        Log::info('Merchant data cleared', [
            'merchant_id' => $merchant->id,
            'conversations_deleted' => $conversationIds->count(),
            'documents_deleted' => $documentIds->count(),
            'orders_deleted' => $orderIds->count(),
        ]);
    }
}
