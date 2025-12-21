<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import DataTable from "@/Components/DataTable.vue";
import TableActionButton from "@/Components/TableActionButton.vue";
import BaseModal from "@/Components/BaseModal.vue";
import DeleteModal from "@/Components/DeleteModal.vue";
import ViewProductModal from "@/Components/Products/ViewProductModal.vue";
import EditProductModal from "@/Components/Products/EditProductModal.vue";
import { Head, router } from "@inertiajs/vue3";
import { ref, computed } from "vue";
import axios from "axios";

const MAX_IMAGES = 3;

const props = defineProps({
    products: Object,
    filters: {
        type: Object,
        default: () => ({
            search: "",
            status: "all",
            sort_key: "updated_at",
            sort_order: "desc",
        }),
    },
});

// Table columns configuration
const columns = [
    { key: "name", label: "Product", sortable: true, width: "30%" },
    { key: "price", label: "Price", sortable: true },
    { key: "total_sales", label: "Total Sales", sortable: false },
    { key: "is_active", label: "Status", sortable: true },
    { key: "updated_at", label: "Updated", sortable: true },
];

// Loading state
const isLoading = ref(false);

// Create modal state
const showCreateModal = ref(false);
const createFormData = ref({
    name: "",
    price: "",
    description: "",
    is_active: true,
});
const newCreateImages = ref([]);
const newCreatePreviews = ref([]);
const createErrors = ref({});
const isCreating = ref(false);

const totalCreateImageCount = computed(() => newCreatePreviews.value.length);
const canAddMoreCreateImages = computed(
    () => totalCreateImageCount.value < MAX_IMAGES
);

const handleCreateFileSelect = (event) => {
    const files = Array.from(event.target.files);
    const remainingSlots = MAX_IMAGES - totalCreateImageCount.value;
    const filesToAdd = files.slice(0, remainingSlots);

    filesToAdd.forEach((file) => {
        newCreateImages.value.push(file);

        const reader = new FileReader();
        reader.onload = (e) => {
            newCreatePreviews.value.push({
                url: e.target.result,
                name: file.name,
            });
        };
        reader.readAsDataURL(file);
    });

    event.target.value = "";
};

const removeCreateImage = (index) => {
    newCreateImages.value.splice(index, 1);
    newCreatePreviews.value.splice(index, 1);
};

const resetCreateForm = () => {
    createFormData.value = {
        name: "",
        price: "",
        description: "",
        is_active: true,
    };
    newCreateImages.value = [];
    newCreatePreviews.value = [];
    createErrors.value = {};
};

const handleCreateClose = () => {
    // Prevent closing while processing
    if (isCreating.value) return;

    showCreateModal.value = false;
    resetCreateForm();
};

const submitCreateProduct = async () => {
    if (isCreating.value) return;

    isCreating.value = true;
    createErrors.value = {};

    try {
        const formData = new FormData();
        formData.append("name", createFormData.value.name);
        formData.append("price", createFormData.value.price);
        formData.append("description", createFormData.value.description || "");
        formData.append(
            "is_active",
            createFormData.value.is_active ? "1" : "0"
        );

        newCreateImages.value.forEach((file, index) => {
            formData.append(`images[${index}]`, file);
        });

        await axios.post(route("products.store"), formData, {
            headers: { "Content-Type": "multipart/form-data" },
        });

        showCreateModal.value = false;
        resetCreateForm();
        router.reload({ only: ["products"] });
    } catch (error) {
        if (error.response?.status === 422) {
            createErrors.value = error.response.data.errors || {};
        } else {
            console.error("Error creating product:", error);
        }
    } finally {
        isCreating.value = false;
    }
};

// View modal state
const showViewModal = ref(false);
const viewingProduct = ref(null);

const openViewModal = (product) => {
    viewingProduct.value = product;
    showViewModal.value = true;
};

const closeViewModal = () => {
    showViewModal.value = false;
    viewingProduct.value = null;
};

// Edit modal state
const showEditModal = ref(false);
const editingProduct = ref(null);

const openEditModal = (product) => {
    showViewModal.value = false;
    editingProduct.value = product;
    showEditModal.value = true;
};

const closeEditModal = () => {
    showEditModal.value = false;
    editingProduct.value = null;
    // Reload to get fresh data
    router.reload({ only: ["products"] });
};

// Delete modal state
const showDeleteModal = ref(false);
const productToDelete = ref(null);
const isDeleting = ref(false);

const openDeleteModal = (product) => {
    productToDelete.value = product;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    productToDelete.value = null;
};

const confirmDelete = () => {
    if (!productToDelete.value) return;

    isDeleting.value = true;
    router.delete(route("products.destroy", productToDelete.value.id), {
        onFinish: () => {
            isDeleting.value = false;
            closeDeleteModal();
        },
    });
};

// Toggle active status
const toggleActive = (product) => {
    router.post(
        route("products.toggle-active", product.id),
        {},
        {
            preserveScroll: true,
        }
    );
};

// Helper to build query params
const buildParams = (overrides = {}) => ({
    search: props.filters.search,
    status: props.filters.status,
    sort_key: props.filters.sort_key || "updated_at",
    sort_order: props.filters.sort_order || "desc",
    ...overrides,
});

// Server-side search
const handleSearch = (query) => {
    isLoading.value = true;
    router.get(
        route("products.index"),
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
        route("products.index"),
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
    router.get(route("products.index"), buildParams({ page }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

// Filter by status
const filterByStatus = (status) => {
    isLoading.value = true;
    router.get(route("products.index"), buildParams({ status, page: 1 }), {
        preserveState: true,
        onFinish: () => (isLoading.value = false),
    });
};

// Server pagination data
const serverPagination = computed(() => ({
    current_page: props.products.current_page,
    last_page: props.products.last_page,
    total: props.products.total,
    per_page: props.products.per_page,
}));

const formatPrice = (price) => {
    return "RM " + Number(price || 0).toFixed(2);
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
    <Head title="Products" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Products</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Manage your product catalog
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
                    Add Product
                </button>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <DataTable
                    :columns="columns"
                    :data="products.data"
                    :server-pagination="serverPagination"
                    :per-page="products.per_page"
                    :searchable="true"
                    search-placeholder="Search by name or description..."
                    :initial-search="filters.search"
                    :initial-sort-key="filters.sort_key || 'updated_at'"
                    :initial-sort-order="filters.sort_order || 'desc'"
                    :loading="isLoading"
                    :server-side="true"
                    empty-message="No products found"
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
                            </select>
                        </div>
                    </template>

                    <!-- Product Name Cell -->
                    <template #cell-name="{ row, highlight }">
                        <div class="flex items-center gap-3">
                            <!-- Product Thumbnail -->
                            <div
                                v-if="row.primary_image_url"
                                class="w-10 h-10 rounded-lg overflow-hidden flex-shrink-0"
                            >
                                <img
                                    :src="row.primary_image_url"
                                    :alt="row.name"
                                    class="w-full h-full object-cover"
                                />
                            </div>
                            <div
                                v-else
                                class="w-10 h-10 bg-gradient-to-br from-primary-100 to-secondary-100 dark:from-primary-900/30 dark:to-secondary-900/30 rounded-lg flex items-center justify-center flex-shrink-0"
                            >
                                <svg
                                    class="w-5 h-5 text-primary-400"
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
                                <div
                                    class="font-medium text-gray-900 dark:text-white"
                                    v-html="highlight(row.name)"
                                ></div>
                            </div>
                        </div>
                    </template>

                    <!-- Price Cell -->
                    <template #cell-price="{ row }">
                        <span
                            class="font-semibold text-primary-600 dark:text-primary-400"
                        >
                            {{ formatPrice(row.price) }}
                        </span>
                    </template>

                    <!-- Total Sales Cell -->
                    <template #cell-total_sales="{ row }">
                        <div class="flex items-center gap-2">
                            <svg
                                class="w-4 h-4 text-gray-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
                                />
                            </svg>
                            <span
                                class="font-medium text-gray-900 dark:text-white"
                            >
                                {{ row.total_sales || 0 }}
                            </span>
                        </div>
                    </template>

                    <!-- Status Cell -->
                    <template #cell-is_active="{ row }">
                        <button
                            @click="toggleActive(row)"
                            :class="[
                                'px-3 py-1 text-xs font-medium rounded-full transition-all',
                                row.is_active
                                    ? 'bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300 hover:bg-success-200'
                                    : 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-200',
                            ]"
                        >
                            {{ row.is_active ? "Active" : "Inactive" }}
                        </button>
                    </template>

                    <!-- Updated At Cell -->
                    <template #cell-updated_at="{ row }">
                        <span class="text-gray-500 dark:text-gray-400">
                            {{ formatDate(row.updated_at) }}
                        </span>
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
                            type="delete"
                            @click="openDeleteModal(row)"
                        />
                    </template>
                </DataTable>
            </div>
        </div>

        <!-- Create Product Modal -->
        <BaseModal
            :show="showCreateModal"
            title="Add Product"
            icon="plus"
            size="lg"
            :closeable="!isCreating"
            @close="handleCreateClose"
        >
            <template #content>
                <form
                    @submit.prevent="submitCreateProduct"
                    id="createProductForm"
                >
                    <div class="space-y-4">
                        <!-- Product Images Section -->
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
                            >
                                Product Images ({{ totalCreateImageCount }}/{{
                                    MAX_IMAGES
                                }})
                            </label>

                            <div class="grid grid-cols-4 gap-3 mb-3">
                                <!-- New image previews -->
                                <div
                                    v-for="(
                                        preview, index
                                    ) in newCreatePreviews"
                                    :key="'new-' + index"
                                    class="relative aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-slate-700 group"
                                >
                                    <img
                                        :src="preview.url"
                                        :alt="preview.name"
                                        class="w-full h-full object-cover"
                                    />
                                    <button
                                        type="button"
                                        @click="removeCreateImage(index)"
                                        :disabled="isCreating"
                                        class="absolute top-1 right-1 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity disabled:opacity-50"
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
                                    </button>
                                </div>

                                <!-- Add Image Button - only show if under limit -->
                                <label
                                    v-if="canAddMoreCreateImages"
                                    class="aspect-square rounded-xl border-2 border-dashed border-gray-300 dark:border-slate-600 hover:border-primary-400 dark:hover:border-primary-500 flex flex-col items-center justify-center cursor-pointer transition-colors bg-gray-50 dark:bg-slate-800"
                                >
                                    <svg
                                        class="w-8 h-8 text-gray-400 dark:text-gray-500 mb-1"
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
                                    <span
                                        class="text-xs text-gray-500 dark:text-gray-400"
                                        >Add</span
                                    >
                                    <input
                                        type="file"
                                        accept="image/*"
                                        multiple
                                        class="hidden"
                                        @change="handleCreateFileSelect"
                                        :disabled="isCreating"
                                    />
                                </label>
                            </div>
                            <p class="text-xs text-gray-500 dark:text-gray-400">
                                Max {{ MAX_IMAGES }} images. 5MB each.
                                Supported: JPG, PNG, GIF, WebP
                            </p>
                        </div>

                        <!-- Product Name -->
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Product Name *
                            </label>
                            <input
                                v-model="createFormData.name"
                                type="text"
                                required
                                :disabled="isCreating"
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
                                placeholder="e.g., Classic Burger"
                            />
                            <p
                                v-if="createErrors.name"
                                class="mt-1 text-sm text-red-600 dark:text-red-400"
                            >
                                {{ createErrors.name[0] }}
                            </p>
                        </div>

                        <!-- Price -->
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Price (RM) *
                            </label>
                            <div class="relative">
                                <span
                                    class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400"
                                    >RM</span
                                >
                                <input
                                    v-model="createFormData.price"
                                    type="number"
                                    step="0.01"
                                    min="0"
                                    required
                                    :disabled="isCreating"
                                    class="w-full px-4 py-2.5 pl-12 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
                                    placeholder="0.00"
                                />
                            </div>
                            <p
                                v-if="createErrors.price"
                                class="mt-1 text-sm text-red-600 dark:text-red-400"
                            >
                                {{ createErrors.price[0] }}
                            </p>
                        </div>

                        <!-- Description -->
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Description
                            </label>
                            <textarea
                                v-model="createFormData.description"
                                rows="3"
                                :disabled="isCreating"
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 resize-none disabled:opacity-50"
                                placeholder="Describe your product..."
                            ></textarea>
                        </div>

                        <!-- Active Status -->
                        <div class="flex items-center gap-3">
                            <button
                                type="button"
                                @click="
                                    createFormData.is_active =
                                        !createFormData.is_active
                                "
                                :disabled="isCreating"
                                :class="[
                                    'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50',
                                    createFormData.is_active
                                        ? 'bg-primary-500'
                                        : 'bg-gray-200 dark:bg-slate-600',
                                ]"
                            >
                                <span
                                    :class="[
                                        'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                                        createFormData.is_active
                                            ? 'translate-x-5'
                                            : 'translate-x-0',
                                    ]"
                                />
                            </button>
                            <span
                                class="text-sm text-gray-700 dark:text-gray-300"
                            >
                                {{
                                    createFormData.is_active
                                        ? "Product is active and visible"
                                        : "Product is hidden"
                                }}
                            </span>
                        </div>
                    </div>
                </form>
            </template>
            <template #footer>
                <button
                    type="button"
                    @click="handleCreateClose"
                    :disabled="isCreating"
                    class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    Cancel
                </button>
                <button
                    type="submit"
                    form="createProductForm"
                    :disabled="isCreating"
                    class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all flex items-center gap-2"
                >
                    <svg
                        v-if="isCreating"
                        class="w-4 h-4 animate-spin"
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
                    {{ isCreating ? "Creating..." : "Create Product" }}
                </button>
            </template>
        </BaseModal>

        <!-- View Product Modal -->
        <ViewProductModal
            :show="showViewModal"
            :product="viewingProduct"
            @close="closeViewModal"
            @edit="openEditModal"
        />

        <!-- Edit Product Modal -->
        <EditProductModal
            :show="showEditModal"
            :product="editingProduct"
            @close="closeEditModal"
            @updated="closeEditModal"
        />

        <!-- Delete Modal -->
        <DeleteModal
            :show="showDeleteModal"
            title="Delete Product"
            :message="`Are you sure you want to delete '${productToDelete?.name}'? This action cannot be undone.`"
            :processing="isDeleting"
            @close="closeDeleteModal"
            @confirm="confirmDelete"
        />
    </AuthenticatedLayout>
</template>
