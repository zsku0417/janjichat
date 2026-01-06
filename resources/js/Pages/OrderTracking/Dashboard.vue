<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import { Head, Link, router } from "@inertiajs/vue3";
import { ref, onMounted, onUnmounted, computed } from "vue";

const props = defineProps({
    stats: Object,
    recentConversations: Array,
    recentOrders: Array,
});

const statsData = ref(props.stats);
const recentConversationsData = ref(props.recentConversations);
const recentOrdersData = ref(props.recentOrders);

// Loading state
const isRefreshing = ref(false);

// Auto-refresh countdown (60 seconds)
const countdown = ref(60);
let countdownInterval = null;

const startCountdown = () => {
    countdown.value = 60;

    if (countdownInterval) {
        clearInterval(countdownInterval);
    }

    countdownInterval = setInterval(() => {
        countdown.value--;

        if (countdown.value <= 0) {
            refreshData();
        }
    }, 1000);
};

const refreshData = () => {
    isRefreshing.value = true;
    router.reload({
        only: ["stats", "recentConversations", "recentOrders"],
        preserveState: true,
        preserveScroll: true,
        onSuccess: (page) => {
            statsData.value = page.props.stats;
            recentConversationsData.value = page.props.recentConversations;
            recentOrdersData.value = page.props.recentOrders;
        },
        onFinish: () => {
            isRefreshing.value = false;
            startCountdown();
        },
    });
};

const formatCountdown = computed(() => {
    const mins = Math.floor(countdown.value / 60);
    const secs = countdown.value % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
});

// Progress bar percentage
const progressPercentage = computed(() => {
    return ((60 - countdown.value) / 60) * 100;
});

onMounted(() => {
    startCountdown();
});

onUnmounted(() => {
    if (countdownInterval) clearInterval(countdownInterval);
});

const getStatusColor = (status) => {
    const colors = {
        pending_payment: "bg-amber-100 text-amber-700",
        processing: "bg-blue-100 text-blue-700",
        completed: "bg-green-100 text-green-700",
        cancelled: "bg-red-100 text-red-700",
    };
    return colors[status] || "bg-gray-100 text-gray-700";
};
</script>

<template>
    <Head title="Dashboard - Order Tracking" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Dashboard</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Welcome back! Here's your order tracking overview.
                    </p>
                </div>
                <div class="flex items-center gap-3">
                    <div class="flex flex-col items-end">
                        <div
                            class="text-sm text-gray-500 dark:text-gray-400 mb-1"
                        >
                            Auto-refresh:
                            <span class="font-mono font-medium">{{
                                formatCountdown
                            }}</span>
                        </div>
                        <div
                            class="w-32 h-1 bg-gray-200 dark:bg-slate-600 rounded-full overflow-hidden"
                        >
                            <div
                                class="h-full bg-gradient-to-r from-primary-500 to-secondary-500 transition-all duration-1000"
                                :style="{ width: progressPercentage + '%' }"
                            ></div>
                        </div>
                    </div>
                    <button
                        @click="refreshData"
                        :disabled="isRefreshing"
                        class="px-4 py-2 bg-white dark:bg-slate-700 text-gray-700 dark:text-gray-300 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors flex items-center gap-2 disabled:opacity-50"
                    >
                        <svg
                            :class="['w-4 h-4', isRefreshing && 'animate-spin']"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                            />
                        </svg>
                        {{ isRefreshing ? "Refreshing..." : "Refresh" }}
                    </button>
                </div>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <!-- Stats Grid -->
                <div
                    class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4"
                >
                    <!-- Total Products -->
                    <div class="stat-card group">
                        <div class="flex items-center justify-between mb-4">
                            <div
                                class="w-12 h-12 bg-gradient-to-br from-primary-400 to-primary-600 rounded-xl flex items-center justify-center shadow-lg shadow-primary-500/30 group-hover:scale-110 transition-transform"
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
                                        d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p class="text-sm font-medium text-gray-500">
                            Total Products
                        </p>
                        <p class="text-3xl font-bold text-gray-900 mt-1">
                            {{ statsData.total_products }}
                        </p>
                        <p class="text-sm text-gray-500 mt-1">
                            {{ statsData.active_products }} active
                        </p>
                    </div>

                    <!-- Pending Orders -->
                    <div
                        :class="[
                            'stat-card group',
                            statsData.pending_orders > 0
                                ? 'ring-2 ring-amber-400 bg-amber-50/50'
                                : '',
                        ]"
                    >
                        <div class="flex items-center justify-between mb-4">
                            <div
                                :class="[
                                    'w-12 h-12 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform',
                                    statsData.pending_orders > 0
                                        ? 'bg-gradient-to-br from-amber-400 to-amber-600 shadow-amber-500/30'
                                        : 'bg-gradient-to-br from-gray-300 to-gray-400 shadow-gray-400/30',
                                ]"
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
                                        d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p class="text-sm font-medium text-gray-500">
                            Pending Payment
                        </p>
                        <p
                            :class="[
                                'text-3xl font-bold mt-1',
                                statsData.pending_orders > 0
                                    ? 'text-amber-600'
                                    : 'text-gray-900',
                            ]"
                        >
                            {{ statsData.pending_orders }}
                        </p>
                        <Link
                            v-if="statsData.pending_orders > 0"
                            :href="
                                route('orders.index', {
                                    filter: 'pending_payment',
                                })
                            "
                            class="inline-flex items-center gap-1 text-sm text-amber-600 hover:text-amber-800 mt-2 font-medium"
                        >
                            View all →
                        </Link>
                    </div>

                    <!-- Processing Orders -->
                    <div class="stat-card group">
                        <div class="flex items-center justify-between mb-4">
                            <div
                                class="w-12 h-12 bg-gradient-to-br from-blue-400 to-blue-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/30 group-hover:scale-110 transition-transform"
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
                                        d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p class="text-sm font-medium text-gray-500">
                            Processing
                        </p>
                        <p class="text-3xl font-bold text-gray-900 mt-1">
                            {{ statsData.processing_orders }}
                        </p>
                    </div>

                    <!-- Completed Today -->
                    <div class="stat-card group">
                        <div class="flex items-center justify-between mb-4">
                            <div
                                class="w-12 h-12 bg-gradient-to-br from-green-400 to-green-600 rounded-xl flex items-center justify-center shadow-lg shadow-green-500/30 group-hover:scale-110 transition-transform"
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
                                        d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p class="text-sm font-medium text-gray-500">
                            Completed Today
                        </p>
                        <p class="text-3xl font-bold text-gray-900 mt-1">
                            {{ statsData.completed_today }}
                        </p>
                    </div>
                </div>

                <!-- Two Column Layout -->
                <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
                    <!-- Recent Orders -->
                    <div class="glass rounded-2xl overflow-hidden">
                        <div
                            class="px-6 py-4 border-b border-white/20 bg-gradient-to-r from-cyan-500/10 to-primary-500/10"
                        >
                            <h3
                                class="text-lg font-semibold text-gray-900 flex items-center gap-2"
                            >
                                <svg
                                    class="w-5 h-5 text-cyan-500"
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
                                Recent Orders
                            </h3>
                        </div>
                        <ul class="divide-y divide-gray-100/50">
                            <li
                                v-for="order in recentOrdersData"
                                :key="order.id"
                            >
                                <Link
                                    :href="route('orders.show', order.id)"
                                    class="block hover:bg-white/50 transition-colors"
                                >
                                    <div class="px-6 py-4">
                                        <div
                                            class="flex items-center justify-between"
                                        >
                                            <div
                                                class="flex items-center gap-3"
                                            >
                                                <div
                                                    class="w-10 h-10 bg-gradient-to-br from-cyan-400 to-primary-400 rounded-xl flex items-center justify-center text-white font-semibold shadow-sm"
                                                >
                                                    {{
                                                        order.customer_name
                                                            ?.charAt(0)
                                                            ?.toUpperCase() ||
                                                        "?"
                                                    }}
                                                </div>
                                                <div>
                                                    <p
                                                        class="text-sm font-medium text-gray-900"
                                                    >
                                                        {{
                                                            order.customer_name
                                                        }}
                                                    </p>
                                                    <p
                                                        class="text-xs text-gray-500"
                                                    >
                                                        {{
                                                            order.items_count
                                                        }}
                                                        items •
                                                        {{ order.total_amount }}
                                                    </p>
                                                </div>
                                            </div>
                                            <span
                                                :class="[
                                                    'px-2 py-1 text-xs font-medium rounded-full',
                                                    getStatusColor(
                                                        order.status
                                                    ),
                                                ]"
                                            >
                                                {{ order.status_label }}
                                            </span>
                                        </div>
                                        <div
                                            class="mt-2 flex items-center gap-4 text-sm text-gray-500"
                                        >
                                            <span>{{
                                                order.fulfillment_type ===
                                                "pickup"
                                                    ? "🏪 Pickup"
                                                    : "🚚 Delivery"
                                            }}</span>
                                            <span
                                                >📅
                                                {{
                                                    order.requested_datetime
                                                }}</span
                                            >
                                        </div>
                                    </div>
                                </Link>
                            </li>
                            <li
                                v-if="!recentOrdersData?.length"
                                class="px-6 py-8 text-center text-gray-500"
                            >
                                <div
                                    class="w-16 h-16 bg-gray-100 rounded-2xl flex items-center justify-center mx-auto mb-3"
                                >
                                    <svg
                                        class="w-8 h-8 text-gray-400"
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
                                No orders yet
                            </li>
                        </ul>
                        <div
                            class="px-6 py-3 bg-gradient-to-r from-gray-50 to-gray-100/50 border-t border-gray-100"
                        >
                            <Link
                                :href="route('orders.index')"
                                class="text-sm font-medium text-cyan-600 hover:text-cyan-700 flex items-center gap-1"
                            >
                                View all orders →
                            </Link>
                        </div>
                    </div>

                    <!-- Recent Conversations -->
                    <div class="glass rounded-2xl overflow-hidden">
                        <div
                            class="px-6 py-4 border-b border-white/20 bg-gradient-to-r from-primary-500/10 to-secondary-500/10"
                        >
                            <h3
                                class="text-lg font-semibold text-gray-900 flex items-center gap-2"
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
                                        d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                                    />
                                </svg>
                                Recent Conversations
                            </h3>
                        </div>
                        <ul class="divide-y divide-gray-100/50">
                            <li
                                v-for="conversation in recentConversationsData"
                                :key="conversation.id"
                            >
                                <Link
                                    :href="
                                        route(
                                            'conversations.show',
                                            conversation.id
                                        )
                                    "
                                    class="block hover:bg-white/50 transition-colors"
                                >
                                    <div class="px-6 py-4">
                                        <div
                                            class="flex items-center justify-between"
                                        >
                                            <div
                                                class="flex items-center gap-3"
                                            >
                                                <div
                                                    class="w-10 h-10 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-xl flex items-center justify-center text-white font-semibold shadow-sm"
                                                >
                                                    {{
                                                        conversation.customer_name
                                                            ?.charAt(0)
                                                            ?.toUpperCase() ||
                                                        "?"
                                                    }}
                                                </div>
                                                <p
                                                    class="text-sm font-medium text-gray-900"
                                                >
                                                    {{
                                                        conversation.customer_name
                                                    }}
                                                </p>
                                            </div>
                                            <span
                                                v-if="conversation.needs_reply"
                                                class="px-2 py-1 text-xs font-medium rounded-full bg-red-100 text-red-700"
                                            >
                                                Needs Reply
                                            </span>
                                            <span
                                                v-else
                                                class="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-700"
                                            >
                                                AI Mode
                                            </span>
                                        </div>
                                        <div
                                            class="mt-2 flex items-center justify-between"
                                        >
                                            <p
                                                class="text-sm text-gray-500 truncate max-w-xs"
                                            >
                                                {{ conversation.last_message }}
                                            </p>
                                            <span
                                                class="text-xs text-gray-400"
                                                >{{
                                                    conversation.last_message_at
                                                }}</span
                                            >
                                        </div>
                                    </div>
                                </Link>
                            </li>
                            <li
                                v-if="!recentConversationsData?.length"
                                class="px-6 py-8 text-center text-gray-500"
                            >
                                No conversations yet
                            </li>
                        </ul>
                        <div
                            class="px-6 py-3 bg-gradient-to-r from-gray-50 to-gray-100/50 border-t border-gray-100"
                        >
                            <Link
                                :href="route('conversations.index')"
                                class="text-sm font-medium text-primary-600 hover:text-primary-700 flex items-center gap-1"
                            >
                                View all conversations →
                            </Link>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
