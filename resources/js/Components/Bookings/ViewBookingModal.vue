<script setup>
/**
 * ViewBookingModal - Display booking details in a read-only modal
 */

import BaseModal from "@/Components/BaseModal.vue";

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    booking: {
        type: Object,
        default: null,
    },
});

const emit = defineEmits(["close", "edit"]);

const getStatusColor = (status) => {
    switch (status) {
        case "confirmed":
            return "bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300";
        case "cancelled":
            return "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300";
        case "completed":
            return "bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300";
        case "no_show":
            return "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300";
        default:
            return "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300";
    }
};
</script>

<template>
    <BaseModal
        :show="show"
        title="Booking Details"
        icon="view"
        size="md"
        @close="emit('close')"
    >
        <template #content>
            <div v-if="booking" class="space-y-4">
                <!-- Customer Info -->
                <div class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4">
                    <div class="flex items-center gap-3 mb-3">
                        <div
                            class="w-12 h-12 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-xl flex items-center justify-center"
                        >
                            <svg
                                class="w-6 h-6 text-white"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                                />
                            </svg>
                        </div>
                        <div>
                            <h4
                                class="font-semibold text-gray-900 dark:text-white"
                            >
                                {{ booking.customer_name }}
                            </h4>
                            <p class="text-sm text-gray-500 dark:text-gray-400">
                                {{ booking.customer_phone }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Booking Details Grid -->
                <div class="grid grid-cols-2 gap-4">
                    <!-- Date -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                    >
                        <p
                            class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1"
                        >
                            Date
                        </p>
                        <p class="font-semibold text-gray-900 dark:text-white">
                            {{ booking.booking_date_formatted }}
                        </p>
                    </div>

                    <!-- Time -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                    >
                        <p
                            class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1"
                        >
                            Time
                        </p>
                        <p class="font-semibold text-gray-900 dark:text-white">
                            {{ booking.booking_time }}
                        </p>
                    </div>

                    <!-- Table -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                    >
                        <p
                            class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1"
                        >
                            Table
                        </p>
                        <p class="font-semibold text-gray-900 dark:text-white">
                            {{ booking.table_name }}
                        </p>
                    </div>

                    <!-- Guests -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                    >
                        <p
                            class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1"
                        >
                            Guests
                        </p>
                        <p class="font-semibold text-gray-900 dark:text-white">
                            {{ booking.pax }} pax
                        </p>
                    </div>
                </div>

                <!-- Status -->
                <div class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4">
                    <p
                        class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-2"
                    >
                        Status
                    </p>
                    <span
                        :class="[
                            getStatusColor(booking.status),
                            'px-3 py-1.5 text-sm font-medium rounded-full capitalize inline-block',
                        ]"
                    >
                        {{ booking.status }}
                    </span>
                </div>

                <!-- Special Request -->
                <div class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4">
                    <p
                        class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-2"
                    >
                        Special Request
                    </p>
                    <p
                        class="text-gray-700 dark:text-gray-300 whitespace-pre-wrap"
                    >
                        {{ booking.special_request || "—" }}
                    </p>
                </div>

                <!-- Created By -->
                <div class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4">
                    <p
                        class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1"
                    >
                        Created By
                    </p>
                    <p
                        class="font-semibold text-gray-900 dark:text-white flex items-center gap-2"
                    >
                        <span v-if="booking.created_by === 'admin'">👤</span>
                        <span v-else>📱</span>
                        {{
                            booking.created_by === "admin"
                                ? "Admin"
                                : "Customer (WhatsApp)"
                        }}
                    </p>
                </div>
            </div>
        </template>

        <template #footer>
            <button
                type="button"
                @click="emit('close')"
                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Close
            </button>
            <button
                v-if="booking?.status === 'confirmed'"
                type="button"
                @click="emit('edit', booking)"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all"
            >
                Edit Booking
            </button>
        </template>
    </BaseModal>
</template>
