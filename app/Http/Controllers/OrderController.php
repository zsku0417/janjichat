<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
            'cancelled' => auth()->user()->orders()->where('status', 'cancelled')->count(),
            'total' => auth()->user()->orders()->count(),
        ];

        // Get products for order creation
        $products = auth()->user()->products()->active()->get(['id', 'name', 'price']);

        return Inertia::render('OrderTracking/Orders/Index', [
            'orders' => $orders,
            'filter' => $filter,
            'stats' => $stats,
            'products' => $products,
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
     * Store a new order.
     */
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'customer_name' => 'required|string|max:255',
            'customer_phone' => 'required|string|max:50',
            'fulfillment_type' => 'required|in:pickup,delivery',
            'delivery_address' => 'nullable|required_if:fulfillment_type,delivery|string|max:500',
            'requested_datetime' => 'required|date',
            'notes' => 'nullable|string|max:1000',
            'status' => 'required|in:pending_payment,processing,completed,cancelled',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'nullable|exists:products,id',
            'items.*.product_name' => 'required|string|max:255',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.unit_price' => 'required|numeric|min:0',
        ]);

        $merchant = auth()->user();

        return DB::transaction(function () use ($validated, $merchant) {
            // Generate order code
            $orderPrefix = $merchant->orderTrackingSetting?->order_prefix;
            $lastOrder = Order::where('user_id', $merchant->id)->orderBy('id', 'desc')->first();
            $lastNumber = 0;
            if ($lastOrder && $lastOrder->code) {
                $numericPart = preg_replace('/^[A-Za-z]+-/', '', $lastOrder->code);
                $lastNumber = (int) $numericPart;
            }
            $nextNumber = $lastNumber + 1;
            $numberPart = str_pad($nextNumber, 4, '0', STR_PAD_LEFT);
            $orderCode = $orderPrefix ? "{$orderPrefix}-{$numberPart}" : $numberPart;

            // Create order
            $order = Order::create([
                'user_id' => $merchant->id,
                'code' => $orderCode,
                'customer_name' => $validated['customer_name'],
                'customer_phone' => $validated['customer_phone'],
                'fulfillment_type' => $validated['fulfillment_type'],
                'delivery_address' => $validated['delivery_address'] ?? null,
                'requested_datetime' => $validated['requested_datetime'],
                'notes' => $validated['notes'] ?? null,
                'status' => $validated['status'],
                'total_amount' => 0,
            ]);

            // Create order items
            $totalAmount = 0;
            foreach ($validated['items'] as $item) {
                $subtotal = $item['quantity'] * $item['unit_price'];
                $totalAmount += $subtotal;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product_id'] ?? null,
                    'product_name' => $item['product_name'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['unit_price'],
                    'subtotal' => $subtotal,
                ]);
            }

            // Update total
            $order->update(['total_amount' => $totalAmount]);

            return redirect()->route('orders.index')
                ->with('success', "Order #{$orderCode} created successfully.");
        });
    }

    /**
     * Update an existing order.
     */
    public function update(Request $request, Order $order): RedirectResponse
    {
        $this->authorize('update', $order);

        $validated = $request->validate([
            'customer_name' => 'required|string|max:255',
            'customer_phone' => 'required|string|max:50',
            'fulfillment_type' => 'required|in:pickup,delivery',
            'delivery_address' => 'nullable|required_if:fulfillment_type,delivery|string|max:500',
            'requested_datetime' => 'required|date',
            'notes' => 'nullable|string|max:1000',
            'status' => 'required|in:pending_payment,processing,completed,cancelled',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'nullable|exists:products,id',
            'items.*.product_name' => 'required|string|max:255',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.unit_price' => 'required|numeric|min:0',
        ]);

        return DB::transaction(function () use ($validated, $order) {
            // Update order details
            $order->update([
                'customer_name' => $validated['customer_name'],
                'customer_phone' => $validated['customer_phone'],
                'fulfillment_type' => $validated['fulfillment_type'],
                'delivery_address' => $validated['delivery_address'] ?? null,
                'requested_datetime' => $validated['requested_datetime'],
                'notes' => $validated['notes'] ?? null,
                'status' => $validated['status'],
            ]);

            // Delete existing items and recreate
            $order->items()->delete();

            $totalAmount = 0;
            foreach ($validated['items'] as $item) {
                $subtotal = $item['quantity'] * $item['unit_price'];
                $totalAmount += $subtotal;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product_id'] ?? null,
                    'product_name' => $item['product_name'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['unit_price'],
                    'subtotal' => $subtotal,
                ]);
            }

            // Update total
            $order->update(['total_amount' => $totalAmount]);

            return redirect()->route('orders.index')
                ->with('success', "Order #{$order->code} updated successfully.");
        });
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
