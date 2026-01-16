<?php

namespace App\Console\Commands;

use App\Jobs\SendOrderReminderJob;
use App\Models\Order;
use Illuminate\Console\Command;

class SendOrderReminders extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'orders:send-reminders';

    /**
     * The console command description.
     */
    protected $description = 'Send reminder messages for upcoming orders scheduled for tomorrow';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Checking for orders needing reminders...');

        // Find orders:
        // - scheduled for tomorrow
        // - reminder not yet sent
        // - status is processing (payment verified, being prepared)
        $tomorrow = now()->addDay()->startOfDay();
        $dayAfter = now()->addDays(2)->startOfDay();

        $orders = Order::where('reminder_sent', false)
            ->where('status', Order::STATUS_PROCESSING)
            ->whereBetween('requested_datetime', [$tomorrow, $dayAfter])
            ->with(['items', 'user.merchantSettings'])
            ->get();

        if ($orders->isEmpty()) {
            $this->info('No reminders to send.');
            return Command::SUCCESS;
        }

        $this->info("Found {$orders->count()} orders needing reminders.");

        foreach ($orders as $order) {
            SendOrderReminderJob::dispatch($order);
            $this->line("  - Queued reminder for order #{$order->code} ({$order->customer_phone})");
        }

        $this->info('All reminders queued successfully.');
        return Command::SUCCESS;
    }
}
