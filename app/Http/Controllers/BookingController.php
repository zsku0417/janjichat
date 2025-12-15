<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Table;
use App\Models\RestaurantSetting;
use App\Services\BookingService;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;
use Carbon\Carbon;

class BookingController extends Controller
{
    protected BookingService $bookingService;

    public function __construct(BookingService $bookingService)
    {
        $this->bookingService = $bookingService;
    }

    /**
     * Display all bookings.
     */
    public function index(Request $request): Response
    {
        $query = Booking::with('table');

        // Search functionality (case-insensitive)
        if ($request->has('search') && $request->search) {
            $search = strtolower($request->search);
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(customer_name) LIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(customer_phone) LIKE ?', ["%{$search}%"])
                    ->orWhereHas('table', function ($tableQuery) use ($search) {
                        $tableQuery->whereRaw('LOWER(name) LIKE ?', ["%{$search}%"]);
                    });
            });
        }

        // Filter by date
        if ($request->has('date') && $request->date) {
            $query->whereDate('booking_date', $request->date);
        }

        // Filter by status
        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        // Sorting
        $sortKey = $request->get('sort_key', 'booking_date');
        $sortOrder = $request->get('sort_order', 'desc');

        // Map frontend keys to database columns
        $sortableColumns = [
            'customer_name' => 'customer_name',
            'booking_date_formatted' => 'booking_date',
            'booking_date' => 'booking_date',
            'table_name' => 'table_id', // Will need special handling
            'pax' => 'pax',
            'status' => 'status',
            'created_by' => 'created_by',
        ];

        if (array_key_exists($sortKey, $sortableColumns)) {
            if ($sortKey === 'table_name') {
                // Sort by table name requires join
                $query->join('tables', 'bookings.table_id', '=', 'tables.id')
                    ->orderBy('tables.name', $sortOrder)
                    ->select('bookings.*');
            } else {
                $query->orderBy($sortableColumns[$sortKey], $sortOrder);
            }
        } else {
            $query->orderBy('booking_date', 'desc');
        }

        // Secondary sort by time if sorting by date
        if ($sortKey === 'booking_date' || $sortKey === 'booking_date_formatted') {
            $query->orderBy('booking_time', 'asc');
        }

        $bookings = $query->paginate(20)
            ->through(function ($booking) {
                return [
                    'id' => $booking->id,
                    'customer_name' => $booking->customer_name,
                    'customer_phone' => $booking->customer_phone,
                    'booking_date' => $booking->booking_date->format('Y-m-d'),
                    'booking_date_formatted' => $booking->booking_date->format('M j, Y'),
                    'booking_time' => Carbon::parse($booking->booking_time)->format('g:i A'),
                    'pax' => $booking->pax,
                    'table_name' => $booking->table->name,
                    'special_request' => $booking->special_request,
                    'status' => $booking->status,
                    'created_by' => $booking->created_by,
                ];
            });

        $tables = Table::active()->get(['id', 'name', 'capacity']);
        $settings = RestaurantSetting::getInstance();

        return Inertia::render('Bookings/Index', [
            'bookings' => $bookings,
            'tables' => $tables,
            'filters' => [
                'date' => $request->date,
                'status' => $request->status ?? 'all',
                'search' => $request->search ?? '',
                'sort_key' => $sortKey,
                'sort_order' => $sortOrder,
            ],
            'restaurantSettings' => [
                'opening_time' => $settings->opening_time,
                'closing_time' => $settings->closing_time,
            ],
        ]);
    }

    /**
     * Store a new booking (admin-created).
     */
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'customer_name' => 'required|string|max:255',
            'customer_phone' => 'required|string|max:20',
            'booking_date' => 'required|date|after_or_equal:today',
            'booking_time' => 'required',
            'pax' => 'required|integer|min:1|max:50',
            'special_request' => 'nullable|string|max:1000',
        ]);

        try {
            $this->bookingService->createBooking([
                'customer_name' => $request->customer_name,
                'customer_phone' => $request->customer_phone,
                'booking_date' => $request->booking_date,
                'booking_time' => $request->booking_time,
                'pax' => $request->pax,
                'special_request' => $request->special_request,
                'created_by' => 'admin',
            ]);

            return back()->with('success', 'Booking created successfully!');
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    /**
     * Update a booking.
     */
    public function update(Request $request, Booking $booking): RedirectResponse
    {
        $request->validate([
            'booking_date' => 'nullable|date',
            'booking_time' => 'nullable',
            'pax' => 'nullable|integer|min:1|max:50',
            'special_request' => 'nullable|string|max:1000',
            'status' => 'nullable|in:confirmed,cancelled,completed,no_show',
        ]);

        try {
            $data = array_filter($request->only([
                'booking_date',
                'booking_time',
                'pax',
                'special_request',
                'status'
            ]));

            $this->bookingService->modifyBooking($booking, $data);

            return back()->with('success', 'Booking updated successfully!');
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    /**
     * Cancel a booking.
     */
    public function cancel(Booking $booking): RedirectResponse
    {
        $this->bookingService->cancelBooking($booking);

        return back()->with('success', 'Booking cancelled successfully!');
    }

    /**
     * Permanently delete a booking.
     */
    public function destroy(Booking $booking): RedirectResponse
    {
        $customerName = $booking->customer_name;
        $booking->delete();

        return back()->with('success', "Booking for {$customerName} has been permanently deleted.");
    }

    /**
     * Get calendar data for a month.
     */
    public function calendar(Request $request): Response
    {
        $month = $request->get('month', now()->format('Y-m'));
        $startOfMonth = Carbon::parse($month)->startOfMonth();
        $endOfMonth = Carbon::parse($month)->endOfMonth();

        $bookings = Booking::whereBetween('booking_date', [$startOfMonth, $endOfMonth])
            ->where('status', 'confirmed')
            ->with('table')
            ->get()
            ->groupBy(fn($booking) => $booking->booking_date->format('Y-m-d'))
            ->map(fn($dayBookings) => $dayBookings->count());

        return Inertia::render('Bookings/Calendar', [
            'month' => $month,
            'bookingCounts' => $bookings,
        ]);
    }
}
