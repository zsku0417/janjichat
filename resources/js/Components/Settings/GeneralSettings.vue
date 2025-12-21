<script setup>
import { useForm } from "@inertiajs/vue3";
import { computed } from "vue";

const props = defineProps({
    settings: Object,
    businessType: String,
});

const emit = defineEmits(["saved"]);

// Check business type for conditional fields
const isRestaurant = computed(() => props.businessType === "restaurant");
const isOrderTracking = computed(() => props.businessType === "order_tracking");

// Dynamic labels based on business type
const labels = computed(() => {
    if (isOrderTracking.value) {
        return {
            formTemplate: "Order Form Template",
            formTemplatePlaceholder: "Enter your order form template...",
            formTemplateHelp:
                "The template shown to customers when they want to place an order. Leave empty to use the default template.",
            confirmationTemplate: "Order Confirmation Template",
            confirmationPlaceholder:
                "Your order is confirmed! Order #: {order_code}, Total: {total}",
            confirmationHelp:
                "Message sent to customers after successful order. Use placeholders: {name}, {order_code}, {total}, {items}, {datetime}, {fulfillment}",
            reminderTemplate: "Order Reminder Template",
            reminderPlaceholder:
                "Reminder: Your order #{order_code} is scheduled for {datetime}.",
            reminderHelp:
                "Reminder message sent before order fulfillment. Use placeholders: {name}, {order_code}, {total}, {datetime}, {fulfillment}",
            reminderHoursLabel: "Reminder Hours Before Order",
            reminderHoursHelp:
                "How many hours before the order fulfillment time should the reminder be sent? (Default: 24 hours)",
        };
    }
    // Default: Restaurant labels
    return {
        formTemplate: "Booking Form Template",
        formTemplatePlaceholder: "Enter your booking form template...",
        formTemplateHelp:
            "The template shown to customers when they want to make a booking. Leave empty to use the default template.",
        confirmationTemplate: "Booking Confirmation Template",
        confirmationPlaceholder:
            "Your booking is confirmed! Date: {date}, Time: {time}, Pax: {pax}",
        confirmationHelp:
            "Message sent to customers after successful booking. Use placeholders: {name}, {date}, {time}, {pax}, {table}, {phone}",
        reminderTemplate: "Booking Reminder Template",
        reminderPlaceholder:
            "Reminder: You have a booking tomorrow at {time} for {pax} people.",
        reminderHelp:
            "Reminder message sent before booking. Use placeholders: {name}, {date}, {time}, {pax}, {table}, {phone}",
        reminderHoursLabel: "Reminder Hours Before Booking",
        reminderHoursHelp:
            "How many hours before the booking should the reminder be sent? (Default: 24 hours)",
    };
});

// Merchant settings form
const form = useForm({
    business_name: props.settings?.business_name || "",
    greeting_message: props.settings?.greeting_message || "",
    ai_tone: props.settings?.ai_tone || "",
    booking_form_template: props.settings?.booking_form_template || "",
    confirmation_template: props.settings?.confirmation_template || "",
    reminder_template: props.settings?.reminder_template || "",
    reminder_hours_before: props.settings?.reminder_hours_before || 24,
    email_on_escalation: props.settings?.email_on_escalation ?? true,
    notification_email: props.settings?.notification_email || "",
});

const saveSettings = () => {
    form.patch(route("settings.merchant.update"), {
        onSuccess: () => emit("saved"),
    });
};
</script>

<template>
    <form @submit.prevent="saveSettings" class="space-y-6">
        <!-- Business Name (Full Width) -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
                Business Name
            </label>
            <input
                v-model="form.business_name"
                type="text"
                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
            />
        </div>

        <!-- Row 1: Greeting Message + AI Tone -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Greeting Message -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    Greeting Message
                </label>
                <textarea
                    v-model="form.greeting_message"
                    rows="4"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                    placeholder="Hello! How can I help you today?"
                ></textarea>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    This is the first message sent to customers when they
                    initialize a conversation with your business.
                </p>
            </div>

            <!-- AI Tone -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    AI Tone / Personality
                </label>
                <textarea
                    v-model="form.ai_tone"
                    rows="4"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                    placeholder="Describe how the AI should communicate with customers..."
                ></textarea>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    Define the personality and tone of your AI assistant.
                </p>
            </div>
        </div>

        <!-- Row 2: Form Template + Confirmation Template -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Form Template -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    {{ labels.formTemplate }}
                </label>
                <textarea
                    v-model="form.booking_form_template"
                    rows="6"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 font-mono text-sm"
                    :placeholder="labels.formTemplatePlaceholder"
                ></textarea>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    {{ labels.formTemplateHelp }}
                </p>
            </div>

            <!-- Confirmation Template -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    {{ labels.confirmationTemplate }}
                </label>
                <textarea
                    v-model="form.confirmation_template"
                    rows="6"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 font-mono text-sm"
                    :placeholder="labels.confirmationPlaceholder"
                ></textarea>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    {{ labels.confirmationHelp }}
                </p>
            </div>
        </div>

        <!-- Row 3: Reminder Template + Reminder Hours -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Reminder Template -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    {{ labels.reminderTemplate }}
                </label>
                <textarea
                    v-model="form.reminder_template"
                    rows="4"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 font-mono text-sm"
                    :placeholder="labels.reminderPlaceholder"
                ></textarea>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    {{ labels.reminderHelp }}
                </p>
            </div>

            <!-- Reminder Hours -->
            <div>
                <label
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                    {{ labels.reminderHoursLabel }}
                </label>
                <input
                    v-model.number="form.reminder_hours_before"
                    type="number"
                    min="1"
                    max="168"
                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                />
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    {{ labels.reminderHoursHelp }}
                </p>
            </div>
        </div>

        <!-- Email Notification Settings -->
        <div class="border-t border-gray-200 dark:border-slate-700 pt-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
                📧 Email Notifications
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Email Toggle -->
                <div class="flex items-start gap-4">
                    <div class="flex h-6 items-center">
                        <input
                            v-model="form.email_on_escalation"
                            type="checkbox"
                            class="h-4 w-4 rounded border-gray-300 text-primary-600 focus:ring-primary-600"
                        />
                    </div>
                    <div>
                        <label
                            class="text-sm font-medium text-gray-900 dark:text-white"
                        >
                            Email me when conversation escalates
                        </label>
                        <p
                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                        >
                            Receive email when AI cannot answer a question or
                            customer requests human support.
                        </p>
                    </div>
                </div>

                <!-- Notification Email -->
                <div>
                    <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                        Notification Email
                    </label>
                    <input
                        v-model="form.notification_email"
                        type="email"
                        placeholder="Leave empty to use your account email"
                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                        :disabled="!form.email_on_escalation"
                        :class="{ 'opacity-50': !form.email_on_escalation }"
                    />
                    <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Email to receive escalation notifications. Includes last
                        10 messages and direct link.
                    </p>
                </div>
            </div>
        </div>

        <!-- Save Button -->
        <div class="flex justify-end">
            <button
                type="submit"
                :disabled="form.processing"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
            >
                {{ form.processing ? "Saving..." : "Save General Settings" }}
            </button>
        </div>
    </form>
</template>
