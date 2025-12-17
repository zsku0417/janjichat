<script setup>
import { useForm, router } from "@inertiajs/vue3";
import { ref, computed } from "vue";
import BaseModal from "@/Components/BaseModal.vue";
import DeleteModal from "@/Components/DeleteModal.vue";

const props = defineProps({
    tables: Array,
});

const emit = defineEmits(["saved"]);

// Modal states
const showModal = ref(false);
const editingTable = ref(null);

// Table form
const form = useForm({
    name: "",
    capacity: 4,
    is_active: true,
});

// Delete modal states
const showDeleteModal = ref(false);
const tableToDelete = ref(null);

// Computed modal title and icon
const modalTitle = computed(() =>
    editingTable.value ? "Edit Table" : "Add New Table"
);
const modalIcon = computed(() => (editingTable.value ? "edit" : "plus"));

const openModal = (table = null) => {
    editingTable.value = table;
    if (table) {
        form.name = table.name;
        form.capacity = table.capacity;
        form.is_active = table.is_active;
    } else {
        form.reset();
        form.capacity = 4;
        form.is_active = true;
    }
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
    editingTable.value = null;
    form.reset();
};

const saveTable = () => {
    if (editingTable.value) {
        form.patch(route("settings.tables.update", editingTable.value.id), {
            onSuccess: () => {
                closeModal();
                emit("saved");
            },
        });
    } else {
        form.post(route("settings.tables.store"), {
            onSuccess: () => {
                closeModal();
                emit("saved");
            },
        });
    }
};

const openDeleteModal = (table) => {
    tableToDelete.value = table;
    showDeleteModal.value = true;
};

const confirmDelete = () => {
    if (tableToDelete.value) {
        router.delete(
            route("settings.tables.destroy", tableToDelete.value.id),
            {
                onSuccess: () => {
                    showDeleteModal.value = false;
                    tableToDelete.value = null;
                    emit("saved");
                },
            }
        );
    }
};
</script>

<template>
    <div class="space-y-4">
        <!-- Header -->
        <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
                Manage Tables
            </h3>
            <button
                @click="openModal()"
                class="px-4 py-2 bg-gradient-to-r from-primary-500 to-secondary-500 text-white rounded-xl font-medium shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all text-sm"
            >
                + Add Table
            </button>
        </div>

        <!-- Tables Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <div
                v-for="table in tables"
                :key="table.id"
                class="p-4 bg-gray-50 dark:bg-slate-700 rounded-xl flex items-center justify-between"
            >
                <div>
                    <p class="font-medium text-gray-900 dark:text-white">
                        {{ table.name }}
                    </p>
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                        Capacity: {{ table.capacity }}
                    </p>
                    <span
                        :class="[
                            table.is_active
                                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                : 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300',
                            'inline-flex px-2 py-0.5 text-xs font-medium rounded-full mt-1',
                        ]"
                    >
                        {{ table.is_active ? "Active" : "Inactive" }}
                    </span>
                </div>
                <div class="flex gap-2">
                    <button
                        @click="openModal(table)"
                        class="p-2 text-gray-600 dark:text-gray-400 hover:text-primary-500 transition-colors"
                    >
                        <svg
                            class="w-5 h-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                            />
                        </svg>
                    </button>
                    <button
                        @click="openDeleteModal(table)"
                        class="p-2 text-gray-600 dark:text-gray-400 hover:text-red-500 transition-colors"
                    >
                        <svg
                            class="w-5 h-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                            />
                        </svg>
                    </button>
                </div>
            </div>
        </div>

        <!-- Empty State -->
        <div
            v-if="!tables || tables.length === 0"
            class="text-center py-12 text-gray-500 dark:text-gray-400"
        >
            No tables added yet. Click "Add Table" to create one.
        </div>
    </div>

    <!-- Add/Edit Table Modal using BaseModal -->
    <BaseModal
        :show="showModal"
        :title="modalTitle"
        :icon="modalIcon"
        size="md"
        @close="closeModal"
    >
        <template #content>
            <div class="space-y-4">
                <!-- Table Name -->
                <div>
                    <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                        Table Name
                    </label>
                    <input
                        v-model="form.name"
                        type="text"
                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                        placeholder="e.g., Table 1, VIP Table"
                    />
                </div>

                <!-- Capacity -->
                <div>
                    <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                        Capacity (Max Guests)
                    </label>
                    <input
                        v-model.number="form.capacity"
                        type="number"
                        min="1"
                        class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                    />
                </div>

                <!-- Active Checkbox -->
                <div class="flex items-center gap-3">
                    <input
                        v-model="form.is_active"
                        type="checkbox"
                        class="w-4 h-4 rounded border-gray-300 text-primary-500 focus:ring-primary-500"
                    />
                    <label class="text-sm text-gray-700 dark:text-gray-300">
                        Table is active and available for bookings
                    </label>
                </div>
            </div>
        </template>

        <template #footer>
            <button
                type="button"
                @click="closeModal"
                class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white"
            >
                Cancel
            </button>
            <button
                @click="saveTable"
                :disabled="form.processing"
                class="px-4 py-2 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg disabled:opacity-50"
            >
                {{ form.processing ? "Saving..." : "Save Table" }}
            </button>
        </template>
    </BaseModal>

    <!-- Delete Confirmation Modal -->
    <DeleteModal
        :show="showDeleteModal"
        title="Delete Table"
        :message="`Are you sure you want to delete table '${tableToDelete?.name}'? This action cannot be undone.`"
        @close="showDeleteModal = false"
        @confirm="confirmDelete"
    />
</template>
