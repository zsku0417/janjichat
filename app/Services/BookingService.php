<?php

namespace App\Services;

use App\Models\Booking;
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
     */
    public function getBookingFormTemplate(User $merchant): string
    {
        $settings = RestaurantSetting::getInstance();
        $restaurantName = $settings->name ?? $merchant->name ?? 'Our Restaurant';

        return <<<TEMPLATE
Welcome to {$restaurantName}! 🍽️

To make a table reservation, please fill in the form below:

👥 *Number of Guests (Pax):*

📅 *Date & Time:*
(e.g. 15-12-2024, 7:00pm)

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
        $openingTime = $settings->formatted_opening_time ?? '10:00 AM';
        $closingTime = $settings->formatted_closing_time ?? '10:00 PM';

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

IMPORTANT DATE CONTEXT:
- Today is {$currentDayOfWeek}, {$currentDate}
- Current date/time: {$currentDateTime}
- Use this to calculate relative dates (e.g., "tomorrow", "next Tuesday", "this weekend")
{$conversationContext}
Customer's LATEST message (this is what they sent NOW):
---
{$message}
---

Extract the following information. IMPORTANT: If information is not in the latest message but was provided in a PREVIOUS message in the conversation context above, USE THAT.

Return a JSON object with these fields:
- pax: number (number of guests) - check previous messages if not in latest
- datetime: string in "YYYY-MM-DD HH:mm" format - check previous messages if only correcting the date
- phone: string (phone number, use default if not provided)
- name: string (customer name, use default if not provided)  
- special_request: string or null - check previous messages if not in latest
- is_valid: boolean - true if required fields (pax, datetime) can be determined from latest or previous messages

If pax or datetime cannot be extracted from latest OR previous messages, return: {"is_valid": false, "reason": "explanation"}

Default phone if not provided: {$customerPhone}
Default name if not provided: {$customerName}

IMPORTANT: 
- Return ONLY valid JSON, no markdown, no explanation.
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
     * Check if a message looks like a booking attempt.
     */
    public function isBookingAttempt(string $message): bool
    {
        // Look for patterns that suggest a booking
        $bookingPatterns = [
            '/\b\d+\s*(pax|guests?|people|persons?)\b/i',
            '/\bpax\s*[:=]?\s*\d+/i',
            '/\bguests?\s*[:=]?\s*\d+/i',
            '/\bbook(ing)?.*table/i',
            '/\btable.*book/i',
            '/\breservation/i',
            '/\bspecial\s*request/i',
            '/\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4}/i',  // Date patterns
            '/\d{1,2}[:.]\d{2}\s*(am|pm)?/i',  // Time patterns
            '/\b(2|3|4|5|6|7|8|9|10|11|12)\s*(am|pm)/i',  // Simple time
            '/\bphone\s*[:=]?\s*[\d\s+()-]+/i',
            '/\bname\s*[:=]/i',
        ];

        $matchCount = 0;
        foreach ($bookingPatterns as $pattern) {
            if (preg_match($pattern, $message)) {
                $matchCount++;
            }
        }

        // Require at least 2 patterns to match (to reduce false positives)
        return $matchCount >= 2;
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
        $endTime = $bookingTime->copy()->addMinutes($settings->slot_duration_minutes);

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
        $opening = Carbon::parse($settings->opening_time);
        $closing = Carbon::parse($settings->closing_time);

        if (
            $bookingTime->format('H:i:s') < $opening->format('H:i:s') ||
            $endTime->format('H:i:s') > $closing->format('H:i:s')
        ) {
            return [
                'available' => false,
                'tables' => collect(),
                'message' => "Sorry, we are only open from {$settings->formatted_opening_time} to {$settings->formatted_closing_time}. Please choose a time within our business hours.",
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
        $endTime = $bookingTime->copy()->addMinutes($settings->slot_duration_minutes);

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

        $booking = Booking::create([
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
                $endTime = $bookingTime->copy()->addMinutes($settings->slot_duration_minutes);

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
                $data['end_time'] = $bookingTime->addMinutes($settings->slot_duration_minutes)->format('H:i:s');
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
     *
     * @return Collection
     */
    public function getUpcomingReminders(): Collection
    {
        $settings = RestaurantSetting::getInstance();
        $reminderTime = now()->addHours($settings->reminder_hours_before);

        return Booking::needsReminder()
            ->whereDate('booking_date', $reminderTime->toDateString())
            ->whereTime('booking_time', '<=', $reminderTime->format('H:i:s'))
            ->whereTime('booking_time', '>', now()->format('H:i:s'))
            ->with(['table', 'conversation'])
            ->get();
    }

    /**
     * Format booking confirmation message.
     *
     * @param Booking $booking
     * @return string
     */
    public function formatConfirmationMessage(Booking $booking): string
    {
        $settings = RestaurantSetting::getInstance();
        $template = $settings->confirmation_template;

        return str_replace(
            ['{name}', '{date}', '{time}', '{pax}', '{table}'],
            [
                $booking->customer_name,
                $booking->booking_date->format('l, F j, Y'),
                Carbon::parse($booking->booking_time)->format('g:i A'),
                $booking->pax,
                $booking->table->name,
            ],
            $template
        );
    }

    /**
     * Format booking reminder message.
     *
     * @param Booking $booking
     * @return string
     */
    public function formatReminderMessage(Booking $booking): string
    {
        $settings = RestaurantSetting::getInstance();
        $template = $settings->reminder_template;

        return str_replace(
            ['{name}', '{date}', '{time}', '{pax}', '{table}'],
            [
                $booking->customer_name,
                $booking->booking_date->format('l, F j, Y'),
                Carbon::parse($booking->booking_time)->format('g:i A'),
                $booking->pax,
                $booking->table->name,
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

        $opening = Carbon::parse($settings->opening_time);
        $closing = Carbon::parse($settings->closing_time);
        $slotDuration = $settings->slot_duration_minutes;

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
