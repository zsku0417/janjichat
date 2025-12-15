<?php

namespace App\Console\Commands;

use App\Jobs\SendBookingReminderJob;
use App\Services\BookingService;
use Illuminate\Console\Command;

class SendBookingReminders extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'bookings:send-reminders';

    /**
     * The console command description.
     */
    protected $description = 'Send reminder messages for upcoming bookings';

    /**
     * Execute the console command.
     */
    public function handle(BookingService $bookingService): int
    {
        $this->info('Checking for bookings needing reminders...');

        $bookings = $bookingService->getUpcomingReminders();

        if ($bookings->isEmpty()) {
            $this->info('No reminders to send.');
            return Command::SUCCESS;
        }

        $this->info("Found {$bookings->count()} bookings needing reminders.");

        foreach ($bookings as $booking) {
            SendBookingReminderJob::dispatch($booking);
            $this->line("  - Queued reminder for booking #{$booking->id}");
        }

        $this->info('All reminders queued successfully.');
        return Command::SUCCESS;
    }
}
