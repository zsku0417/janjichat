<?php

namespace App\Jobs;

use App\Models\Order;
use App\Services\OrderService;
use App\Services\WhatsAppService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendOrderReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Create a new job instance.
     */
    public function __construct(
        public Order $order
    ) {
    }

    /**
     * Execute the job.
     */
    public function handle(
        OrderService $orderService,
        WhatsAppService $whatsAppService
    ): void {
        // Skip if reminder already sent or order is cancelled/completed
        if ($this->order->reminder_sent) {
            Log::info('Skipping order reminder - already sent', [
                'order_id' => $this->order->id,
            ]);
            return;
        }

        if (in_array($this->order->status, [Order::STATUS_CANCELLED, Order::STATUS_COMPLETED])) {
            Log::info('Skipping order reminder - order is cancelled or completed', [
                'order_id' => $this->order->id,
                'status' => $this->order->status,
            ]);
            return;
        }

        try {
            // Load the order's merchant
            $this->order->load('user');
            $merchant = $this->order->user;

            if (!$merchant || !$merchant->hasWhatsAppConfigured()) {
                Log::warning('Skipping order reminder - merchant has no WhatsApp configured', [
                    'order_id' => $this->order->id,
                    'merchant_id' => $merchant?->id,
                ]);
                return;
            }

            // Use the order's merchant WhatsApp credentials
            $whatsAppService->setMerchant($merchant);

            // Get the reminder message from OrderService
            $message = $orderService->getOrderReminderMessage($this->order);

            // Send via WhatsApp
            $whatsAppService->sendMessage($this->order->customer_phone, $message);

            // Mark reminder as sent
            $this->order->update(['reminder_sent' => true]);

            Log::info('Order reminder sent', [
                'order_id' => $this->order->id,
                'order_code' => $this->order->code,
                'phone' => $this->order->customer_phone,
                'merchant_id' => $merchant->id,
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to send order reminder', [
                'order_id' => $this->order->id,
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }
    }
}
