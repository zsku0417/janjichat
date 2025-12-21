<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\Media;
use App\Services\MediaService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Inertia\Inertia;
use Inertia\Response;

class ProductController extends Controller
{
    public function __construct(
        protected MediaService $mediaService
    ) {
    }

    /**
     * Display a listing of products.
     */
    public function index(Request $request): Response
    {
        $query = auth()->user()->products()->with('media');

        // Search filter
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Status filter
        if ($request->input('status') && $request->input('status') !== 'all') {
            $isActive = $request->input('status') === 'active';
            $query->where('is_active', $isActive);
        }

        // Sorting
        $sortKey = $request->input('sort_key', 'updated_at');
        $sortOrder = $request->input('sort_order', 'desc');

        $allowedSortKeys = ['name', 'price', 'is_active', 'created_at', 'updated_at'];
        if (in_array($sortKey, $allowedSortKeys)) {
            $query->orderBy($sortKey, $sortOrder === 'asc' ? 'asc' : 'desc');
        }

        $products = $query->paginate(10)->withQueryString();

        return Inertia::render('OrderTracking/Products/Index', [
            'products' => $products,
            'filters' => [
                'search' => $request->input('search', ''),
                'status' => $request->input('status', 'all'),
                'sort_key' => $request->input('sort_key'),
                'sort_order' => $request->input('sort_order'),
            ],
        ]);
    }

    /**
     * Show the form for creating a new product.
     * @deprecated Use modal in Index page instead
     */
    public function create(): Response
    {
        return Inertia::render('OrderTracking/Products/Create');
    }

    /**
     * Store a newly created product.
     */
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'description' => 'nullable|string|max:2000',
            'is_active' => 'boolean',
            'images' => 'nullable|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120', // 5MB max
        ]);

        $product = auth()->user()->products()->create([
            'name' => $validated['name'],
            'price' => $validated['price'],
            'description' => $validated['description'] ?? null,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        // Handle image uploads
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $media = $this->mediaService->uploadImage(
                    $image,
                    auth()->id(),
                    'products'
                );
                $media->update([
                    'mediable_id' => $product->id,
                    'mediable_type' => Product::class,
                ]);
            }
        }

        return redirect()->route('products.index')
            ->with('success', 'Product created successfully!');
    }

    /**
     * Show the form for editing a product.
     * @deprecated Use modal in Index page instead
     */
    public function edit(Product $product): Response
    {
        $this->authorize('update', $product);

        $product->load('media');

        return Inertia::render('OrderTracking/Products/Edit', [
            'product' => $product,
        ]);
    }

    /**
     * Update the specified product.
     */
    public function update(Request $request, Product $product): RedirectResponse
    {
        $this->authorize('update', $product);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'description' => 'nullable|string|max:2000',
            'is_active' => 'boolean',
            'images' => 'nullable|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'delete_images' => 'nullable|array',
            'delete_images.*' => 'integer|exists:media,id',
        ]);

        $product->update([
            'name' => $validated['name'],
            'price' => $validated['price'],
            'description' => $validated['description'] ?? null,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        // Handle image deletions
        if (!empty($validated['delete_images'])) {
            foreach ($validated['delete_images'] as $mediaId) {
                $media = Media::where('id', $mediaId)
                    ->where('mediable_id', $product->id)
                    ->where('mediable_type', Product::class)
                    ->first();

                if ($media) {
                    $this->mediaService->delete($media);
                }
            }
        }

        // Handle new image uploads
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $media = $this->mediaService->uploadImage(
                    $image,
                    auth()->id(),
                    'products'
                );
                $media->update([
                    'mediable_id' => $product->id,
                    'mediable_type' => Product::class,
                ]);
            }
        }

        return redirect()->route('products.index')
            ->with('success', 'Product updated successfully!');
    }

    /**
     * Remove the specified product.
     */
    public function destroy(Product $product): RedirectResponse
    {
        $this->authorize('delete', $product);

        // Delete all associated media
        foreach ($product->media as $media) {
            $this->mediaService->delete($media);
        }

        $product->delete();

        return redirect()->route('products.index')
            ->with('success', 'Product deleted successfully!');
    }

    /**
     * Toggle product active status.
     */
    public function toggleActive(Product $product): RedirectResponse
    {
        $this->authorize('update', $product);

        $product->update(['is_active' => !$product->is_active]);

        return redirect()->back()
            ->with('success', $product->is_active ? 'Product activated!' : 'Product deactivated!');
    }

    /**
     * Upload images to a product.
     */
    public function uploadImages(Request $request, Product $product): JsonResponse
    {
        $this->authorize('update', $product);

        $request->validate([
            'images' => 'required|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        $uploadedImages = [];

        foreach ($request->file('images') as $image) {
            $media = $this->mediaService->uploadImage(
                $image,
                auth()->id(),
                'products'
            );
            $media->update([
                'mediable_id' => $product->id,
                'mediable_type' => Product::class,
            ]);
            $uploadedImages[] = [
                'id' => $media->id,
                'url' => $media->url,
                'original_name' => $media->original_name,
            ];
        }

        return response()->json([
            'success' => true,
            'images' => $uploadedImages,
        ]);
    }

    /**
     * Delete a specific image from a product.
     */
    public function deleteImage(Product $product, Media $media): JsonResponse
    {
        $this->authorize('update', $product);

        // Verify the media belongs to this product
        if ($media->mediable_id !== $product->id || $media->mediable_type !== Product::class) {
            return response()->json(['error' => 'Image does not belong to this product'], 403);
        }

        $this->mediaService->delete($media);

        return response()->json(['success' => true]);
    }

    /**
     * Get orders for a specific product.
     */
    public function getOrders(Request $request, Product $product): JsonResponse
    {
        $this->authorize('view', $product);

        $period = $request->input('period', 'all');

        $query = $product->orderItems()
            ->with([
                'order' => function ($q) {
                    $q->select('id', 'code', 'customer_name', 'customer_phone', 'status', 'created_at', 'total_amount');
                }
            ])
            ->whereHas('order');

        // Apply date filter
        $query = $this->applyDateFilter($query, $period);

        $orderItems = $query->orderBy('created_at', 'desc')
            ->take(50)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'order_id' => $item->order_id,
                    'quantity' => $item->quantity,
                    'unit_price' => $item->unit_price,
                    'subtotal' => $item->subtotal,
                    'created_at' => $item->created_at->format('d M Y H:i'),
                    'order' => $item->order ? [
                        'id' => $item->order->id,
                        'code' => $item->order->code,
                        'customer_name' => $item->order->customer_name,
                        'customer_phone' => $item->order->customer_phone,
                        'status' => $item->order->status,
                        'status_label' => $item->order->status_label,
                        'total_amount' => $item->order->total_amount,
                    ] : null,
                ];
            });

        // Calculate statistics
        $stats = $this->calculateProductStats($product, $period);

        return response()->json([
            'orders' => $orderItems,
            'stats' => $stats,
        ]);
    }

    /**
     * Export product orders as Excel or PDF.
     */
    public function exportOrders(Request $request, Product $product)
    {
        $this->authorize('view', $product);

        $period = $request->input('period', 'all');
        $format = $request->input('format', 'excel'); // excel or pdf

        $query = $product->orderItems()
            ->with(['order'])
            ->whereHas('order');

        $query = $this->applyDateFilter($query, $period);

        $orderItems = $query->orderBy('created_at', 'desc')->get();

        $data = $orderItems->map(function ($item) use ($product) {
            return [
                'Order ID' => '#' . $item->order_id,
                'Order Date' => $item->created_at->format('d M Y H:i'),
                'Customer Name' => $item->order->customer_name ?? 'N/A',
                'Customer Phone' => $item->order->customer_phone ?? 'N/A',
                'Product Name' => $product->name,
                'Quantity' => $item->quantity,
                'Unit Price (RM)' => number_format($item->unit_price, 2),
                'Subtotal (RM)' => number_format($item->subtotal, 2),
                'Order Status' => $item->order->status_label ?? $item->order->status,
            ];
        })->toArray();

        $filename = $product->name . '_orders_' . $period . '_' . now()->format('Y-m-d');

        if ($format === 'pdf') {
            return $this->exportAsPdf($data, $product, $period, $filename);
        }

        return $this->exportAsExcel($data, $filename);
    }

    /**
     * Export data as Excel file.
     */
    private function exportAsExcel(array $data, string $filename)
    {
        $spreadsheet = new \PhpOffice\PhpSpreadsheet\Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();

        // Headers
        if (!empty($data)) {
            $headers = array_keys($data[0]);
            $col = 'A';
            foreach ($headers as $header) {
                $sheet->setCellValue($col . '1', $header);
                $sheet->getStyle($col . '1')->getFont()->setBold(true);
                $sheet->getColumnDimension($col)->setAutoSize(true);
                $col++;
            }

            // Data rows
            $row = 2;
            foreach ($data as $rowData) {
                $col = 'A';
                foreach ($rowData as $value) {
                    $sheet->setCellValue($col . $row, $value);
                    $col++;
                }
                $row++;
            }
        }

        $writer = new \PhpOffice\PhpSpreadsheet\Writer\Xlsx($spreadsheet);

        $tempFile = tempnam(sys_get_temp_dir(), 'excel');
        $writer->save($tempFile);

        return response()->download($tempFile, $filename . '.xlsx', [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ])->deleteFileAfterSend(true);
    }

    /**
     * Export data as PDF file.
     */
    private function exportAsPdf(array $data, Product $product, string $period, string $filename)
    {
        $periodLabels = [
            'all' => 'All Time',
            'today' => 'Today',
            'yesterday' => 'Yesterday',
            'last_week' => 'Last 7 Days',
            'last_month' => 'Last 30 Days',
            'last_3_months' => 'Last 3 Months',
            'last_year' => 'Last Year',
        ];

        $html = view('exports.product-orders-pdf', [
            'product' => $product,
            'data' => $data,
            'period' => $periodLabels[$period] ?? $period,
            'generatedAt' => now()->format('d M Y H:i'),
        ])->render();

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadHTML($html)
            ->setPaper('a4', 'landscape');

        return $pdf->download($filename . '.pdf');
    }

    /**
     * Apply date filter to query based on period.
     */
    private function applyDateFilter($query, string $period)
    {
        $now = now();

        switch ($period) {
            case 'today':
                $query->whereDate('created_at', $now->toDateString());
                break;
            case 'yesterday':
                $query->whereDate('created_at', $now->subDay()->toDateString());
                break;
            case 'last_week':
                $query->whereBetween('created_at', [$now->subWeek()->startOfDay(), now()]);
                break;
            case 'last_month':
                $query->whereBetween('created_at', [$now->subMonth()->startOfDay(), now()]);
                break;
            case 'last_3_months':
                $query->whereBetween('created_at', [$now->subMonths(3)->startOfDay(), now()]);
                break;
            case 'last_year':
                $query->whereBetween('created_at', [$now->subYear()->startOfDay(), now()]);
                break;
            // 'all' - no filter
        }

        return $query;
    }

    /**
     * Calculate product statistics for a given period.
     */
    private function calculateProductStats(Product $product, string $period): array
    {
        $query = $product->orderItems()->whereHas('order');
        $query = $this->applyDateFilter($query, $period);

        $totalOrders = $query->count();
        $totalQuantity = $query->sum('quantity');
        $totalRevenue = $query->sum('subtotal');

        return [
            'total_orders' => $totalOrders,
            'total_quantity' => (int) $totalQuantity,
            'total_revenue' => number_format($totalRevenue, 2),
        ];
    }
}

