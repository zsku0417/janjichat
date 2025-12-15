<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import Tab from "@/Components/Tab.vue";
import DeleteModal from "@/Components/DeleteModal.vue";
import { Head, useForm, router } from "@inertiajs/vue3";
import { ref, computed } from "vue";

const props = defineProps({
    businessType: String,
    merchantSettings: Object,
    restaurantSettings: Object,
    orderTrackingSettings: Object,
    tables: Array,
});

// Active tab
const activeTab = ref("general");

// Business type checks (must be defined before tabs)
const isRestaurant = computed(() => props.businessType === "restaurant");
const isOrderTracking = computed(() => props.businessType === "order_tracking");

// Tab configuration
const tabs = computed(() => {
    const baseTabs = [{ key: "general", label: "General" }];

    if (isRestaurant.value) {
        baseTabs.push({ key: "restaurant", label: "Restaurant" });
        baseTabs.push({
            key: "tables",
            label: "Tables",
            badge: props.tables?.length || 0,
        });
    }

    if (isOrderTracking.value) {
        baseTabs.push({ key: "order-tracking", label: "Order Tracking" });
    }

    return baseTabs;
});

// Merchant settings form (shared by all business types)
const merchantForm = useForm({
    business_name: props.merchantSettings.business_name || "",
    greeting_message: props.merchantSettings.greeting_message || "",
    ai_tone: props.merchantSettings.ai_tone || "",
    confirmation_template: props.merchantSettings.confirmation_template || "",
    reminder_template: props.merchantSettings.reminder_template || "",
    reminder_hours_before: props.merchantSettings.reminder_hours_before || 24,
});

const saveMerchantSettings = () => {
    merchantForm.patch(route("settings.merchant.update"));
};

// Restaurant settings form
const restaurantForm = useForm({
    opening_time: props.restaurantSettings?.opening_time || "09:00",
    closing_time: props.restaurantSettings?.closing_time || "22:00",
    slot_duration_minutes:
        props.restaurantSettings?.slot_duration_minutes || 60,
});

const saveRestaurantSettings = () => {
    restaurantForm.patch(route("settings.restaurant.update"));
};

// Order tracking settings form
const orderTrackingForm = useForm({
    pickup_address: props.orderTrackingSettings?.pickup_address || "",
    order_prefix: props.orderTrackingSettings?.order_prefix || "ORD",
});

const saveOrderTrackingSettings = () => {
    orderTrackingForm.patch(route("settings.order-tracking.update"));
};

// Table management (restaurant only)
const showTableModal = ref(false);
const editingTable = ref(null);

const tableForm = useForm({
    name: "",
    capacity: 4,
    is_active: true,
});

const openTableModal = (table = null) => {
    editingTable.value = table;
    if (table) {
        tableForm.name = table.name;
        tableForm.capacity = table.capacity;
        tableForm.is_active = table.is_active;
    } else {
        tableForm.reset();
        tableForm.capacity = 4;
        tableForm.is_active = true;
    }
    showTableModal.value = true;
};

const saveTable = () => {
    if (editingTable.value) {
        tableForm.patch(
            route("settings.tables.update", editingTable.value.id),
            {
                onSuccess: () => {
                    showTableModal.value = false;
                    tableForm.reset();
                },
            }
        );
    } else {
        tableForm.post(route("settings.tables.store"), {
            onSuccess: () => {
                showTableModal.value = false;
                tableForm.reset();
            },
        });
    }
};

// Delete modal state
const showDeleteModal = ref(false);
const tableToDelete = ref(null);
const isDeleting = ref(false);

const openDeleteModal = (table) => {
    tableToDelete.value = table;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    tableToDelete.value = null;
};

const confirmDeleteTable = () => {
    if (!tableToDelete.value) return;

    isDeleting.value = true;
    router.delete(route("settings.tables.destroy", tableToDelete.value.id), {
        onFinish: () => {
            isDeleting.value = false;
            closeDeleteModal();
        },
    });
};
</script>

<template>
    <Head title="Settings" />

    <AuthenticatedLayout>
        <template #header>
            <div>
                <h2 class="text-2xl font-bold text-gradient">Settings</h2>
                <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                    Manage your business settings and preferences
                </p>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <div
                    class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700"
                >
                    <!-- Tabs -->
                    <div class="px-6 pt-6">
                        <Tab v-model="activeTab" :tabs="tabs" />
                    </div>

                    <!-- Tab Content -->
                    <div class="p-6">
                        <!-- General Settings Tab -->
                        <div v-if="activeTab === 'general'">
                            <form
                                @submit.prevent="saveMerchantSettings"
                                class="space-y-6"
                            >
                                <div>
                                    <label
                                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                    >
                                        Business Name
                                    </label>
                                    <input
                                        v-model="merchantForm.business_name"
                                        type="text"
                                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                    />
                                </div>

                                <div>
                                    <label
                                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                    >
                                        Greeting Message
                                    </label>
                                    <textarea
                                        v-model="merchantForm.greeting_message"
                                        rows="2"
                                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                        placeholder="Hello! How can I help you today?"
                                    ></textarea>
                                </div>

                                <div>
                                    <label
                                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                    >
                                        AI Tone / Personality
                                    </label>
                                    <textarea
                                        v-model="merchantForm.ai_tone"
                                        rows="3"
                                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                        placeholder="Describe how the AI should communicate with customers..."
                                    ></textarea>
                                </div>

                                <div class="flex justify-end">
                                    <button
                                        type="submit"
                                        :disabled="merchantForm.processing"
                                        class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
                                    >
                                        {{
                                            merchantForm.processing
                                                ? "Saving..."
                                                : "Save General Settings"
                                        }}
                                    </button>
                                </div>
                            </form>
                        </div>

                        <!-- Restaurant Settings Tab -->
                        <div v-if="activeTab === 'restaurant' && isRestaurant">
                            <form
                                @submit.prevent="saveRestaurantSettings"
                                class="space-y-6"
                            >
                                <div
                                    class="grid grid-cols-1 md:grid-cols-2 gap-6"
                                >
                                    <div>
                                        <label
                                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                        >
                                            Opening Time
                                        </label>
                                        <input
                                            v-model="
                                                restaurantForm.opening_time
                                            "
                                            type="time"
                                            class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>

                                    <div>
                                        <label
                                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                        >
                                            Closing Time
                                        </label>
                                        <input
                                            v-model="
                                                restaurantForm.closing_time
                                            "
                                            type="time"
                                            class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>

                                    <div class="md:col-span-2">
                                        <label
                                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                        >
                                            Booking Slot Duration (minutes)
                                        </label>
                                        <input
                                            v-model.number="
                                                restaurantForm.slot_duration_minutes
                                            "
                                            type="number"
                                            min="15"
                                            step="15"
                                            class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>
                                </div>

                                <div class="flex justify-end">
                                    <button
                                        type="submit"
                                        :disabled="restaurantForm.processing"
                                        class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
                                    >
                                        {{
                                            restaurantForm.processing
                                                ? "Saving..."
                                                : "Save Restaurant Settings"
                                        }}
                                    </button>
                                </div>
                            </form>
                        </div>

                        <!-- Tables Tab (Restaurant only) -->
                        <div v-if="activeTab === 'tables' && isRestaurant">
                            <div class="space-y-4">
                                <div class="flex items-center justify-between">
                                    <h3
                                        class="text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        Manage Tables
                                    </h3>
                                    <button
                                        @click="openTableModal()"
                                        class="px-4 py-2 bg-gradient-to-r from-primary-500 to-secondary-500 text-white rounded-xl font-medium shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all text-sm"
                                    >
                                        + Add Table
                                    </button>
                                </div>

                                <div
                                    class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
                                >
                                    <div
                                        v-for="table in tables"
                                        :key="table.id"
                                        class="p-4 bg-gray-50 dark:bg-slate-700 rounded-xl flex items-center justify-between"
                                    >
                                        <div>
                                            <p
                                                class="font-medium text-gray-900 dark:text-white"
                                            >
                                                {{ table.name }}
                                            </p>
                                            <p
                                                class="text-sm text-gray-500 dark:text-gray-400"
                                            >
                                                Capacity: {{ table.capacity }}
                                            </p>
                                            <span
                                                :class="[
                                                    table.is_active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300',
                                                    'inline-flex px-2 py-0.5 text-xs font-medium rounded-full mt-1',
                                                ]"
                                            >
                                                {{
                                                    table.is_active
                                                        ? "Active"
                                                        : "Inactive"
                                                }}
                                            </span>
                                        </div>
                                        <div class="flex gap-2">
                                            <button
                                                @click="openTableModal(table)"
                                                class="p-2 text-gray-600 dark:text-gray-400 hover:text-primary-500 transition-colors"
                                            >
                                                <svg
                                                    class="w-5 h-5"
                                                    fill="none"
                                                    viewBox="0 0 24 24"
                                                    stroke="currentColor"
                                                >
                                                    <path
                                                        stroke-linecap="round"
                                                        stroke-linejoin="round"
                                                        stroke-width="2"
                                                        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                                                    />
                                                </svg>
                                            </button>
                                            <button
                                                @click="openDeleteModal(table)"
                                                class="p-2 text-gray-600 dark:text-gray-400 hover:text-red-500 transition-colors"
                                            >
                                                <svg
                                                    class="w-5 h-5"
                                                    fill="none"
                                                    viewBox="0 0 24 24"
                                                    stroke="currentColor"
                                                >
                                                    <path
                                                        stroke-linecap="round"
                                                        stroke-linejoin="round"
                                                        stroke-width="2"
                                                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                                                    />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <div
                                    v-if="!tables || tables.length === 0"
                                    class="text-center py-12 text-gray-500 dark:text-gray-400"
                                >
                                    No tables added yet. Click "Add Table" to
                                    create one.
                                </div>
                            </div>
                        </div>

                        <!-- Order Tracking Settings Tab -->
                        <div
                            v-if="
                                activeTab === 'order-tracking' &&
                                isOrderTracking
                            "
                        >
                            <form
                                @submit.prevent="saveOrderTrackingSettings"
                                class="space-y-6"
                            >
                                <div>
                                    <label
                                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                    >
                                        Pickup Address
                                    </label>
                                    <textarea
                                        v-model="
                                            orderTrackingForm.pickup_address
                                        "
                                        rows="3"
                                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                        placeholder="Enter your business pickup address..."
                                    ></textarea>
                                </div>

                                <div>
                                    <label
                                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                    >
                                        Order Prefix
                                    </label>
                                    <input
                                        v-model="orderTrackingForm.order_prefix"
                                        type="text"
                                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                        placeholder="ORD"
                                    />
                                    <p
                                        class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        Orders will be numbered as
                                        {{
                                            orderTrackingForm.order_prefix
                                        }}-001,
                                        {{
                                            orderTrackingForm.order_prefix
                                        }}-002, etc.
                                    </p>
                                </div>

                                <div class="flex justify-end">
                                    <button
                                        type="submit"
                                        :disabled="orderTrackingForm.processing"
                                        class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
                                    >
                                        {{
                                            orderTrackingForm.processing
                                                ? "Saving..."
                                                : "Save Order Tracking Settings"
                                        }}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Table Modal (when adding/editing) -->
        <div
            v-if="showTableModal"
            class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            @click.self="showTableModal = false"
        >
            <div
                class="bg-white dark:bg-slate-800 rounded-2xl shadow-xl max-w-md w-full"
            >
                <div class="p-6">
                    <h3
                        class="text-lg font-semibold text-gray-900 dark:text-white mb-4"
                    >
                        {{ editingTable ? "Edit Table" : "Add Table" }}
                    </h3>
                    <form @submit.prevent="saveTable" class="space-y-4">
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Table Name
                            </label>
                            <input
                                v-model="tableForm.name"
                                type="text"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                placeholder="e.g., Table 1"
                            />
                        </div>

                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Capacity
                            </label>
                            <input
                                v-model.number="tableForm.capacity"
                                type="number"
                                min="1"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                        </div>

                        <div class="flex items-center">
                            <input
                                v-model="tableForm.is_active"
                                type="checkbox"
                                class="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                            />
                            <label
                                class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                            >
                                Active
                            </label>
                        </div>

                        <div class="flex justify-end gap-3 mt-6">
                            <button
                                type="button"
                                @click="showTableModal = false"
                                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                :disabled="tableForm.processing"
                                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
                            >
                                {{
                                    tableForm.processing ? "Saving..." : "Save"
                                }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Delete Modal -->
        <DeleteModal
            :show="showDeleteModal"
            title="Delete Table"
            :message="`Are you sure you want to delete '${tableToDelete?.name}'?`"
            :processing="isDeleting"
            @close="closeDeleteModal"
            @confirm="confirmDeleteTable"
        />
    </AuthenticatedLayout>
</template>
