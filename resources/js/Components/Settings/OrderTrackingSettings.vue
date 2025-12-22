<script setup>
import { useForm } from "@inertiajs/vue3";

const props = defineProps({
    settings: Object,
});

const emit = defineEmits(["saved"]);

// Order tracking settings form
const form = useForm({
    pickup_address: props.settings?.pickup_address || "",
    order_prefix: props.settings?.order_prefix || "ORD",
    payment_message: props.settings?.payment_message || "",
});

const saveSettings = () => {
    form.patch(route("settings.order-tracking.update"), {
        onSuccess: () => emit("saved"),
    });
};
</script>

<template>
    <form @submit.prevent="saveSettings" class="space-y-6">
        <!-- Pickup Address -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
                Pickup Address
            </label>
            <textarea
                v-model="form.pickup_address"
                rows="3"
                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                placeholder="Enter your business pickup address..."
            ></textarea>
        </div>

        <!-- Order Prefix -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
                Order Prefix
            </label>
            <input
                v-model="form.order_prefix"
                type="text"
                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                placeholder="ORD"
            />
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                Orders will be numbered as {{ form.order_prefix }}-001,
                {{ form.order_prefix }}-002, etc.
            </p>
        </div>

        <!-- Payment Message -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
                Payment Instructions
            </label>
            <textarea
                v-model="form.payment_message"
                rows="4"
                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                placeholder="Bank: ABC Bank
Account Name: Your Business Name
Account Number: 1234567890

Or scan QR code..."
            ></textarea>
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                This message will be shown after order confirmation. Use
                <code class="px-1 py-0.5 bg-gray-100 dark:bg-slate-600 rounded"
                    >{amount}</code
                >
                to insert the payment amount.
            </p>
        </div>

        <!-- Save Button -->
        <div class="flex justify-end">
            <button
                type="submit"
                :disabled="form.processing"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
            >
                {{
                    form.processing
                        ? "Saving..."
                        : "Save Order Tracking Settings"
                }}
            </button>
        </div>
    </form>
</template>
