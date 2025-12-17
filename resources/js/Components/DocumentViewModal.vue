<script setup>
/**
 * DocumentViewModal - Modal component for viewing document chunks
 *
 * Usage:
 *   <DocumentViewModal
 *       :show="showModal"
 *       :document-id="docId"
 *       @close="showModal = false"
 *   />
 */

import { ref, watch } from "vue";
import BaseModal from "@/Components/BaseModal.vue";
import { marked } from "marked";

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    documentId: {
        type: [Number, String],
        default: null,
    },
});

const emit = defineEmits(["close"]);

// State
const document = ref(null);
const loading = ref(false);

// Configure marked
marked.setOptions({ breaks: true, gfm: true });

// Watch for show changes to load document
watch(
    () => props.show,
    async (isOpen) => {
        if (isOpen && props.documentId) {
            await loadDocument();
        } else if (!isOpen) {
            document.value = null;
        }
    }
);

// Load document data
const loadDocument = async () => {
    loading.value = true;
    document.value = null;

    try {
        const response = await fetch(route("documents.show", props.documentId));
        const data = await response.json();
        document.value = data;
    } catch (error) {
        console.error("Failed to load document:", error);
    } finally {
        loading.value = false;
    }
};

const handleClose = () => {
    emit("close");
};

// File icons
const getFileIcon = (type) => {
    switch (type?.toLowerCase()) {
        case "pdf":
            return "📄";
        case "docx":
        case "doc":
            return "📝";
        case "txt":
            return "📃";
        case "md":
            return "📋";
        default:
            return "📁";
    }
};

// Content formatting
const formatChunkContent = (content, fileType = "txt") => {
    if (!content) return "";

    let processed = content;

    switch (fileType?.toLowerCase()) {
        case "md":
            processed = processMdContent(processed);
            break;
        case "txt":
            processed = processTxtContent(processed);
            break;
        case "pdf":
            processed = processPdfContent(processed);
            break;
        case "docx":
        case "doc":
            processed = processDocxContent(processed);
            break;
    }

    return addTailwindClasses(marked.parse(processed));
};

// MD files
const processMdContent = (content) => {
    return content.replace(/\|/g, " | ").replace(/^(#{1,3})/gm, "\n$1");
};

// TXT files
const processTxtContent = (content) => {
    return content
        .replace(/^[=]{3,}.*$/gm, "\n\n---\n\n")
        .replace(/^[-]{3,}$/gm, "\n\n---\n\n")
        .replace(/^[_]{3,}$/gm, "\n\n---\n\n")
        .replace(/^([A-Z][A-Z0-9\s&\-\/:\.]{2,50})$/gm, "\n\n## $1\n\n")
        .replace(/\[ \]/g, "\n- [ ]")
        .replace(/\[x\]/gi, "\n- [x]")
        .replace(/(\d+)\.\s+/g, "\n$1. ")
        .replace(/^[•●]\s*/gm, "\n- ")
        .replace(/(\d{1,2}:\d{2}\s*(?:AM|PM))\s*[-–]/g, "\n\n**$1** -");
};

// PDF files
const processPdfContent = (content) => {
    return content
        .replace(/\f/g, "\n\n---\n\n")
        .replace(/\s{3,}/g, "\n")
        .replace(/(\d+\.\d+)\s+([A-Z])/g, "\n\n**$1** $2")
        .replace(/(RM\s*\d+(?:\.\d{2})?)/g, "\n$1")
        .replace(/(Package [A-Z]|Item \d+)/g, "\n\n**$1**");
};

// DOCX files
const processDocxContent = (content) => {
    return content
        .replace(/[•●○◦►▸▹→]\s*/g, "\n- ")
        .replace(/^(\d+)\)\s+/gm, "\n$1. ")
        .replace(/(\d+\.\d+)\s+([A-Z])/g, "\n\n### $1 $2")
        .replace(/[""]/g, '"')
        .replace(/['']/g, "'");
};

// Add Tailwind classes
const addTailwindClasses = (html) => {
    return html
        .replace(
            /<h1>/g,
            '<h1 class="text-xl font-bold text-gray-900 dark:text-white mt-6 mb-3 border-b pb-2 border-gray-200 dark:border-gray-700">'
        )
        .replace(
            /<h2>/g,
            '<h2 class="text-lg font-bold text-primary-600 dark:text-primary-400 mt-5 mb-2">'
        )
        .replace(
            /<h3>/g,
            '<h3 class="text-base font-semibold text-gray-800 dark:text-gray-200 mt-4 mb-2">'
        )
        .replace(
            /<hr>/g,
            '<hr class="my-4 border-gray-200 dark:border-gray-700">'
        )
        .replace(
            /<hr \/>/g,
            '<hr class="my-4 border-gray-200 dark:border-gray-700">'
        )
        .replace(
            /<ul>/g,
            '<ul class="list-disc list-inside space-y-1 ml-4 my-2">'
        )
        .replace(
            /<ol>/g,
            '<ol class="list-decimal list-inside space-y-1 ml-4 my-2">'
        )
        .replace(/<li>/g, '<li class="text-gray-700 dark:text-gray-300">')
        .replace(
            /<p>/g,
            '<p class="mb-3 leading-relaxed text-gray-700 dark:text-gray-300">'
        )
        .replace(
            /<strong>/g,
            '<strong class="font-semibold text-gray-900 dark:text-white">'
        )
        .replace(
            /<table>/g,
            '<table class="w-full text-sm border-collapse border border-gray-200 dark:border-gray-700 my-3">'
        )
        .replace(
            /<th>/g,
            '<th class="border border-gray-200 dark:border-gray-700 px-3 py-2 bg-gray-100 dark:bg-slate-700">'
        )
        .replace(
            /<td>/g,
            '<td class="border border-gray-200 dark:border-gray-700 px-3 py-2">'
        );
};
</script>

<template>
    <BaseModal
        :show="show"
        :title="document?.original_name || 'Loading...'"
        icon="view"
        size="full"
        @close="handleClose"
    >
        <template #content>
            <!-- Loading -->
            <div v-if="loading" class="flex items-center justify-center py-12">
                <svg
                    class="animate-spin h-8 w-8 text-primary-500"
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
                <span class="ml-3 text-gray-600 dark:text-gray-400">
                    Loading document content...
                </span>
            </div>

            <!-- Document Info & Chunks -->
            <div v-else-if="document" class="space-y-6">
                <!-- Document Summary -->
                <div
                    class="bg-gradient-to-r from-primary-50 to-secondary-50 dark:from-primary-900/20 dark:to-secondary-900/20 rounded-xl p-4 border border-primary-200/50 dark:border-primary-800/50"
                >
                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <span class="text-3xl">{{
                                getFileIcon(document.file_type)
                            }}</span>
                            <div>
                                <p
                                    class="font-medium text-gray-900 dark:text-white"
                                >
                                    {{ document.original_name }}
                                </p>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{ document.file_type?.toUpperCase() }}
                                    • {{ document.file_size }}
                                </p>
                            </div>
                        </div>
                        <div class="text-right">
                            <div
                                class="text-2xl font-bold text-primary-600 dark:text-primary-400"
                            >
                                {{ document.chunks_count }}
                            </div>
                            <div
                                class="text-xs text-gray-500 dark:text-gray-400"
                            >
                                Chunks
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Chunks List -->
                <div
                    v-if="document.chunks?.length"
                    class="space-y-4 max-h-[50vh] overflow-y-auto pr-2"
                >
                    <div
                        v-for="(chunk, index) in document.chunks"
                        :key="chunk.id"
                        class="bg-white dark:bg-slate-800/80 rounded-xl border border-gray-200 dark:border-slate-700 overflow-hidden"
                    >
                        <!-- Chunk Header -->
                        <div
                            class="flex items-center justify-between px-4 py-3 bg-gray-50 dark:bg-slate-700/50 border-b border-gray-200 dark:border-slate-700"
                        >
                            <div class="flex items-center gap-2">
                                <span
                                    class="flex items-center justify-center w-6 h-6 bg-primary-500 text-white text-xs font-bold rounded-full"
                                >
                                    {{ index + 1 }}
                                </span>
                                <span
                                    class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    Section {{ index + 1 }}
                                </span>
                            </div>
                            <div class="flex items-center gap-2">
                                <span
                                    v-if="chunk.tokens_count"
                                    class="px-2 py-0.5 text-xs bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full"
                                >
                                    {{ chunk.tokens_count }} tokens
                                </span>
                            </div>
                        </div>

                        <!-- Chunk Content -->
                        <div class="p-4">
                            <div
                                class="text-gray-700 dark:text-gray-300 text-sm leading-relaxed whitespace-pre-line"
                                v-html="
                                    formatChunkContent(
                                        chunk.content,
                                        document.file_type
                                    )
                                "
                            ></div>
                        </div>
                    </div>
                </div>

                <!-- No chunks -->
                <div v-else class="text-center py-12">
                    <div
                        class="w-16 h-16 bg-gray-100 dark:bg-slate-700 rounded-2xl flex items-center justify-center mx-auto mb-4"
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
                                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                            />
                        </svg>
                    </div>
                    <p class="text-gray-500 dark:text-gray-400">
                        No content chunks found for this document.
                    </p>
                </div>
            </div>
        </template>

        <template #footer>
            <button
                @click="handleClose"
                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Close
            </button>
        </template>
    </BaseModal>
</template>
