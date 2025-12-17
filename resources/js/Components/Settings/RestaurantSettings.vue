<script setup>
import { useForm } from "@inertiajs/vue3";
import InputError from "@/Components/InputError.vue";

const props = defineProps({
    settings: Object,
});

const emit = defineEmits(["saved"]);

// Restaurant settings form
const form = useForm({
    opening_time: props.settings?.opening_time || "09:00",
    closing_time: props.settings?.closing_time || "22:00",
    slot_duration_minutes: props.settings?.slot_duration_minutes || 60,
});

const saveSettings = () => {
    form.patch(route("settings.restaurant.update"), {
        onSuccess: () => emit("saved"),
    });
};
</script>

<template>
    <form @submit.prevent="saveSettings" class="space-y-6">
        <!-- Section Header -->
        <div class="mb-6">
            <h3
                class="text-lg font-semibold text-gray-900 dark:text-white mb-2"
            >
                Booking Time Settings
            </h3>
            <p class="text-sm text-gray-500 dark:text-gray-400">
                Configure the time window when customers can make reservations.
                These settings control booking acceptance, not your operating
                hours (which can be documented in your knowledge base).
            </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Earliest Booking Time -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    Earliest Booking Time
                </label>
                <input
                    v-model="form.opening_time"
                    type="time"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                />
                <InputError :message="form.errors.opening_time" class="mt-1" />
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    The earliest time customers can book (e.g., 10:00 AM means
                    no bookings before 10 AM)
                </p>
            </div>

            <!-- Latest Booking Time -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    Latest Booking Time
                </label>
                <input
                    v-model="form.closing_time"
                    type="time"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                />
                <InputError :message="form.errors.closing_time" class="mt-1" />
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    The latest time customers can book (e.g., 10:00 PM means the
                    last booking can start at 10 PM)
                </p>
            </div>

            <!-- Booking Slot Duration -->
            <div class="md:col-span-2">
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    Booking Slot Duration (minutes)
                </label>
                <input
                    v-model.number="form.slot_duration_minutes"
                    type="number"
                    min="15"
                    step="15"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                />
                <InputError
                    :message="form.errors.slot_duration_minutes"
                    class="mt-1"
                />
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    The default duration to reserve a table for each booking
                    (e.g., 60 = 1 hour, 120 = 2 hours). This prevents
                    overlapping reservations.
                </p>
            </div>
        </div>

        <div class="flex justify-end">
            <button
                type="submit"
                :disabled="form.processing"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
            >
                {{ form.processing ? "Saving..." : "Save Restaurant Settings" }}
            </button>
        </div>
    </form>
</template>
