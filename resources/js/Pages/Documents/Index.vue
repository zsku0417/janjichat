<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import DataTable from "@/Components/DataTable.vue";
import TableActionButton from "@/Components/TableActionButton.vue";
import DeleteModal from "@/Components/DeleteModal.vue";
import { Head, useForm, router } from "@inertiajs/vue3";
import { ref } from "vue";

defineProps({
    documents: Array,
});

// Table columns configuration
const columns = [
    { key: "original_name", label: "Document", sortable: true },
    { key: "file_type", label: "Type", sortable: true },
    { key: "file_size", label: "Size", sortable: true },
    { key: "status", label: "Status", sortable: true },
    { key: "chunks_count", label: "Chunks", sortable: true },
    { key: "created_at", label: "Uploaded", sortable: true },
];

const fileInput = ref(null);
const uploadForm = useForm({
    file: null,
});

// View modal state
const showViewModal = ref(false);
const viewingDocument = ref(null);
const loadingContent = ref(false);

// Delete modal state
const showDeleteModal = ref(false);
const documentToDelete = ref(null);
const isDeleting = ref(false);

const selectFile = () => {
    fileInput.value.click();
};

const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
        uploadForm.file = file;
        uploadForm.post(route("documents.store"), {
            forceFormData: true,
            onSuccess: () => {
                uploadForm.reset();
                fileInput.value.value = "";
            },
        });
    }
};

const openDeleteModal = (doc) => {
    documentToDelete.value = doc;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    documentToDelete.value = null;
};

const confirmDelete = () => {
    if (!documentToDelete.value) return;

    isDeleting.value = true;
    router.delete(route("documents.destroy", documentToDelete.value.id), {
        onFinish: () => {
            isDeleting.value = false;
            closeDeleteModal();
        },
    });
};

const reprocessDocument = (id) => {
    router.post(route("documents.reprocess", id));
};

const viewDocument = async (doc) => {
    loadingContent.value = true;
    showViewModal.value = true;
    viewingDocument.value = null;

    try {
        const response = await fetch(route("documents.show", doc.id));
        const data = await response.json();
        viewingDocument.value = data;
    } catch (error) {
        console.error("Failed to load document:", error);
    } finally {
        loadingContent.value = false;
    }
};

const closeViewModal = () => {
    showViewModal.value = false;
    viewingDocument.value = null;
};

const getStatusColor = (status) => {
    switch (status) {
        case "completed":
            return "bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300";
        case "processing":
            return "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300";
        case "pending":
            return "bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300";
        case "failed":
            return "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300";
        default:
            return "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300";
    }
};

const getFileIcon = (type) => {
    switch (type?.toLowerCase()) {
        case 'pdf':
            return '📄';
        case 'docx':
        case 'doc':
            return '📝';
        case 'txt':
            return '📃';
        case 'md':
            return '📋';
        default:
            return '📁';
    }
};
</script>

<template>
    <Head title="Knowledge Base" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Knowledge Base</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Manage documents for AI-powered customer responses
                    </p>
                </div>
                <button
                    @click="selectFile"
                    :disabled="uploadForm.processing"
                    class="px-5 py-2.5 bg-gradient-to-r from-primary-500 to-secondary-500 text-white rounded-xl font-medium shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all duration-200 flex items-center gap-2 disabled:opacity-50"
                >
                    <svg v-if="!uploadForm.processing" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                    </svg>
                    <svg v-else class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    {{ uploadForm.processing ? "Uploading..." : "Upload Document" }}
                </button>
                <input
                    ref="fileInput"
                    type="file"
                    accept=".pdf,.docx,.doc,.txt,.md"
                    class="hidden"
                    @change="handleFileSelect"
                />
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <!-- Upload Error -->
                <div
                    v-if="uploadForm.errors.file"
                    class="mb-6 rounded-xl bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 p-4"
                >
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 bg-red-500 rounded-lg flex items-center justify-center flex-shrink-0">
                            <svg class="w-5 h-5 text-white" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <p class="text-sm text-red-700 dark:text-red-300">
                            {{ uploadForm.errors.file }}
                        </p>
                    </div>
                </div>

                <!-- Info Box -->
                <div class="mb-6 rounded-xl bg-primary-50 dark:bg-primary-900/20 border border-primary-200 dark:border-primary-800 p-4">
                    <div class="flex items-start gap-3">
                        <div class="w-8 h-8 bg-primary-500 rounded-lg flex items-center justify-center flex-shrink-0">
                            <svg class="w-5 h-5 text-white" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <div>
                            <h4 class="font-medium text-primary-800 dark:text-primary-200">How it works</h4>
                            <p class="text-sm text-primary-700 dark:text-primary-300 mt-1">
                                Upload PDF, DOCX, TXT, or Markdown files. The AI will learn from these documents to provide accurate answers to customer questions.
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Documents Table -->
                <DataTable
                    :columns="columns"
                    :data="documents"
                    :searchable="true"
                    search-placeholder="Search documents..."
                    :search-keys="['original_name', 'file_type']"
                    :paginated="true"
                    :per-page="10"
                    empty-message="No documents uploaded yet. Upload your first document to get started!"
                >
                    <!-- Document Name Cell -->
                    <template #cell-original_name="{ row }">
                        <div class="flex items-center gap-3">
                            <span class="text-2xl">{{ getFileIcon(row.file_type) }}</span>
                            <div>
                                <div class="font-medium text-gray-900 dark:text-white">
                                    {{ row.original_name }}
                                </div>
                                <div
                                    v-if="row.error_message"
                                    class="text-xs text-red-500 truncate max-w-xs"
                                >
                                    {{ row.error_message }}
                                </div>
                            </div>
                        </div>
                    </template>

                    <!-- Type Cell -->
                    <template #cell-file_type="{ row }">
                        <span class="px-2 py-1 text-xs font-medium bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-gray-300 rounded-lg uppercase">
                            {{ row.file_type }}
                        </span>
                    </template>

                    <!-- Status Cell -->
                    <template #cell-status="{ row }">
                        <span
                            :class="[
                                getStatusColor(row.status),
                                'px-3 py-1 text-xs font-medium rounded-full capitalize'
                            ]"
                        >
                            {{ row.status }}
                        </span>
                    </template>

                    <!-- Actions -->
                    <template #actions="{ row }">
                        <TableActionButton
                            v-if="row.status === 'completed'"
                            type="view"
                            @click="viewDocument(row)"
                        />
                        <TableActionButton
                            v-if="row.status === 'failed'"
                            type="refresh"
                            tooltip="Retry Processing"
                            @click="reprocessDocument(row.id)"
                        />
                        <TableActionButton
                            type="delete"
                            @click="openDeleteModal(row)"
                        />
                    </template>
                </DataTable>
            </div>
        </div>

        <!-- View Document Modal -->
        <div v-if="showViewModal" class="fixed inset-0 z-50 overflow-y-auto">
            <div class="flex min-h-screen items-center justify-center p-4">
                <!-- Backdrop -->
                <div
                    class="fixed inset-0 bg-black/50 backdrop-blur-sm"
                    @click="closeViewModal"
                ></div>

                <!-- Modal -->
                <div
                    class="relative w-full max-w-4xl max-h-[80vh] glass rounded-2xl shadow-2xl overflow-hidden"
                >
                    <!-- Header -->
                    <div
                        class="flex items-center justify-between px-6 py-4 border-b border-white/20 dark:border-white/10 bg-gradient-to-r from-primary-500/10 to-secondary-500/10"
                    >
                        <div class="flex items-center gap-3">
                            <span class="text-2xl">{{ getFileIcon(viewingDocument?.file_type) }}</span>
                            <div>
                                <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
                                    {{ viewingDocument?.original_name || "Loading..." }}
                                </h3>
                                <p
                                    v-if="viewingDocument"
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{ viewingDocument.chunks_count }} chunks •
                                    {{ viewingDocument.file_type?.toUpperCase() }}
                                </p>
                            </div>
                        </div>
                        <button
                            @click="closeViewModal"
                            class="w-8 h-8 flex items-center justify-center rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors"
                        >
                            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </div>

                    <!-- Content -->
                    <div class="overflow-y-auto max-h-[60vh] p-6">
                        <!-- Loading -->
                        <div v-if="loadingContent" class="flex items-center justify-center py-12">
                            <svg class="animate-spin h-8 w-8 text-primary-500" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            <span class="ml-3 text-gray-600 dark:text-gray-400">Loading document content...</span>
                        </div>

                        <!-- Chunks -->
                        <div v-else-if="viewingDocument?.chunks?.length" class="space-y-4">
                            <div
                                v-for="chunk in viewingDocument.chunks"
                                :key="chunk.id"
                                class="bg-white/50 dark:bg-slate-800/50 rounded-xl p-4 border border-gray-200/50 dark:border-slate-700/50"
                            >
                                <div class="flex items-center justify-between mb-3">
                                    <span class="text-xs font-medium text-primary-600 dark:text-primary-400 bg-primary-100 dark:bg-primary-900/30 px-2 py-1 rounded-lg">
                                        Chunk {{ chunk.index + 1 }}
                                    </span>
                                </div>
                                <p class="text-sm text-gray-700 dark:text-gray-300 whitespace-pre-wrap leading-relaxed">
                                    {{ chunk.content }}
                                </p>
                            </div>
                        </div>

                        <!-- No chunks -->
                        <div v-else class="text-center py-12">
                            <div class="w-16 h-16 bg-gray-100 dark:bg-slate-700 rounded-2xl flex items-center justify-center mx-auto mb-4">
                                <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                            </div>
                            <p class="text-gray-500 dark:text-gray-400">No content chunks found for this document.</p>
                        </div>
                    </div>

                    <!-- Footer -->
                    <div class="px-6 py-4 border-t border-white/20 dark:border-white/10">
                        <button
                            @click="closeViewModal"
                            class="w-full px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
                        >
                            Close
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Delete Modal -->
        <DeleteModal
            :show="showDeleteModal"
            title="Delete Document"
            :message="`Are you sure you want to delete '${documentToDelete?.original_name}'? This will remove all processed chunks and cannot be undone.`"
            :processing="isDeleting"
            @close="closeDeleteModal"
            @confirm="confirmDelete"
        />
    </AuthenticatedLayout>
</template>

