<script setup>
import { ref, nextTick, watch } from "vue";
import axios from "axios";

const props = defineProps({
    isDark: {
        type: Boolean,
        default: false,
    },
});

// Chat state
const isOpen = ref(false);
const message = ref("");
const messages = ref([]);
const isLoading = ref(false);
const messagesContainer = ref(null);

// Toggle chat open/close
const toggleChat = () => {
    isOpen.value = !isOpen.value;
    if (isOpen.value && messages.value.length === 0) {
        // Add welcome message
        messages.value.push({
            role: "assistant",
            content:
                "Hi there! 👋 I'm Janji, your AI assistant. How can I help you learn about Janji Chat today?",
        });
    }
};

// Scroll to bottom of messages
const scrollToBottom = () => {
    nextTick(() => {
        if (messagesContainer.value) {
            messagesContainer.value.scrollTop =
                messagesContainer.value.scrollHeight;
        }
    });
};

// Watch messages and scroll
watch(messages, scrollToBottom, { deep: true });

// Send message
const sendMessage = async () => {
    const userMessage = message.value.trim();
    if (!userMessage || isLoading.value) return;

    // Add user message
    messages.value.push({
        role: "user",
        content: userMessage,
    });

    message.value = "";
    isLoading.value = true;

    try {
        // Prepare history (exclude the message we just added)
        const history = messages.value.slice(0, -1).map((msg) => ({
            role: msg.role,
            content: msg.content,
        }));

        const response = await axios.post("/api/landing/chat", {
            message: userMessage,
            history: history,
        });

        // Add AI response
        messages.value.push({
            role: "assistant",
            content: response.data.response,
        });
    } catch (error) {
        console.error("Chat error:", error);
        messages.value.push({
            role: "assistant",
            content:
                "I'm sorry, I'm having trouble connecting right now. Please try again in a moment.",
        });
    } finally {
        isLoading.value = false;
    }
};

// Handle enter key
const handleKeydown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
};

// Suggested questions
const suggestedQuestions = [
    "What is Janji Chat?",
    "How does it work?",
    "What features do you offer?",
];

const askSuggested = (question) => {
    message.value = question;
    sendMessage();
};
</script>

<template>
    <div class="fixed bottom-6 right-6 z-50">
        <!-- Chat Panel -->
        <Transition
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="opacity-0 scale-95 translate-y-4"
            enter-to-class="opacity-100 scale-100 translate-y-0"
            leave-active-class="transition duration-200 ease-in"
            leave-from-class="opacity-100 scale-100 translate-y-0"
            leave-to-class="opacity-0 scale-95 translate-y-4"
        >
            <div
                v-if="isOpen"
                class="absolute bottom-20 right-0 w-[380px] max-w-[calc(100vw-3rem)] bg-white dark:bg-slate-900 rounded-2xl shadow-2xl shadow-slate-900/20 dark:shadow-black/40 border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col"
                style="height: 520px"
            >
                <!-- Header -->
                <div
                    class="flex items-center justify-between px-5 py-4 bg-gradient-to-r from-emerald-500 to-teal-500 text-white"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center"
                        >
                            <span class="text-xl">🤖</span>
                        </div>
                        <div>
                            <h3 class="font-semibold">Janji AI Assistant</h3>
                            <p class="text-xs text-white/80">
                                Ask me anything!
                            </p>
                        </div>
                    </div>
                    <button
                        @click="toggleChat"
                        class="p-2 rounded-lg hover:bg-white/20 transition-colors"
                        aria-label="Close chat"
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
                                d="M6 18L18 6M6 6l12 12"
                            />
                        </svg>
                    </button>
                </div>

                <!-- Messages -->
                <div
                    ref="messagesContainer"
                    class="flex-1 overflow-y-auto p-4 space-y-4 bg-slate-50 dark:bg-slate-950"
                >
                    <template v-for="(msg, idx) in messages" :key="idx">
                        <!-- Assistant Message -->
                        <div v-if="msg.role === 'assistant'" class="flex gap-3">
                            <div
                                class="w-8 h-8 rounded-full bg-gradient-to-br from-emerald-400 to-teal-400 flex items-center justify-center flex-shrink-0"
                            >
                                <span class="text-sm">🤖</span>
                            </div>
                            <div
                                class="flex-1 bg-white dark:bg-slate-800 rounded-2xl rounded-tl-md px-4 py-3 shadow-sm border border-slate-100 dark:border-slate-700"
                            >
                                <p
                                    class="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-wrap leading-relaxed"
                                >
                                    {{ msg.content }}
                                </p>
                            </div>
                        </div>

                        <!-- User Message -->
                        <div v-else class="flex justify-end">
                            <div
                                class="max-w-[80%] bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-2xl rounded-tr-md px-4 py-3 shadow-sm"
                            >
                                <p
                                    class="text-sm whitespace-pre-wrap leading-relaxed"
                                >
                                    {{ msg.content }}
                                </p>
                            </div>
                        </div>
                    </template>

                    <!-- Loading indicator -->
                    <div v-if="isLoading" class="flex gap-3">
                        <div
                            class="w-8 h-8 rounded-full bg-gradient-to-br from-emerald-400 to-teal-400 flex items-center justify-center flex-shrink-0"
                        >
                            <span class="text-sm">🤖</span>
                        </div>
                        <div
                            class="bg-white dark:bg-slate-800 rounded-2xl rounded-tl-md px-4 py-3 shadow-sm border border-slate-100 dark:border-slate-700"
                        >
                            <div class="flex gap-1.5">
                                <span
                                    class="w-2 h-2 bg-slate-400 rounded-full animate-bounce"
                                    style="animation-delay: 0ms"
                                ></span>
                                <span
                                    class="w-2 h-2 bg-slate-400 rounded-full animate-bounce"
                                    style="animation-delay: 150ms"
                                ></span>
                                <span
                                    class="w-2 h-2 bg-slate-400 rounded-full animate-bounce"
                                    style="animation-delay: 300ms"
                                ></span>
                            </div>
                        </div>
                    </div>

                    <!-- Suggested questions (only show when no messages yet) -->
                    <div v-if="messages.length === 1" class="pt-2">
                        <p
                            class="text-xs text-slate-500 dark:text-slate-400 mb-3"
                        >
                            Try asking:
                        </p>
                        <div class="flex flex-wrap gap-2">
                            <button
                                v-for="question in suggestedQuestions"
                                :key="question"
                                @click="askSuggested(question)"
                                class="px-3 py-1.5 text-xs font-medium bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 rounded-full border border-slate-200 dark:border-slate-700 hover:border-emerald-300 dark:hover:border-emerald-700 hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
                            >
                                {{ question }}
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Input -->
                <div
                    class="p-4 bg-white dark:bg-slate-900 border-t border-slate-100 dark:border-slate-800"
                >
                    <div class="flex gap-3">
                        <input
                            v-model="message"
                            @keydown="handleKeydown"
                            type="text"
                            placeholder="Type your message..."
                            class="flex-1 px-4 py-3 bg-slate-100 dark:bg-slate-800 rounded-xl text-sm text-slate-700 dark:text-slate-300 placeholder-slate-400 dark:placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 border-0"
                            :disabled="isLoading"
                        />
                        <button
                            @click="sendMessage"
                            :disabled="!message.trim() || isLoading"
                            class="p-3 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-xl hover:shadow-lg hover:shadow-emerald-500/30 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:shadow-none transition-all"
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
                                    d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                                />
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        </Transition>

        <!-- Floating Button -->
        <button
            @click="toggleChat"
            class="group relative w-16 h-16 rounded-full bg-gradient-to-r from-emerald-500 to-teal-500 text-white shadow-xl shadow-emerald-500/30 hover:shadow-2xl hover:shadow-emerald-500/40 hover:scale-105 active:scale-95 transition-all flex items-center justify-center"
            :class="{ 'ring-4 ring-emerald-500/20': !isOpen }"
            aria-label="Open chat"
        >
            <!-- Pulse animation when closed -->
            <span
                v-if="!isOpen"
                class="absolute inset-0 rounded-full bg-emerald-400 animate-ping opacity-20"
            ></span>

            <!-- Icon -->
            <Transition
                mode="out-in"
                enter-active-class="transition duration-200 ease-out"
                enter-from-class="opacity-0 rotate-90 scale-50"
                enter-to-class="opacity-100 rotate-0 scale-100"
                leave-active-class="transition duration-150 ease-in"
                leave-from-class="opacity-100 rotate-0 scale-100"
                leave-to-class="opacity-0 -rotate-90 scale-50"
            >
                <svg
                    v-if="!isOpen"
                    class="w-7 h-7"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                    />
                </svg>
                <svg
                    v-else
                    class="w-7 h-7"
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
            </Transition>
        </button>
    </div>
</template>
