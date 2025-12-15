<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import { Head, Link, router } from "@inertiajs/vue3";
import { ref, onMounted, onUnmounted } from "vue";

const props = defineProps({
    stats: Object,
    recentConversations: Array,
    upcomingBookings: Array,
});

const statsData = ref(props.stats);
const recentConversationsData = ref(props.recentConversations);
const upcomingBookingsData = ref(props.upcomingBookings);
let pollInterval = null;

const refreshData = () => {
    router.reload({
        only: ["stats", "recentConversations", "upcomingBookings"],
        preserveState: true,
        preserveScroll: true,
        onSuccess: (page) => {
            statsData.value = page.props.stats;
            recentConversationsData.value = page.props.recentConversations;
            upcomingBookingsData.value = page.props.upcomingBookings;
        },
    });
};

// Start polling when component mounts
onMounted(() => {
    pollInterval = setInterval(refreshData, 10000); // Refresh every 10 seconds
});

// Stop polling when component unmounts
onUnmounted(() => {
    if (pollInterval) {
        clearInterval(pollInterval);
    }
});
</script>

<template>
    <Head title="Dashboard" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Dashboard</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Welcome back! Here's your restaurant overview.
                    </p>
                </div>
                <div
                    class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-success-50 dark:bg-success-900/20 border border-success-200 dark:border-success-800"
                >
                    <div
                        class="w-2 h-2 bg-success-500 rounded-full animate-pulse"
                    ></div>
                    <span
                        class="text-xs font-medium text-success-700 dark:text-success-400"
                        >Live updates</span
                    >
                </div>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <!-- Stats Grid -->
                <div
                    class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4"
                >
                    <!-- Total Conversations -->
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
                                        d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            Total Conversations
                        </p>
                        <p
                            class="text-3xl font-bold text-gray-900 dark:text-white mt-1"
                        >
                            {{ statsData.total_conversations }}
                        </p>
                    </div>

                    <!-- Needs Reply -->
                    <div
                        :class="[
                            'stat-card group',
                            statsData.needs_reply > 0
                                ? 'ring-2 ring-accent-400 bg-accent-50/50'
                                : '',
                        ]"
                    >
                        <div class="flex items-center justify-between mb-4">
                            <div
                                :class="[
                                    'w-12 h-12 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform',
                                    statsData.needs_reply > 0
                                        ? 'bg-gradient-to-br from-accent-400 to-accent-600 shadow-accent-500/30'
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
                                        d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            Needs Reply
                        </p>
                        <p
                            :class="[
                                'text-3xl font-bold mt-1',
                                statsData.needs_reply > 0
                                    ? 'text-accent-600 dark:text-accent-400'
                                    : 'text-gray-900 dark:text-white',
                            ]"
                        >
                            {{ statsData.needs_reply }}
                        </p>
                        <Link
                            v-if="statsData.needs_reply > 0"
                            :href="
                                route('conversations.index', {
                                    filter: 'needs_reply',
                                })
                            "
                            class="inline-flex items-center gap-1 text-sm text-accent-600 hover:text-accent-800 mt-2 font-medium"
                        >
                            View all
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
                                    d="M9 5l7 7-7 7"
                                />
                            </svg>
                        </Link>
                    </div>

                    <!-- Today's Bookings -->
                    <div class="stat-card group">
                        <div class="flex items-center justify-between mb-4">
                            <div
                                class="w-12 h-12 bg-gradient-to-br from-secondary-400 to-secondary-600 rounded-xl flex items-center justify-center shadow-lg shadow-secondary-500/30 group-hover:scale-110 transition-transform"
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
                                        d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            Today's Bookings
                        </p>
                        <p
                            class="text-3xl font-bold text-gray-900 dark:text-white mt-1"
                        >
                            {{ statsData.todays_bookings }}
                        </p>
                    </div>

                    <!-- Upcoming Bookings -->
                    <div class="stat-card group">
                        <div class="flex items-center justify-between mb-4">
                            <div
                                class="w-12 h-12 bg-gradient-to-br from-success-400 to-success-600 rounded-xl flex items-center justify-center shadow-lg shadow-success-500/30 group-hover:scale-110 transition-transform"
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
                        <p
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            Upcoming Bookings
                        </p>
                        <p
                            class="text-3xl font-bold text-gray-900 dark:text-white mt-1"
                        >
                            {{ statsData.upcoming_bookings }}
                        </p>
                    </div>
                </div>

                <!-- Knowledge Base Stats -->
                <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <div class="stat-card group">
                        <div class="flex items-center gap-4">
                            <div
                                class="w-14 h-14 bg-gradient-to-br from-primary-400 via-primary-500 to-secondary-500 rounded-2xl flex items-center justify-center shadow-lg shadow-primary-500/30 group-hover:scale-110 transition-transform"
                            >
                                <svg
                                    class="w-7 h-7 text-white"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                                    />
                                </svg>
                            </div>
                            <div>
                                <p
                                    class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                >
                                    Documents in Knowledge Base
                                </p>
                                <p
                                    class="text-3xl font-bold text-gray-900 dark:text-white"
                                >
                                    {{ statsData.total_documents }}
                                </p>
                                <div
                                    v-if="statsData.pending_documents > 0"
                                    class="flex items-center gap-2 mt-1"
                                >
                                    <div
                                        class="w-2 h-2 bg-amber-500 rounded-full animate-pulse"
                                    ></div>
                                    <span class="text-sm text-amber-600"
                                        >{{
                                            statsData.pending_documents
                                        }}
                                        processing...</span
                                    >
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Two Column Layout -->
                <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
                    <!-- Recent Conversations -->
                    <div class="glass rounded-2xl overflow-hidden">
                        <div
                            class="px-6 py-4 border-b border-white/20 dark:border-white/10 bg-gradient-to-r from-primary-500/10 to-secondary-500/10 dark:from-primary-500/20 dark:to-secondary-500/20"
                        >
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2"
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
                        <ul
                            class="divide-y divide-gray-100/50 dark:divide-gray-700/50"
                        >
                            <li
                                v-for="conversation in recentConversationsData"
                                :key="conversation.id"
                            >
                                <Link
                                    :href="`/conversations?selected=${conversation.id}`"
                                    class="block hover:bg-white/50 dark:hover:bg-slate-800/50 transition-colors"
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
                                                    class="text-sm font-medium text-gray-900 dark:text-gray-100"
                                                >
                                                    {{
                                                        conversation.customer_name
                                                    }}
                                                </p>
                                            </div>
                                            <span
                                                v-if="conversation.needs_reply"
                                                class="badge-danger"
                                            >
                                                Needs Reply
                                            </span>
                                            <span
                                                v-else-if="
                                                    conversation.mode ===
                                                    'admin'
                                                "
                                                class="badge-warning"
                                            >
                                                Admin Mode
                                            </span>
                                            <span v-else class="badge-success">
                                                AI Mode
                                            </span>
                                        </div>
                                        <div
                                            class="mt-2 flex items-center justify-between"
                                        >
                                            <p
                                                class="text-sm text-gray-500 dark:text-gray-400 truncate max-w-xs"
                                            >
                                                {{ conversation.last_message }}
                                            </p>
                                            <span
                                                class="text-xs text-gray-400 dark:text-gray-500"
                                                >{{
                                                    conversation.last_message_at
                                                }}</span
                                            >
                                        </div>
                                    </div>
                                </Link>
                            </li>
                            <li
                                v-if="recentConversationsData?.length === 0"
                                class="px-6 py-8 text-center text-gray-500 dark:text-gray-400"
                            >
                                <div
                                    class="w-16 h-16 bg-gray-100 dark:bg-slate-700/50 rounded-2xl flex items-center justify-center mx-auto mb-3"
                                >
                                    <svg
                                        class="w-8 h-8 text-gray-400 dark:text-gray-500"
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
                                </div>
                                No conversations yet
                            </li>
                        </ul>
                        <div
                            class="px-6 py-3 bg-gradient-to-r from-gray-50 to-gray-100/50 dark:from-slate-800/50 dark:to-slate-900/50 border-t border-gray-100 dark:border-white/5"
                        >
                            <Link
                                :href="route('conversations.index')"
                                class="text-sm font-medium text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 flex items-center gap-1"
                            >
                                View all conversations
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
                                        d="M9 5l7 7-7 7"
                                    />
                                </svg>
                            </Link>
                        </div>
                    </div>

                    <!-- Upcoming Bookings -->
                    <div class="glass rounded-2xl overflow-hidden">
                        <div
                            class="px-6 py-4 border-b border-white/20 dark:border-white/10 bg-gradient-to-r from-secondary-500/10 to-success-500/10 dark:from-secondary-500/20 dark:to-success-500/20"
                        >
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2"
                            >
                                <svg
                                    class="w-5 h-5 text-secondary-500"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                                    />
                                </svg>
                                Upcoming Bookings
                            </h3>
                        </div>
                        <ul
                            class="divide-y divide-gray-100/50 dark:divide-gray-700/50"
                        >
                            <li
                                v-for="booking in upcomingBookingsData"
                                :key="booking.id"
                                class="px-6 py-4 hover:bg-white/50 dark:hover:bg-slate-800/50 transition-colors"
                            >
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3">
                                        <div
                                            class="w-10 h-10 bg-gradient-to-br from-secondary-400 to-success-400 rounded-xl flex items-center justify-center text-white font-semibold shadow-sm"
                                        >
                                            {{
                                                booking.customer_name
                                                    ?.charAt(0)
                                                    ?.toUpperCase() || "?"
                                            }}
                                        </div>
                                        <p
                                            class="text-sm font-medium text-gray-900 dark:text-gray-100"
                                        >
                                            {{ booking.customer_name }}
                                        </p>
                                    </div>
                                    <span
                                        class="text-sm text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-slate-700 px-2 py-1 rounded-lg"
                                        >{{ booking.pax }} guests</span
                                    >
                                </div>
                                <div
                                    class="mt-3 flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    <span class="flex items-center gap-1">
                                        <span>📅</span>
                                        {{ booking.booking_date }}
                                    </span>
                                    <span class="flex items-center gap-1">
                                        <span>⏰</span>
                                        {{ booking.booking_time }}
                                    </span>
                                    <span class="flex items-center gap-1">
                                        <span>🪑</span> {{ booking.table_name }}
                                    </span>
                                </div>
                            </li>
                            <li
                                v-if="upcomingBookingsData?.length === 0"
                                class="px-6 py-8 text-center text-gray-500 dark:text-gray-400"
                            >
                                <div
                                    class="w-16 h-16 bg-gray-100 dark:bg-slate-700/50 rounded-2xl flex items-center justify-center mx-auto mb-3"
                                >
                                    <svg
                                        class="w-8 h-8 text-gray-400 dark:text-gray-500"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                                        />
                                    </svg>
                                </div>
                                No upcoming bookings
                            </li>
                        </ul>
                        <div
                            class="px-6 py-3 bg-gradient-to-r from-gray-50 to-gray-100/50 dark:from-slate-800/50 dark:to-slate-900/50 border-t border-gray-100 dark:border-white/5"
                        >
                            <Link
                                :href="route('bookings.index')"
                                class="text-sm font-medium text-secondary-600 dark:text-secondary-400 hover:text-secondary-700 dark:hover:text-secondary-300 flex items-center gap-1"
                            >
                                View all bookings
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
                                        d="M9 5l7 7-7 7"
                                    />
                                </svg>
                            </Link>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
