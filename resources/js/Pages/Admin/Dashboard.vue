<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import { Head, router } from "@inertiajs/vue3";
import { ref, onMounted, onUnmounted, computed } from "vue";

const props = defineProps({
    stats: Object,
    recentMerchants: Array,
});

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
            refreshDashboard();
        }
    }, 1000);
};

const refreshDashboard = () => {
    isRefreshing.value = true;
    router.reload({
        only: ["stats", "recentMerchants"],
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

// Chart data
const merchantChartData = computed(() => {
    const total = props.stats.total_merchants || 1;
    return [
        {
            label: "Active",
            value: props.stats.active_merchants,
            percentage: (props.stats.active_merchants / total) * 100,
            color: "bg-green-500",
        },
        {
            label: "Inactive",
            value: props.stats.inactive_merchants,
            percentage: (props.stats.inactive_merchants / total) * 100,
            color: "bg-red-500",
        },
        {
            label: "Pending",
            value: props.stats.pending_verification,
            percentage: (props.stats.pending_verification / total) * 100,
            color: "bg-yellow-500",
        },
    ];
});

const activityChartData = computed(() => [
    {
        label: "Conversations",
        value: props.stats.total_conversations,
        todayValue: props.stats.conversations_today,
        icon: "M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z",
    },
    {
        label: "Messages",
        value: props.stats.total_messages,
        todayValue: props.stats.messages_today,
        icon: "M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z",
    },
    {
        label: "Documents",
        value: props.stats.total_documents,
        todayValue: props.stats.document_chunks,
        icon: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
    },
]);

onMounted(() => {
    startCountdown();
});

onUnmounted(() => {
    if (countdownInterval) {
        clearInterval(countdownInterval);
    }
});
</script>

<template>
    <Head title="Admin Dashboard" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">
                        Admin Dashboard
                    </h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Platform-wide statistics and activity
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
                        @click="refreshDashboard"
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
                <!-- Loading Skeleton -->
                <div v-if="isRefreshing" class="space-y-8 animate-pulse">
                    <!-- Stats Skeleton -->
                    <div>
                        <div
                            class="h-6 bg-gray-200 dark:bg-slate-700 rounded w-48 mb-4"
                        ></div>
                        <div
                            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
                        >
                            <div
                                v-for="i in 4"
                                :key="i"
                                class="p-6 bg-gray-200 dark:bg-slate-700 rounded-2xl h-32"
                            ></div>
                        </div>
                    </div>
                    <!-- Activity Skeleton -->
                    <div>
                        <div
                            class="h-6 bg-gray-200 dark:bg-slate-700 rounded w-48 mb-4"
                        ></div>
                        <div
                            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
                        >
                            <div
                                v-for="i in 4"
                                :key="i"
                                class="p-6 bg-gray-200 dark:bg-slate-700 rounded-2xl h-28"
                            ></div>
                        </div>
                    </div>
                </div>

                <!-- Actual Content -->
                <div v-else class="flex flex-col gap-8">
                    <!-- Merchant Stats -->
                    <div>
                        <h3
                            class="text-lg font-semibold text-gray-900 dark:text-white mb-4"
                        >
                            Merchants Overview
                        </h3>
                        <div
                            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
                        >
                            <!-- Total Merchants -->
                            <div
                                class="relative overflow-hidden p-6 bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 dark:from-indigo-800 dark:via-purple-800 dark:to-pink-800 rounded-2xl shadow-lg group hover:shadow-xl transition-all duration-300"
                            >
                                <div
                                    class="absolute inset-0 bg-black opacity-0 group-hover:opacity-10 transition-opacity"
                                ></div>
                                <div class="relative z-10">
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <div>
                                            <p
                                                class="text-sm font-medium text-white/90"
                                            >
                                                Total Merchants
                                            </p>
                                            <p
                                                class="text-4xl font-bold text-white mt-2"
                                            >
                                                {{ stats.total_merchants }}
                                            </p>
                                        </div>
                                        <div
                                            class="w-16 h-16 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center"
                                        >
                                            <svg
                                                class="w-8 h-8 text-white"
                                                fill="none"
                                                viewBox="0 0 24 24"
                                                stroke="currentColor"
                                            >
                                                <path
                                                    stroke-linecap="round"
                                                    stroke-linejoin="round"
                                                    stroke-width="2"
                                                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                                                />
                                            </svg>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Active Merchants -->
                            <div
                                class="relative overflow-hidden p-6 bg-gradient-to-br from-green-500 to-emerald-600 dark:from-green-600 dark:to-emerald-800 rounded-2xl shadow-lg group hover:shadow-xl transition-all duration-300"
                            >
                                <div
                                    class="absolute inset-0 bg-black opacity-0 group-hover:opacity-10 transition-opacity"
                                ></div>
                                <div class="relative z-10">
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <div>
                                            <p
                                                class="text-sm font-medium text-white/90"
                                            >
                                                Active
                                            </p>
                                            <p
                                                class="text-4xl font-bold text-white mt-2"
                                            >
                                                {{ stats.active_merchants }}
                                            </p>
                                        </div>
                                        <div
                                            class="w-16 h-16 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center"
                                        >
                                            <svg
                                                class="w-8 h-8 text-white"
                                                fill="none"
                                                viewBox="0 0 24 24"
                                                stroke="currentColor"
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
                                </div>
                            </div>

                            <!-- Inactive Merchants -->
                            <div
                                class="relative overflow-hidden p-6 bg-gradient-to-br from-red-500 to-rose-600 dark:from-red-600 dark:to-rose-800 rounded-2xl shadow-lg group hover:shadow-xl transition-all duration-300"
                            >
                                <div
                                    class="absolute inset-0 bg-black opacity-0 group-hover:opacity-10 transition-opacity"
                                ></div>
                                <div class="relative z-10">
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <div>
                                            <p
                                                class="text-sm font-medium text-white/90"
                                            >
                                                Inactive
                                            </p>
                                            <p
                                                class="text-4xl font-bold text-white mt-2"
                                            >
                                                {{ stats.inactive_merchants }}
                                            </p>
                                        </div>
                                        <div
                                            class="w-16 h-16 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center"
                                        >
                                            <svg
                                                class="w-8 h-8 text-white"
                                                fill="none"
                                                viewBox="0 0 24 24"
                                                stroke="currentColor"
                                            >
                                                <path
                                                    stroke-linecap="round"
                                                    stroke-linejoin="round"
                                                    stroke-width="2"
                                                    d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                                                />
                                            </svg>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Pending Verification -->
                            <div
                                class="relative overflow-hidden p-6 bg-gradient-to-br from-amber-400 via-orange-500 to-yellow-500 dark:from-amber-600 dark:via-orange-700 dark:to-yellow-800 rounded-2xl shadow-lg group hover:shadow-xl transition-all duration-300"
                            >
                                <div
                                    class="absolute inset-0 bg-black opacity-0 group-hover:opacity-10 transition-opacity"
                                ></div>
                                <div class="relative z-10">
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <div>
                                            <p
                                                class="text-sm font-medium text-white/90"
                                            >
                                                Pending
                                            </p>
                                            <p
                                                class="text-4xl font-bold text-white mt-2"
                                            >
                                                {{ stats.pending_verification }}
                                            </p>
                                        </div>
                                        <div
                                            class="w-16 h-16 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center"
                                        >
                                            <svg
                                                class="w-8 h-8 text-white"
                                                fill="none"
                                                viewBox="0 0 24 24"
                                                stroke="currentColor"
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
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Activity Stats -->
                    <div>
                        <h3
                            class="text-lg font-semibold text-gray-900 dark:text-white mb-4"
                        >
                            Platform Activity
                        </h3>
                        <div
                            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
                        >
                            <div
                                v-for="activity in activityChartData"
                                :key="activity.label"
                                class="p-6 bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 hover:shadow-md transition-shadow"
                            >
                                <div class="flex items-center gap-3 mb-3">
                                    <div
                                        class="w-10 h-10 rounded-lg bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center"
                                    >
                                        <svg
                                            class="w-5 h-5 text-white"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                            stroke="currentColor"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="2"
                                                :d="activity.icon"
                                            />
                                        </svg>
                                    </div>
                                    <p
                                        class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >
                                        {{ activity.label }}
                                    </p>
                                </div>
                                <p
                                    class="text-3xl font-bold text-gray-900 dark:text-white"
                                >
                                    {{ activity.value.toLocaleString() }}
                                </p>
                                <p
                                    class="text-xs text-gray-500 dark:text-gray-400 mt-2"
                                >
                                    <span
                                        class="text-green-600 dark:text-green-400 font-medium"
                                        >{{ activity.todayValue }}</span
                                    >
                                    {{
                                        activity.label === "Documents"
                                            ? "chunks"
                                            : "today"
                                    }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Merchant Distribution and Recent Merchants Side by Side -->
                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <!-- Merchant Distribution Chart -->
                        <div
                            class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6"
                        >
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white mb-6"
                            >
                                Merchant Distribution
                            </h3>
                            <div class="space-y-4">
                                <div
                                    v-for="item in merchantChartData"
                                    :key="item.label"
                                    class="space-y-2"
                                >
                                    <div
                                        class="flex items-center justify-between text-sm"
                                    >
                                        <span
                                            class="font-medium text-gray-700 dark:text-gray-300"
                                            >{{ item.label }}</span
                                        >
                                        <span
                                            class="text-gray-500 dark:text-gray-400"
                                            >{{ item.value }} ({{
                                                item.percentage.toFixed(1)
                                            }}%)</span
                                        >
                                    </div>
                                    <div
                                        class="w-full h-3 bg-gray-200 dark:bg-slate-700 rounded-full overflow-hidden"
                                    >
                                        <div
                                            :class="item.color"
                                            class="h-full transition-all duration-500 rounded-full"
                                            :style="{
                                                width: item.percentage + '%',
                                            }"
                                        ></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Recent Merchants -->
                        <div
                            class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6"
                        >
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white mb-4"
                            >
                                Recent Merchants
                            </h3>
                            <div class="space-y-3">
                                <div
                                    v-for="merchant in recentMerchants"
                                    :key="merchant.id"
                                    class="flex items-center justify-between p-4 bg-gray-50 dark:bg-slate-700 rounded-xl hover:bg-gray-100 dark:hover:bg-slate-600 transition-colors"
                                >
                                    <div class="flex-1 min-w-0">
                                        <p
                                            class="text-sm font-medium text-gray-900 dark:text-white truncate"
                                        >
                                            {{ merchant.name }}
                                        </p>
                                        <p
                                            class="text-xs text-gray-500 dark:text-gray-400 truncate"
                                        >
                                            {{ merchant.email }}
                                        </p>
                                        <p
                                            class="text-xs text-gray-500 dark:text-gray-400 mt-1"
                                        >
                                            {{ merchant.business_type }}
                                        </p>
                                    </div>
                                    <div class="flex items-center gap-3 ml-4">
                                        <span
                                            :class="[
                                                merchant.email_verified
                                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                    : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
                                                'px-2 py-1 text-xs font-medium rounded-full',
                                            ]"
                                        >
                                            {{
                                                merchant.email_verified
                                                    ? "✓"
                                                    : "⏳"
                                            }}
                                        </span>
                                        <span
                                            :class="[
                                                merchant.is_active
                                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                    : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
                                                'px-2 py-1 text-xs font-medium rounded-full',
                                            ]"
                                        >
                                            {{
                                                merchant.is_active
                                                    ? "Active"
                                                    : "Inactive"
                                            }}
                                        </span>
                                        <span
                                            class="text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap"
                                            >{{ merchant.created_at }}</span
                                        >
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
