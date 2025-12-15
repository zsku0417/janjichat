<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import DeleteModal from "@/Components/DeleteModal.vue";
import { Head, Link, router } from "@inertiajs/vue3";
import { ref } from "vue";

const props = defineProps({
    order: Object,
    statuses: Object,
});

const getStatusColor = (status) => {
    const colors = {
        pending_payment:
            "bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-300 dark:border-amber-700/30",
        processing:
            "bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-300 dark:border-blue-700/30",
        completed:
            "bg-green-100 text-green-700 border-green-200 dark:bg-green-900/30 dark:text-green-300 dark:border-green-700/30",
        cancelled:
            "bg-red-100 text-red-700 border-red-200 dark:bg-red-900/30 dark:text-red-300 dark:border-red-700/30",
    };
    return (
        colors[status] ||
        "bg-gray-100 text-gray-700 border-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-700"
    );
};

const updateStatus = (newStatus) => {
    router.patch(
        route("orders.update-status", props.order.id),
        {
            status: newStatus,
        },
        {
            preserveScroll: true,
        }
    );
};

// Cancel modal state
const showCancelModal = ref(false);
const isCancelling = ref(false);

const openCancelModal = () => {
    showCancelModal.value = true;
};

const closeCancelModal = () => {
    showCancelModal.value = false;
};

const confirmCancelOrder = () => {
    isCancelling.value = true;
    router.post(
        route("orders.cancel", props.order.id),
        {},
        {
            onFinish: () => {
                isCancelling.value = false;
                closeCancelModal();
            },
        }
    );
};
</script>

<template>
    <Head :title="`Order #${order.id}`" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center gap-4">
                <Link
                    :href="route('orders.index')"
                    class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-all"
                >
                    <svg
                        class="w-5 h-5 text-gray-500"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M15 19l-7-7 7-7"
                        />
                    </svg>
                </Link>
                <div class="flex-1">
                    <h2 class="text-2xl font-bold text-gradient">
                        Order #{{ order.id }}
                    </h2>
                    <p class="text-gray-500 text-sm mt-1">
                        Placed on
                        {{ new Date(order.created_at).toLocaleDateString() }}
                    </p>
                </div>
                <span
                    :class="[
                        'px-4 py-2 text-sm font-medium rounded-full border',
                        getStatusColor(order.status),
                    ]"
                >
                    {{ statuses[order.status] }}
                </span>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
                <div class="grid gap-6">
                    <!-- Customer Info -->
                    <div class="glass rounded-2xl p-6 dark:bg-gray-800/50">
                        <h3
                            class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5 text-primary-500"
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
                            Customer Information
                        </h3>
                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    Name
                                </p>
                                <p
                                    class="font-medium text-gray-900 dark:text-gray-200"
                                >
                                    {{ order.customer_name }}
                                </p>
                            </div>
                            <div>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    Phone
                                </p>
                                <p
                                    class="font-medium text-gray-900 dark:text-gray-200"
                                >
                                    {{ order.customer_phone }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Order Details -->
                    <div class="glass rounded-2xl p-6 dark:bg-gray-800/50">
                        <h3
                            class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5 text-primary-500"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                                />
                            </svg>
                            Order Details
                        </h3>
                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    Fulfillment Type
                                </p>
                                <p
                                    class="font-medium text-gray-900 dark:text-gray-200"
                                >
                                    {{
                                        order.fulfillment_type === "pickup"
                                            ? "🏪 Pickup"
                                            : "🚚 Delivery"
                                    }}
                                </p>
                            </div>
                            <div>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    Requested Date/Time
                                </p>
                                <p
                                    class="font-medium text-gray-900 dark:text-gray-200"
                                >
                                    {{
                                        new Date(
                                            order.requested_datetime
                                        ).toLocaleString()
                                    }}
                                </p>
                            </div>
                            <div
                                v-if="order.delivery_address"
                                class="col-span-2"
                            >
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    Delivery Address
                                </p>
                                <p
                                    class="font-medium text-gray-900 dark:text-gray-200"
                                >
                                    {{ order.delivery_address }}
                                </p>
                            </div>
                            <div v-if="order.special_notes" class="col-span-2">
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    Special Notes
                                </p>
                                <p
                                    class="font-medium text-gray-900 dark:text-gray-200"
                                >
                                    {{ order.special_notes }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Order Items -->
                    <div class="glass rounded-2xl p-6 dark:bg-gray-800/50">
                        <h3
                            class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5 text-primary-500"
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
                            Items
                        </h3>
                        <div
                            class="divide-y divide-gray-100 dark:divide-gray-700"
                        >
                            <div
                                v-for="item in order.items"
                                :key="item.id"
                                class="py-4 flex items-center justify-between"
                            >
                                <div class="flex items-center gap-4">
                                    <div
                                        class="w-12 h-12 bg-gradient-to-br from-primary-100 to-secondary-100 dark:from-primary-900/30 dark:to-secondary-900/30 rounded-xl flex items-center justify-center"
                                    >
                                        <svg
                                            class="w-6 h-6 text-primary-400"
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
                                    <div>
                                        <p
                                            class="font-medium text-gray-900 dark:text-gray-200"
                                        >
                                            {{ item.product_name }}
                                        </p>
                                        <p
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            RM
                                            {{
                                                Number(item.unit_price).toFixed(
                                                    2
                                                )
                                            }}
                                            × {{ item.quantity }}
                                        </p>
                                    </div>
                                </div>
                                <p
                                    class="font-semibold text-gray-900 dark:text-gray-200"
                                >
                                    RM {{ Number(item.subtotal).toFixed(2) }}
                                </p>
                            </div>
                        </div>
                        <div
                            class="pt-4 border-t border-gray-200 dark:border-gray-700 flex justify-between items-center"
                        >
                            <p
                                class="text-lg font-semibold text-gray-900 dark:text-white"
                            >
                                Total
                            </p>
                            <p
                                class="text-2xl font-bold text-primary-600 dark:text-primary-400"
                            >
                                RM {{ Number(order.total_amount).toFixed(2) }}
                            </p>
                        </div>
                    </div>

                    <!-- Status Actions -->
                    <div class="glass rounded-2xl p-6 dark:bg-gray-800/50">
                        <h3
                            class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2"
                        >
                            <svg
                                class="w-5 h-5 text-primary-500"
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
                            Update Status
                        </h3>
                        <div class="flex flex-wrap gap-3">
                            <button
                                v-if="order.status === 'pending_payment'"
                                @click="updateStatus('processing')"
                                class="px-4 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 transition-all"
                            >
                                ✓ Mark as Processing
                            </button>
                            <button
                                v-if="order.status === 'processing'"
                                @click="updateStatus('completed')"
                                class="px-4 py-2 bg-green-500 text-white rounded-lg font-medium hover:bg-green-600 transition-all"
                            >
                                ✓ Mark as Completed
                            </button>
                            <button
                                v-if="
                                    order.status !== 'completed' &&
                                    order.status !== 'cancelled'
                                "
                                @click="openCancelModal"
                                class="px-4 py-2 bg-red-100 text-red-700 rounded-lg font-medium hover:bg-red-200 transition-all"
                            >
                                ✕ Cancel Order
                            </button>
                            <span
                                v-if="order.status === 'completed'"
                                class="px-4 py-2 bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300 rounded-lg font-medium"
                            >
                                ✓ Order Completed
                            </span>
                            <span
                                v-if="order.status === 'cancelled'"
                                class="px-4 py-2 bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300 rounded-lg font-medium"
                            >
                                ✕ Order Cancelled
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Cancel Order Modal -->
        <DeleteModal
            :show="showCancelModal"
            title="Cancel Order"
            :message="`Are you sure you want to cancel Order #${order.id}? This action cannot be undone.`"
            confirmText="Cancel Order"
            :processing="isCancelling"
            @close="closeCancelModal"
            @confirm="confirmCancelOrder"
        />
    </AuthenticatedLayout>
</template>
