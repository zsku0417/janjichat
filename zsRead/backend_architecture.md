# Janji Chat - Backend Architecture Guide

This document explains the key backend components and how they work together in the Janji Chat application.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         HTTP Request                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Routes (web.php / api.php)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Controllers                               │
│   (Handle HTTP requests, validate input, return responses)       │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐  ┌──────────────┐  ┌──────────────┐
│     Services     │  │   Policies   │  │    Jobs      │
│ (Business Logic) │  │(Authorization)│ │ (Background) │
└──────────────────┘  └──────────────┘  └──────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Models                                  │
│         (Database interaction, relationships, attributes)        │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Database                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Directory Structure

```
app/
├── Http/
│   └── Controllers/          # Handle HTTP requests
├── Models/                   # Eloquent database models
├── Services/                 # Business logic layer
├── Jobs/                     # Background/queued tasks
├── Policies/                 # Authorization rules
└── Providers/                # Service providers

routes/
├── web.php                   # Web routes (with sessions)
└── api.php                   # API routes (stateless)

database/
├── migrations/               # Database schema changes
└── seeders/                  # Sample/demo data

config/
└── *.php                     # Configuration files
```

---

## 🎯 Models (`app/Models/`)

**Purpose**: Represent database tables and define relationships.

### Key Models:

| Model | Table | Description |
|-------|-------|-------------|
| `User` | `users` | Business owners (merchants) |
| `Conversation` | `conversations` | WhatsApp chat sessions |
| `Message` | `messages` | Individual messages |
| `Booking` | `bookings` | Restaurant reservations |
| `Table` | `tables` | Restaurant tables |
| `Product` | `products` | Shop products |
| `Order` | `orders` | Customer orders |
| `OrderItem` | `order_items` | Items in an order |
| `Document` | `documents` | Knowledge base files |
| `DocumentChunk` | `document_chunks` | Embedded text chunks |

### Example - User Model:
```php
class User extends Authenticatable
{
    // Business type constants
    const TYPE_RESTAURANT = 'restaurant';
    const TYPE_ORDER_TRACKING = 'order_tracking';

    // Relationships
    public function bookings() { return $this->hasMany(Booking::class); }
    public function products() { return $this->hasMany(Product::class); }
    public function orders() { return $this->hasMany(Order::class); }

    // Helper methods
    public function isRestaurant(): bool { return $this->business_type === self::TYPE_RESTAURANT; }
    public function isOrderTracking(): bool { return $this->business_type === self::TYPE_ORDER_TRACKING; }
}
```

---

## 🎮 Controllers (`app/Http/Controllers/`)

**Purpose**: Handle HTTP requests, validate input, call services, return responses.

### Key Controllers:

| Controller | Purpose |
|------------|---------|
| `DashboardController` | Dashboard stats for each business type |
| `BookingController` | Restaurant booking CRUD |
| `ProductController` | Product catalog CRUD |
| `OrderController` | Order management |
| `DocumentController` | Knowledge base documents |
| `ConversationController` | WhatsApp conversations UI |
| `WebhookController` | WhatsApp incoming webhooks |
| `DevelopmentController` | Simulator for testing |

### Example - Controller Flow:
```php
class BookingController extends Controller
{
    public function index(Request $request)
    {
        // 1. Authorize - Check user can view bookings
        $this->authorize('viewAny', Booking::class);

        // 2. Get data - Fetch from database
        $bookings = Booking::where('user_id', auth()->id())
            ->with('table')
            ->paginate(10);

        // 3. Return response - Inertia Vue page
        return Inertia::render('Bookings/Index', [
            'bookings' => $bookings
        ]);
    }
}
```

---

## ⚙️ Services (`app/Services/`)

**Purpose**: Encapsulate business logic (keep controllers thin).

### Key Services:

| Service | Responsibility |
|---------|----------------|
| `ConversationHandler` | Process incoming WhatsApp messages |
| `BookingService` | Booking creation, availability checks |
| `OrderService` | Order parsing, creation, confirmation |
| `WhatsAppService` | Send/receive WhatsApp messages |
| `OpenAIService` | AI chat & embeddings |
| `RAGService` | Knowledge base search & intent detection |
| `DocumentService` | Document upload, chunking, embedding |

### Example - Service Pattern:
```php
class BookingService
{
    protected OpenAIService $openAI;

    public function __construct(OpenAIService $openAI)
    {
        $this->openAI = $openAI; // Dependency injection
    }

    public function checkAvailability(string $date, string $time, int $pax): array
    {
        // Complex business logic here
        // - Check operating hours
        // - Find suitable tables
        // - Check for conflicts
        return ['available' => true, 'tables' => $tables];
    }

    public function createBooking(array $data): Booking
    {
        // Create booking with all validations
    }
}
```

### Message Flow Example:

```
WhatsApp → Webhook → ConversationHandler
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    RAGService      BookingService   OrderService
    (Intent)        (Restaurant)     (Order Tracking)
          │               │               │
          └───────────────┼───────────────┘
                          ▼
                  WhatsAppService
                   (Send Reply)
```

---

## 📋 Jobs (`app/Jobs/`)

**Purpose**: Handle time-consuming tasks in the background.

### Key Jobs:

| Job | Purpose |
|-----|---------|
| `ProcessDocumentJob` | Extract text, chunk, generate embeddings |
| `SendWhatsAppMessageJob` | Send messages asynchronously |

### Example - Job Pattern:
```php
class ProcessDocumentJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    protected Document $document;

    public function __construct(Document $document)
    {
        $this->document = $document;
    }

    public function handle(DocumentService $documentService): void
    {
        // This runs in background
        $documentService->processDocument($this->document);
    }
}
```

### Dispatching Jobs:
```php
// In controller after upload
ProcessDocumentJob::dispatch($document);
```

### Running the Queue Worker:
```bash
php artisan queue:work
```

---

## 🔐 Policies (`app/Policies/`)

**Purpose**: Authorization logic (who can do what).

### Key Policies:

| Policy | Authorizes |
|--------|------------|
| `BookingPolicy` | Booking actions |
| `ProductPolicy` | Product CRUD |
| `OrderPolicy` | Order management |

### Example - Policy:
```php
class ProductPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isOrderTracking(); // Only order_tracking users
    }

    public function update(User $user, Product $product): bool
    {
        return $product->user_id === $user->id; // Only owner
    }
}
```

### Using Policies:
```php
// In controller
$this->authorize('update', $product);

// In Blade/Vue
@can('update', $product) ... @endcan
```

---

## 🛣️ Routes (`routes/`)

### web.php (Session-based):
```php
// Auth routes
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::resource('bookings', BookingController::class);
    Route::resource('products', ProductController::class);
});
```

### api.php (Stateless):
```php
Route::get('/webhook/whatsapp', [WebhookController::class, 'verify']);
Route::post('/webhook/whatsapp', [WebhookController::class, 'handle']);
```

---

## 🗃️ Database

### Migrations (`database/migrations/`):
Define table structure with version control.

```php
public function up(): void
{
    Schema::create('bookings', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained();
        $table->foreignId('table_id')->constrained();
        $table->date('booking_date');
        $table->time('booking_time');
        $table->integer('pax');
        $table->timestamps();
    });
}
```

### Seeders (`database/seeders/`):
Populate demo data.

```php
class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        User::create([
            'email' => 'restaurant@demo.com',
            'password' => Hash::make('password123'),
            'business_type' => 'restaurant',
        ]);
    }
}
```

---

## ⚡ Request Lifecycle Summary

1. **Request arrives** → `routes/web.php` or `routes/api.php`
2. **Middleware** → Authentication, CSRF, etc.
3. **Controller** → Validates input, calls services
4. **Policy** → Checks authorization
5. **Service** → Executes business logic
6. **Model** → Interacts with database
7. **Job** (optional) → Queues background work
8. **Response** → Returns JSON or Inertia page

---

## 🔗 Related Files

| File | Purpose |
|------|---------|
| `config/openai.php` | OpenAI API settings |
| `config/whatsapp.php` | WhatsApp API settings |
| `.env` | Environment variables |
| `app/Providers/AppServiceProvider.php` | Service bindings |
