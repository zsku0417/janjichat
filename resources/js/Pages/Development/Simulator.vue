<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import DeleteModal from "@/Components/DeleteModal.vue";
import { Head, useForm, usePage } from "@inertiajs/vue3";
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from "vue";

const props = defineProps({
    initialMessages: {
        type: Array,
        default: () => [],
    },
    conversationId: {
        type: Number,
        default: null,
    },
    initialPhone: {
        type: String,
        default: "60108685352",
    },
});

const form = useForm({
    phone_number: props.initialPhone,
    name: "Ku Zhi Shing",
    message: "",
});

const messages = ref(props.initialMessages || []);
const chatContainer = ref(null);
const isPolling = ref(true);
const lastMessageCount = ref(props.initialMessages?.length || 0);
const isLoading = ref(false);

// Get business type from auth user
const page = usePage();
const businessType = computed(
    () => page.props.auth?.user?.business_type || "restaurant"
);

// Different presets for different business types
const restaurantPresets = [
    "Hello!",
    "I want to book a table",
    "4 pax\\n\\n15-12-2024, 7:00pm\\n\\n60123456789\\n\\nAhmad\\n\\nWindow seat please",
    "What are your opening hours?",
    "Do you have any vegetarian options?",
    "What is my booking status?",
    "Can I cancel my booking?",
    "我要订位",
];

const orderTrackingPresets = [
    "Hi, I want to order",
    "What products do you have?",
    "Chicken Rice x2\n\n10-12-2024, 3:00pm\n\n123 Jalan ABC, KL\n\nNo spicy please",
    "What are your delivery charges?",
    "Can I pickup instead of delivery?",
    "What is my order status?",
    "Do you deliver to Subang?",
    "What payment methods do you accept?",
    "我要下单",
];

const presetMessages = computed(() => {
    return businessType.value === "order_tracking"
        ? orderTrackingPresets
        : restaurantPresets;
});

let pollInterval = null;

const scrollToBottom = () => {
    nextTick(() => {
        if (chatContainer.value) {
            chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
        }
    });
};

const fetchMessages = async () => {
    if (!form.phone_number) return;

    try {
        const response = await fetch(
            `/dev/messages?phone=${form.phone_number}`
        );
        const data = await response.json();

        if (data.messages && data.messages.length !== lastMessageCount.value) {
            messages.value = data.messages;
            lastMessageCount.value = data.messages.length;
            scrollToBottom();
        }
    } catch (error) {
        console.error("Failed to fetch messages:", error);
    }
};

const submit = () => {
    if (!form.message.trim()) return;

    isLoading.value = true;

    form.post(route("dev.simulate"), {
        preserveScroll: true,
        onSuccess: () => {
            form.message = "";
            // Fetch messages immediately after sending
            setTimeout(() => {
                fetchMessages();
                isLoading.value = false;
            }, 1000);
            // And again after AI response
            setTimeout(fetchMessages, 3000);
        },
        onError: () => {
            isLoading.value = false;
        },
    });
};

const usePreset = (message) => {
    form.message = message;
    // Trigger resize on next tick
    nextTick(() => {
        const textarea = document.querySelector("textarea");
        if (textarea) {
            textarea.style.height = "auto";
            textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px";
        }
    });
};

// Auto-resize textarea as user types
const autoResize = (event) => {
    const textarea = event.target;
    textarea.style.height = "auto";
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px";
};

// Clear conversation modal state
const showClearModal = ref(false);
const isClearing = ref(false);

const openClearModal = () => {
    showClearModal.value = true;
};

const closeClearModal = () => {
    showClearModal.value = false;
};

const confirmClearConversation = async () => {
    isClearing.value = true;
    try {
        // Get CSRF token from cookie (Laravel's default approach)
        const csrfToken = document.cookie
            .split("; ")
            .find((row) => row.startsWith("XSRF-TOKEN="))
            ?.split("=")[1];

        const response = await fetch("/dev/clear", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-XSRF-TOKEN": csrfToken ? decodeURIComponent(csrfToken) : "",
                Accept: "application/json",
            },
            credentials: "same-origin",
            body: JSON.stringify({ phone: form.phone_number }),
        });

        const result = await response.json();

        if (result.success) {
            messages.value = [];
            lastMessageCount.value = 0;
        }
    } catch (error) {
        console.error("Failed to clear conversation:", error);
    } finally {
        isClearing.value = false;
        closeClearModal();
    }
};

// Start polling when component mounts
onMounted(() => {
    scrollToBottom();
    pollInterval = setInterval(() => {
        if (isPolling.value) {
            fetchMessages();
        }
    }, 2000); // Poll every 2 seconds
});

// Stop polling when component unmounts
onUnmounted(() => {
    if (pollInterval) {
        clearInterval(pollInterval);
    }
});

// Watch for phone number changes
watch(
    () => form.phone_number,
    () => {
        messages.value = [];
        lastMessageCount.value = 0;
        fetchMessages();
    }
);
</script>

<template>
    <Head title="Webhook Simulator" />

    <AuthenticatedLayout>
        <template #header>
            <h2
                class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight"
            >
                🧪 Development Webhook Simulator
            </h2>
        </template>

        <div class="py-6">
            <div class="max-w-6xl mx-auto sm:px-6 lg:px-8">
                <!-- Warning Banner -->
                <div
                    class="mb-4 bg-yellow-50 border-l-4 border-yellow-400 p-3 rounded-r-lg"
                >
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <svg
                                class="h-5 w-5 text-yellow-400"
                                viewBox="0 0 20 20"
                                fill="currentColor"
                            >
                                <path
                                    fill-rule="evenodd"
                                    d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                                    clip-rule="evenodd"
                                />
                            </svg>
                        </div>
                        <div class="ml-3">
                            <p
                                class="text-sm text-yellow-700 dark:text-yellow-800"
                            >
                                <strong>Development Mode</strong> - Messages
                                auto-refresh every 2 seconds
                            </p>
                        </div>
                    </div>
                </div>

                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <!-- Left Side: Chat Window -->
                    <div
                        class="bg-white overflow-hidden shadow-sm sm:rounded-lg flex flex-col"
                        style="height: 600px"
                    >
                        <!-- Chat Header -->
                        <div
                            class="bg-gradient-to-r from-green-500 to-green-600 px-4 py-3 flex items-center justify-between"
                        >
                            <div class="flex items-center">
                                <div
                                    class="w-10 h-10 bg-white rounded-full flex items-center justify-center mr-3"
                                >
                                    <svg
                                        class="w-6 h-6 text-green-600"
                                        fill="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"
                                        />
                                    </svg>
                                </div>
                                <div>
                                    <div class="text-white font-semibold">
                                        {{ form.name }}
                                    </div>
                                    <div class="text-green-100 text-sm">
                                        +{{ form.phone_number }}
                                    </div>
                                </div>
                            </div>
                            <button
                                @click="openClearModal"
                                class="text-white hover:bg-green-700 px-3 py-1 rounded text-sm"
                                title="Clear conversation"
                            >
                                🗑️ Clear
                            </button>
                        </div>

                        <!-- Messages Area -->
                        <div
                            ref="chatContainer"
                            class="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-100 dark:bg-gray-900"
                            style="background-image: url('data:image/svg+xml,%3Csvg width=\'60\' height=\'60\' viewBox=\'0 0 60 60\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cg fill=\'none\' fill-rule=\'evenodd\'%3E%3Cg fill=\'%239C92AC\' fill-opacity=\'0.05\'%3E%3Cpath d=\'M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z\'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E\');"
                        >
                            <div
                                v-if="messages.length === 0"
                                class="text-center text-gray-500 dark:text-gray-400 py-8"
                            >
                                <div class="text-4xl mb-2">💬</div>
                                <p>
                                    No messages yet. Send a message to start the
                                    conversation!
                                </p>
                            </div>

                            <div
                                v-for="msg in messages"
                                :key="msg.id"
                                :class="[
                                    'max-w-[80%] rounded-lg px-4 py-2 shadow-sm',
                                    msg.direction === 'inbound'
                                        ? 'bg-green-500 text-white ml-auto rounded-tr-none'
                                        : 'bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-100 mr-auto rounded-tl-none',
                                ]"
                            >
                                <div class="whitespace-pre-wrap break-words">
                                    {{ msg.content }}
                                </div>
                                <div
                                    :class="[
                                        'text-xs mt-1',
                                        msg.direction === 'inbound'
                                            ? 'text-green-100'
                                            : 'text-gray-400',
                                    ]"
                                >
                                    {{ msg.created_at }}
                                    <span
                                        v-if="msg.sender_type === 'ai'"
                                        class="ml-1"
                                        >🤖</span
                                    >
                                    <span
                                        v-else-if="msg.sender_type === 'admin'"
                                        class="ml-1"
                                        >👨‍💼</span
                                    >
                                </div>
                            </div>

                            <!-- Loading indicator -->
                            <div v-if="isLoading" class="flex justify-start">
                                <div
                                    class="bg-white rounded-lg px-4 py-2 shadow-sm rounded-tl-none"
                                >
                                    <div class="flex space-x-1">
                                        <div
                                            class="w-2 h-2 bg-gray-400 rounded-full animate-bounce"
                                        ></div>
                                        <div
                                            class="w-2 h-2 bg-gray-400 rounded-full animate-bounce"
                                            style="animation-delay: 0.1s"
                                        ></div>
                                        <div
                                            class="w-2 h-2 bg-gray-400 rounded-full animate-bounce"
                                            style="animation-delay: 0.2s"
                                        ></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Message Input -->
                        <form
                            @submit.prevent="submit"
                            class="p-3 bg-gray-200 dark:bg-gray-700 flex items-end gap-2"
                        >
                            <textarea
                                v-model="form.message"
                                rows="1"
                                class="flex-1 border-gray-300 dark:border-gray-600 dark:bg-gray-800 dark:text-white rounded-2xl shadow-sm focus:ring-green-500 focus:border-green-500 px-4 py-3 resize-none overflow-y-auto"
                                style="max-height: 120px; min-height: 48px"
                                placeholder="Type a message..."
                                :disabled="form.processing"
                                @keydown.enter.exact.prevent="submit"
                                @input="autoResize($event)"
                            ></textarea>
                            <button
                                type="submit"
                                :disabled="form.processing || !form.message"
                                class="w-12 h-12 bg-green-500 hover:bg-green-600 text-white rounded-full flex items-center justify-center disabled:opacity-50 transition-colors flex-shrink-0"
                            >
                                <svg
                                    v-if="!form.processing"
                                    class="w-6 h-6"
                                    fill="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"
                                    />
                                </svg>
                                <svg
                                    v-else
                                    class="animate-spin w-5 h-5"
                                    xmlns="http://www.w3.org/2000/svg"
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
                            </button>
                        </form>
                    </div>

                    <!-- Right Side: Controls -->
                    <div class="space-y-6">
                        <!-- Customer Settings -->
                        <div
                            class="bg-white dark:bg-gray-800 overflow-hidden shadow-sm sm:rounded-lg p-6"
                        >
                            <h3
                                class="text-lg font-medium text-gray-900 dark:text-white mb-4"
                            >
                                Customer Settings
                            </h3>

                            <div class="space-y-4">
                                <div>
                                    <label
                                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                    >
                                        Phone Number
                                    </label>
                                    <input
                                        v-model="form.phone_number"
                                        type="text"
                                        class="w-full border-gray-300 dark:border-gray-600 dark:bg-gray-900 dark:text-white rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500"
                                        placeholder="60108685352"
                                    />
                                    <p
                                        class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        Format: country code + number (no + or
                                        spaces)
                                    </p>
                                </div>
                                <div>
                                    <label
                                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                    >
                                        Customer Name
                                    </label>
                                    <input
                                        v-model="form.name"
                                        type="text"
                                        class="w-full border-gray-300 dark:border-gray-600 dark:bg-gray-900 dark:text-white rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500"
                                        placeholder="Ku Zhi Shing"
                                    />
                                </div>
                            </div>
                        </div>

                        <!-- Quick Presets -->
                        <div
                            class="bg-white dark:bg-gray-800 overflow-hidden shadow-sm sm:rounded-lg p-6"
                        >
                            <div class="flex items-center justify-between mb-4">
                                <h3
                                    class="text-lg font-medium text-gray-900 dark:text-white"
                                >
                                    Quick Presets
                                </h3>
                                <span
                                    :class="[
                                        'px-2 py-1 text-xs font-medium rounded-full',
                                        businessType === 'order_tracking'
                                            ? 'bg-cyan-100 text-cyan-700'
                                            : 'bg-orange-100 text-orange-700',
                                    ]"
                                >
                                    {{
                                        businessType === "order_tracking"
                                            ? "📦 Order Tracking"
                                            : "🍽️ Restaurant"
                                    }}
                                </span>
                            </div>
                            <div class="flex flex-wrap gap-2">
                                <button
                                    v-for="preset in presetMessages"
                                    :key="preset"
                                    type="button"
                                    @click="usePreset(preset)"
                                    class="inline-flex items-center px-3 py-1.5 border border-gray-300 dark:border-gray-600 rounded-full text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                                >
                                    {{ preset }}
                                </button>
                            </div>
                        </div>

                        <!-- Instructions -->
                        <div
                            class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4"
                        >
                            <h4
                                class="text-md font-medium text-gray-900 dark:text-gray-100 mb-2"
                            >
                                How it works:
                            </h4>
                            <ol
                                class="list-decimal list-inside space-y-1 text-sm text-gray-600 dark:text-gray-300"
                            >
                                <li>Enter phone number and customer name</li>
                                <li>Type a message or use a preset</li>
                                <li>
                                    Press send - AI will respond automatically
                                </li>
                                <li>Conversation updates in real-time!</li>
                            </ol>
                        </div>

                        <!-- Status -->
                        <div
                            class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4"
                        >
                            <div class="flex items-center">
                                <div
                                    class="w-3 h-3 bg-green-500 rounded-full mr-2 animate-pulse"
                                ></div>
                                <span
                                    class="text-sm text-green-700 dark:text-green-300 font-medium"
                                    >Auto-refresh active</span
                                >
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Clear Conversation Modal -->
        <DeleteModal
            :show="showClearModal"
            title="Clear Conversation"
            message="Are you sure you want to clear this conversation? All messages will be deleted."
            confirmText="Clear"
            :processing="isClearing"
            @close="closeClearModal"
            @confirm="confirmClearConversation"
        />
    </AuthenticatedLayout>
</template>
