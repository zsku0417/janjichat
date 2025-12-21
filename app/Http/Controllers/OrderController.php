<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class OrderController extends Controller
{
    /**
     * Display a listing of orders.
     */
    public function index(Request $request): Response
    {
        $filter = $request->get('filter', 'all');

        $query = auth()->user()->orders()
            ->with('items');

        // Status filter
        if ($filter !== 'all') {
            $query->where('status', $filter);
        }

        // Search filter
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('customer_name', 'like', "%{$search}%")
                    ->orWhere('customer_phone', 'like', "%{$search}%")
                    ->orWhere('code', 'like', "%{$search}%");
            });
        }

        // Date range filter (on requested_datetime)
        if ($dateFrom = $request->input('date_from')) {
            $query->whereDate('requested_datetime', '>=', $dateFrom);
        }
        if ($dateTo = $request->input('date_to')) {
            $query->whereDate('requested_datetime', '<=', $dateTo);
        }

        // Sorting
        $sortKey = $request->input('sort_key', 'created_at');
        $sortOrder = $request->input('sort_order', 'desc');

        $allowedSortKeys = ['customer_name', 'fulfillment_type', 'requested_datetime', 'total_amount', 'status', 'created_at'];
        if (in_array($sortKey, $allowedSortKeys)) {
            $query->orderBy($sortKey, $sortOrder === 'asc' ? 'asc' : 'desc');
        } else {
            $query->orderBy('created_at', 'desc');
        }

        $orders = $query->paginate(15)->withQueryString();

        $stats = [
            'pending' => auth()->user()->orders()->where('status', 'pending_payment')->count(),
            'processing' => auth()->user()->orders()->where('status', 'processing')->count(),
            'completed' => auth()->user()->orders()->where('status', 'completed')->count(),
            'total' => auth()->user()->orders()->count(),
        ];

        return Inertia::render('OrderTracking/Orders/Index', [
            'orders' => $orders,
            'filter' => $filter,
            'stats' => $stats,
            'filters' => [
                'search' => $request->input('search', ''),
                'sort_key' => $request->input('sort_key'),
                'sort_order' => $request->input('sort_order'),
                'date_from' => $request->input('date_from'),
                'date_to' => $request->input('date_to'),
            ],
        ]);
    }

    /**
     * Display the specified order.
     */
    public function show(Order $order): Response
    {
        $this->authorize('view', $order);

        $order->load('items', 'conversation');

        return Inertia::render('OrderTracking/Orders/Show', [
            'order' => $order,
            'statuses' => Order::getStatuses(),
        ]);
    }

    /**
     * Update the order status.
     */
    public function updateStatus(Request $request, Order $order): RedirectResponse
    {
        $this->authorize('update', $order);

        $validated = $request->validate([
            'status' => 'required|in:pending_payment,processing,completed,cancelled',
        ]);

        $order->update(['status' => $validated['status']]);

        return redirect()->back()
            ->with('success', 'Order status updated to: ' . $order->status_label);
    }

    /**
     * Cancel an order.
     */
    public function cancel(Order $order): RedirectResponse
    {
        $this->authorize('update', $order);

        if ($order->status === Order::STATUS_COMPLETED) {
            return redirect()->back()
                ->with('error', 'Cannot cancel a completed order.');
        }

        $order->update(['status' => Order::STATUS_CANCELLED]);

        return redirect()->back()
            ->with('success', 'Order has been cancelled.');
    }

    /**
     * Delete an order.
     */
    public function destroy(Order $order): RedirectResponse
    {
        $this->authorize('delete', $order);

        // Delete order items first (cascade)
        $order->items()->delete();
        $order->delete();

        return redirect()->route('orders.index')
            ->with('success', 'Order has been deleted.');
    }
}
