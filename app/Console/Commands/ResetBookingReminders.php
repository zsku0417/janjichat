<?php

namespace App\Console\Commands;

use App\Models\Booking;
use App\Models\Message;
use Illuminate\Console\Command;

class ResetBookingReminders extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'bookings:reset-reminders {--all : Reset all bookings, not just tomorrow}';

    /**
     * The console command description.
     */
    protected $description = 'Reset reminder_sent flag and delete reminder messages from database';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        if ($this->option('all')) {
            // Get all bookings with reminder_sent = true
            $bookings = Booking::where('reminder_sent', true)->with('conversation')->get();
        } else {
            // Get only tomorrow's bookings
            $tomorrow = now()->addDay()->toDateString();
            $bookings = Booking::where('reminder_sent', true)
                ->whereDate('booking_date', $tomorrow)
                ->with('conversation')
                ->get();
        }

        $messagesDeleted = 0;

        foreach ($bookings as $booking) {
            if ($booking->conversation) {
                // Delete reminder messages from this conversation
                // Reminder messages contain "Reminder" or "提醒" (Chinese) in the content
                $deleted = Message::where('conversation_id', $booking->conversation->id)
                    ->where('direction', 'outbound')
                    ->where(function ($query) {
                        $query->where('content', 'like', '%Reminder%')
                            ->orWhere('content', 'like', '%提醒%')
                            ->orWhere('content', 'like', '%reminder%');
                    })
                    ->delete();

                $messagesDeleted += $deleted;
            }

            // Reset the reminder_sent flag
            $booking->update(['reminder_sent' => false]);
        }

        $this->info("Reset reminder_sent for {$bookings->count()} bookings.");
        $this->info("Deleted {$messagesDeleted} reminder messages from database.");

        return Command::SUCCESS;
    }
}
