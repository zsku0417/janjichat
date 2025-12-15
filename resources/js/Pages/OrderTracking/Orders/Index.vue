<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import { Head, Link, router } from "@inertiajs/vue3";
import { ref, onMounted, onUnmounted } from "vue";

const props = defineProps({
    orders: Object,
    filter: String,
    stats: Object,
});

const ordersData = ref(props.orders);
let pollInterval = null;

const refreshData = () => {
    router.reload({
        only: ["orders", "stats"],
        preserveState: true,
        preserveScroll: true,
        onSuccess: (page) => {
            ordersData.value = page.props.orders;
        },
    });
};

onMounted(() => {
    pollInterval = setInterval(refreshData, 5000);
});

onUnmounted(() => {
    if (pollInterval) clearInterval(pollInterval);
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

const getStatusLabel = (status) => {
    const labels = {
        pending_payment: "Pending Payment",
        processing: "Processing",
        completed: "Completed",
        cancelled: "Cancelled",
    };
    return labels[status] || status;
};

const filters = [
    { value: "all", label: "All Orders" },
    { value: "pending_payment", label: "Pending Payment" },
    { value: "processing", label: "Processing" },
    { value: "completed", label: "Completed" },
];
</script>

<template>
    <Head title="Orders" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Orders</h2>
                    <p class="text-gray-500 text-sm mt-1">
                        Manage customer orders
                    </p>
                </div>
                <div
                    class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-green-50 border border-green-200 dark:bg-green-900/20 dark:border-green-800"
                >
                    <div
                        class="w-2 h-2 bg-green-500 rounded-full animate-pulse"
                    ></div>
                    <span
                        class="text-xs font-medium text-green-700 dark:text-green-300"
                        >Live updates</span
                    >
                </div>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <!-- Stats Row -->
                <div class="grid grid-cols-4 gap-4 mb-6">
                    <div
                        class="glass rounded-xl p-4 text-center dark:bg-gray-800/50"
                    >
                        <p
                            class="text-2xl font-bold text-gray-900 dark:text-white"
                        >
                            {{ stats?.total || 0 }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Total
                        </p>
                    </div>
                    <div
                        class="glass rounded-xl p-4 text-center border-2 border-amber-200 dark:border-amber-900/50 dark:bg-gray-800/50"
                    >
                        <p
                            class="text-2xl font-bold text-amber-600 dark:text-amber-400"
                        >
                            {{ stats?.pending || 0 }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Pending
                        </p>
                    </div>
                    <div
                        class="glass rounded-xl p-4 text-center border-2 border-blue-200 dark:border-blue-900/50 dark:bg-gray-800/50"
                    >
                        <p
                            class="text-2xl font-bold text-blue-600 dark:text-blue-400"
                        >
                            {{ stats?.processing || 0 }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Processing
                        </p>
                    </div>
                    <div
                        class="glass rounded-xl p-4 text-center border-2 border-green-200 dark:border-green-900/50 dark:bg-gray-800/50"
                    >
                        <p
                            class="text-2xl font-bold text-green-600 dark:text-green-400"
                        >
                            {{ stats?.completed || 0 }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Completed
                        </p>
                    </div>
                </div>

                <!-- Filter Tabs -->
                <div class="flex gap-2 mb-6">
                    <Link
                        v-for="f in filters"
                        :key="f.value"
                        :href="route('orders.index', { filter: f.value })"
                        :class="[
                            'px-4 py-2 rounded-lg text-sm font-medium transition-all',
                            filter === f.value
                                ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                                : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700',
                        ]"
                    >
                        {{ f.label }}
                    </Link>
                </div>

                <!-- Orders List -->
                <div v-if="ordersData.data?.length" class="space-y-4">
                    <div
                        v-for="order in ordersData.data"
                        :key="order.id"
                        class="glass rounded-2xl overflow-hidden"
                    >
                        <div class="p-6">
                            <div class="flex items-start justify-between">
                                <div class="flex items-center gap-4">
                                    <div
                                        class="w-14 h-14 bg-gradient-to-br from-cyan-400 to-primary-400 rounded-xl flex items-center justify-center text-white font-bold text-xl shadow-lg"
                                    >
                                        {{
                                            order.customer_name
                                                ?.charAt(0)
                                                ?.toUpperCase() || "?"
                                        }}
                                    </div>
                                    <div>
                                        <h3
                                            class="font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ order.customer_name }}
                                        </h3>
                                        <p
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{ order.customer_phone }}
                                        </p>
                                    </div>
                                </div>
                                <span
                                    :class="[
                                        'px-3 py-1 text-sm font-medium rounded-full border',
                                        getStatusColor(order.status),
                                    ]"
                                >
                                    {{ getStatusLabel(order.status) }}
                                </span>
                            </div>

                            <div class="mt-4 grid grid-cols-3 gap-4 text-sm">
                                <div>
                                    <p class="text-gray-500 dark:text-gray-400">
                                        Fulfillment
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
                                    <p class="text-gray-500 dark:text-gray-400">
                                        Requested Time
                                    </p>
                                    <p
                                        class="font-medium text-gray-900 dark:text-gray-200"
                                    >
                                        {{ order.requested_datetime }}
                                    </p>
                                </div>
                                <div>
                                    <p class="text-gray-500 dark:text-gray-400">
                                        Total
                                    </p>
                                    <p
                                        class="font-bold text-primary-600 dark:text-primary-400 text-lg"
                                    >
                                        {{ order.total_amount }}
                                    </p>
                                </div>
                            </div>

                            <div
                                v-if="order.items?.length"
                                class="mt-4 pt-4 border-t border-gray-100 dark:border-gray-700"
                            >
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400 mb-2"
                                >
                                    Items ({{ order.items.length }})
                                </p>
                                <div class="flex flex-wrap gap-2">
                                    <span
                                        v-for="item in order.items"
                                        :key="item.id"
                                        class="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-300"
                                    >
                                        {{ item.product_name }} ×
                                        {{ item.quantity }}
                                    </span>
                                </div>
                            </div>

                            <div
                                class="mt-4 pt-4 border-t border-gray-100 dark:border-gray-700 flex justify-end"
                            >
                                <Link
                                    :href="route('orders.show', order.id)"
                                    class="btn-gradient-secondary text-sm"
                                >
                                    View Details →
                                </Link>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Empty State -->
                <div
                    v-else
                    class="glass rounded-2xl p-12 text-center dark:bg-gray-800/50"
                >
                    <div
                        class="w-20 h-20 bg-gradient-to-br from-cyan-100 to-primary-100 dark:from-cyan-900/30 dark:to-primary-900/30 rounded-2xl flex items-center justify-center mx-auto mb-6"
                    >
                        <svg
                            class="w-10 h-10 text-primary-400"
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
                    </div>
                    <h3
                        class="text-lg font-semibold text-gray-900 dark:text-white mb-2"
                    >
                        No orders yet
                    </h3>
                    <p class="text-gray-500 dark:text-gray-400">
                        Orders will appear here when customers place them via
                        WhatsApp.
                    </p>
                </div>

                <!-- Pagination -->
                <div
                    v-if="ordersData.data?.length && ordersData.last_page > 1"
                    class="mt-8 flex justify-center gap-2"
                >
                    <Link
                        v-for="link in ordersData.links"
                        :key="link.label"
                        :href="link.url"
                        :class="[
                            'px-4 py-2 rounded-lg text-sm font-medium transition-all',
                            link.active
                                ? 'bg-primary-500 text-white'
                                : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700',
                            !link.url && 'opacity-50 cursor-not-allowed',
                        ]"
                        v-html="link.label"
                    />
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
