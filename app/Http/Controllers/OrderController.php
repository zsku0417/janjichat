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
            ->with('items')
            ->orderBy('created_at', 'desc');

        if ($filter !== 'all') {
            $query->where('status', $filter);
        }

        $orders = $query->paginate(15);

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
}
