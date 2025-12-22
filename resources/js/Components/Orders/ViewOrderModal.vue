<script setup>
/**
 * ViewOrderModal - Display order details in a modal with improved layout
 */

import { computed, ref } from "vue";
import { router } from "@inertiajs/vue3";
import BaseModal from "@/Components/BaseModal.vue";
import DeleteModal from "@/Components/DeleteModal.vue";

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    order: {
        type: Object,
        default: null,
    },
    statuses: {
        type: Object,
        default: () => ({
            pending_payment: "Pending Payment",
            processing: "Processing",
            completed: "Completed",
            cancelled: "Cancelled",
        }),
    },
});

const emit = defineEmits(["close", "updated"]);

// Cancel modal state
const showCancelModal = ref(false);
const isCancelling = ref(false);

const getStatusColor = (status) => {
    const colors = {
        pending_payment:
            "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 border-amber-200 dark:border-amber-800",
        processing:
            "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 border-blue-200 dark:border-blue-800",
        completed:
            "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300 border-green-200 dark:border-green-800",
        cancelled:
            "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300 border-red-200 dark:border-red-800",
    };
    return (
        colors[status] ||
        "bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300"
    );
};

const updateStatus = (newStatus) => {
    if (!props.order) return;

    router.patch(
        route("orders.update-status", props.order.id),
        { status: newStatus },
        {
            preserveScroll: true,
            onSuccess: () => {
                emit("updated");
                emit("close");
            },
        }
    );
};

const openCancelModal = () => {
    showCancelModal.value = true;
};

const closeCancelModal = () => {
    showCancelModal.value = false;
};

const confirmCancelOrder = () => {
    if (!props.order) return;

    isCancelling.value = true;
    router.post(
        route("orders.cancel", props.order.id),
        {},
        {
            onSuccess: () => {
                isCancelling.value = false;
                closeCancelModal();
                emit("updated");
            },
            onFinish: () => {
                isCancelling.value = false;
            },
        }
    );
};

const formatPrice = (price) => {
    return "RM " + Number(price || 0).toFixed(2);
};

const formatDate = (date) => {
    if (!date) return "—";
    return new Date(date).toLocaleDateString("en-GB", {
        day: "numeric",
        month: "short",
        year: "numeric",
    });
};

const formatDateTime = (date) => {
    if (!date) return "—";
    return new Date(date).toLocaleString("en-MY", {
        year: "numeric",
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
    });
};

const itemsCount = computed(() => {
    return (
        props.order?.items?.reduce((sum, item) => sum + item.quantity, 0) || 0
    );
});
</script>

<template>
    <BaseModal
        :show="show"
        :title="order?.code || `Order #${order?.id || ''}`"
        icon="view"
        customWidth="max-w-[900px]"
        @close="emit('close')"
    >
        <template #content>
            <div v-if="order" class="space-y-6">
                <!-- Header with Status and Date -->
                <div
                    class="flex items-center justify-between bg-gradient-to-r from-gray-50 to-gray-100 dark:from-slate-800 dark:to-slate-700 rounded-2xl p-5"
                >
                    <div class="flex items-center gap-4">
                        <span
                            :class="[
                                getStatusColor(order.status),
                                'px-5 py-2.5 text-sm font-semibold rounded-full border',
                            ]"
                        >
                            {{ statuses[order.status] || order.status }}
                        </span>
                        <div class="text-sm text-gray-500 dark:text-gray-400">
                            <span class="font-medium">Created:</span>
                            {{ formatDateTime(order.created_at) }}
                        </div>
                    </div>
                    <div class="text-right">
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Total Amount
                        </p>
                        <p
                            class="text-3xl font-bold text-primary-600 dark:text-primary-400"
                        >
                            {{ formatPrice(order.total_amount) }}
                        </p>
                    </div>
                </div>

                <!-- Two Column Layout -->
                <div class="grid grid-cols-2 gap-6">
                    <!-- Left Column: Customer & Delivery -->
                    <div class="space-y-4">
                        <!-- Customer Info -->
                        <div
                            class="bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-gray-100 dark:border-slate-700"
                        >
                            <h3
                                class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-4"
                            >
                                Customer Information
                            </h3>
                            <div class="flex items-start gap-4">
                                <div
                                    class="w-14 h-14 bg-gradient-to-br from-cyan-400 to-primary-500 rounded-2xl flex items-center justify-center text-white font-bold text-xl flex-shrink-0"
                                >
                                    {{
                                        order.customer_name
                                            ?.charAt(0)
                                            ?.toUpperCase() || "?"
                                    }}
                                </div>
                                <div class="flex-1 min-w-0">
                                    <h4
                                        class="text-lg font-semibold text-gray-900 dark:text-white truncate"
                                    >
                                        {{ order.customer_name }}
                                    </h4>
                                    <a
                                        :href="`tel:${order.customer_phone}`"
                                        class="text-primary-600 dark:text-primary-400 hover:underline font-medium"
                                    >
                                        {{ order.customer_phone }}
                                    </a>
                                </div>
                            </div>
                        </div>

                        <!-- Fulfillment Details -->
                        <div
                            class="bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-gray-100 dark:border-slate-700"
                        >
                            <h3
                                class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-4"
                            >
                                Fulfillment Details
                            </h3>
                            <div class="space-y-4">
                                <div class="flex items-center gap-3">
                                    <div
                                        class="w-10 h-10 rounded-xl flex items-center justify-center text-2xl"
                                        :class="
                                            order.fulfillment_type === 'pickup'
                                                ? 'bg-orange-100 dark:bg-orange-900/30'
                                                : 'bg-blue-100 dark:bg-blue-900/30'
                                        "
                                    >
                                        {{
                                            order.fulfillment_type === "pickup"
                                                ? "🏪"
                                                : "🚚"
                                        }}
                                    </div>
                                    <div>
                                        <p
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            Type
                                        </p>
                                        <p
                                            class="font-semibold text-gray-900 dark:text-white capitalize"
                                        >
                                            {{ order.fulfillment_type }}
                                        </p>
                                    </div>
                                </div>
                                <div class="flex items-center gap-3">
                                    <div
                                        class="w-10 h-10 bg-purple-100 dark:bg-purple-900/30 rounded-xl flex items-center justify-center text-2xl"
                                    >
                                        📅
                                    </div>
                                    <div>
                                        <p
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            Requested Time
                                        </p>
                                        <p
                                            class="font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{
                                                formatDateTime(
                                                    order.requested_datetime
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Delivery Address -->
                        <div
                            v-if="order.delivery_address"
                            class="bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-gray-100 dark:border-slate-700"
                        >
                            <h3
                                class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3"
                            >
                                Delivery Address
                            </h3>
                            <p
                                class="text-gray-900 dark:text-white leading-relaxed"
                            >
                                {{ order.delivery_address }}
                            </p>
                        </div>

                        <!-- Special Notes -->
                        <div
                            v-if="order.special_notes"
                            class="bg-amber-50 dark:bg-amber-900/20 rounded-2xl p-5 border border-amber-200 dark:border-amber-800"
                        >
                            <h3
                                class="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase tracking-wider mb-3 flex items-center gap-2"
                            >
                                <svg
                                    class="w-4 h-4"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
                                    />
                                </svg>
                                Special Notes
                            </h3>
                            <p
                                class="text-amber-800 dark:text-amber-200 whitespace-pre-wrap"
                            >
                                {{ order.special_notes }}
                            </p>
                        </div>
                    </div>

                    <!-- Right Column: Order Items -->
                    <div
                        class="bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-gray-100 dark:border-slate-700 flex flex-col"
                    >
                        <h3
                            class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-4 flex items-center justify-between"
                        >
                            <span>Order Items</span>
                            <span class="text-primary-600 dark:text-primary-400"
                                >{{ itemsCount }} items</span
                            >
                        </h3>

                        <!-- Items List -->
                        <div
                            class="flex-1 overflow-y-auto max-h-[280px] space-y-3 pr-1"
                        >
                            <div
                                v-for="item in order.items"
                                :key="item.id"
                                class="flex items-center gap-4 p-3 bg-gray-50 dark:bg-slate-700/50 rounded-xl"
                            >
                                <div
                                    class="w-12 h-12 bg-gradient-to-br from-primary-100 to-secondary-100 dark:from-primary-900/30 dark:to-secondary-900/30 rounded-xl flex items-center justify-center flex-shrink-0"
                                >
                                    <svg
                                        class="w-6 h-6 text-primary-500"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                                        />
                                    </svg>
                                </div>
                                <div class="flex-1 min-w-0">
                                    <p
                                        class="font-medium text-gray-900 dark:text-white truncate"
                                    >
                                        {{ item.product_name }}
                                    </p>
                                    <p
                                        class="text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{ formatPrice(item.unit_price) }} ×
                                        {{ item.quantity }}
                                    </p>
                                </div>
                                <p
                                    class="font-bold text-gray-900 dark:text-white whitespace-nowrap"
                                >
                                    {{ formatPrice(item.subtotal) }}
                                </p>
                            </div>
                        </div>

                        <!-- Total -->
                        <div
                            class="mt-4 pt-4 border-t-2 border-dashed border-gray-200 dark:border-gray-600 flex justify-between items-center"
                        >
                            <span
                                class="text-lg font-semibold text-gray-900 dark:text-white"
                                >Total</span
                            >
                            <span
                                class="text-2xl font-bold text-primary-600 dark:text-primary-400"
                            >
                                {{ formatPrice(order.total_amount) }}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Status Actions -->
                <div
                    class="bg-gradient-to-r from-gray-50 to-gray-100 dark:from-slate-800 dark:to-slate-700 rounded-2xl p-5"
                >
                    <h3
                        class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-4"
                    >
                        Quick Actions
                    </h3>
                    <div class="flex flex-wrap gap-3">
                        <button
                            v-if="order.status === 'pending_payment'"
                            @click="updateStatus('processing')"
                            class="px-6 py-3 bg-blue-500 text-white rounded-xl font-semibold hover:bg-blue-600 transition-all text-sm shadow-lg shadow-blue-500/30 flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M13 10V3L4 14h7v7l9-11h-7z"
                                />
                            </svg>
                            Mark as Processing
                        </button>
                        <button
                            v-if="order.status === 'processing'"
                            @click="updateStatus('completed')"
                            class="px-6 py-3 bg-green-500 text-white rounded-xl font-semibold hover:bg-green-600 transition-all text-sm shadow-lg shadow-green-500/30 flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M5 13l4 4L19 7"
                                />
                            </svg>
                            Mark as Completed
                        </button>
                        <button
                            v-if="
                                order.status !== 'completed' &&
                                order.status !== 'cancelled'
                            "
                            @click="openCancelModal"
                            class="px-6 py-3 bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300 rounded-xl font-semibold hover:bg-red-200 dark:hover:bg-red-900/50 transition-all text-sm flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                            Cancel Order
                        </button>
                        <div
                            v-if="order.status === 'completed'"
                            class="px-6 py-3 bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300 rounded-xl font-semibold text-sm flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                                />
                            </svg>
                            Order Completed
                        </div>
                        <div
                            v-if="order.status === 'cancelled'"
                            class="px-6 py-3 bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300 rounded-xl font-semibold text-sm flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                                />
                            </svg>
                            Order Cancelled
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <template #footer>
            <button
                type="button"
                @click="emit('close')"
                class="px-6 py-3 text-sm font-semibold text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Close
            </button>
        </template>
    </BaseModal>

    <!-- Cancel Order Modal -->
    <DeleteModal
        :show="showCancelModal"
        title="Cancel Order"
        :message="`Are you sure you want to cancel ${
            order?.code || 'Order #' + order?.id
        }? This action cannot be undone.`"
        confirmText="Cancel Order"
        :processing="isCancelling"
        @close="closeCancelModal"
        @confirm="confirmCancelOrder"
    />
</template>
