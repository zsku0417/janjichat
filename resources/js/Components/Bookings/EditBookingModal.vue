<script setup>
/**
 * EditBookingModal - Edit booking details
 */

import { watch, computed } from "vue";
import { useForm } from "@inertiajs/vue3";
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
    restaurantSettings: {
        type: Object,
        default: () => ({
            opening_time: "09:00",
            closing_time: "22:00",
        }),
    },
});

const emit = defineEmits(["close", "updated"]);

const form = useForm({
    booking_date: "",
    booking_time: "",
    pax: 2,
    special_request: "",
    status: "confirmed",
});

// Get today's date in YYYY-MM-DD format for min date validation
const todayDate = computed(() => {
    const today = new Date();
    return today.toISOString().split("T")[0];
});

// Check if the booking's date/time has passed
const isPastBooking = computed(() => {
    if (!props.booking) return false;

    const now = new Date();
    const bookingDate = new Date(props.booking.booking_date);
    const bookingTime = convertTo24Hour(props.booking.booking_time);

    if (bookingTime) {
        const [hours, minutes] = bookingTime.split(":");
        bookingDate.setHours(parseInt(hours), parseInt(minutes), 0, 0);
    }

    return bookingDate < now;
});

// Watch for booking changes to populate form
watch(
    () => props.booking,
    (booking) => {
        if (booking) {
            form.booking_date = booking.booking_date || "";
            // Convert time from "10:00 AM" format to "10:00" for input
            form.booking_time = convertTo24Hour(booking.booking_time) || "";
            form.pax = booking.pax || 2;
            form.special_request = booking.special_request || "";
            form.status = booking.status || "confirmed";
        }
    },
    { immediate: true }
);

// Helper to convert 12-hour time to 24-hour for input
const convertTo24Hour = (time12h) => {
    if (!time12h) return "";

    const match = time12h.match(/(\d+):(\d+)\s*(AM|PM)/i);
    if (!match) return time12h;

    let [, hours, minutes, period] = match;
    hours = parseInt(hours);

    if (period.toUpperCase() === "PM" && hours !== 12) {
        hours += 12;
    } else if (period.toUpperCase() === "AM" && hours === 12) {
        hours = 0;
    }

    return `${hours.toString().padStart(2, "0")}:${minutes}`;
};

const submitForm = () => {
    if (!props.booking) return;

    form.patch(route("bookings.update", props.booking.id), {
        preserveScroll: true,
        onSuccess: () => {
            emit("updated");
            emit("close");
        },
    });
};

const handleClose = () => {
    form.reset();
    form.clearErrors();
    emit("close");
};
</script>

<template>
    <BaseModal
        :show="show"
        title="Edit Booking"
        icon="edit"
        size="md"
        @close="handleClose"
    >
        <template #content>
            <form @submit.prevent="submitForm" id="editBookingForm">
                <div class="space-y-4">
                    <!-- Customer Info (Read-only) -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                    >
                        <div class="flex items-center gap-3">
                            <div
                                class="w-10 h-10 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-xl flex items-center justify-center"
                            >
                                <svg
                                    class="w-5 h-5 text-white"
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
                                    {{ booking?.customer_name }}
                                </h4>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{ booking?.customer_phone }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Date & Time -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Date
                            </label>
                            <input
                                v-model="form.booking_date"
                                type="date"
                                :min="todayDate"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                            <p
                                v-if="form.errors.booking_date"
                                class="mt-1 text-sm text-red-600 dark:text-red-400"
                            >
                                {{ form.errors.booking_date }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Time
                            </label>
                            <input
                                v-model="form.booking_time"
                                type="time"
                                :min="restaurantSettings.opening_time"
                                :max="restaurantSettings.closing_time"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                            <p
                                v-if="form.errors.booking_time"
                                class="mt-1 text-sm text-red-600 dark:text-red-400"
                            >
                                {{ form.errors.booking_time }}
                            </p>
                        </div>
                    </div>

                    <!-- Guests & Status -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Number of Guests
                            </label>
                            <input
                                v-model="form.pax"
                                type="number"
                                min="1"
                                max="50"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                            <p
                                v-if="form.errors.pax"
                                class="mt-1 text-sm text-red-600 dark:text-red-400"
                            >
                                {{ form.errors.pax }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Status
                            </label>
                            <select
                                v-model="form.status"
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            >
                                <option value="confirmed">Confirmed</option>
                                <option v-if="isPastBooking" value="completed">
                                    Completed
                                </option>
                                <option v-if="isPastBooking" value="no_show">
                                    No Show
                                </option>
                                <option value="cancelled">Cancelled</option>
                            </select>
                        </div>
                    </div>

                    <!-- Special Request -->
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Special Request
                        </label>
                        <textarea
                            v-model="form.special_request"
                            rows="3"
                            class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 resize-none"
                            placeholder="Any special requests..."
                        ></textarea>
                    </div>
                </div>
            </form>
        </template>

        <template #footer>
            <button
                type="button"
                @click="handleClose"
                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Cancel
            </button>
            <button
                type="submit"
                form="editBookingForm"
                :disabled="form.processing"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
            >
                {{ form.processing ? "Saving..." : "Save Changes" }}
            </button>
        </template>
    </BaseModal>
</template>
