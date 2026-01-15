<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\MerchantSetting;
use App\Models\Table;
use App\Models\RestaurantSetting;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Exception;

class BookingService
{
    protected OpenAIService $openAI;

    public function __construct(OpenAIService $openAI)
    {
        $this->openAI = $openAI;
    }

    /**
     * Get the booking form template message.
     * Uses merchant's custom template or falls back to default.
     */
    public function getBookingFormTemplate(User $merchant): string
    {
        $merchantSettings = $merchant->merchantSettings;

        // Priority 1: Use custom booking form template from merchant settings
        if ($merchantSettings && !empty($merchantSettings->booking_form_template)) {
            return $merchantSettings->booking_form_template;
        }

        // Priority 2: Generate default template
        $restaurantName = $merchantSettings->business_name ?? $merchant->name ?? 'Our Restaurant';

        return <<<TEMPLATE
Welcome to {$restaurantName}! 🍽️

To make a table reservation, please fill in the form below:

👥 *Number of Guests (Pax):*

📅 *Date & Time:*
(e.g. 15-12-2026, 7:00pm)

📞 *Phone Number:*

👤 *Name:*

📝 *Special Requests:*
(e.g. birthday celebration, high chair, window seat)

---
Please copy, fill in and send the form back to us!
TEMPLATE;
    }

    /**
     * Parse booking details from customer message using AI.
     * Includes recent conversation context so AI can remember previous booking attempt details.
     */
    public function parseBookingFromMessage(string $message, string $customerPhone, ?string $customerName = null, ?Conversation $conversation = null): ?array
    {
        $settings = RestaurantSetting::getInstance();
        $openingTime = $settings?->formatted_opening_time ?? '10:00 AM';
        $closingTime = $settings?->formatted_closing_time ?? '10:00 PM';

        // Get current date info for better relative date parsing
        $currentDate = now()->format('Y-m-d');
        $currentDayOfWeek = now()->format('l'); // e.g., "Tuesday"
        $currentDateTime = now()->format('Y-m-d H:i');
        $currentYear = now()->format('Y');

        // Build conversation context from recent messages
        $conversationContext = '';
        if ($conversation) {
            $recentMessages = $conversation->messages()
                ->orderBy('created_at', 'desc')
                ->take(6) // Last 6 messages (3 exchanges)
                ->get()
                ->reverse();

            if ($recentMessages->isNotEmpty()) {
                $conversationContext = "\n\nRECENT CONVERSATION CONTEXT (use this to fill in missing details from previous messages):\n";
                foreach ($recentMessages as $msg) {
                    $role = $msg->direction === 'inbound' ? 'Customer' : 'Restaurant';
                    $conversationContext .= "{$role}: {$msg->content}\n";
                }
            }
        }

        $prompt = <<<PROMPT
You are parsing a customer table reservation message for a restaurant.

Restaurant operating hours: {$openingTime} - {$closingTime}

CRITICAL DATE CONTEXT:
- TODAY is {$currentDayOfWeek}, {$currentDate}
- Current date/time: {$currentDateTime}
- Current year: {$currentYear}

RELATIVE DATE TRANSLATIONS (calculate based on today's date above):
- English: tomorrow, day after tomorrow, next week, this weekend
- Chinese: 明天 (tomorrow), 后天 (day after tomorrow), 下周/下星期 (next week), 这个周末 (this weekend), 今天 (today)
- Malay: esok (tomorrow), lusa (day after tomorrow), minggu depan (next week)

EXAMPLE: If today is 2026-01-07 and customer says "明天12pm", the datetime should be "2026-01-08 12:00"
{$conversationContext}
Customer's LATEST message (this is what they sent NOW):
---
{$message}
---

Extract the following information. IMPORTANT: If information is not in the latest message but was provided in a PREVIOUS message in the conversation context above, USE THAT.

Return a JSON object with these fields:
- pax: number (number of guests) - check previous messages if not in latest
- datetime: string in "YYYY-MM-DD HH:mm" format - CALCULATE CORRECTLY based on today's date above
- phone: string (phone number, use default if not provided)
- name: string (customer name, use default if not provided)  
- special_request: string or null - check previous messages if not in latest
- is_valid: boolean - true if required fields (pax, datetime) can be determined from latest or previous messages
- language: string - the language code of the customer's message (e.g., "en", "zh", "ms")

If pax or datetime cannot be extracted from latest OR previous messages, return: {"is_valid": false, "reason": "explanation"}

Default phone if not provided: {$customerPhone}
Default name if not provided: {$customerName}

IMPORTANT: 
- Return ONLY valid JSON, no markdown, no explanation.
- CALCULATE dates correctly: 明天 = tomorrow = today + 1 day
- Make sure the year is correct (currently we are in year {$currentYear}).
- If customer is correcting/updating information from a previous message, merge the old and new info.
PROMPT;

        $prompt = str_replace('{$customerPhone}', $customerPhone, $prompt);
        $prompt = str_replace('{$customerName}', $customerName ?? 'Customer', $prompt);

        try {
            $response = $this->openAI->chat([
                ['role' => 'user', 'content' => $prompt]
            ]);

            // Clean the response - remove markdown code blocks if present
            $response = preg_replace('/```json\s*/', '', $response);
            $response = preg_replace('/```\s*/', '', $response);
            $response = trim($response);

            $parsed = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                Log::warning('Failed to parse AI booking response as JSON', [
                    'response' => $response,
                    'error' => json_last_error_msg(),
                ]);
                return null;
            }

            return $parsed;
        } catch (Exception $e) {
            Log::error('Failed to parse booking with AI', [
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Parse booking modification details using AI.
     * This is smarter than regex - handles any language and understands context.
     *
     * @param string $message Customer's message
     * @param Booking $currentBooking The booking being modified
     * @param Conversation $conversation For context
     * @return array|null Parsed changes {booking_date?, booking_time?, pax?} or null if nothing to change
     */
    public function parseBookingChanges(string $message, Booking $currentBooking, Conversation $conversation): ?array
    {
        $settings = RestaurantSetting::getInstance();
        $openingTime = $settings?->formatted_opening_time ?? '10:00 AM';
        $closingTime = $settings?->formatted_closing_time ?? '10:00 PM';

        $currentDate = now()->format('Y-m-d');
        $currentDayOfWeek = now()->format('l');
        $currentYear = now()->format('Y');

        // Build conversation context
        $conversationContext = '';
        $recentMessages = $conversation->messages()
            ->orderBy('created_at', 'desc')
            ->take(6)
            ->get()
            ->reverse();

        if ($recentMessages->isNotEmpty()) {
            $conversationContext = "\nRECENT CONVERSATION:\n";
            foreach ($recentMessages as $msg) {
                $role = $msg->direction === 'inbound' ? 'Customer' : 'Restaurant';
                $conversationContext .= "{$role}: {$msg->content}\n";
            }
        }

        $currentBookingInfo = "CURRENT BOOKING:\n" .
            "- Date: " . $currentBooking->booking_date->format('l, F j, Y') . "\n" .
            "- Time: " . Carbon::parse($currentBooking->booking_time)->format('g:i A') . "\n" .
            "- Guests: {$currentBooking->pax}\n";

        $prompt = <<<PROMPT
You are parsing a customer's request to MODIFY their restaurant booking.

{$currentBookingInfo}

Restaurant operating hours: {$openingTime} - {$closingTime}

DATE CONTEXT:
- Today is {$currentDayOfWeek}, {$currentDate}
- Current year: {$currentYear}
{$conversationContext}

Customer's LATEST message:
---
{$message}
---

TASK: Determine what the customer wants to change about their booking.

Return a JSON object with ONLY the fields that should be changed:
- booking_date: "YYYY-MM-DD" format (only if customer wants to change date)
- booking_time: "HH:mm:00" 24-hour format (only if customer wants to change time)
- pax: number (only if customer wants to change number of guests)
- has_changes: boolean - true if any changes are requested

Examples:
- "tukar ke khamis 25th" → {"booking_date": "2024-12-25", "has_changes": true}
- "change to 7pm" → {"booking_time": "19:00:00", "has_changes": true}
- "add 2 more people" (current is 4) → {"pax": 6, "has_changes": true}
- "reschedule please" (no specific details) → {"has_changes": false}

IMPORTANT:
- Understand Malay: esok=tomorrow, minggu depan=next week, isnin/selasa/rabu/khamis/jumaat/sabtu/ahad = Mon-Sun
- Understand Chinese: 明天=tomorrow, 下周=next week
- Return ONLY valid JSON, no explanation
PROMPT;

        try {
            $response = $this->openAI->chat([
                ['role' => 'user', 'content' => $prompt]
            ]);

            // Clean response
            $response = preg_replace('/```json\s*/', '', $response);
            $response = preg_replace('/```\s*/', '', $response);
            $response = trim($response);

            $parsed = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                Log::warning('Failed to parse AI booking changes as JSON', [
                    'response' => $response,
                    'error' => json_last_error_msg(),
                ]);
                return null;
            }

            Log::info('AI parsed booking changes', [
                'message' => $message,
                'parsed' => $parsed,
            ]);

            // Return null if no changes
            if (!($parsed['has_changes'] ?? false)) {
                return null;
            }

            // Remove has_changes flag from return value
            unset($parsed['has_changes']);
            return empty($parsed) ? null : $parsed;

        } catch (Exception $e) {
            Log::error('Failed to parse booking changes with AI', [
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Check if a message looks like a booking attempt.
     * This is a quick heuristic check - the AI intent detection is the primary method.
     * We use this as a fast pre-filter to catch obvious booking form submissions.
     */
    public function isBookingAttempt(string $message): bool
    {
        // Count how many booking-related data points are present
        $score = 0;

        // Has pax/guests mentioned (multilingual)
        // English: 4 pax, 4 guests, 4 people
        // Malay: 4 orang, 4 tetamu
        // Chinese: 4个人, 4位, 四个人
        if (
            preg_match('/\b\d+\s*(pax|guests?|people|persons?|orang|tetamu)/i', $message) ||
            preg_match('/\d+\s*(个人|位|個人)/', $message)
        ) {
            $score += 2;
        }

        // Has date pattern (various formats and languages)
        // Format: 15/12/2026, 15-12-2026
        // English: tomorrow, next Monday
        // Malay: esok, minggu depan
        // Chinese: 明天, 后天, 今天, 下周
        if (
            preg_match('/\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4}|\b(tomorrow|esok|minggu depan|next\s+\w+day)/i', $message) ||
            preg_match('/(明天|后天|今天|下周|下星期|這個週末|这个周末)/', $message)
        ) {
            $score += 2;
        }

        // Has time pattern (multilingual)
        // English: 12pm, 7:00pm
        // Malay: 12 petang, 7 malam
        // Chinese: 12点, 12時, 中午12点
        if (
            preg_match('/\d{1,2}(:\d{2})?\s*(am|pm|pagi|petang|malam)/i', $message) ||
            preg_match('/\d{1,2}\s*(点|點|時|时)/', $message)
        ) {
            $score += 1;
        }

        // Has name/phone indicators (multilingual)
        // English: name:, phone:
        // Malay: nama:, telefon:
        // Chinese: 名字, 电话, 電話
        if (
            preg_match('/\b(name|nama|phone|telefon|contact)\s*[:=]/i', $message) ||
            preg_match('/(名字|电话|電話|名字放|电话放|電話放)/', $message)
        ) {
            $score += 1;
        }

        // Has phone number pattern (6+ digits together)
        if (preg_match('/\d{8,}/', $message) || preg_match('/\d{3,4}[-\s]?\d{3,4}[-\s]?\d{3,4}/', $message)) {
            $score += 1;
        }

        // Looks like a filled form (multiple lines with data)
        if (substr_count($message, "\n") >= 2) {
            $score += 1;
        }

        // Require at least 3 points to be considered a booking attempt
        return $score >= 3;
    }

    /**
     * Create a booking from parsed data.
     * @throws Exception if booking cannot be created (availability, past date, etc.)
     */
    public function createBookingFromParsed(array $bookingData, Conversation $conversation): ?Booking
    {
        // Parse datetime
        $datetime = $this->parseDateTime($bookingData['datetime'] ?? '');
        if (!$datetime) {
            return null;
        }

        $data = [
            'user_id' => $conversation->user_id, // Use merchant from conversation
            'conversation_id' => $conversation->id,
            'customer_name' => $bookingData['name'] ?? $conversation->customer_name ?? 'Customer',
            'customer_phone' => $bookingData['phone'] ?? $conversation->phone_number ?? $conversation->whatsapp_id,
            'booking_date' => $datetime->format('Y-m-d'),
            'booking_time' => $datetime->format('H:i:s'),
            'pax' => (int) ($bookingData['pax'] ?? 2),
            'special_request' => $bookingData['special_request'] ?? null,
            'created_by' => 'customer',
        ];

        // This may throw an exception for availability/date issues - let it propagate
        return $this->createBooking($data);
    }

    /**
     * Parse datetime string to Carbon instance.
     */
    protected function parseDateTime(?string $datetime): ?Carbon
    {
        if (empty($datetime)) {
            return null;
        }

        try {
            return Carbon::parse($datetime);
        } catch (Exception $e) {
            Log::warning('Failed to parse datetime', [
                'datetime' => $datetime,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }
    /**
     * Check availability for a given date, time, and party size.
     *
     * @param string $date Date in Y-m-d format
     * @param string $time Time in H:i format
     * @param int $pax Number of guests
     * @return array ['available' => bool, 'tables' => Collection, 'message' => string]
     */
    public function checkAvailability(string $date, string $time, int $pax): array
    {
        $settings = RestaurantSetting::getInstance();
        $bookingDate = Carbon::parse($date);
        $bookingTime = Carbon::parse($time);
        $slotDuration = $settings?->slot_duration_minutes ?? 60;
        $endTime = $bookingTime->copy()->addMinutes($slotDuration);

        // Create full datetime for comparison
        $bookingDateTime = Carbon::parse($date . ' ' . $time);
        $now = Carbon::now();

        // Check if the booking date/time is in the past
        if ($bookingDateTime->isPast()) {
            // If it's today but the time has passed
            if ($bookingDate->isToday()) {
                return [
                    'available' => false,
                    'tables' => collect(),
                    'message' => "Sorry, the requested time has already passed. Please choose a later time today or another date.",
                ];
            }
            // If it's a past date entirely
            return [
                'available' => false,
                'tables' => collect(),
                'message' => "Sorry, you cannot book for a past date. Please choose a future date. Today is " . $now->format('l, F j, Y') . ".",
            ];
        }

        // Check if time is within operating hours
        // Only check START time - allow bookings that start before closing even if slot extends past
        $openingTimeStr = $settings?->opening_time ?? '10:00:00';
        $closingTimeStr = $settings?->closing_time ?? '22:00:00';
        $opening = Carbon::parse($openingTimeStr);
        $closing = Carbon::parse($closingTimeStr);

        if (
            $bookingTime->format('H:i:s') < $opening->format('H:i:s') ||
            $bookingTime->format('H:i:s') > $closing->format('H:i:s')
        ) {
            $formattedOpening = $settings?->formatted_opening_time ?? '10:00 AM';
            $formattedClosing = $settings?->formatted_closing_time ?? '10:00 PM';
            return [
                'available' => false,
                'tables' => collect(),
                'message' => "Sorry, we are only open from {$formattedOpening} to {$formattedClosing}. Please choose a time within our business hours.",
            ];
        }

        // Get tables that can accommodate the party size
        $suitableTables = Table::active()
            ->where('capacity', '>=', $pax)
            ->orderBy('capacity', 'asc') // Prefer smaller tables that fit
            ->get();

        if ($suitableTables->isEmpty()) {
            return [
                'available' => false,
                'tables' => collect(),
                'message' => "Sorry, we don't have any tables that can accommodate {$pax} guests.",
            ];
        }

        // Find tables that are not booked during the requested time slot
        $availableTables = $suitableTables->filter(function ($table) use ($bookingDate, $bookingTime, $endTime) {
            return !$this->hasConflictingBooking($table, $bookingDate, $bookingTime, $endTime);
        });

        if ($availableTables->isEmpty()) {
            // Suggest alternative times
            $alternatives = $this->findAlternativeTimes($date, $pax);
            $alternativeText = $alternatives->isNotEmpty()
                ? " Available times on this date: " . $alternatives->implode(', ')
                : " Would you like to try a different date?";

            return [
                'available' => false,
                'tables' => collect(),
                'message' => "Sorry, no tables are available at {$bookingTime->format('g:i A')} on {$bookingDate->format('l, F j')}." . $alternativeText,
            ];
        }

        return [
            'available' => true,
            'tables' => $availableTables,
            'message' => "Tables available for {$pax} guests at {$bookingTime->format('g:i A')} on {$bookingDate->format('l, F j')}.",
        ];
    }

    /**
     * Create a new booking.
     *
     * @param array $data
     * @return Booking
     */
    public function createBooking(array $data): Booking
    {
        $settings = RestaurantSetting::getInstance();
        $bookingTime = Carbon::parse($data['booking_time']);
        $slotDuration = $settings?->slot_duration_minutes ?? 60;
        $endTime = $bookingTime->copy()->addMinutes($slotDuration);

        // Find the best available table
        $availability = $this->checkAvailability(
            $data['booking_date'],
            $data['booking_time'],
            $data['pax']
        );

        if (!$availability['available']) {
            throw new \Exception($availability['message']);
        }

        // Use the smallest available table
        $table = $availability['tables']->first();

        // Get merchant user_id - from data or from first merchant
        $userId = $data['user_id'] ?? null;
        if (!$userId) {
            $merchant = User::where('role', User::ROLE_MERCHANT)->first();
            $userId = $merchant?->id;
        }

        $booking = Booking::create([
            'user_id' => $userId,
            'conversation_id' => $data['conversation_id'] ?? null,
            'table_id' => $table->id,
            'customer_name' => $data['customer_name'],
            'customer_phone' => $data['customer_phone'],
            'booking_date' => $data['booking_date'],
            'booking_time' => $data['booking_time'],
            'end_time' => $endTime->format('H:i:s'),
            'pax' => $data['pax'],
            'special_request' => $data['special_request'] ?? null,
            'status' => 'confirmed',
            'created_by' => $data['created_by'] ?? 'customer',
        ]);

        Log::info('Booking created', [
            'booking_id' => $booking->id,
            'table' => $table->name,
            'date' => $data['booking_date'],
        ]);

        return $booking;
    }

    /**
     * Modify an existing booking.
     *
     * @param Booking $booking
     * @param array $data
     * @return Booking
     */
    public function modifyBooking(Booking $booking, array $data): Booking
    {
        $settings = RestaurantSetting::getInstance();

        // If date/time is changing, check availability
        if (isset($data['booking_date']) || isset($data['booking_time']) || isset($data['pax'])) {
            $date = $data['booking_date'] ?? $booking->booking_date->format('Y-m-d');
            $time = $data['booking_time'] ?? $booking->booking_time;
            $pax = $data['pax'] ?? $booking->pax;

            // Check availability (excluding current booking)
            $availability = $this->checkAvailability($date, $time, $pax);

            if (!$availability['available']) {
                // Also check if same table is available
                $bookingTime = Carbon::parse($time);
                $slotMinutes = $settings?->slot_duration_minutes ?? 60;
                $endTime = $bookingTime->copy()->addMinutes($slotMinutes);

                $hasConflict = Booking::where('table_id', $booking->table_id)
                    ->where('id', '!=', $booking->id)
                    ->where('booking_date', $date)
                    ->where('status', 'confirmed')
                    ->where(function ($query) use ($time, $endTime) {
                        $query->whereBetween('booking_time', [$time, $endTime->format('H:i:s')])
                            ->orWhereBetween('end_time', [$time, $endTime->format('H:i:s')]);
                    })
                    ->exists();

                if ($hasConflict) {
                    throw new \Exception($availability['message']);
                }
            } else {
                // Use new table if party size changed
                $newTable = $availability['tables']->first();
                if ($newTable && $newTable->id !== $booking->table_id) {
                    $data['table_id'] = $newTable->id;
                }
            }

            // Update end time if time changed
            if (isset($data['booking_time'])) {
                $bookingTime = Carbon::parse($data['booking_time']);
                $slotMinutes = $settings?->slot_duration_minutes ?? 60;
                $data['end_time'] = $bookingTime->addMinutes($slotMinutes)->format('H:i:s');
            }
        }

        $booking->update($data);

        Log::info('Booking modified', [
            'booking_id' => $booking->id,
            'changes' => array_keys($data),
        ]);

        return $booking->fresh();
    }

    /**
     * Cancel a booking.
     *
     * @param Booking $booking
     * @return bool
     */
    public function cancelBooking(Booking $booking): bool
    {
        $booking->update(['status' => 'cancelled']);

        Log::info('Booking cancelled', [
            'booking_id' => $booking->id,
        ]);

        return true;
    }

    /**
     * Get bookings for a customer by phone number.
     *
     * @param string $phone
     * @return Collection
     */
    public function getCustomerBookings(string $phone): Collection
    {
        return Booking::where('customer_phone', $phone)
            ->where('status', 'confirmed')
            ->where('booking_date', '>=', now()->toDateString())
            ->orderBy('booking_date')
            ->orderBy('booking_time')
            ->with('table')
            ->get();
    }

    /**
     * Get bookings by conversation ID (more reliable for cancellation).
     *
     * @param int $conversationId
     * @return Collection
     */
    public function getBookingsByConversation(int $conversationId): Collection
    {
        return Booking::where('conversation_id', $conversationId)
            ->where('status', 'confirmed')
            ->orderBy('booking_date', 'desc')
            ->orderBy('booking_time', 'desc')
            ->with('table')
            ->get();
    }

    /**
     * Check if a customer has a recent booking (for intent detection context).
     * Returns true if customer has an upcoming confirmed booking OR made a booking within last 24 hours.
     *
     * @param string $phone
     * @return bool
     */
    public function hasRecentBooking(string $phone): bool
    {
        return Booking::where('customer_phone', $phone)
            ->where('status', 'confirmed')
            ->where(function ($query) {
                // Upcoming bookings
                $query->where('booking_date', '>=', now()->toDateString())
                    // Or bookings created within last 24 hours
                    ->orWhere('created_at', '>=', now()->subHours(24));
            })
            ->exists();
    }

    /**
     * Get upcoming bookings needing reminders.
     * Finds confirmed bookings that are scheduled for tomorrow.
     *
     * @return Collection
     */
    public function getUpcomingReminders(): Collection
    {
        $tomorrow = now()->addDay()->toDateString();

        return Booking::needsReminder()  // status='confirmed' AND reminder_sent=false
            ->whereDate('booking_date', $tomorrow)
            ->with(['table', 'conversation'])
            ->get();
    }

    /**
     * Format booking confirmation message.
     * Uses merchant's custom template or falls back to default.
     *
     * @param Booking $booking
     * @return string
     */
    public function formatConfirmationMessage(Booking $booking, User $merchant): string
    {
        // Get merchant settings (conversation is linked to merchant)
        $merchantSettings = $merchant?->merchantSettings;

        // Use custom template or default
        $template = $merchantSettings?->confirmation_template;

        if (empty($template)) {
            // Default confirmation template
            $template = "✅ *Booking Confirmed!*\n\n" .
                "📅 Date: {date}\n" .
                "🕐 Time: {time}\n" .
                "👥 Guests: {pax}\n" .
                "🪑 Table: {table}\n\n" .
                "We look forward to seeing you, {name}!";
        }

        return str_replace(
            ['{name}', '{date}', '{time}', '{pax}', '{table}', '{phone}'],
            [
                $booking->customer_name,
                $booking->booking_date->format('l, F j, Y'),
                Carbon::parse($booking->booking_time)->format('g:i A'),
                $booking->pax,
                $booking->table->name ?? 'TBA',
                $booking->customer_phone,
            ],
            $template
        );
    }

    /**
     * Format booking reminder message.
     * Uses merchant's custom template or falls back to default.
     *
     * @param Booking $booking
     * @return string
     */
    public function formatReminderMessage(Booking $booking): string
    {
        // Get merchant settings
        $merchant = User::where('role', User::ROLE_MERCHANT)->first();
        $merchantSettings = $merchant?->merchantSettings;

        // Use custom template or default
        $template = $merchantSettings?->reminder_template;

        if (empty($template)) {
            // Default reminder template
            $template = "👋 Hi {name}! 👋\n\n" .
                "This is a reminder about your booking tomorrow:\n\n" .
                "📅 Date: {date}\n" .
                "🕐 Time: {time}\n" .
                "👥 Guests: {pax}\n" .

                "See you soon!";
        }

        return str_replace(
            ['{name}', '{date}', '{time}', '{pax}', '{table}', '{phone}'],
            [
                $booking->customer_name,
                $booking->booking_date->format('l, F j, Y'),
                Carbon::parse($booking->booking_time)->format('g:i A'),
                $booking->pax,
                $booking->table->name ?? 'TBA',
                $booking->customer_phone,
            ],
            $template
        );
    }

    /**
     * Check if a table has a conflicting booking.
     */
    protected function hasConflictingBooking(Table $table, Carbon $date, Carbon $startTime, Carbon $endTime): bool
    {
        return Booking::where('table_id', $table->id)
            ->where('booking_date', $date->format('Y-m-d'))
            ->where('status', 'confirmed')
            ->where(function ($query) use ($startTime, $endTime) {
                $start = $startTime->format('H:i:s');
                $end = $endTime->format('H:i:s');

                // Check for overlapping time slots
                $query->where(function ($q) use ($start, $end) {
                    $q->where('booking_time', '<', $end)
                        ->where('end_time', '>', $start);
                });
            })
            ->exists();
    }

    /**
     * Find alternative available times on a given date.
     */
    protected function findAlternativeTimes(string $date, int $pax): Collection
    {
        $settings = RestaurantSetting::getInstance();
        $alternatives = collect();

        $openingTime = $settings?->opening_time ?? '10:00';
        $closingTime = $settings?->closing_time ?? '22:00';
        $slotDuration = $settings?->slot_duration_minutes ?? 60;

        $opening = Carbon::parse($openingTime);
        $closing = Carbon::parse($closingTime);

        $currentTime = $opening->copy();

        while ($currentTime->copy()->addMinutes($slotDuration)->lte($closing)) {
            $availability = $this->checkAvailability($date, $currentTime->format('H:i'), $pax);

            if ($availability['available']) {
                $alternatives->push($currentTime->format('g:i A'));
            }

            $currentTime->addHour(); // Check every hour
        }

        return $alternatives->take(5); // Return max 5 alternatives
    }
}
