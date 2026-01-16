# Janjichat - Viva FAQ & Answers

---

## 1. Explain the Title

**Title:** "A Modular WhatsApp Chatbot System for Smart and Automated Customer Engagement"

**How to explain:**

> "The title describes a WhatsApp-based chatbot that intelligently automates customer interactions for businesses. It uses AI to understand what customers want and responds automatically – whether they're asking questions, booking appointments, or placing orders."

**What does "Modular" mean?**

> "Modular means the system is built with **separate, independent components** that can work together. Each module handles a specific function:"
>
> -   **Booking Module** – handles restaurant reservations
> -   **Order Module** – handles e-commerce orders
> -   **RAG Module** – handles knowledge base Q&A
> -   **Multilingual Module** – handles language detection
>
> "The benefit is **flexibility** – a restaurant only needs the Booking Module, while a shop only needs the Order Module. We can add or remove modules without breaking the system. It's like LEGO blocks – you can combine different pieces based on business needs."

---








## 2. Explain WebSocket

**What is WebSocket?**

> "Normal HTTP is request-response – client asks, server answers, connection closes. WebSocket keeps the connection **open permanently**, so the server can **push updates instantly** without the client asking."

**How it works in Janjichat:**

### Step 1: Event is created when something changes

```php
// app/Events/NewMessageEvent.php
class NewMessageEvent implements ShouldBroadcast
{
    public function __construct(
        public Conversation $conversation,
        public Message $message
    ) {}

    // Which channel to broadcast to
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('conversations.' . $this->conversation->user_id),
        ];
    }

    // Data sent to frontend
    public function broadcastWith(): array
    {
        return [
            'message' => $this->message,
            'conversation_id' => $this->conversation->id,
        ];
    }
}
```

### Step 2: Backend broadcasts when message is saved

```php
// In ConversationHandler.php after saving message
broadcast(new NewMessageEvent($conversation, $message))->toOthers();
```

### Step 3: Frontend listens for the event

```javascript
// In Vue component
Echo.private(`conversations.${userId}`).listen(".new.message", (event) => {
    // Update UI instantly without page refresh
    this.conversations.push(event.message);
});
```

> "So when a customer sends a WhatsApp message, the backend saves it and broadcasts via WebSocket. The merchant dashboard receives it **instantly** without refreshing."

---











## 3. Message Flow with Code

**Complete flow when customer sends "I want to book a table for 4 tomorrow":**

### Step 1: WhatsApp sends webhook to Laravel

```php
// routes/api.php
Route::post('/webhook/whatsapp', [WhatsAppWebhookController::class, 'handle']);
```

### Step 2: Controller receives and parses

```php
// app/Http/Controllers/Api/WhatsAppWebhookController.php
public function handle(Request $request)
{
    $payload = $request->all();
    $parsedData = $this->whatsApp->parseWebhookPayload($payload);

    // Route to ConversationHandler
    $this->conversationHandler->handleIncomingMessage($parsedData);

    return response('OK', 200);
}
```

### Step 3: ConversationHandler processes

```php
// app/Services/ConversationHandler.php
public function handleIncomingMessage(array $messageData)
{
    // 1. Get or create conversation
    $conversation = $this->getOrCreateConversation($messageData);

    // 2. Store the message
    $message = $this->storeMessage($conversation, $messageData);

    // 3. Detect intent using AI
    $intent = $this->ragService->detectIntent($messageData['content'], $conversation);

    // 4. Route to appropriate handler
    if ($intent['intent'] === 'booking_request') {
        $response = $this->restaurantHandler->handleBookingRequest($conversation, $messageData);
    }

    // 5. Send response via WhatsApp
    $this->sendResponse($conversation, $response);
}
```

### Step 4: RestaurantHandler calls BookingService

```php
// app/Services/Handlers/RestaurantHandler.php
public function handleBookingRequest($conversation, $messageData)
{
    // Parse booking details using AI
    $bookingData = $this->bookingService->parseBookingFromMessage($messageData['content']);

    // Check availability
    $availability = $this->bookingService->checkAvailability($bookingData);

    if ($availability['available']) {
        // Create booking
        $booking = $this->bookingService->createBooking($bookingData);
        return $this->bookingService->formatConfirmationMessage($booking);
    }
}
```

### Step 5: Send response back

```php
// app/Services/ConversationHandler.php
public function sendResponse(Conversation $conversation, string $content)
{
    // Send via WhatsApp API
    $this->whatsApp->sendMessage($conversation->phone_number, $content);

    // Broadcast to dashboard (WebSocket)
    broadcast(new NewMessageEvent($conversation, $message))->toOthers();
}
```

---

## Summary Flow Diagram

```
Customer WhatsApp
    → WhatsApp API
    → WebhookController
    → ConversationHandler
    → RAGService (detect intent)
    → RestaurantHandler
    → BookingService
    → WhatsApp API
    → Customer receives confirmation
    → WebSocket
    → Dashboard updated
```
