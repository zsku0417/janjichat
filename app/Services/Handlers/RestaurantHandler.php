<?php

namespace App\Services\Handlers;

use App\Models\Booking;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use App\Models\RestaurantSetting;
use App\Services\BookingService;
use App\Services\RAGService;
use App\Services\WhatsAppService;
use Illuminate\Support\Facades\Log;
use Exception;
use Carbon\Carbon;

/**
 * Handler for Restaurant business type.
 * Manages all booking-related conversation logic.
 */
class RestaurantHandler implements BusinessHandlerInterface
{
    protected BookingService $booking;
    protected RAGService $rag;
    protected WhatsAppService $whatsApp;

    /**
     * Callback to send response (injected by ConversationHandler)
     */
    protected $sendResponseCallback;

    public function __construct(
        BookingService $booking,
        RAGService $rag,
        WhatsAppService $whatsApp
    ) {
        $this->booking = $booking;
        $this->rag = $rag;
        $this->whatsApp = $whatsApp;
    }

    /**
     * Set the callback for sending responses.
     */
    public function setSendResponseCallback(callable $callback): void
    {
        $this->sendResponseCallback = $callback;
    }

    /**
     * Send a response using the callback.
     */
    protected function sendResponse(Conversation $conversation, string $content): void
    {
        if ($this->sendResponseCallback) {
            call_user_func($this->sendResponseCallback, $conversation, $content);
        }
    }

    /**
     * Process an incoming message for restaurant business type.
     */
    public function processMessage(Conversation $conversation, Message $message, string $content, User $merchant): void
    {
        // Check if this looks like a filled booking form
        if ($this->booking->isBookingAttempt($content)) {
            $this->handleBookingAttempt($conversation, $content, $merchant);
            return;
        }

        // Detect intent with full conversation context
        $intentResult = $this->rag->detectIntent($content, $conversation, 'restaurant');
        $intent = $intentResult['intent'];
        $entities = $intentResult['entities'];

        Log::info('Restaurant intent detected', [
            'conversation_id' => $conversation->id,
            'intent' => $intent,
            'entities' => $entities,
        ]);

        // Handle based on intent
        switch ($intent) {
            case 'greeting':
            case 'booking_request':
                $this->handleGreeting($conversation, $merchant);
                break;

            case 'booking_inquiry':
                $this->handleBookingInquiry($conversation);
                break;

            case 'booking_modify':
                // Pass the raw content, not entities, so we only accept NEW details
                $this->handleBookingModify($conversation, $content);
                break;

            case 'booking_cancel':
                $this->handleBookingCancel($conversation);
                break;

            case 'general_question':
            default:
                // Check if they might want to book based on keywords
                if ($this->looksLikeBusinessIntent($content)) {
                    $this->handleGreeting($conversation, $merchant);
                } else {
                    // Return false to indicate this should be handled by general question handler
                    // The ConversationHandler will handle this
                    return;
                }
                break;
        }
    }

    /**
     * Handle greeting for restaurant - show booking form.
     */
    public function handleGreeting(Conversation $conversation, User $merchant): void
    {
        $bookingForm = $this->booking->getBookingFormTemplate($merchant);

        $this->sendResponse($conversation, $bookingForm);

        // Set context to await booking
        $conversation->setContext(Conversation::CONTEXT_BOOKING_FLOW, [
            'step' => 'awaiting_form',
        ]);
    }

    /**
     * Handle contextual responses specific to restaurant bookings.
     * INTENT-FIRST: Always detect intent first, only use context if intent matches.
     */
    public function handleContextualResponse(Conversation $conversation, string $content, array $context): bool
    {
        $contextType = $context['type'];
        $contextData = $context['data'] ?? [];

        // INTENT-FIRST: Detect intent from current message
        $intentResult = $this->rag->detectIntent($content, $conversation, 'restaurant');
        $intent = $intentResult['intent'];
        $entities = $intentResult['entities'];

        Log::info('Intent-first context check', [
            'conversation_id' => $conversation->id,
            'context_type' => $contextType,
            'detected_intent' => $intent,
        ]);

        // Determine if intent is compatible with current context
        $bookingRelatedIntents = ['greeting', 'booking_request'];
        $isBookingFormInput = $this->booking->isBookingAttempt($content);

        switch ($contextType) {
            case Conversation::CONTEXT_AWAITING_BOOKING_CONFIRMATION:
                // This is handled by detectResponseType in ConversationHandler
                return false;

            case Conversation::CONTEXT_BOOKING_FLOW:
                // If customer provides booking form data, continue booking
                if ($isBookingFormInput) {
                    return $this->continueBookingFlow($conversation, $content, $contextData);
                }

                // If intent is still booking-related OR providing booking details
                if (in_array($intent, $bookingRelatedIntents) || !empty($entities['date']) || !empty($entities['time']) || !empty($entities['pax'])) {
                    return $this->continueBookingFlow($conversation, $content, $contextData);
                }

                // INTENT CHANGED - clear context and let main handler process
                Log::info('Intent changed, clearing booking context', [
                    'conversation_id' => $conversation->id,
                    'new_intent' => $intent,
                ]);
                $conversation->clearContext();
                return false; // Let main processMessage handle the new intent

            case Conversation::CONTEXT_BOOKING_SELECTION:
                // User needs to select which booking to modify/cancel
                return $this->handleBookingSelection($conversation, $content, $contextData);

            case Conversation::CONTEXT_AWAITING_CANCELLATION_CONFIRMATION:
                // This is handled by detectResponseType in ConversationHandler
                return false;
        }

        return false;
    }

    /**
     * Get keywords that indicate booking intent.
     */
    public function getIntentKeywords(): array
    {
        return ['book', 'reserve', 'reservation', 'table', 'booking', 'tempah', 'nak book', 'meja', '预订', '订位', 'pax', 'guests', 'people'];
    }

    /**
     * Check if content looks like customer wants to book.
     */
    public function looksLikeBusinessIntent(string $content): bool
    {
        $normalized = strtolower($content);

        foreach ($this->getIntentKeywords() as $keyword) {
            if (str_contains($normalized, $keyword)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Handle a filled booking form attempt.
     */
    public function handleBookingAttempt(Conversation $conversation, string $content, ?User $merchant): void
    {
        // Parse the booking using AI - include conversation for context
        $parsedBooking = $this->booking->parseBookingFromMessage(
            $content,
            $conversation->phone_number ?? $conversation->whatsapp_id,
            $conversation->customer_name,
            $conversation  // Pass conversation for context
        );

        if (!$parsedBooking || !($parsedBooking['is_valid'] ?? false)) {
            $reason = $parsedBooking['reason'] ?? 'Could not parse booking details.';
            $response = "Sorry, I couldn't process your reservation. " . $reason . "\n\n" .
                "Please make sure to include:\n" .
                "• Number of guests (pax)\n" .
                "• Date and time\n\n" .
                "Would you like me to show the booking form again?";

            $this->sendResponse($conversation, $response);
            return;
        }

        // Try to create the booking
        try {
            $booking = $this->booking->createBookingFromParsed($parsedBooking, $conversation);

            if (!$booking) {
                $response = "Sorry, there was an error creating your reservation. Please try again or contact us directly.";
                $this->sendResponse($conversation, $response);
                return;
            }

            // Send confirmation
            $confirmation = $this->booking->formatConfirmationMessage($booking);
            $this->sendResponse($conversation, $confirmation);

            // Clear the booking context
            $conversation->clearContext();
        } catch (Exception $e) {
            // Availability error - show the error message
            $this->sendResponse($conversation, $e->getMessage());
        }
    }

    /**
     * Handle booking request with entities.
     */
    public function handleBookingRequest(Conversation $conversation, array $entities): void
    {
        $phone = $conversation->phone_number;

        // Check what information we have
        $name = $entities['name'] ?? $conversation->customer_name;
        $date = $entities['date'] ?? null;
        $time = $entities['time'] ?? null;
        $pax = $entities['pax'] ?? null;
        $specialRequest = $entities['special_request'] ?? null;

        // If we have all required information
        if ($name && $date && $time && $pax) {
            try {
                // Check availability
                $availability = $this->booking->checkAvailability($date, $time, (int) $pax);

                if (!$availability['available']) {
                    $this->sendResponse($conversation, $availability['message']);
                    return;
                }

                // Create booking
                $booking = $this->booking->createBooking([
                    'conversation_id' => $conversation->id,
                    'customer_name' => $name,
                    'customer_phone' => $phone,
                    'booking_date' => $date,
                    'booking_time' => $time,
                    'pax' => (int) $pax,
                    'special_request' => $specialRequest,
                    'created_by' => 'customer',
                ]);

                // Update conversation with customer name if not set
                if (!$conversation->customer_name) {
                    $conversation->update(['customer_name' => $name]);
                }

                $confirmation = $this->booking->formatConfirmationMessage($booking);
                $this->sendResponse($conversation, $confirmation);

            } catch (Exception $e) {
                $this->sendResponse($conversation, "Sorry, I couldn't complete your booking: " . $e->getMessage());
            }
        } else {
            // Ask for missing information
            $this->askForBookingDetails($conversation, $name, $date, $time, $pax);
        }
    }

    /**
     * Ask for missing booking details.
     */
    protected function askForBookingDetails(Conversation $conversation, ?string $name, ?string $date, ?string $time, ?int $pax): void
    {
        $missing = [];

        if (!$name)
            $missing[] = 'your name';
        if (!$date)
            $missing[] = 'the date';
        if (!$time)
            $missing[] = 'the time';
        if (!$pax)
            $missing[] = 'the number of guests';

        $message = "I'd be happy to help you make a reservation! 📅\n\n";
        $message .= "Could you please provide " . implode(', ', $missing) . "?\n\n";
        $message .= "For example: \"Book a table for 4 people on December 25th at 7pm under the name John\"";

        $this->sendResponse($conversation, $message);
    }

    /**
     * Handle booking inquiry.
     * Uses AI to craft natural responses showing booking details.
     */
    public function handleBookingInquiry(Conversation $conversation): void
    {
        $bookings = $this->booking->getCustomerBookings($conversation->phone_number);

        if ($bookings->isEmpty()) {
            // Set context so "Yes" response will start booking flow
            $conversation->setContext(Conversation::CONTEXT_AWAITING_BOOKING_CONFIRMATION, [
                'prompted_at' => now()->toDateTimeString(),
            ]);

            // Let AI craft the response
            $response = $this->rag->generateContextualResponse(
                'booking_inquiry',
                'checking my booking',
                [
                    'bookings' => [],
                    'action_needed' => 'No bookings found - offer to make a new reservation',
                ],
                $conversation,
                'restaurant'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Format bookings for AI context
        $bookingData = $bookings->map(function ($booking) {
            return [
                'id' => $booking->id,
                'date' => $booking->booking_date->format('l, F j, Y'),
                'time' => Carbon::parse($booking->booking_time)->format('g:i A'),
                'pax' => $booking->pax,
                'table' => $booking->table->name ?? 'Assigned',
                'special_request' => $booking->special_request,
            ];
        })->toArray();

        // Let AI craft a natural response
        $response = $this->rag->generateContextualResponse(
            'booking_inquiry',
            'checking my booking',
            ['bookings' => $bookingData],
            $conversation,
            'restaurant'
        );
        $this->sendResponse($conversation, $response);
    }

    /**
     * Handle booking modification request.
     * Uses AI to craft natural responses with booking context.
     * Asks user to choose if multiple active bookings exist.
     */
    public function handleBookingModify(Conversation $conversation, string $content): void
    {
        $bookings = $this->booking->getCustomerBookings($conversation->phone_number);

        if ($bookings->isEmpty()) {
            $response = $this->rag->generateContextualResponse(
                'booking_modify',
                $content,
                [
                    'bookings' => [],
                    'action_result' => 'No upcoming bookings found for this customer',
                ],
                $conversation,
                'restaurant'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Format all bookings for AI context
        $bookingData = $bookings->map(function ($booking, $index) {
            return [
                'number' => $index + 1,
                'id' => $booking->id,
                'date' => $booking->booking_date->format('l, F j, Y'),
                'time' => Carbon::parse($booking->booking_time)->format('g:i A'),
                'pax' => $booking->pax,
                'table' => $booking->table->name ?? 'Assigned',
                'special_request' => $booking->special_request,
            ];
        })->toArray();

        // Check if user has already selected a booking from context
        $context = $conversation->getContext();
        $selectedBookingId = null;

        if ($context && $context['type'] === Conversation::CONTEXT_BOOKING_SELECTION) {
            $selectedBookingId = $context['data']['booking_id'] ?? null;
        }

        // If multiple bookings and no selection yet, ask user to choose
        if ($bookings->count() > 1 && !$selectedBookingId) {
            // Set context to await booking selection
            $bookingIds = $bookings->pluck('id')->toArray();
            $conversation->setContext(Conversation::CONTEXT_BOOKING_SELECTION, [
                'action' => 'modify',
                'booking_ids' => $bookingIds,
            ]);

            $response = $this->rag->generateContextualResponse(
                'booking_modify',
                $content,
                [
                    'bookings' => $bookingData,
                    'action_needed' => 'Multiple bookings found. Ask customer which booking they want to modify by number (1, 2, 3, etc.)',
                ],
                $conversation,
                'restaurant'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Use selected booking or first booking
        $booking = $selectedBookingId
            ? $bookings->firstWhere('id', $selectedBookingId)
            : $bookings->first();

        if (!$booking) {
            $this->sendResponse($conversation, "I couldn't find that booking. Please try again.");
            return;
        }

        // Clear selection context
        if ($selectedBookingId) {
            $conversation->clearContext();
        }

        // Parse the current message for explicit new details
        $newDetails = $this->parseModificationDetails($content);

        Log::info('Modification request', [
            'conversation_id' => $conversation->id,
            'booking_id' => $booking->id,
            'content' => $content,
            'parsed_details' => $newDetails,
        ]);

        // If customer provided new details, try to modify
        if (!empty($newDetails)) {
            try {
                $updatedBooking = $this->booking->modifyBooking($booking, $newDetails);

                $updatedData = [
                    'id' => $updatedBooking->id,
                    'date' => $updatedBooking->booking_date->format('l, F j, Y'),
                    'time' => Carbon::parse($updatedBooking->booking_time)->format('g:i A'),
                    'pax' => $updatedBooking->pax,
                    'table' => $updatedBooking->table->name ?? 'Assigned',
                    'special_request' => $updatedBooking->special_request,
                ];

                $response = $this->rag->generateContextualResponse(
                    'booking_modify',
                    $content,
                    [
                        'bookings' => [$updatedData],
                        'action_result' => 'Booking successfully updated',
                    ],
                    $conversation,
                    'restaurant'
                );
                $this->sendResponse($conversation, $response);
                return;

            } catch (Exception $e) {
                Log::error('Booking modification failed', [
                    'conversation_id' => $conversation->id,
                    'booking_id' => $booking->id,
                    'error' => $e->getMessage(),
                ]);

                $response = $this->rag->generateContextualResponse(
                    'booking_modify',
                    $content,
                    [
                        'bookings' => $bookingData,
                        'action_result' => 'Error: ' . $e->getMessage(),
                    ],
                    $conversation,
                    'restaurant'
                );
                $this->sendResponse($conversation, $response);
                return;
            }
        }

        // No new details provided - ask what they want to change
        $currentBookingData = [
            'id' => $booking->id,
            'date' => $booking->booking_date->format('l, F j, Y'),
            'time' => Carbon::parse($booking->booking_time)->format('g:i A'),
            'pax' => $booking->pax,
            'table' => $booking->table->name ?? 'Assigned',
            'special_request' => $booking->special_request,
        ];

        $response = $this->rag->generateContextualResponse(
            'booking_modify',
            $content,
            [
                'bookings' => [$currentBookingData],
                'action_needed' => 'Ask customer what they would like to change (date, time, or number of guests)',
            ],
            $conversation,
            'restaurant'
        );
        $this->sendResponse($conversation, $response);
    }

    /**
     * Handle booking selection when user has multiple bookings.
     * Processes user input like "1", "2", "first", etc.
     */
    protected function handleBookingSelection(Conversation $conversation, string $content, array $contextData): bool
    {
        $bookingIds = $contextData['booking_ids'] ?? [];
        $action = $contextData['action'] ?? 'modify';

        if (empty($bookingIds)) {
            $conversation->clearContext();
            return false;
        }

        // Try to extract selection number from message
        $selection = null;

        // Check for number patterns: "1", "#1", "number 1", "first", etc.
        if (preg_match('/^#?(\d+)$/', trim($content), $match)) {
            $selection = (int) $match[1];
        } elseif (preg_match('/(first|1st)/i', $content)) {
            $selection = 1;
        } elseif (preg_match('/(second|2nd)/i', $content)) {
            $selection = 2;
        } elseif (preg_match('/(third|3rd)/i', $content)) {
            $selection = 3;
        } elseif (preg_match('/number\s*(\d+)/i', $content, $match)) {
            $selection = (int) $match[1];
        }

        // Validate selection
        if ($selection && $selection >= 1 && $selection <= count($bookingIds)) {
            $selectedBookingId = $bookingIds[$selection - 1];

            // Clear selection context and proceed with action
            if ($action === 'cancel') {
                // Set confirmation context and proceed
                $conversation->setContext(Conversation::CONTEXT_AWAITING_CANCELLATION_CONFIRMATION, [
                    'booking_id' => $selectedBookingId,
                ]);

                $booking = Booking::find($selectedBookingId);
                if ($booking) {
                    $response = $this->rag->generateContextualResponse(
                        'booking_cancel',
                        $content,
                        [
                            'bookings' => [
                                [
                                    'id' => $booking->id,
                                    'date' => $booking->booking_date->format('l, F j, Y'),
                                    'time' => Carbon::parse($booking->booking_time)->format('g:i A'),
                                    'pax' => $booking->pax,
                                ]
                            ],
                            'action_needed' => 'Ask customer to confirm cancellation of this booking',
                        ],
                        $conversation,
                        'restaurant'
                    );
                    $this->sendResponse($conversation, $response);
                    return true;
                }
            } else {
                // Modify action - store selected booking in context for modification
                $conversation->setContext(Conversation::CONTEXT_BOOKING_SELECTION, [
                    'action' => 'modify',
                    'booking_id' => $selectedBookingId,
                    'booking_ids' => $bookingIds,
                ]);

                // Re-call handleBookingModify with the selected booking
                $this->handleBookingModify($conversation, $content);
                return true;
            }
        }

        // Selection not recognized - ask again
        $bookings = Booking::whereIn('id', $bookingIds)->with('table')->get();
        $bookingData = $bookings->map(function ($booking, $index) {
            return [
                'number' => $index + 1,
                'id' => $booking->id,
                'date' => $booking->booking_date->format('l, F j, Y'),
                'time' => Carbon::parse($booking->booking_time)->format('g:i A'),
                'pax' => $booking->pax,
            ];
        })->toArray();

        $response = $this->rag->generateContextualResponse(
            $action === 'cancel' ? 'booking_cancel' : 'booking_modify',
            $content,
            [
                'bookings' => $bookingData,
                'action_needed' => "Customer input not recognized. Ask them to reply with a number (1, 2, 3) to select which booking to {$action}.",
            ],
            $conversation,
            'restaurant'
        );
        $this->sendResponse($conversation, $response);
        return true;
    }

    /**
     * Parse modification details from the current message.
     * Only returns values that are explicitly provided in this message.
     */
    protected function parseModificationDetails(string $content): array
    {
        $changes = [];

        // Check if message actually contains booking details, not just "reschedule"
        $rescheduleOnly = preg_match('/^(i\s+)?(want\s+to\s+|wish\s+to\s+|would\s+like\s+to\s+)?(reschedule|change|modify|update)(\s+my\s+booking)?\.?$/i', trim($content));

        if ($rescheduleOnly) {
            return [];
        }

        // Try to extract date patterns
        if (preg_match('/(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})/', $content, $dateMatch)) {
            $day = $dateMatch[1];
            $month = $dateMatch[2];
            $year = $dateMatch[3];
            if (strlen($year) == 2)
                $year = '20' . $year;
            $changes['booking_date'] = "{$year}-{$month}-{$day}";
        } elseif (preg_match('/(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s*(\d{4}))?/i', $content, $dateMatch)) {
            $monthName = $dateMatch[1];
            $day = $dateMatch[2];
            $year = $dateMatch[3] ?? date('Y');
            $changes['booking_date'] = Carbon::parse("{$monthName} {$day} {$year}")->format('Y-m-d');
        } elseif (preg_match('/(tomorrow|next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday))/i', $content, $dateMatch)) {
            $changes['booking_date'] = Carbon::parse($dateMatch[0])->format('Y-m-d');
        }

        // Try to extract time patterns
        if (preg_match('/(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i', $content, $timeMatch)) {
            $hour = (int) $timeMatch[1];
            $minutes = $timeMatch[2] ?? '00';
            $period = strtolower($timeMatch[3]);
            if ($period === 'pm' && $hour < 12)
                $hour += 12;
            if ($period === 'am' && $hour == 12)
                $hour = 0;
            $changes['booking_time'] = sprintf('%02d:%s:00', $hour, $minutes);
        } elseif (preg_match('/(\d{1,2}):(\d{2})/', $content, $timeMatch)) {
            $changes['booking_time'] = sprintf('%02d:%s:00', $timeMatch[1], $timeMatch[2]);
        }

        // Try to extract pax
        if (preg_match('/(\d+)\s*(pax|people|persons?|guests?)/i', $content, $paxMatch)) {
            $changes['pax'] = (int) $paxMatch[1];
        } elseif (preg_match('/for\s+(\d+)/i', $content, $paxMatch)) {
            $changes['pax'] = (int) $paxMatch[1];
        }

        return $changes;
    }

    /**
     * Handle booking cancellation.
     * Asks user to choose if multiple active bookings exist.
     */
    public function handleBookingCancel(Conversation $conversation): void
    {
        // First try to find bookings by conversation_id (most reliable)
        $bookings = $this->booking->getBookingsByConversation($conversation->id);

        // If no bookings found by conversation, try by phone number
        if ($bookings->isEmpty() && $conversation->phone_number) {
            $bookings = $this->booking->getCustomerBookings($conversation->phone_number);
        }

        if ($bookings->isEmpty()) {
            $conversation->setContext(Conversation::CONTEXT_AWAITING_BOOKING_CONFIRMATION, [
                'prompted_at' => now()->toDateTimeString(),
            ]);

            $response = $this->rag->generateContextualResponse(
                'booking_cancel',
                'cancel my booking',
                [
                    'bookings' => [],
                    'action_result' => 'No upcoming bookings found to cancel',
                ],
                $conversation,
                'restaurant'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Format bookings for AI display
        $bookingData = $bookings->map(function ($booking, $index) {
            return [
                'number' => $index + 1,
                'id' => $booking->id,
                'date' => $booking->booking_date->format('l, F j, Y'),
                'time' => Carbon::parse($booking->booking_time)->format('g:i A'),
                'pax' => $booking->pax,
                'table' => $booking->table->name ?? 'Assigned',
            ];
        })->toArray();

        // If multiple bookings, ask user to choose which one to cancel
        if ($bookings->count() > 1) {
            $conversation->setContext(Conversation::CONTEXT_BOOKING_SELECTION, [
                'action' => 'cancel',
                'booking_ids' => $bookings->pluck('id')->toArray(),
            ]);

            $response = $this->rag->generateContextualResponse(
                'booking_cancel',
                'cancel my booking',
                [
                    'bookings' => $bookingData,
                    'action_needed' => 'Multiple bookings found. Ask customer which booking they want to cancel by number (1, 2, 3, etc.)',
                ],
                $conversation,
                'restaurant'
            );
            $this->sendResponse($conversation, $response);
            return;
        }

        // Single booking - ask for confirmation
        $booking = $bookings->first();
        $conversation->setContext(Conversation::CONTEXT_AWAITING_CANCELLATION_CONFIRMATION, [
            'booking_id' => $booking->id,
        ]);

        $response = $this->rag->generateContextualResponse(
            'booking_cancel',
            'cancel my booking',
            [
                'bookings' => [$bookingData[0]],
                'action_needed' => 'Ask customer to confirm cancellation',
            ],
            $conversation,
            'restaurant'
        );
        $this->sendResponse($conversation, $response);
    }

    /**
     * Start a new booking flow by asking for details.
     */
    public function startBookingFlow(Conversation $conversation): void
    {
        $settings = RestaurantSetting::getInstance();

        $response = "Great! Let's make a reservation. 📅\n\n" .
            "Please tell me:\n" .
            "• When would you like to book? (e.g., tomorrow, Dec 15)\n" .
            "• What time? (e.g., 7pm)\n" .
            "• How many people?";

        $conversation->setContext(Conversation::CONTEXT_BOOKING_FLOW, [
            'step' => 'collecting_details',
            'date' => null,
            'time' => null,
            'pax' => null,
        ]);

        $this->sendResponse($conversation, $response);
    }

    /**
     * Continue an ongoing booking flow.
     * Uses AI to craft responses in the customer's language.
     * Note: Intent check is done in handleContextualResponse before this is called.
     */
    public function continueBookingFlow(Conversation $conversation, string $content, array $contextData): bool
    {
        // Extract entities from the message
        $intentResult = $this->rag->detectIntent($content, $conversation, 'restaurant');
        $entities = $intentResult['entities'];

        // Merge with existing context data
        $date = $entities['date'] ?? $contextData['date'] ?? null;
        $time = $entities['time'] ?? $contextData['time'] ?? null;
        $pax = $entities['pax'] ?? $contextData['pax'] ?? null;
        $name = $entities['name'] ?? $conversation->customer_name;

        // If we have all required information
        if ($date && $time && $pax) {
            $conversation->clearContext();
            $this->handleBookingRequest($conversation, [
                'name' => $name,
                'date' => $date,
                'time' => $time,
                'pax' => $pax,
            ]);
            return true;
        }

        // Update context with what we have so far
        $conversation->setContext(Conversation::CONTEXT_BOOKING_FLOW, [
            'step' => 'collecting_details',
            'date' => $date,
            'time' => $time,
            'pax' => $pax,
        ]);

        // Build what we still need
        $missing = [];
        if (!$date)
            $missing[] = "date";
        if (!$time)
            $missing[] = "time";
        if (!$pax)
            $missing[] = "number of guests";

        // Use AI to ask for missing info in customer's language
        $response = $this->rag->generateContextualResponse(
            'booking_request',
            $content,
            [
                'action_needed' => 'Ask for missing booking details: ' . implode(', ', $missing),
                'settings' => [
                    'already_have_date' => $date ? 'Yes: ' . $date : 'No',
                    'already_have_time' => $time ? 'Yes: ' . $time : 'No',
                    'already_have_pax' => $pax ? 'Yes: ' . $pax : 'No',
                ],
            ],
            $conversation,
            'restaurant'
        );
        $this->sendResponse($conversation, $response);
        return true;
    }

    /**
     * Confirm booking cancellation.
     */
    public function confirmBookingCancellation(Conversation $conversation, int $bookingId): void
    {
        $booking = Booking::find($bookingId);
        if ($booking && $booking->status !== 'cancelled') {
            $this->booking->cancelBooking($booking);
            $this->sendResponse($conversation, "Your booking has been cancelled. ✅ We hope to see you again soon!");
        } else {
            $this->sendResponse($conversation, "I couldn't find that booking or it's already been cancelled.");
        }
    }
}
