<script setup>
import BaseModal from "@/Components/BaseModal.vue";
import Tab from "@/Components/Tab.vue";
import { ref, computed } from "vue";
import { router } from "@inertiajs/vue3";

const props = defineProps({
    show: Boolean,
    merchant: Object,
});

const emit = defineEmits(["close"]);

const activeTab = ref("info");

const tabs = computed(() => [
    { key: "info", label: "Basic Info" },
    {
        key: "documents",
        label: "Documents",
        badge: props.merchant?.documents_count || 0,
    },
    { key: "activity", label: "Activity" },
]);

// Fetch detailed merchant data when modal opens
const merchantDetails = ref(null);
const loading = ref(false);

const fetchMerchantDetails = () => {
    if (!props.merchant?.id) return;

    loading.value = true;
    router.reload({
        only: ["merchantDetails"],
        data: { merchant_id: props.merchant.id },
        onSuccess: () => {
            loading.value = false;
        },
        onError: () => {
            loading.value = false;
        },
    });
};

const formatDate = (date) => {
    if (!date) return "N/A";
    return new Date(date).toLocaleDateString("en-US", {
        year: "numeric",
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
    });
};
</script>

<template>
    <BaseModal
        :show="show"
        title="View Merchant Details"
        icon="view"
        size="2xl"
        @close="$emit('close')"
    >
        <template #content>
            <div v-if="merchant" class="space-y-4">
                <!-- Tabs -->
                <Tab v-model="activeTab" :tabs="tabs" />

                <!-- Tab Content -->
                <div class="pt-4">
                    <!-- Basic Info Tab -->
                    <div v-if="activeTab === 'info'" class="space-y-4">
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label
                                    class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Business Name
                                </label>
                                <p
                                    class="text-sm font-medium text-gray-900 dark:text-white"
                                >
                                    {{ merchant.name }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Email
                                </label>
                                <p
                                    class="text-sm text-gray-900 dark:text-white"
                                >
                                    {{ merchant.email }}
                                </p>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label
                                    class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Business Type
                                </label>
                                <span
                                    :class="[
                                        merchant.business_type === 'restaurant'
                                            ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                            : 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
                                        'inline-flex px-3 py-1 text-xs font-medium rounded-full',
                                    ]"
                                >
                                    {{ merchant.business_type_label }}
                                </span>
                            </div>
                            <div>
                                <label
                                    class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Status
                                </label>
                                <div class="flex items-center gap-2">
                                    <span
                                        :class="[
                                            merchant.is_active
                                                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
                                            'inline-flex px-3 py-1 text-xs font-medium rounded-full',
                                        ]"
                                    >
                                        {{
                                            merchant.is_active
                                                ? "Active"
                                                : "Inactive"
                                        }}
                                    </span>
                                    <span
                                        :class="[
                                            merchant.email_verified
                                                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
                                            'inline-flex px-3 py-1 text-xs font-medium rounded-full',
                                        ]"
                                    >
                                        {{
                                            merchant.email_verified
                                                ? "✓ Verified"
                                                : "⏳ Pending"
                                        }}
                                    </span>
                                </div>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label
                                    class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    WhatsApp Phone Number ID
                                </label>
                                <p
                                    class="text-sm text-gray-900 dark:text-white font-mono"
                                >
                                    {{
                                        merchant.whatsapp_phone_number_id ||
                                        "Not configured"
                                    }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    WhatsApp Phone Number
                                </label>
                                <p
                                    class="text-sm text-gray-900 dark:text-white font-mono"
                                >
                                    {{
                                        merchant.whatsapp_phone_number ||
                                        "Not configured"
                                    }}
                                </p>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label
                                    class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    WhatsApp Access Token
                                </label>
                                <p
                                    class="text-sm text-gray-900 dark:text-white"
                                >
                                    {{
                                        merchant.has_whatsapp
                                            ? "✓ Configured"
                                            : "✗ Not configured"
                                    }}
                                </p>
                            </div>
                        </div>

                        <div>
                            <label
                                class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1"
                            >
                                Created At
                            </label>
                            <p class="text-sm text-gray-900 dark:text-white">
                                {{ merchant.created_at }}
                            </p>
                        </div>
                    </div>

                    <!-- Documents Tab -->
                    <div v-if="activeTab === 'documents'" class="space-y-3">
                        <div
                            v-if="
                                merchant.documents &&
                                merchant.documents.length > 0
                            "
                        >
                            <div
                                v-for="doc in merchant.documents"
                                :key="doc.id"
                                class="p-4 bg-gray-50 dark:bg-slate-700 rounded-xl mb-2"
                            >
                                <div class="flex items-start justify-between">
                                    <div class="flex-1">
                                        <h4
                                            class="text-sm font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ doc.filename }}
                                        </h4>
                                        <p
                                            class="text-xs text-gray-500 dark:text-gray-400 mt-1"
                                        >
                                            {{ doc.chunks_count }} chunks
                                        </p>
                                    </div>
                                    <span
                                        :class="[
                                            doc.status === 'completed'
                                                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                : doc.status === 'processing'
                                                ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
                                                : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
                                            'px-2 py-1 text-xs font-medium rounded-full',
                                        ]"
                                    >
                                        {{ doc.status }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div
                            v-else
                            class="text-center py-8 text-gray-500 dark:text-gray-400"
                        >
                            No documents uploaded
                        </div>
                    </div>

                    <!-- Activity Tab -->
                    <div v-if="activeTab === 'activity'" class="space-y-4">
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div
                                class="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl"
                            >
                                <div class="flex items-center justify-between">
                                    <div>
                                        <p
                                            class="text-xs font-medium text-blue-600 dark:text-blue-400"
                                        >
                                            Total Conversations
                                        </p>
                                        <p
                                            class="text-2xl font-bold text-blue-700 dark:text-blue-300 mt-1"
                                        >
                                            {{
                                                merchant.conversations_count ||
                                                0
                                            }}
                                        </p>
                                    </div>
                                    <svg
                                        class="w-8 h-8 text-blue-600 dark:text-blue-400"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
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

                            <div
                                class="p-4 bg-green-50 dark:bg-green-900/20 rounded-xl"
                            >
                                <div class="flex items-center justify-between">
                                    <div>
                                        <p
                                            class="text-xs font-medium text-green-600 dark:text-green-400"
                                        >
                                            Total Messages
                                        </p>
                                        <p
                                            class="text-2xl font-bold text-green-700 dark:text-green-300 mt-1"
                                        >
                                            {{ merchant.messages_count || 0 }}
                                        </p>
                                    </div>
                                    <svg
                                        class="w-8 h-8 text-green-600 dark:text-green-400"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"
                                        />
                                    </svg>
                                </div>
                            </div>
                        </div>

                        <div
                            class="p-4 bg-purple-50 dark:bg-purple-900/20 rounded-xl"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <p
                                        class="text-xs font-medium text-purple-600 dark:text-purple-400"
                                    >
                                        Knowledge Base Documents
                                    </p>
                                    <p
                                        class="text-2xl font-bold text-purple-700 dark:text-purple-300 mt-1"
                                    >
                                        {{ merchant.documents_count || 0 }}
                                    </p>
                                    <p
                                        class="text-xs text-purple-600 dark:text-purple-400 mt-1"
                                    >
                                        {{ merchant.chunks_count || 0 }} total
                                        chunks
                                    </p>
                                </div>
                                <svg
                                    class="w-8 h-8 text-purple-600 dark:text-purple-400"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke="currentColor"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                                    />
                                </svg>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </template>
        <template #footer>
            <button
                type="button"
                @click="$emit('close')"
                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Close
            </button>
        </template>
    </BaseModal>
</template>
