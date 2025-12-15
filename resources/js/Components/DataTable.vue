<script setup>
import { ref, computed, watch, onMounted } from "vue";

const props = defineProps({
    // Column definitions: { key, label, sortable?, class?, render?, width? }
    columns: {
        type: Array,
        required: true,
    },
    // Data array
    data: {
        type: Array,
        required: true,
    },
    // Search configuration
    searchable: {
        type: Boolean,
        default: true,
    },
    searchPlaceholder: {
        type: String,
        default: "Search...",
    },
    searchKeys: {
        type: Array,
        default: () => [], // Keys to search in, empty = all string fields
    },
    // Initial search value (for server-side)
    initialSearch: {
        type: String,
        default: "",
    },
    // Initial sort state (for server-side)
    initialSortKey: {
        type: String,
        default: null,
    },
    initialSortOrder: {
        type: String,
        default: "asc",
    },
    // Server-side mode - disables client-side filtering/sorting
    serverSide: {
        type: Boolean,
        default: false,
    },
    // Pagination
    paginated: {
        type: Boolean,
        default: true,
    },
    perPage: {
        type: Number,
        default: 10,
    },
    // Server-side pagination data (optional)
    serverPagination: {
        type: Object,
        default: null, // { current_page, last_page, total, per_page }
    },
    // Loading state
    loading: {
        type: Boolean,
        default: false,
    },
    // Empty state message
    emptyMessage: {
        type: String,
        default: "No data found",
    },
    // Row key
    rowKey: {
        type: String,
        default: "id",
    },
});

const emit = defineEmits(["sort", "search", "page-change", "action"]);

// Search - initialize from prop
const searchQuery = ref(props.initialSearch || "");
const debouncedSearch = ref(props.initialSearch || "");
let searchTimeout = null;

watch(searchQuery, (value) => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        debouncedSearch.value = value;
        emit("search", value);
    }, 300);
});

// Sorting - initialize from props
const sortKey = ref(props.initialSortKey);
const sortOrder = ref(props.initialSortOrder || "asc");

const toggleSort = (column) => {
    if (!column.sortable) return;

    if (sortKey.value === column.key) {
        sortOrder.value = sortOrder.value === "asc" ? "desc" : "asc";
    } else {
        sortKey.value = column.key;
        sortOrder.value = "asc";
    }

    emit("sort", { key: sortKey.value, order: sortOrder.value });
};

// Pagination
const currentPage = ref(1);
const totalPages = computed(() => {
    if (props.serverPagination) {
        return props.serverPagination.last_page || 1;
    }
    return Math.ceil(filteredData.value.length / props.perPage);
});

const goToPage = (page) => {
    if (page < 1 || page > totalPages.value) return;
    currentPage.value = page;
    emit("page-change", page);
};

// Reset page when search changes (for client-side only)
watch(debouncedSearch, () => {
    if (!props.serverSide) {
        currentPage.value = 1;
    }
});

// Client-side filtering & sorting (only when not in server-side mode)
const filteredData = computed(() => {
    let result = [...props.data];

    // Skip client-side operations if in server-side mode
    if (props.serverSide || props.serverPagination) {
        return result;
    }

    // Search filter (client-side)
    if (debouncedSearch.value) {
        const query = debouncedSearch.value.toLowerCase();
        const keys =
            props.searchKeys.length > 0
                ? props.searchKeys
                : props.columns.map((c) => c.key);

        result = result.filter((item) => {
            return keys.some((key) => {
                const value = item[key];
                if (value == null) return false;
                return String(value).toLowerCase().includes(query);
            });
        });
    }

    // Sort (client-side)
    if (sortKey.value) {
        result.sort((a, b) => {
            const aVal = a[sortKey.value];
            const bVal = b[sortKey.value];

            if (aVal == null) return 1;
            if (bVal == null) return -1;

            let comparison = 0;
            if (typeof aVal === "string") {
                comparison = aVal.localeCompare(bVal);
            } else {
                comparison = aVal - bVal;
            }

            return sortOrder.value === "desc" ? -comparison : comparison;
        });
    }

    return result;
});

// Paginated data
const paginatedData = computed(() => {
    if (props.serverPagination) {
        return props.data; // Server already paginated
    }

    if (!props.paginated) {
        return filteredData.value;
    }

    const start = (currentPage.value - 1) * props.perPage;
    return filteredData.value.slice(start, start + props.perPage);
});

// Pagination display range
const paginationRange = computed(() => {
    const total = totalPages.value;
    const current = props.serverPagination?.current_page || currentPage.value;
    const delta = 2;

    const range = [];
    const rangeWithDots = [];

    for (let i = 1; i <= total; i++) {
        if (
            i === 1 ||
            i === total ||
            (i >= current - delta && i <= current + delta)
        ) {
            range.push(i);
        }
    }

    let prev = null;
    for (const i of range) {
        if (prev) {
            if (i - prev === 2) {
                rangeWithDots.push(prev + 1);
            } else if (i - prev !== 1) {
                rangeWithDots.push("...");
            }
        }
        rangeWithDots.push(i);
        prev = i;
    }

    return rangeWithDots;
});

// Highlight search term in text (case-insensitive)
const highlightSearch = (text) => {
    if (!searchQuery.value || !text) return text;

    const searchTerm = searchQuery.value.trim();
    if (!searchTerm) return text;

    // Escape special regex characters
    const escapedTerm = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    // Create case-insensitive regex
    const regex = new RegExp(`(${escapedTerm})`, "gi");

    // Replace matches with highlighted span
    return String(text).replace(
        regex,
        '<mark class="bg-yellow-200 dark:bg-yellow-500/40 text-inherit px-0.5 rounded">$1</mark>'
    );
};

// Mobile card view
const isMobileView = ref(false);
const checkMobile = () => {
    isMobileView.value = window.innerWidth < 768;
};

// Check on mount and resize
if (typeof window !== "undefined") {
    checkMobile();
    window.addEventListener("resize", checkMobile);
}
</script>

<template>
    <div class="data-table-wrapper">
        <!-- Header: Search + Filters Slot -->
        <div
            class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6"
        >
            <!-- Search -->
            <div v-if="searchable" class="relative flex-1 max-w-md">
                <div
                    class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
                >
                    <svg
                        class="w-5 h-5 text-gray-400"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                        />
                    </svg>
                </div>
                <input
                    v-model="searchQuery"
                    type="text"
                    :placeholder="searchPlaceholder"
                    class="w-full pl-10 pr-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-primary-500 transition-all"
                />
            </div>

            <!-- Filters Slot -->
            <div class="flex items-center gap-3">
                <slot name="filters"></slot>
            </div>
        </div>

        <!-- Table Container -->
        <div class="glass rounded-2xl overflow-hidden">
            <!-- Loading Overlay -->
            <div
                v-if="loading"
                class="absolute inset-0 bg-white/50 dark:bg-slate-900/50 flex items-center justify-center z-10 rounded-2xl"
            >
                <div
                    class="flex items-center gap-3 px-4 py-2 bg-white dark:bg-slate-800 rounded-xl shadow-lg"
                >
                    <svg
                        class="animate-spin w-5 h-5 text-primary-500"
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
                    <span
                        class="text-sm font-medium text-gray-600 dark:text-gray-300"
                        >Loading...</span
                    >
                </div>
            </div>

            <!-- Desktop Table View -->
            <div class="hidden md:block overflow-x-auto">
                <table class="w-full table-fixed">
                    <thead>
                        <tr
                            class="bg-gradient-to-r from-primary-500/5 to-secondary-500/5 dark:from-primary-500/10 dark:to-secondary-500/10 border-b border-gray-100 dark:border-slate-700"
                        >
                            <th
                                v-for="column in columns"
                                :key="column.key"
                                :class="[
                                    'px-6 py-4 text-left text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase tracking-wider',
                                    column.sortable
                                        ? 'cursor-pointer hover:bg-white/50 dark:hover:bg-slate-700/50 transition-colors select-none'
                                        : '',
                                    column.class || '',
                                ]"
                                :style="{ width: column.width }"
                                @click="toggleSort(column)"
                            >
                                <div class="flex items-center gap-2">
                                    <span>{{ column.label }}</span>
                                    <span
                                        v-if="column.sortable"
                                        class="flex flex-col"
                                    >
                                        <svg
                                            :class="[
                                                'w-3 h-3 -mb-1',
                                                sortKey === column.key &&
                                                sortOrder === 'asc'
                                                    ? 'text-primary-500'
                                                    : 'text-gray-300 dark:text-gray-600',
                                            ]"
                                            fill="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                d="M12 8l-6 6 1.41 1.41L12 10.83l4.59 4.58L18 14z"
                                            />
                                        </svg>
                                        <svg
                                            :class="[
                                                'w-3 h-3 -mt-1',
                                                sortKey === column.key &&
                                                sortOrder === 'desc'
                                                    ? 'text-primary-500'
                                                    : 'text-gray-300 dark:text-gray-600',
                                            ]"
                                            fill="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                d="M16.59 8.59L12 13.17 7.41 8.59 6 10l6 6 6-6z"
                                            />
                                        </svg>
                                    </span>
                                </div>
                            </th>
                            <!-- Actions Column -->
                            <th
                                v-if="$slots.actions"
                                class="px-6 py-4 text-right text-xs font-semibold text-gray-600 dark:text-gray-300 uppercase tracking-wider"
                            >
                                Actions
                            </th>
                        </tr>
                    </thead>
                    <tbody
                        class="divide-y divide-gray-100 dark:divide-slate-700"
                    >
                        <tr
                            v-for="(row, index) in paginatedData"
                            :key="row[rowKey] || index"
                            class="hover:bg-white/50 dark:hover:bg-slate-700/30 transition-colors"
                        >
                            <td
                                v-for="column in columns"
                                :key="column.key"
                                :class="[
                                    'px-6 py-4 text-sm text-gray-700 dark:text-gray-200',
                                    column.class || '',
                                ]"
                            >
                                <slot
                                    :name="`cell-${column.key}`"
                                    :row="row"
                                    :value="row[column.key]"
                                    :highlight="highlightSearch"
                                >
                                    <span
                                        v-html="
                                            highlightSearch(row[column.key])
                                        "
                                    ></span>
                                </slot>
                            </td>
                            <!-- Actions Cell -->
                            <td
                                v-if="$slots.actions"
                                class="px-6 py-4 text-right"
                            >
                                <div
                                    class="flex items-center justify-end gap-2"
                                >
                                    <slot name="actions" :row="row"></slot>
                                </div>
                            </td>
                        </tr>
                        <!-- Empty State -->
                        <tr v-if="paginatedData.length === 0 && !loading">
                            <td
                                :colspan="
                                    columns.length + ($slots.actions ? 1 : 0)
                                "
                                class="px-6 py-12 text-center"
                            >
                                <div class="flex flex-col items-center">
                                    <div
                                        class="w-16 h-16 bg-gray-100 dark:bg-slate-700 rounded-2xl flex items-center justify-center mb-4"
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
                                                d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                                            />
                                        </svg>
                                    </div>
                                    <p class="text-gray-500 dark:text-gray-400">
                                        {{ emptyMessage }}
                                    </p>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Mobile Card View -->
            <div
                class="md:hidden divide-y divide-gray-100 dark:divide-slate-700"
            >
                <div
                    v-for="(row, index) in paginatedData"
                    :key="row[rowKey] || index"
                    class="p-4 hover:bg-white/50 dark:hover:bg-slate-700/30 transition-colors"
                >
                    <div class="space-y-3">
                        <div
                            v-for="column in columns"
                            :key="column.key"
                            class="flex justify-between items-start gap-4"
                        >
                            <span
                                class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase"
                            >
                                {{ column.label }}
                            </span>
                            <span
                                class="text-sm text-gray-900 dark:text-white text-right"
                            >
                                <slot
                                    :name="`cell-${column.key}`"
                                    :row="row"
                                    :value="row[column.key]"
                                    :highlight="highlightSearch"
                                >
                                    <span
                                        v-html="
                                            highlightSearch(row[column.key])
                                        "
                                    ></span>
                                </slot>
                            </span>
                        </div>
                        <!-- Mobile Actions -->
                        <div
                            v-if="$slots.actions"
                            class="flex items-center justify-end gap-2 pt-2 border-t border-gray-100 dark:border-slate-700"
                        >
                            <slot name="actions" :row="row"></slot>
                        </div>
                    </div>
                </div>
                <!-- Empty State Mobile -->
                <div
                    v-if="paginatedData.length === 0 && !loading"
                    class="p-8 text-center"
                >
                    <div class="flex flex-col items-center">
                        <div
                            class="w-16 h-16 bg-gray-100 dark:bg-slate-700 rounded-2xl flex items-center justify-center mb-4"
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
                                    d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                                />
                            </svg>
                        </div>
                        <p class="text-gray-500 dark:text-gray-400">
                            {{ emptyMessage }}
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Pagination -->
        <div
            v-if="paginated && totalPages > 1"
            class="flex flex-col sm:flex-row items-center justify-between gap-4 mt-6"
        >
            <p class="text-sm text-gray-500 dark:text-gray-400">
                Showing
                {{
                    ((serverPagination?.current_page || currentPage) - 1) *
                        perPage +
                    1
                }}
                to
                {{
                    Math.min(
                        (serverPagination?.current_page || currentPage) *
                            perPage,
                        serverPagination?.total || filteredData.length
                    )
                }}
                of {{ serverPagination?.total || filteredData.length }} results
            </p>

            <nav class="flex items-center gap-1">
                <!-- Previous -->
                <button
                    @click="
                        goToPage(
                            (serverPagination?.current_page || currentPage) - 1
                        )
                    "
                    :disabled="
                        (serverPagination?.current_page || currentPage) === 1
                    "
                    class="w-9 h-9 flex items-center justify-center rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
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
                            d="M15 19l-7-7 7-7"
                        />
                    </svg>
                </button>

                <!-- Page Numbers -->
                <template v-for="page in paginationRange" :key="page">
                    <span
                        v-if="page === '...'"
                        class="w-9 h-9 flex items-center justify-center text-gray-400"
                    >
                        ...
                    </span>
                    <button
                        v-else
                        @click="goToPage(page)"
                        :class="[
                            'w-9 h-9 flex items-center justify-center rounded-lg text-sm font-medium transition-all',
                            (serverPagination?.current_page || currentPage) ===
                            page
                                ? 'bg-gradient-to-r from-primary-500 to-secondary-500 text-white shadow-lg shadow-primary-500/30'
                                : 'text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700',
                        ]"
                    >
                        {{ page }}
                    </button>
                </template>

                <!-- Next -->
                <button
                    @click="
                        goToPage(
                            (serverPagination?.current_page || currentPage) + 1
                        )
                    "
                    :disabled="
                        (serverPagination?.current_page || currentPage) ===
                        totalPages
                    "
                    class="w-9 h-9 flex items-center justify-center rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
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
                            d="M9 5l7 7-7 7"
                        />
                    </svg>
                </button>
            </nav>
        </div>
    </div>
</template>
