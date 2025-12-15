<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import DataTable from "@/Components/DataTable.vue";
import TableActionButton from "@/Components/TableActionButton.vue";
import BaseModal from "@/Components/BaseModal.vue";
import DeleteModal from "@/Components/DeleteModal.vue";
import ViewBookingModal from "@/Components/Bookings/ViewBookingModal.vue";
import EditBookingModal from "@/Components/Bookings/EditBookingModal.vue";
import { Head, useForm, router } from "@inertiajs/vue3";
import { ref, computed } from "vue";

const props = defineProps({
    bookings: Object,
    tables: Array,
    filters: Object,
    restaurantSettings: {
        type: Object,
        default: () => ({
            opening_time: "09:00",
            closing_time: "22:00",
        }),
    },
});

// Get today's date in YYYY-MM-DD format for min date validation
const todayDate = computed(() => {
    const today = new Date();
    return today.toISOString().split("T")[0];
});

// Table columns configuration
const columns = [
    { key: "customer_name", label: "Customer", sortable: true },
    { key: "booking_date_formatted", label: "Date & Time", sortable: true },
    { key: "table_name", label: "Table", sortable: true },
    { key: "pax", label: "Guests", sortable: true },
    { key: "status", label: "Status", sortable: true },
    { key: "special_request", label: "Notes", sortable: false },
    { key: "created_by", label: "Created By", sortable: true },
];

// Loading state
const isLoading = ref(false);

const showCreateModal = ref(false);

const createForm = useForm({
    customer_name: "",
    customer_phone: "",
    booking_date: "",
    booking_time: "",
    pax: 2,
    special_request: "",
});

const submitBooking = () => {
    createForm.post(route("bookings.store"), {
        onSuccess: () => {
            showCreateModal.value = false;
            createForm.reset();
        },
    });
};

// View modal state
const showViewModal = ref(false);
const viewingBooking = ref(null);

const openViewModal = (booking) => {
    viewingBooking.value = booking;
    showViewModal.value = true;
};

const closeViewModal = () => {
    showViewModal.value = false;
    viewingBooking.value = null;
};

// Edit modal state
const showEditModal = ref(false);
const editingBooking = ref(null);

const openEditModal = (booking) => {
    // Close view modal if open
    showViewModal.value = false;
    editingBooking.value = booking;
    showEditModal.value = true;
};

const closeEditModal = () => {
    showEditModal.value = false;
    editingBooking.value = null;
};

// Cancel modal state
const showCancelModal = ref(false);
const bookingToCancel = ref(null);
const isCancelling = ref(false);

const openCancelModal = (booking) => {
    bookingToCancel.value = booking;
    showCancelModal.value = true;
};

const closeCancelModal = () => {
    showCancelModal.value = false;
    bookingToCancel.value = null;
};

const confirmCancelBooking = () => {
    if (!bookingToCancel.value) return;

    isCancelling.value = true;
    router.post(
        route("bookings.cancel", bookingToCancel.value.id),
        {},
        {
            onFinish: () => {
                isCancelling.value = false;
                closeCancelModal();
            },
        }
    );
};

// Delete modal state
const showDeleteModal = ref(false);
const bookingToDelete = ref(null);
const isDeleting = ref(false);

const openDeleteModal = (booking) => {
    bookingToDelete.value = booking;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    bookingToDelete.value = null;
};

const confirmDeleteBooking = () => {
    if (!bookingToDelete.value) return;

    isDeleting.value = true;
    router.delete(route("bookings.destroy", bookingToDelete.value.id), {
        onFinish: () => {
            isDeleting.value = false;
            closeDeleteModal();
        },
    });
};

// Helper to build query params preserving all filters
const buildParams = (overrides = {}) => ({
    date: props.filters.date,
    status: props.filters.status,
    search: props.filters.search,
    sort_key: props.filters.sort_key,
    sort_order: props.filters.sort_order,
    ...overrides,
});

// Filter handlers
const filterByDate = (date) => {
    isLoading.value = true;
    router.get(route("bookings.index"), buildParams({ date, page: 1 }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

const filterByStatus = (status) => {
    isLoading.value = true;
    router.get(route("bookings.index"), buildParams({ status, page: 1 }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

// Server-side search
const handleSearch = (query) => {
    isLoading.value = true;
    router.get(
        route("bookings.index"),
        buildParams({ search: query, page: 1 }),
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

// Server-side sort
const handleSort = ({ key, order }) => {
    isLoading.value = true;
    router.get(
        route("bookings.index"),
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
    router.get(route("bookings.index"), buildParams({ page }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

// Clear all filters
const clearFilters = () => {
    isLoading.value = true;
    router.get(
        route("bookings.index"),
        {},
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

const getStatusColor = (status) => {
    switch (status) {
        case "confirmed":
            return "bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300";
        case "cancelled":
            return "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300";
        case "completed":
            return "bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300";
        case "no_show":
            return "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300";
        default:
            return "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300";
    }
};

// Server pagination data
const serverPagination = computed(() => ({
    current_page: props.bookings.current_page,
    last_page: props.bookings.last_page,
    total: props.bookings.total,
    per_page: props.bookings.per_page,
}));

// Check if any filter is active
const hasActiveFilters = computed(() => {
    return (
        props.filters.date ||
        props.filters.status !== "all" ||
        props.filters.search
    );
});
</script>

<template>
    <Head title="Bookings" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Bookings</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Manage your restaurant reservations
                    </p>
                </div>
                <button
                    @click="showCreateModal = true"
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
                    New Booking
                </button>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <DataTable
                    :columns="columns"
                    :data="bookings.data"
                    :server-pagination="serverPagination"
                    :per-page="bookings.per_page"
                    :searchable="true"
                    search-placeholder="Search by name, phone, or table..."
                    :initial-search="filters.search"
                    :initial-sort-key="filters.sort_key"
                    :initial-sort-order="filters.sort_order"
                    :loading="isLoading"
                    :server-side="true"
                    empty-message="No bookings found"
                    @page-change="handlePageChange"
                    @search="handleSearch"
                    @sort="handleSort"
                >
                    <!-- Filters Slot -->
                    <template #filters>
                        <div class="flex flex-wrap items-center gap-3">
                            <div class="relative">
                                <input
                                    type="date"
                                    :value="filters.date"
                                    @change="filterByDate($event.target.value)"
                                    class="px-4 py-2 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 text-sm"
                                />
                            </div>
                            <select
                                :value="filters.status"
                                @change="filterByStatus($event.target.value)"
                                class="px-4 py-2 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 text-sm"
                            >
                                <option value="all">All Status</option>
                                <option value="confirmed">Confirmed</option>
                                <option value="cancelled">Cancelled</option>
                                <option value="completed">Completed</option>
                                <option value="no_show">No Show</option>
                            </select>
                            <button
                                v-if="hasActiveFilters"
                                @click="clearFilters"
                                class="px-3 py-2 rounded-xl text-sm font-medium text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors flex items-center gap-1"
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
                                        d="M6 18L18 6M6 6l12 12"
                                    />
                                </svg>
                                Clear
                            </button>
                        </div>
                    </template>

                    <!-- Customer Cell -->
                    <template #cell-customer_name="{ row, highlight }">
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
                    </template>

                    <!-- Date & Time Cell -->
                    <template #cell-booking_date_formatted="{ row }">
                        <div>
                            <div
                                class="font-medium text-gray-900 dark:text-white"
                            >
                                {{ row.booking_date_formatted }}
                            </div>
                            <div
                                class="text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ row.booking_time }}
                            </div>
                        </div>
                    </template>

                    <!-- Status Cell -->
                    <template #cell-status="{ row }">
                        <span
                            :class="[
                                getStatusColor(row.status),
                                'px-3 py-1 text-xs font-medium rounded-full capitalize',
                            ]"
                        >
                            {{ row.status }}
                        </span>
                    </template>

                    <!-- Created By Cell -->
                    <template #cell-created_by="{ row }">
                        <span class="inline-flex items-center gap-1 text-sm">
                            <span v-if="row.created_by === 'admin'">👤</span>
                            <span v-else>📱</span>
                            <span class="text-gray-500 dark:text-gray-400">
                                {{
                                    row.created_by === "admin"
                                        ? "Admin"
                                        : "Customer"
                                }}
                            </span>
                        </span>
                    </template>

                    <!-- Special Request Cell -->
                    <template #cell-special_request="{ row }">
                        <span
                            v-if="row.special_request"
                            class="text-sm text-gray-500 dark:text-gray-400 truncate block max-w-32"
                            :title="row.special_request"
                        >
                            {{ row.special_request }}
                        </span>
                        <span v-else class="text-gray-300 dark:text-gray-600"
                            >—</span
                        >
                    </template>

                    <!-- Actions -->
                    <template #actions="{ row }">
                        <TableActionButton
                            type="view"
                            @click="openViewModal(row)"
                        />
                        <TableActionButton
                            v-if="row.status === 'confirmed'"
                            type="edit"
                            @click="openEditModal(row)"
                        />
                        <TableActionButton
                            v-if="row.status === 'confirmed'"
                            type="cancel"
                            @click="openCancelModal(row)"
                        />
                        <TableActionButton
                            type="delete"
                            @click="openDeleteModal(row)"
                        />
                    </template>
                </DataTable>
            </div>
        </div>

        <!-- Create Booking Modal -->
        <BaseModal
            :show="showCreateModal"
            title="New Booking"
            icon="plus"
            size="md"
            @close="showCreateModal = false"
        >
            <template #content>
                <form @submit.prevent="submitBooking" id="createBookingForm">
                    <div class="space-y-4">
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Customer Name
                            </label>
                            <input
                                v-model="createForm.customer_name"
                                type="text"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                            <p
                                v-if="createForm.errors.customer_name"
                                class="mt-1 text-sm text-red-600 dark:text-red-400"
                            >
                                {{ createForm.errors.customer_name }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Phone Number
                            </label>
                            <input
                                v-model="createForm.customer_phone"
                                type="tel"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                        </div>
                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <label
                                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                >
                                    Date
                                </label>
                                <input
                                    v-model="createForm.booking_date"
                                    type="date"
                                    :min="todayDate"
                                    required
                                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                            <div>
                                <label
                                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                >
                                    Time
                                </label>
                                <input
                                    v-model="createForm.booking_time"
                                    type="time"
                                    :min="restaurantSettings.opening_time"
                                    :max="restaurantSettings.closing_time"
                                    required
                                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Number of Guests
                            </label>
                            <input
                                v-model="createForm.pax"
                                type="number"
                                min="1"
                                max="50"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Special Request
                            </label>
                            <textarea
                                v-model="createForm.special_request"
                                rows="2"
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 resize-none"
                                placeholder="Any special requests..."
                            ></textarea>
                        </div>
                    </div>
                </form>
            </template>
            <template #footer>
                <button
                    type="button"
                    @click="showCreateModal = false"
                    class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
                >
                    Cancel
                </button>
                <button
                    type="submit"
                    form="createBookingForm"
                    :disabled="createForm.processing"
                    class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
                >
                    {{
                        createForm.processing ? "Creating..." : "Create Booking"
                    }}
                </button>
            </template>
        </BaseModal>

        <!-- View Booking Modal -->
        <ViewBookingModal
            :show="showViewModal"
            :booking="viewingBooking"
            @close="closeViewModal"
            @edit="openEditModal"
        />

        <!-- Edit Booking Modal -->
        <EditBookingModal
            :show="showEditModal"
            :booking="editingBooking"
            :restaurant-settings="restaurantSettings"
            @close="closeEditModal"
            @updated="closeEditModal"
        />

        <!-- Cancel Booking Modal -->
        <BaseModal
            :show="showCancelModal"
            title="Cancel Booking"
            :message="`Are you sure you want to cancel the booking for ${bookingToCancel?.customer_name}? The customer will be notified.`"
            confirmText="Cancel Booking"
            :processing="isCancelling"
            @close="closeCancelModal"
            @confirm="confirmCancelBooking"
        />

        <!-- Delete Booking Modal -->
        <DeleteModal
            :show="showDeleteModal"
            title="Delete Booking"
            :message="`Are you sure you want to permanently delete the booking for ${bookingToDelete?.customer_name}? This action cannot be undone.`"
            :processing="isDeleting"
            @close="closeDeleteModal"
            @confirm="confirmDeleteBooking"
        />
    </AuthenticatedLayout>
</template>
