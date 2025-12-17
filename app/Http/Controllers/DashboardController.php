<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Models\Booking;
use App\Models\Document;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    /**
     * Display the admin dashboard with statistics.
     * Routes to different dashboards based on business type.
     */
    public function index(): Response
    {
        $user = auth()->user();

        // Admin dashboard
        if ($user->isAdmin()) {
            return $this->adminDashboard($user);
        }

        if ($user->isOrderTracking()) {
            return $this->orderTrackingDashboard($user);
        }

        return $this->restaurantDashboard($user);
    }

    /**
     * Admin dashboard with platform-wide statistics.
     */
    protected function adminDashboard($user): Response
    {
        $stats = [
            'total_merchants' => \App\Models\User::where('role', 'merchant')->count(),
            'active_merchants' => \App\Models\User::where('role', 'merchant')->where('is_active', true)->count(),
            'inactive_merchants' => \App\Models\User::where('role', 'merchant')->where('is_active', false)->count(),
            'pending_verification' => \App\Models\User::where('role', 'merchant')->whereNull('email_verified_at')->count(),
            'total_conversations' => Conversation::count(),
            'total_messages' => \App\Models\Message::count(),
            'conversations_today' => Conversation::whereDate('created_at', today())->count(),
            'messages_today' => \App\Models\Message::whereDate('created_at', today())->count(),
            'total_documents' => Document::count(),
            'document_chunks' => \App\Models\DocumentChunk::count(),
            'total_bookings' => Booking::count(),
            'bookings_today' => Booking::whereDate('created_at', today())->count(),
            'total_orders' => Order::count(),
        ];

        // Recent merchants
        $recentMerchants = \App\Models\User::where('role', 'merchant')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($merchant) {
                return [
                    'id' => $merchant->id,
                    'name' => $merchant->name,
                    'email' => $merchant->email,
                    'business_type' => \App\Models\User::getBusinessTypes()[$merchant->business_type] ?? 'Unknown',
                    'is_active' => $merchant->is_active ?? true,
                    'email_verified' => !is_null($merchant->email_verified_at),
                    'created_at' => $merchant->created_at->diffForHumans(),
                ];
            });

        return Inertia::render('Admin/Dashboard', [
            'stats' => $stats,
            'recentMerchants' => $recentMerchants,
        ]);
    }

    /**
     * Restaurant business dashboard.
     */
    protected function restaurantDashboard($user): Response
    {
        $stats = [
            'total_conversations' => Conversation::where('user_id', $user->id)->count(),
            'needs_reply' => Conversation::where('user_id', $user->id)->needsReply()->count(),
            'total_bookings' => Booking::where('user_id', $user->id)->count(),
            'upcoming_bookings' => Booking::where('user_id', $user->id)->upcoming()->count(),
            'todays_bookings' => Booking::where('user_id', $user->id)->today()->where('status', 'confirmed')->count(),
            'total_documents' => Document::where('user_id', $user->id)->where('status', 'completed')->count(),
            'pending_documents' => Document::where('user_id', $user->id)->whereIn('status', ['pending', 'processing'])->count(),
        ];

        $recentConversations = Conversation::where('user_id', $user->id)
            ->with([
                'messages' => function ($query) {
                    $query->latest()->limit(1);
                }
            ])
            ->orderBy('last_message_at', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($conversation) {
                return [
                    'id' => $conversation->id,
                    'customer_name' => $conversation->customer_name ?? 'Unknown',
                    'phone_number' => $conversation->phone_number,
                    'mode' => $conversation->mode,
                    'needs_reply' => $conversation->needs_reply,
                    'last_message' => $conversation->messages->first()?->content ?? '',
                    'last_message_at' => $conversation->last_message_at?->diffForHumans(),
                ];
            });

        $upcomingBookings = Booking::where('user_id', $user->id)
            ->upcoming()
            ->with('table')
            ->limit(5)
            ->get()
            ->map(function ($booking) {
                return [
                    'id' => $booking->id,
                    'customer_name' => $booking->customer_name,
                    'booking_date' => $booking->booking_date->format('M j, Y'),
                    'booking_time' => \Carbon\Carbon::parse($booking->booking_time)->format('g:i A'),
                    'pax' => $booking->pax,
                    'table_name' => $booking->table->name,
                    'status' => $booking->status,
                ];
            });

        return Inertia::render('Dashboard', [
            'stats' => $stats,
            'recentConversations' => $recentConversations,
            'upcomingBookings' => $upcomingBookings,
        ]);
    }

    /**
     * Order tracking business dashboard.
     */
    protected function orderTrackingDashboard($user): Response
    {
        $stats = [
            'total_conversations' => Conversation::where('user_id', $user->id)->count(),
            'needs_reply' => Conversation::where('user_id', $user->id)->needsReply()->count(),
            'total_products' => $user->products()->count(),
            'active_products' => $user->products()->active()->count(),
            'total_orders' => $user->orders()->count(),
            'pending_orders' => $user->orders()->where('status', 'pending_payment')->count(),
            'processing_orders' => $user->orders()->where('status', 'processing')->count(),
            'completed_today' => $user->orders()->where('status', 'completed')
                ->whereDate('updated_at', today())->count(),
            'total_documents' => Document::where('user_id', $user->id)->where('status', 'completed')->count(),
        ];

        $recentConversations = Conversation::where('user_id', $user->id)
            ->with([
                'messages' => function ($query) {
                    $query->latest()->limit(1);
                }
            ])
            ->orderBy('last_message_at', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($conversation) {
                return [
                    'id' => $conversation->id,
                    'customer_name' => $conversation->customer_name ?? 'Unknown',
                    'phone_number' => $conversation->phone_number,
                    'mode' => $conversation->mode,
                    'needs_reply' => $conversation->needs_reply,
                    'last_message' => $conversation->messages->first()?->content ?? '',
                    'last_message_at' => $conversation->last_message_at?->diffForHumans(),
                ];
            });

        $recentOrders = $user->orders()
            ->with('items')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($order) {
                return [
                    'id' => $order->id,
                    'customer_name' => $order->customer_name,
                    'customer_phone' => $order->customer_phone,
                    'fulfillment_type' => $order->fulfillment_type,
                    'requested_datetime' => $order->requested_datetime->format('M j, Y g:i A'),
                    'status' => $order->status,
                    'status_label' => $order->status_label,
                    'total_amount' => $order->formatted_total,
                    'items_count' => $order->items->count(),
                ];
            });

        return Inertia::render('OrderTracking/Dashboard', [
            'stats' => $stats,
            'recentConversations' => $recentConversations,
            'recentOrders' => $recentOrders,
        ]);
    }
}
