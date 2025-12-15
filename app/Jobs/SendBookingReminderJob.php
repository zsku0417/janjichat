<?php

namespace App\Jobs;

use App\Models\Booking;
use App\Services\BookingService;
use App\Services\WhatsAppService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendBookingReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Create a new job instance.
     */
    public function __construct(
        public Booking $booking
    ) {
    }

    /**
     * Execute the job.
     */
    public function handle(
        BookingService $bookingService,
        WhatsAppService $whatsAppService
    ): void {
        if (!$this->booking->shouldSendReminder()) {
            Log::info('Skipping reminder - no longer needed', [
                'booking_id' => $this->booking->id,
            ]);
            return;
        }

        try {
            $message = $bookingService->formatReminderMessage($this->booking);
            $whatsAppService->sendMessage($this->booking->customer_phone, $message);

            $this->booking->update(['reminder_sent' => true]);

            Log::info('Booking reminder sent', [
                'booking_id' => $this->booking->id,
                'phone' => $this->booking->customer_phone,
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to send booking reminder', [
                'booking_id' => $this->booking->id,
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }
    }
}
