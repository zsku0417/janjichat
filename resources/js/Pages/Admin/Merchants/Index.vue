<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import DataTable from "@/Components/DataTable.vue";
import TableActionButton from "@/Components/TableActionButton.vue";
import DeleteModal from "@/Components/DeleteModal.vue";
import CreateModal from "@/Components/Merchants/CreateModal.vue";
import EditModal from "@/Components/Merchants/EditModal.vue";
import ViewModal from "@/Components/Merchants/ViewModal.vue";
import { Head, router } from "@inertiajs/vue3";
import { ref, computed } from "vue";

const props = defineProps({
    merchants: Object,
    businessTypes: Object,
    filters: Object,
});

// Table columns configuration
const columns = [
    { key: "name", label: "Merchant", sortable: true },
    { key: "business_type_label", label: "Business Type", sortable: true },
    { key: "email_verified", label: "Verified", sortable: false },
    { key: "has_whatsapp", label: "WhatsApp", sortable: false },
    { key: "is_active", label: "Status", sortable: true },
    { key: "created_at", label: "Created", sortable: true },
];

// Loading state
const isLoading = ref(false);

// Create modal state
const showCreateModal = ref(false);

const openCreateModal = () => {
    showCreateModal.value = true;
};

const closeCreateModal = () => {
    showCreateModal.value = false;
};

// Edit modal state
const showEditModal = ref(false);
const editingMerchant = ref(null);

const openEditModal = (merchant) => {
    editingMerchant.value = merchant;
    showEditModal.value = true;
};

const closeEditModal = () => {
    showEditModal.value = false;
    editingMerchant.value = null;
};

// View modal state
const showViewModal = ref(false);
const viewingMerchant = ref(null);

const openViewModal = (merchant) => {
    viewingMerchant.value = merchant;
    showViewModal.value = true;
};

const closeViewModal = () => {
    showViewModal.value = false;
    viewingMerchant.value = null;
};

// Toggle active
const toggleActive = (merchant) => {
    router.patch(route("admin.merchants.toggle-active", merchant.id));
};

// Resend email
const resendEmail = (merchant) => {
    router.post(route("admin.merchants.resend-email", merchant.id));
};

// Delete modal state
const showDeleteModal = ref(false);
const merchantToDelete = ref(null);
const isDeleting = ref(false);

const openDeleteModal = (merchant) => {
    merchantToDelete.value = merchant;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    merchantToDelete.value = null;
};

const confirmDelete = () => {
    if (!merchantToDelete.value) return;

    isDeleting.value = true;
    router.delete(route("admin.merchants.destroy", merchantToDelete.value.id), {
        onFinish: () => {
            isDeleting.value = false;
            closeDeleteModal();
        },
    });
};

// Helper to build query params
const buildParams = (overrides = {}) => ({
    search: props.filters.search,
    status: props.filters.status,
    sort_key: props.filters.sort_key,
    sort_order: props.filters.sort_order,
    ...overrides,
});

// Filter by status
const filterByStatus = (status) => {
    isLoading.value = true;
    router.get(
        route("admin.merchants.index"),
        buildParams({ status, page: 1 }),
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

// Server-side search
const handleSearch = (query) => {
    isLoading.value = true;
    router.get(
        route("admin.merchants.index"),
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
        route("admin.merchants.index"),
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
    router.get(route("admin.merchants.index"), buildParams({ page }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

// Clear filters
const clearFilters = () => {
    isLoading.value = true;
    router.get(
        route("admin.merchants.index"),
        {},
        {
            preserveState: true,
            onFinish: () => (isLoading.value = false),
        }
    );
};

// Server pagination data
const serverPagination = computed(() => ({
    current_page: props.merchants.current_page,
    last_page: props.merchants.last_page,
    total: props.merchants.total,
    per_page: props.merchants.per_page,
}));

// Check if any filter is active
const hasActiveFilters = computed(() => {
    return props.filters.search || props.filters.status !== "all";
});
</script>

<template>
    <Head title="Manage Merchants" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Merchants</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Manage merchant accounts
                    </p>
                </div>
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
                    Add Merchant
                </button>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <DataTable
                    :columns="columns"
                    :data="merchants.data"
                    :server-pagination="serverPagination"
                    :per-page="merchants.per_page"
                    :searchable="true"
                    search-placeholder="Search by name or email..."
                    :initial-search="filters.search"
                    :initial-sort-key="filters.sort_key"
                    :initial-sort-order="filters.sort_order"
                    :loading="isLoading"
                    :server-side="true"
                    empty-message="No merchants found"
                    @page-change="handlePageChange"
                    @search="handleSearch"
                    @sort="handleSort"
                >
                    <!-- Filters Slot -->
                    <template #filters>
                        <div class="flex flex-wrap items-center gap-3">
                            <select
                                :value="filters.status"
                                @change="filterByStatus($event.target.value)"
                                class="px-4 py-2 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 text-sm"
                            >
                                <option value="all">All Status</option>
                                <option value="active">Active</option>
                                <option value="inactive">Inactive</option>
                                <option value="verified">Verified</option>
                                <option value="pending">
                                    Pending Verification
                                </option>
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

                    <!-- Merchant Cell (Name + Email) -->
                    <template #cell-name="{ row, highlight }">
                        <div>
                            <div
                                class="font-medium text-gray-900 dark:text-white"
                                v-html="highlight(row.name)"
                            ></div>
                            <div
                                class="text-xs text-gray-500 dark:text-gray-400"
                                v-html="highlight(row.email)"
                            ></div>
                        </div>
                    </template>

                    <!-- Business Type Cell -->
                    <template #cell-business_type_label="{ row }">
                        <span
                            :class="[
                                row.business_type === 'restaurant'
                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                    : 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
                                'px-3 py-1 text-xs font-medium rounded-full text-nowrap',
                            ]"
                        >
                            {{ row.business_type_label }}
                        </span>
                    </template>

                    <!-- Email Verified Cell -->
                    <template #cell-email_verified="{ row }">
                        <span
                            :class="[
                                row.email_verified
                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                    : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
                                'px-3 py-1 text-xs font-medium rounded-full',
                            ]"
                        >
                            {{
                                row.email_verified ? "✓ Verified" : "⏳ Pending"
                            }}
                        </span>
                    </template>

                    <!-- WhatsApp Cell -->
                    <template #cell-has_whatsapp="{ row }">
                        <span
                            :class="[
                                row.has_whatsapp
                                    ? 'text-green-600 dark:text-green-400'
                                    : 'text-gray-400',
                                'text-lg',
                            ]"
                        >
                            {{ row.has_whatsapp ? "✓" : "—" }}
                        </span>
                    </template>

                    <!-- Active Status Cell -->
                    <template #cell-is_active="{ row }">
                        <button
                            @click="toggleActive(row)"
                            :class="[
                                row.is_active
                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300 hover:bg-green-200'
                                    : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300 hover:bg-red-200',
                                'px-3 py-1 text-xs font-medium rounded-full transition-colors cursor-pointer',
                            ]"
                        >
                            {{ row.is_active ? "Active" : "Inactive" }}
                        </button>
                    </template>

                    <!-- Actions -->
                    <template #actions="{ row }">
                        <TableActionButton
                            type="view"
                            @click="openViewModal(row)"
                        />
                        <TableActionButton
                            type="edit"
                            @click="openEditModal(row)"
                        />
                        <TableActionButton
                            v-if="!row.email_verified"
                            type="view"
                            title="Resend Email"
                            @click="resendEmail(row)"
                        />
                        <TableActionButton
                            type="delete"
                            @click="openDeleteModal(row)"
                        />
                    </template>
                </DataTable>
            </div>
        </div>

        <!-- Create Modal -->
        <CreateModal
            :show="showCreateModal"
            :business-types="businessTypes"
            @close="closeCreateModal"
            @success="closeCreateModal"
        />

        <!-- Edit Modal -->
        <EditModal
            :show="showEditModal"
            :merchant="editingMerchant"
            :business-types="businessTypes"
            @close="closeEditModal"
            @success="closeEditModal"
        />

        <!-- View Modal -->
        <ViewModal
            :show="showViewModal"
            :merchant="viewingMerchant"
            @close="closeViewModal"
        />

        <!-- Delete Modal -->
        <DeleteModal
            :show="showDeleteModal"
            title="Delete Merchant"
            :message="`Are you sure you want to delete '${merchantToDelete?.name}'? All associated data (conversations, bookings, orders, documents) will be permanently deleted.`"
            :processing="isDeleting"
            @close="closeDeleteModal"
            @confirm="confirmDelete"
        />
    </AuthenticatedLayout>
</template>
