<script setup>
/**
 * ViewProductModal - Display product details with tabs for Basic Info and Orders
 */

import { ref, watch, computed } from "vue";
import BaseModal from "@/Components/BaseModal.vue";
import ImageGallery from "@/Components/ImageGallery.vue";
import Tab from "@/Components/Tab.vue";
import axios from "axios";

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    product: {
        type: Object,
        default: null,
    },
});

const emit = defineEmits(["close", "edit"]);

// Tab state
const activeTab = ref("info");
const tabs = computed(() => [
    { key: "info", label: "Basic Info" },
    { key: "orders", label: "Orders", badge: stats.value.total_orders || null },
]);

// Gallery state
const showGallery = ref(false);
const galleryStartIndex = ref(0);

// Orders state
const orders = ref([]);
const stats = ref({
    total_orders: 0,
    total_quantity: 0,
    total_revenue: "0.00",
});
const isLoadingOrders = ref(false);
const selectedPeriod = ref("all");

const periodOptions = [
    { value: "all", label: "All Time" },
    { value: "today", label: "Today" },
    { value: "yesterday", label: "Yesterday" },
    { value: "last_week", label: "Last 7 Days" },
    { value: "last_month", label: "Last 30 Days" },
    { value: "last_3_months", label: "Last 3 Months" },
    { value: "last_year", label: "Last Year" },
];

// Status colors
const statusColors = {
    pending_payment:
        "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-300",
    processing:
        "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300",
    completed:
        "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300",
    cancelled: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300",
};

// Fetch orders when tab changes or period changes
const fetchOrders = async () => {
    if (!props.product) return;

    isLoadingOrders.value = true;
    try {
        const response = await axios.get(
            route("products.orders", props.product.id),
            {
                params: { period: selectedPeriod.value },
            }
        );
        orders.value = response.data.orders;
        stats.value = response.data.stats;
    } catch (error) {
        console.error("Error fetching orders:", error);
    } finally {
        isLoadingOrders.value = false;
    }
};

// Watch for tab/period changes
watch(activeTab, (newTab) => {
    if (newTab === "orders" && props.product) {
        fetchOrders();
    }
});

watch(selectedPeriod, () => {
    if (activeTab.value === "orders") {
        fetchOrders();
    }
});

// Reset when modal opens
watch(
    () => props.show,
    (isOpen) => {
        if (isOpen) {
            activeTab.value = "info";
            orders.value = [];
            stats.value = {
                total_orders: 0,
                total_quantity: 0,
                total_revenue: "0.00",
            };
            selectedPeriod.value = "all";
        }
    }
);

// Export orders
const exportOrders = (format) => {
    if (!props.product) return;

    const url =
        route("products.orders.export", props.product.id) +
        `?period=${selectedPeriod.value}&format=${format}`;
    window.open(url, "_blank");
};

const openGallery = (index = 0) => {
    galleryStartIndex.value = index;
    showGallery.value = true;
};

const formatPrice = (price) => {
    return Number(price || 0).toFixed(2);
};

const formatDate = (date) => {
    if (!date) return "—";
    return new Date(date).toLocaleDateString("en-GB", {
        day: "numeric",
        month: "short",
        year: "numeric",
    });
};
</script>

<template>
    <BaseModal
        :show="show"
        title="Product Details"
        icon="view"
        customWidth="max-w-[1000px]"
        @close="emit('close')"
    >
        <template #content>
            <div v-if="product">
                <!-- Tabs -->
                <Tab :tabs="tabs" v-model="activeTab" />

                <!-- Basic Info Tab -->
                <div v-show="activeTab === 'info'" class="pt-4 space-y-4">
                    <!-- Product Images -->
                    <div
                        v-if="product.image_urls?.length"
                        class="grid grid-cols-3 gap-2"
                    >
                        <div
                            v-for="(url, index) in product.image_urls"
                            :key="index"
                            class="relative max-w-[250px] aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-slate-700 cursor-pointer group"
                            @click="openGallery(index)"
                        >
                            <img
                                :src="url"
                                :alt="`Product image ${index + 1}`"
                                class="w-full h-full object-cover transition-transform group-hover:scale-105"
                            />
                            <div
                                class="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100"
                            >
                                <svg
                                    class="w-8 h-8 text-white"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7"
                                    />
                                </svg>
                            </div>
                        </div>
                    </div>
                    <!-- No images placeholder -->
                    <div
                        v-else
                        class="h-48 bg-gradient-to-br from-primary-100 to-secondary-100 dark:from-primary-900/30 dark:to-secondary-900/30 rounded-xl flex items-center justify-center"
                    >
                        <svg
                            class="w-16 h-16 text-primary-300 dark:text-primary-600"
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

                    <!-- Product Info -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                    >
                        <div class="flex items-start justify-between">
                            <div>
                                <h4
                                    class="text-lg font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ product.name }}
                                </h4>
                                <p
                                    class="text-2xl font-bold text-primary-600 dark:text-primary-400 mt-1"
                                >
                                    RM {{ formatPrice(product.price) }}
                                </p>
                            </div>
                            <span
                                :class="[
                                    'px-3 py-1.5 text-sm font-medium rounded-full',
                                    product.is_active
                                        ? 'bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300'
                                        : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400',
                                ]"
                            >
                                {{ product.is_active ? "Active" : "Inactive" }}
                            </span>
                        </div>
                    </div>

                    <!-- Description -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                    >
                        <p
                            class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-2"
                        >
                            Description
                        </p>
                        <p
                            class="text-gray-700 dark:text-gray-300 whitespace-pre-wrap"
                        >
                            {{
                                product.description ||
                                "No description provided."
                            }}
                        </p>
                    </div>

                    <!-- Timestamps -->
                    <div class="grid grid-cols-2 gap-4">
                        <div
                            class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                        >
                            <p
                                class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1"
                            >
                                Created
                            </p>
                            <p
                                class="font-semibold text-gray-900 dark:text-white"
                            >
                                {{ formatDate(product.created_at) }}
                            </p>
                        </div>
                        <div
                            class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4"
                        >
                            <p
                                class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1"
                            >
                                Updated
                            </p>
                            <p
                                class="font-semibold text-gray-900 dark:text-white"
                            >
                                {{ formatDate(product.updated_at) }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Orders Tab -->
                <div v-show="activeTab === 'orders'" class="pt-4 space-y-4">
                    <!-- Period Filter & Export -->
                    <div class="flex items-center justify-between gap-4">
                        <select
                            v-model="selectedPeriod"
                            class="px-4 py-2 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 text-sm"
                        >
                            <option
                                v-for="opt in periodOptions"
                                :key="opt.value"
                                :value="opt.value"
                            >
                                {{ opt.label }}
                            </option>
                        </select>
                        <div class="flex items-center gap-2">
                            <button
                                @click="exportOrders('excel')"
                                :disabled="orders.length === 0"
                                class="px-3 py-2 text-sm font-medium text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/20 rounded-xl hover:bg-green-100 dark:hover:bg-green-900/30 transition-colors disabled:opacity-50 flex items-center gap-2"
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
                                        d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                                    />
                                </svg>
                                Excel
                            </button>
                            <button
                                @click="exportOrders('pdf')"
                                :disabled="orders.length === 0"
                                class="px-3 py-2 text-sm font-medium text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 rounded-xl hover:bg-red-100 dark:hover:bg-red-900/30 transition-colors disabled:opacity-50 flex items-center gap-2"
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
                                        d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                                    />
                                </svg>
                                PDF
                            </button>
                        </div>
                    </div>

                    <!-- Statistics -->
                    <div class="grid grid-cols-3 gap-4">
                        <div
                            class="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20 rounded-xl p-4"
                        >
                            <p
                                class="text-xs font-medium text-blue-600 dark:text-blue-400 uppercase"
                            >
                                Orders
                            </p>
                            <p
                                class="text-2xl font-bold text-blue-700 dark:text-blue-300 mt-1"
                            >
                                {{ stats.total_orders }}
                            </p>
                        </div>
                        <div
                            class="bg-gradient-to-br from-purple-50 to-purple-100 dark:from-purple-900/20 dark:to-purple-800/20 rounded-xl p-4"
                        >
                            <p
                                class="text-xs font-medium text-purple-600 dark:text-purple-400 uppercase"
                            >
                                Quantity Sold
                            </p>
                            <p
                                class="text-2xl font-bold text-purple-700 dark:text-purple-300 mt-1"
                            >
                                {{ stats.total_quantity }}
                            </p>
                        </div>
                        <div
                            class="bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/20 dark:to-green-800/20 rounded-xl p-4"
                        >
                            <p
                                class="text-xs font-medium text-green-600 dark:text-green-400 uppercase"
                            >
                                Revenue
                            </p>
                            <p
                                class="text-2xl font-bold text-green-700 dark:text-green-300 mt-1"
                            >
                                RM {{ stats.total_revenue }}
                            </p>
                        </div>
                    </div>

                    <!-- Orders List -->
                    <div
                        class="bg-white/50 dark:bg-slate-800/50 rounded-xl overflow-hidden"
                    >
                        <!-- Loading -->
                        <div v-if="isLoadingOrders" class="p-8 text-center">
                            <svg
                                class="w-8 h-8 animate-spin mx-auto text-primary-500"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <circle
                                    class="opacity-25"
                                    cx="12"
                                    cy="12"
                                    r="10"
                                    stroke="currentColor"
                                    stroke-width="4"
                                ></circle>
                                <path
                                    class="opacity-75"
                                    fill="currentColor"
                                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                ></path>
                            </svg>
                            <p class="text-gray-500 dark:text-gray-400 mt-2">
                                Loading orders...
                            </p>
                        </div>

                        <!-- Empty State -->
                        <div
                            v-else-if="orders.length === 0"
                            class="p-8 text-center"
                        >
                            <svg
                                class="w-12 h-12 mx-auto text-gray-300 dark:text-gray-600"
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
                            <p class="text-gray-500 dark:text-gray-400 mt-2">
                                No orders found for this period
                            </p>
                        </div>

                        <!-- Orders Table -->
                        <div v-else class="overflow-x-auto max-h-64">
                            <table class="w-full text-sm">
                                <thead
                                    class="bg-gray-50 dark:bg-slate-700/50 sticky top-0"
                                >
                                    <tr>
                                        <th
                                            class="px-4 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase"
                                        >
                                            Order #
                                        </th>
                                        <th
                                            class="px-4 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase"
                                        >
                                            Customer
                                        </th>
                                        <th
                                            class="px-4 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase"
                                        >
                                            Qty
                                        </th>
                                        <th
                                            class="px-4 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase"
                                        >
                                            Subtotal
                                        </th>
                                        <th
                                            class="px-4 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase"
                                        >
                                            Status
                                        </th>
                                        <th
                                            class="px-4 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase"
                                        >
                                            Date
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-100 dark:divide-slate-700"
                                >
                                    <tr
                                        v-for="item in orders"
                                        :key="item.id"
                                        class="hover:bg-gray-50 dark:hover:bg-slate-700/30"
                                    >
                                        <td
                                            class="px-4 py-3 text-gray-900 dark:text-white font-medium"
                                        >
                                            {{
                                                item.order?.code ||
                                                "#" + item.order_id
                                            }}
                                        </td>
                                        <td class="px-4 py-3">
                                            <div
                                                class="text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    item.order?.customer_name ||
                                                    "N/A"
                                                }}
                                            </div>
                                            <div
                                                class="text-xs text-gray-500 dark:text-gray-400"
                                            >
                                                {{
                                                    item.order
                                                        ?.customer_phone || ""
                                                }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-4 py-3 text-gray-900 dark:text-white"
                                        >
                                            {{ item.quantity }}
                                        </td>
                                        <td
                                            class="px-4 py-3 font-medium text-primary-600 dark:text-primary-400"
                                        >
                                            RM {{ formatPrice(item.subtotal) }}
                                        </td>
                                        <td class="px-4 py-3">
                                            <span
                                                :class="[
                                                    'px-2 py-1 text-xs font-medium rounded-full',
                                                    statusColors[
                                                        item.order?.status
                                                    ] ||
                                                        'bg-gray-100 text-gray-600',
                                                ]"
                                            >
                                                {{
                                                    item.order?.status_label ||
                                                    item.order?.status
                                                }}
                                            </span>
                                        </td>
                                        <td
                                            class="px-4 py-3 text-gray-500 dark:text-gray-400 text-xs"
                                        >
                                            {{ item.created_at }}
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <template #footer>
            <button
                type="button"
                @click="emit('close')"
                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Close
            </button>
            <button
                type="button"
                @click="emit('edit', product)"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all"
            >
                Edit Product
            </button>
        </template>
    </BaseModal>

    <!-- Image Gallery -->
    <ImageGallery
        :show="showGallery"
        :images="product?.image_urls || []"
        :initial-index="galleryStartIndex"
        @close="showGallery = false"
    />
</template>
