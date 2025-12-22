<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import { Head, Link, useForm, router } from "@inertiajs/vue3";
import { ref, onMounted, onUnmounted, nextTick, watch } from "vue";

const props = defineProps({
    conversation: Object,
    messages: Array,
});

const messagesData = ref(props.messages || []);
const conversationData = ref(props.conversation);
const messagesContainer = ref(null);
let pollInterval = null;

const replyForm = useForm({
    message: "",
});

const scrollToBottom = () => {
    nextTick(() => {
        const container = document.getElementById("messages-container");
        if (container) {
            container.scrollTop = container.scrollHeight;
        }
    });
};

const sendReply = () => {
    replyForm.post(route("conversations.reply", props.conversation.id), {
        preserveScroll: true,
        onSuccess: () => {
            replyForm.message = "";
            refreshData();
        },
    });
};

const toggleMode = () => {
    router.post(
        route("conversations.toggle-mode", props.conversation.id),
        {},
        {
            preserveScroll: true,
            onSuccess: () => refreshData(),
        }
    );
};

const refreshData = () => {
    router.reload({
        only: ["messages", "conversation"],
        preserveState: true,
        preserveScroll: true,
        onSuccess: (page) => {
            const newMessagesCount = page.props.messages?.length || 0;
            const oldMessagesCount = messagesData.value?.length || 0;

            messagesData.value = page.props.messages;
            conversationData.value = page.props.conversation;

            // Scroll to bottom if new messages arrived
            if (newMessagesCount > oldMessagesCount) {
                scrollToBottom();
            }
        },
    });
};

// Start polling when component mounts
onMounted(() => {
    scrollToBottom();
    pollInterval = setInterval(refreshData, 3000); // Refresh every 3 seconds
});

// Stop polling when component unmounts
onUnmounted(() => {
    if (pollInterval) {
        clearInterval(pollInterval);
    }
});
</script>

<template>
    <Head :title="`Chat with ${conversationData.customer_name}`" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <Link
                        :href="route('conversations.index')"
                        class="mr-4 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                    >
                        <svg
                            class="h-6 w-6"
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
                    </Link>
                    <div>
                        <h2
                            class="text-xl font-semibold leading-tight text-gray-800 dark:text-gray-200"
                        >
                            {{ conversationData.customer_name }}
                        </h2>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{ conversationData.phone_number }}
                        </p>
                    </div>
                </div>
                <div class="flex items-center space-x-4">
                    <div class="flex items-center space-x-2">
                        <div
                            class="w-2 h-2 bg-green-500 rounded-full animate-pulse"
                        ></div>
                        <span class="text-xs text-gray-500 dark:text-gray-400"
                            >Live</span
                        >
                    </div>
                    <span
                        :class="[
                            conversationData.mode === 'ai'
                                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
                            'px-3 py-1 rounded-full text-sm font-medium',
                        ]"
                    >
                        {{
                            conversationData.mode === "ai"
                                ? "AI Mode"
                                : "Admin Mode"
                        }}
                    </span>
                    <button
                        @click="toggleMode"
                        class="px-4 py-2 text-sm font-medium rounded-md"
                        :class="
                            conversationData.mode === 'ai'
                                ? 'bg-yellow-600 text-white hover:bg-yellow-700'
                                : 'bg-green-600 text-white hover:bg-green-700'
                        "
                    >
                        Switch to
                        {{ conversationData.mode === "ai" ? "Admin" : "AI" }}
                        Mode
                    </button>
                </div>
            </div>
        </template>

        <div class="py-6">
            <div class="mx-auto max-w-4xl sm:px-6 lg:px-8">
                <!-- Escalation Reason -->
                <div
                    v-if="conversationData.escalation_reason"
                    class="mb-4 rounded-md bg-red-50 dark:bg-red-900/20 p-4"
                >
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <svg
                                class="h-5 w-5 text-red-400"
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
                            <h3
                                class="text-sm font-medium text-red-800 dark:text-red-300"
                            >
                                Why AI couldn't answer:
                            </h3>
                            <p
                                class="mt-1 text-sm text-red-700 dark:text-red-400"
                            >
                                {{ conversationData.escalation_reason }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Messages -->
                <div
                    class="bg-white dark:bg-gray-800 shadow sm:rounded-lg overflow-hidden"
                >
                    <div
                        class="h-[500px] overflow-y-auto p-4 space-y-4"
                        id="messages-container"
                    >
                        <div
                            v-for="message in messagesData"
                            :key="message.id"
                            :class="[
                                message.direction === 'inbound'
                                    ? 'flex justify-start'
                                    : 'flex justify-end',
                            ]"
                        >
                            <div
                                :class="[
                                    message.direction === 'inbound'
                                        ? 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-100'
                                        : message.sender_type === 'ai'
                                        ? 'bg-green-500 text-white'
                                        : 'bg-indigo-600 text-white',
                                    'max-w-xs lg:max-w-md px-4 py-2 rounded-lg',
                                ]"
                            >
                                <!-- Image message -->
                                <div
                                    v-if="
                                        message.message_type === 'image' &&
                                        message.media_url
                                    "
                                    class="mb-2"
                                >
                                    <a
                                        :href="message.media_url"
                                        target="_blank"
                                        class="block"
                                    >
                                        <img
                                            :src="message.media_url"
                                            alt="Shared image"
                                            class="rounded-lg max-w-full h-auto cursor-pointer hover:opacity-90 transition-opacity"
                                            style="
                                                max-height: 300px;
                                                object-fit: contain;
                                            "
                                        />
                                    </a>
                                </div>
                                <!-- Text content or caption -->
                                <p
                                    v-if="
                                        message.content &&
                                        message.message_type !== 'image'
                                    "
                                    class="text-sm whitespace-pre-wrap"
                                >
                                    {{ message.content }}
                                </p>
                                <p
                                    v-else-if="message.message_type === 'image'"
                                    class="text-sm text-gray-500 dark:text-gray-400 italic"
                                >
                                    📷 Image
                                </p>
                                <div
                                    class="mt-1 flex items-center justify-between"
                                >
                                    <span
                                        :class="[
                                            message.direction === 'inbound'
                                                ? 'text-gray-400 dark:text-gray-400'
                                                : 'text-white/70',
                                            'text-xs',
                                        ]"
                                    >
                                        {{ message.created_at }}
                                    </span>
                                    <span
                                        v-if="message.direction === 'outbound'"
                                        :class="[
                                            'text-xs ml-2',
                                            message.sender_type === 'ai'
                                                ? 'text-white/70'
                                                : 'text-white/70',
                                        ]"
                                    >
                                        {{
                                            message.sender_type === "ai"
                                                ? "🤖 AI"
                                                : "👤 Admin"
                                        }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div
                            v-if="messagesData?.length === 0"
                            class="text-center text-gray-500 dark:text-gray-400 py-8"
                        >
                            No messages yet
                        </div>
                    </div>

                    <!-- Reply Form -->
                    <div
                        class="border-t border-gray-200 dark:border-gray-700 p-4"
                    >
                        <form
                            @submit.prevent="sendReply"
                            class="flex space-x-4"
                        >
                            <textarea
                                v-model="replyForm.message"
                                rows="2"
                                class="flex-1 rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-white shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                placeholder="Type your reply..."
                                :disabled="replyForm.processing"
                            ></textarea>
                            <button
                                type="submit"
                                :disabled="
                                    replyForm.processing || !replyForm.message
                                "
                                class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                Send
                            </button>
                        </form>
                        <p
                            v-if="replyForm.errors.message"
                            class="mt-2 text-sm text-red-600"
                        >
                            {{ replyForm.errors.message }}
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
