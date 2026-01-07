<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import DataTable from "@/Components/DataTable.vue";
import TableActionButton from "@/Components/TableActionButton.vue";
import ViewOrderModal from "@/Components/Orders/ViewOrderModal.vue";
import OrderFormModal from "@/Components/Orders/OrderFormModal.vue";
import { Head, router } from "@inertiajs/vue3";
import { ref, computed, onMounted, onUnmounted, watch } from "vue";

const props = defineProps({
    orders: Object,
    filter: {
        type: String,
        default: "all",
    },
    stats: Object,
    filters: {
        type: Object,
        default: () => ({
            search: "",
            sort_key: null,
            sort_order: null,
            date_from: null,
            date_to: null,
        }),
    },
    products: {
        type: Array,
        default: () => [],
    },
});

// Table columns configuration
const columns = [
    { key: "code", label: "Code", sortable: false },
    { key: "customer", label: "Customer", sortable: true },
    { key: "fulfillment_type", label: "Fulfillment", sortable: true },
    { key: "requested_datetime", label: "Requested Time", sortable: true },
    { key: "total_amount", label: "Total", sortable: true },
    { key: "status", label: "Status", sortable: true },
];

// Loading state
const isLoading = ref(false);

// Date range state
const showDatePicker = ref(false);
const dateFrom = ref(props.filters?.date_from || "");
const dateTo = ref(props.filters?.date_to || "");
const selectedPreset = ref("");

const datePresets = [
    {
        key: "today",
        label: "Today",
        getDates: () => {
            const today = new Date();
            return { from: formatDateInput(today), to: formatDateInput(today) };
        },
    },
    {
        key: "yesterday",
        label: "Yesterday",
        getDates: () => {
            const d = new Date();
            d.setDate(d.getDate() - 1);
            return { from: formatDateInput(d), to: formatDateInput(d) };
        },
    },
    {
        key: "tomorrow",
        label: "Tomorrow",
        getDates: () => {
            const d = new Date();
            d.setDate(d.getDate() + 1);
            return { from: formatDateInput(d), to: formatDateInput(d) };
        },
    },
    {
        key: "next7days",
        label: "Next 7 Days",
        getDates: () => {
            const today = new Date();
            const next = new Date();
            next.setDate(next.getDate() + 7);
            return { from: formatDateInput(today), to: formatDateInput(next) };
        },
    },
    {
        key: "last7days",
        label: "Last 7 Days",
        getDates: () => {
            const today = new Date();
            const past = new Date();
            past.setDate(past.getDate() - 7);
            return { from: formatDateInput(past), to: formatDateInput(today) };
        },
    },
    {
        key: "thisMonth",
        label: "This Month",
        getDates: () => {
            const today = new Date();
            const start = new Date(today.getFullYear(), today.getMonth(), 1);
            const end = new Date(today.getFullYear(), today.getMonth() + 1, 0);
            return { from: formatDateInput(start), to: formatDateInput(end) };
        },
    },
    {
        key: "lastMonth",
        label: "Last Month",
        getDates: () => {
            const today = new Date();
            const start = new Date(
                today.getFullYear(),
                today.getMonth() - 1,
                1
            );
            const end = new Date(today.getFullYear(), today.getMonth(), 0);
            return { from: formatDateInput(start), to: formatDateInput(end) };
        },
    },
];

const formatDateInput = (date) => {
    return date.toISOString().split("T")[0];
};

const applyPreset = (preset) => {
    const dates = preset.getDates();
    dateFrom.value = dates.from;
    dateTo.value = dates.to;
    selectedPreset.value = preset.key;
};

const applyDateFilter = () => {
    showDatePicker.value = false;
    isLoading.value = true;
    router.get(
        route("orders.index"),
        buildParams({
            date_from: dateFrom.value,
            date_to: dateTo.value,
            page: 1,
        }),
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

const clearDateFilter = () => {
    dateFrom.value = "";
    dateTo.value = "";
    selectedPreset.value = "";
    showDatePicker.value = false;
    isLoading.value = true;
    router.get(
        route("orders.index"),
        buildParams({ date_from: null, date_to: null, page: 1 }),
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

const hasDateFilter = computed(() => dateFrom.value || dateTo.value);

const dateRangeLabel = computed(() => {
    if (!dateFrom.value && !dateTo.value) return "Select Date Range";
    if (dateFrom.value && dateTo.value) {
        if (dateFrom.value === dateTo.value) {
            return formatDisplayDate(dateFrom.value);
        }
        return `${formatDisplayDate(dateFrom.value)} - ${formatDisplayDate(
            dateTo.value
        )}`;
    }
    if (dateFrom.value) return `From ${formatDisplayDate(dateFrom.value)}`;
    return `Until ${formatDisplayDate(dateTo.value)}`;
});

const formatDisplayDate = (dateStr) => {
    if (!dateStr) return "";
    return new Date(dateStr).toLocaleDateString("en-GB", {
        day: "numeric",
        month: "short",
        year: "numeric",
    });
};

// Auto-refresh functionality with countdown
const isRefreshing = ref(false);
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
        only: ["orders", "stats"],
        preserveState: true,
        preserveScroll: true,
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

const progressPercentage = computed(() => {
    return ((60 - countdown.value) / 60) * 100;
});

onMounted(() => {
    startCountdown();
});

onUnmounted(() => {
    if (countdownInterval) clearInterval(countdownInterval);
});

// View modal state
const showViewModal = ref(false);
const viewingOrder = ref(null);

const openViewModal = (order) => {
    viewingOrder.value = order;
    showViewModal.value = true;
};

const closeViewModal = () => {
    showViewModal.value = false;
    viewingOrder.value = null;
};

const handleOrderUpdated = () => {
    refreshData();
};

// Create/Edit Order Modal
const showFormModal = ref(false);
const editingOrder = ref(null);

const openCreateModal = () => {
    editingOrder.value = null;
    showFormModal.value = true;
};

const openEditModal = (order) => {
    editingOrder.value = order;
    showFormModal.value = true;
};

const closeFormModal = () => {
    showFormModal.value = false;
    editingOrder.value = null;
};

const handleOrderSaved = () => {
    refreshData();
};

// Delete functionality
const showDeleteConfirm = ref(false);
const orderToDelete = ref(null);

const confirmDelete = (order) => {
    orderToDelete.value = order;
    showDeleteConfirm.value = true;
};

const cancelDelete = () => {
    showDeleteConfirm.value = false;
    orderToDelete.value = null;
};

const deleteOrder = () => {
    if (!orderToDelete.value) return;

    router.delete(route("orders.destroy", orderToDelete.value.id), {
        onSuccess: () => {
            showDeleteConfirm.value = false;
            orderToDelete.value = null;
        },
    });
};

// Status helpers
const getStatusColor = (status) => {
    const colors = {
        pending_payment:
            "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300",
        processing:
            "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300",
        completed:
            "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300",
        cancelled:
            "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300",
    };
    return (
        colors[status] ||
        "bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300"
    );
};

const getStatusLabel = (status) => {
    const labels = {
        pending_payment: "Pending",
        processing: "Processing",
        completed: "Completed",
        cancelled: "Cancelled",
    };
    return labels[status] || status;
};

// Stats card config
const statsCards = computed(() => [
    {
        key: "all",
        label: "Total Orders",
        value: props.stats?.total || 0,
        icon: "📦",
        gradient: "from-slate-500 to-slate-600",
        bgColor: "bg-slate-50 dark:bg-slate-800/50",
        iconBg: "bg-slate-100 dark:bg-slate-700",
        textColor: "text-slate-700 dark:text-slate-200",
        isActive: props.filter === "all",
    },
    {
        key: "pending_payment",
        label: "Pending",
        value: props.stats?.pending || 0,
        icon: "⏳",
        gradient: "from-amber-500 to-orange-500",
        bgColor: "bg-amber-50 dark:bg-amber-900/20",
        iconBg: "bg-amber-100 dark:bg-amber-900/40",
        textColor: "text-amber-700 dark:text-amber-300",
        isActive: props.filter === "pending_payment",
    },
    {
        key: "processing",
        label: "Processing",
        value: props.stats?.processing || 0,
        icon: "⚡",
        gradient: "from-blue-500 to-cyan-500",
        bgColor: "bg-blue-50 dark:bg-blue-900/20",
        iconBg: "bg-blue-100 dark:bg-blue-900/40",
        textColor: "text-blue-700 dark:text-blue-300",
        isActive: props.filter === "processing",
    },
    {
        key: "completed",
        label: "Completed",
        value: props.stats?.completed || 0,
        icon: "✅",
        gradient: "from-green-500 to-emerald-500",
        bgColor: "bg-green-50 dark:bg-green-900/20",
        iconBg: "bg-green-100 dark:bg-green-900/40",
        textColor: "text-green-700 dark:text-green-300",
        isActive: props.filter === "completed",
    },
    {
        key: "cancelled",
        label: "Cancelled",
        value: props.stats?.cancelled || 0,
        icon: "❌",
        gradient: "from-red-500 to-rose-500",
        bgColor: "bg-red-50 dark:bg-red-900/20",
        iconBg: "bg-red-100 dark:bg-red-900/40",
        textColor: "text-red-700 dark:text-red-300",
        isActive: props.filter === "cancelled",
    },
]);

// Helper to build query params
const buildParams = (overrides = {}) => ({
    filter: props.filter,
    search: props.filters?.search,
    sort_key: props.filters?.sort_key,
    sort_order: props.filters?.sort_order,
    date_from: props.filters?.date_from,
    date_to: props.filters?.date_to,
    ...overrides,
});

// Filter by status (clicking stats cards)
const filterByStatus = (status) => {
    isLoading.value = true;
    router.get(
        route("orders.index"),
        buildParams({ filter: status, page: 1 }),
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

// Server-side search
const handleSearch = (query) => {
    isLoading.value = true;
    router.get(route("orders.index"), buildParams({ search: query, page: 1 }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

// Server-side sort
const handleSort = ({ key, order }) => {
    isLoading.value = true;
    router.get(
        route("orders.index"),
        buildParams({ sort_key: key, sort_order: order, page: 1 }),
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

// Pagination
const handlePageChange = (page) => {
    isLoading.value = true;
    router.get(route("orders.index"), buildParams({ page }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

// Server pagination data
const serverPagination = computed(() => ({
    current_page: props.orders.current_page,
    last_page: props.orders.last_page,
    total: props.orders.total,
    per_page: props.orders.per_page,
}));

const formatPrice = (price) => {
    return "RM " + Number(price || 0).toFixed(2);
};

const formatDate = (date) => {
    if (!date) return "—";
    return new Date(date).toLocaleString("en-MY", {
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
    });
};

// Close date picker when clicking outside
const closeDatePicker = (e) => {
    if (!e.target.closest(".date-picker-container")) {
        showDatePicker.value = false;
    }
};
</script>

<template>
    <Head title="Orders" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Orders</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Manage customer orders
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
                    <button
                        @click="openCreateModal"
                        class="px-5 py-2.5 bg-gradient-to-r from-primary-500 to-secondary-500 text-white rounded-xl font-medium shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all duration-200 flex items-center gap-2"
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
                                d="M12 4v16m8-8H4"
                            />
                        </svg>
                        Create Order
                    </button>
                </div>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <!-- Clickable Stats Cards -->
                <div
                    class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 sm:gap-4 mb-6"
                >
                    <button
                        v-for="card in statsCards"
                        :key="card.key"
                        @click="filterByStatus(card.key)"
                        :class="[
                            'relative group rounded-2xl p-4 sm:p-5 text-left transition-all duration-300 overflow-hidden border',
                            card.bgColor,
                            card.isActive
                                ? 'border-2 border-primary-500 dark:border-primary-400 shadow-lg scale-[1.02]'
                                : 'border-gray-100 dark:border-slate-700 hover:shadow-md hover:scale-[1.01]',
                        ]"
                    >
                        <!-- Decorative gradient bar -->
                        <div
                            :class="[
                                'absolute top-0 left-0 right-0 h-1 bg-gradient-to-r',
                                card.gradient,
                                card.isActive
                                    ? 'opacity-100'
                                    : 'opacity-0 group-hover:opacity-50',
                            ]"
                        ></div>

                        <div class="flex items-center gap-3">
                            <!-- Icon -->
                            <div
                                :class="[
                                    'w-10 h-10 sm:w-12 sm:h-12 rounded-xl flex items-center justify-center text-lg sm:text-xl flex-shrink-0 transition-transform group-hover:scale-110',
                                    card.iconBg,
                                ]"
                            >
                                {{ card.icon }}
                            </div>

                            <!-- Content -->
                            <div class="min-w-0">
                                <p
                                    :class="[
                                        'text-2xl sm:text-3xl font-bold leading-none',
                                        card.textColor,
                                    ]"
                                >
                                    {{ card.value }}
                                </p>
                                <p
                                    class="text-xs sm:text-sm text-gray-500 dark:text-gray-400 mt-1 truncate"
                                >
                                    {{ card.label }}
                                </p>
                            </div>
                        </div>

                        <!-- Active indicator -->
                        <div
                            v-if="card.isActive"
                            class="absolute bottom-2 right-2 w-2 h-2 rounded-full bg-primary-500 animate-pulse"
                        ></div>
                    </button>
                </div>

                <DataTable
                    :columns="columns"
                    :data="orders.data"
                    :server-pagination="serverPagination"
                    :per-page="orders.per_page"
                    :searchable="true"
                    search-placeholder="Search by name, phone, or order code..."
                    :initial-search="filters?.search"
                    :initial-sort-key="filters?.sort_key"
                    :initial-sort-order="filters?.sort_order"
                    :loading="isLoading"
                    :server-side="true"
                    empty-message="No orders found"
                    @page-change="handlePageChange"
                    @search="handleSearch"
                    @sort="handleSort"
                >
                    <!-- Filters Slot - Date Range Picker -->
                    <template #filters>
                        <div class="relative date-picker-container">
                            <button
                                @click="showDatePicker = !showDatePicker"
                                :class="[
                                    'px-4 py-2 rounded-xl text-sm font-medium transition-all flex items-center gap-2',
                                    hasDateFilter
                                        ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                                        : 'bg-white dark:bg-slate-700 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-600 ring-1 ring-inset ring-gray-200 dark:ring-slate-600',
                                ]"
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
                                        d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                                    />
                                </svg>
                                {{ dateRangeLabel }}
                                <svg
                                    v-if="hasDateFilter"
                                    @click.stop="clearDateFilter"
                                    class="w-4 h-4 hover:text-white/80"
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
                            </button>

                            <!-- Date Picker Dropdown -->
                            <div
                                v-if="showDatePicker"
                                class="absolute top-full left-0 md:left-auto md:right-0 mt-2 bg-white dark:bg-slate-800 rounded-xl shadow-2xl border border-gray-200 dark:border-slate-700 p-4 z-50 min-w-[400px]"
                            >
                                <div class="flex gap-4">
                                    <!-- Presets -->
                                    <div
                                        class="space-y-1 border-r border-gray-200 dark:border-slate-700 pr-4"
                                    >
                                        <p
                                            class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2"
                                        >
                                            Quick Select
                                        </p>
                                        <button
                                            v-for="preset in datePresets"
                                            :key="preset.key"
                                            @click="applyPreset(preset)"
                                            :class="[
                                                'block w-full text-left px-3 py-2 text-sm rounded-lg transition-colors',
                                                selectedPreset === preset.key
                                                    ? 'bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:text-primary-400'
                                                    : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700',
                                            ]"
                                        >
                                            {{ preset.label }}
                                        </button>
                                    </div>

                                    <!-- Custom Range -->
                                    <div class="flex-1">
                                        <p
                                            class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2"
                                        >
                                            Custom Range
                                        </p>
                                        <div class="space-y-3">
                                            <div>
                                                <label
                                                    class="block text-xs text-gray-500 dark:text-gray-400 mb-1"
                                                    >From</label
                                                >
                                                <input
                                                    type="date"
                                                    v-model="dateFrom"
                                                    @change="
                                                        selectedPreset = ''
                                                    "
                                                    class="w-full px-3 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 text-sm"
                                                />
                                            </div>
                                            <div>
                                                <label
                                                    class="block text-xs text-gray-500 dark:text-gray-400 mb-1"
                                                    >To</label
                                                >
                                                <input
                                                    type="date"
                                                    v-model="dateTo"
                                                    @change="
                                                        selectedPreset = ''
                                                    "
                                                    class="w-full px-3 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 text-sm"
                                                />
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div
                                    class="flex justify-end gap-2 mt-4 pt-4 border-t border-gray-200 dark:border-slate-700"
                                >
                                    <button
                                        @click="clearDateFilter"
                                        class="px-4 py-2 text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700 rounded-lg transition-colors"
                                    >
                                        Clear
                                    </button>
                                    <button
                                        @click="applyDateFilter"
                                        class="px-4 py-2 text-sm font-medium text-white bg-primary-500 hover:bg-primary-600 rounded-lg transition-colors"
                                    >
                                        Apply
                                    </button>
                                </div>
                            </div>
                        </div>
                    </template>

                    <!-- Order Code Cell -->
                    <template #cell-code="{ row }">
                        <span
                            class="font-mono text-gray-600 dark:text-gray-400 text-sm"
                        >
                            {{ row.code }}
                        </span>
                    </template>

                    <!-- Customer Cell -->
                    <template #cell-customer="{ row, highlight }">
                        <div class="flex items-center gap-3">
                            <div>
                                <div
                                    class="font-medium text-gray-900 dark:text-white"
                                    v-html="highlight(row.customer_name)"
                                ></div>
                                <div
                                    class="text-xs text-gray-500 dark:text-gray-400"
                                    v-html="highlight(row.customer_phone)"
                                ></div>
                            </div>
                        </div>
                    </template>

                    <!-- Fulfillment Cell -->
                    <template #cell-fulfillment_type="{ row }">
                        <span class="text-gray-900 dark:text-white">
                            {{
                                row.fulfillment_type === "pickup"
                                    ? "🏪 Pickup"
                                    : "🚚 Delivery"
                            }}
                        </span>
                    </template>

                    <!-- Requested Time Cell -->
                    <template #cell-requested_datetime="{ row }">
                        <span class="text-gray-600 dark:text-gray-300">
                            {{ formatDate(row.requested_datetime) }}
                        </span>
                    </template>

                    <!-- Total Cell -->
                    <template #cell-total_amount="{ row }">
                        <span
                            class="font-bold text-primary-600 dark:text-primary-400"
                        >
                            {{ formatPrice(row.total_amount) }}
                        </span>
                    </template>

                    <!-- Status Cell -->
                    <template #cell-status="{ row }">
                        <span
                            :class="[
                                getStatusColor(row.status),
                                'px-3 py-1 text-xs font-medium rounded-full',
                            ]"
                        >
                            {{ getStatusLabel(row.status) }}
                        </span>
                    </template>

                    <!-- Actions -->
                    <template #actions="{ row }">
                        <div class="flex items-center gap-1">
                            <TableActionButton
                                type="view"
                                @click="openViewModal(row)"
                            />
                            <TableActionButton
                                type="edit"
                                @click="openEditModal(row)"
                            />
                            <TableActionButton
                                type="delete"
                                @click="confirmDelete(row)"
                            />
                        </div>
                    </template>
                </DataTable>
            </div>
        </div>

        <!-- View Order Modal -->
        <ViewOrderModal
            :show="showViewModal"
            :order="viewingOrder"
            @close="closeViewModal"
            @updated="handleOrderUpdated"
        />

        <!-- Create/Edit Order Modal -->
        <OrderFormModal
            :show="showFormModal"
            :order="editingOrder"
            :products="products"
            @close="closeFormModal"
            @saved="handleOrderSaved"
        />

        <!-- Delete Confirmation Modal -->
        <Teleport to="body">
            <div
                v-if="showDeleteConfirm"
                class="fixed inset-0 z-50 flex items-center justify-center"
            >
                <!-- Backdrop -->
                <div
                    class="absolute inset-0 bg-black/50 backdrop-blur-sm"
                    @click="cancelDelete"
                ></div>

                <!-- Modal -->
                <div
                    class="relative bg-white dark:bg-slate-800 rounded-2xl shadow-2xl p-6 max-w-md w-full mx-4"
                >
                    <div class="flex items-center gap-4 mb-4">
                        <div
                            class="w-12 h-12 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center"
                        >
                            <svg
                                class="w-6 h-6 text-red-600 dark:text-red-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                                />
                            </svg>
                        </div>
                        <div>
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white"
                            >
                                Delete Order
                            </h3>
                            <p class="text-sm text-gray-500 dark:text-gray-400">
                                This action cannot be undone.
                            </p>
                        </div>
                    </div>

                    <p class="text-gray-600 dark:text-gray-300 mb-6">
                        Are you sure you want to delete order
                        <span class="font-semibold">{{
                            orderToDelete?.code
                        }}</span
                        >? All order items will also be removed.
                    </p>

                    <div class="flex justify-end gap-3">
                        <button
                            @click="cancelDelete"
                            class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 hover:bg-gray-200 dark:hover:bg-slate-600 rounded-lg transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            @click="deleteOrder"
                            class="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
                        >
                            Delete Order
                        </button>
                    </div>
                </div>
            </div>
        </Teleport>
    </AuthenticatedLayout>
</template>
