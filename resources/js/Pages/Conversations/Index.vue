<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import { Head, useForm, router, usePage } from "@inertiajs/vue3";
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from "vue";

const props = defineProps({
    conversations: Object,
    filter: String,
    search: String,
    selected: [String, Number], // From URL ?selected=ID
    selectedConversation: Object,
    messages: Array,
});

// Store all conversations (unfiltered)
const allConversations = ref(props.conversations?.data || []);
const currentFilter = ref(props.filter || "all");
const searchQuery = ref(props.search || "");
const isLoading = ref(false);
const isLoadingChat = ref(false);

// Selected conversation and messages
const selectedConversationId = ref(props.selectedConversation?.id || null);
const conversationData = ref(props.selectedConversation || null);
const messagesData = ref(props.messages || []);

// Echo channel subscription (replaces polling)
let echoChannel = null;
const page = usePage();
const currentUserId = computed(() => page.props.auth.user?.id);

// Reply form
const replyForm = useForm({
    message: "",
});

// Per-conversation drafts storage
const drafts = ref(new Map());
const textareaRef = ref(null);

// Get draft for current conversation
const getCurrentDraft = () => {
    if (!selectedConversationId.value) return "";
    return drafts.value.get(selectedConversationId.value) || "";
};

// Save draft for current conversation
const saveDraft = (message) => {
    if (!selectedConversationId.value) return;
    if (message.trim()) {
        drafts.value.set(selectedConversationId.value, message);
    } else {
        drafts.value.delete(selectedConversationId.value);
    }
};

// Get draft for any conversation (for list display)
const getDraftForConversation = (conversationId) => {
    return drafts.value.get(conversationId) || "";
};

// WhatsApp-style text formatting
const formatWhatsAppText = (text) => {
    if (!text) return "";

    let formatted = text;

    // Code blocks (must be first to prevent inner formatting)
    formatted = formatted.replace(
        /```([\s\S]*?)```/g,
        '<pre class="bg-gray-800 text-green-400 px-2 py-1 rounded text-xs font-mono my-1 block overflow-x-auto">$1</pre>'
    );

    // Monospace `text`
    formatted = formatted.replace(
        /`([^`]+)`/g,
        '<code class="bg-gray-200 dark:bg-gray-600 px-1 py-0.5 rounded text-xs font-mono">$1</code>'
    );

    // Bold *text*
    formatted = formatted.replace(/\*(.*?)\*/g, "<strong>$1</strong>");

    // Italic _text_
    formatted = formatted.replace(/_(.*?)_/g, "<em>$1</em>");

    // Strikethrough ~text~
    formatted = formatted.replace(/~(.*?)~/g, "<del>$1</del>");

    return formatted;
};

// Auto-resize textarea
const autoResizeTextarea = () => {
    if (textareaRef.value) {
        textareaRef.value.style.height = "auto";
        textareaRef.value.style.height =
            Math.min(textareaRef.value.scrollHeight, 150) + "px";
    }
};

// Handle textarea input
const handleTextareaInput = (e) => {
    replyForm.message = e.target.value;
    saveDraft(e.target.value);
    autoResizeTextarea();
};

// Emoji picker
const showEmojiPicker = ref(false);
const emojiCategories = [
    {
        name: "Smileys",
        emojis: [
            "😀",
            "😃",
            "😄",
            "😁",
            "😅",
            "😂",
            "🤣",
            "😊",
            "😇",
            "🙂",
            "😉",
            "😌",
            "😍",
            "🥰",
            "😘",
            "😗",
            "😙",
            "😚",
            "😋",
            "😛",
            "😜",
            "🤪",
            "😝",
            "🤗",
            "🤭",
            "🤫",
            "🤔",
            "🤐",
            "🤨",
            "😐",
            "😑",
            "😶",
            "😏",
            "😒",
            "🙄",
            "😬",
            "😮",
            "😯",
            "😲",
            "😳",
            "🥺",
            "😦",
            "😧",
            "😨",
            "😰",
            "😥",
            "😢",
            "😭",
            "😱",
            "😖",
            "😣",
            "😞",
            "😓",
            "😩",
            "😫",
            "😤",
            "😡",
            "😠",
            "🤬",
        ],
    },
    {
        name: "Gestures",
        emojis: [
            "👍",
            "👎",
            "👌",
            "🤌",
            "🤏",
            "✌️",
            "🤞",
            "🤟",
            "🤘",
            "🤙",
            "👈",
            "👉",
            "👆",
            "👇",
            "☝️",
            "👋",
            "🤚",
            "🖐️",
            "✋",
            "🖖",
            "👏",
            "🙌",
            "🤲",
            "🤝",
            "🙏",
            "✍️",
            "💪",
            "🦾",
            "🦿",
        ],
    },
    {
        name: "Hearts",
        emojis: [
            "❤️",
            "🧡",
            "💛",
            "💚",
            "💙",
            "💜",
            "🖤",
            "🤍",
            "🤎",
            "💔",
            "❣️",
            "💕",
            "💞",
            "💓",
            "💗",
            "💖",
            "💘",
            "💝",
            "💟",
        ],
    },
    {
        name: "Objects",
        emojis: [
            "📱",
            "💻",
            "🖥️",
            "📞",
            "☎️",
            "📧",
            "📅",
            "📆",
            "🗓️",
            "📋",
            "📌",
            "📍",
            "🔗",
            "✅",
            "❌",
            "⭕",
            "❓",
            "❗",
            "💯",
            "🔔",
            "🔕",
            "⏰",
            "⌚",
            "🎉",
            "🎊",
            "🎁",
            "🎈",
            "🏆",
            "🥇",
            "🥈",
            "🥉",
        ],
    },
];

// Insert emoji at cursor position
const insertEmoji = (emoji) => {
    if (textareaRef.value) {
        const start = textareaRef.value.selectionStart;
        const end = textareaRef.value.selectionEnd;
        const text = replyForm.message;
        replyForm.message =
            text.substring(0, start) + emoji + text.substring(end);
        saveDraft(replyForm.message);

        // Set cursor position after emoji
        nextTick(() => {
            textareaRef.value.focus();
            textareaRef.value.selectionStart = textareaRef.value.selectionEnd =
                start + emoji.length;
        });
    } else {
        replyForm.message += emoji;
        saveDraft(replyForm.message);
    }
};

const toggleEmojiPicker = () => {
    showEmojiPicker.value = !showEmojiPicker.value;
};

// Close emoji picker when clicking outside
const closeEmojiPicker = () => {
    showEmojiPicker.value = false;
};

// Client-side filtered conversations
const filteredConversations = computed(() => {
    if (!allConversations.value) return [];

    let result = allConversations.value;

    // Filter by search query (phone number or customer name)
    if (searchQuery.value.trim()) {
        const query = searchQuery.value.toLowerCase().trim();
        result = result.filter((c) => {
            const name = (c.customer_name || "").toLowerCase();
            const phone = (c.phone_number || "").toLowerCase();
            return name.includes(query) || phone.includes(query);
        });
    }

    // Filter by status
    switch (currentFilter.value) {
        case "needs_reply":
            return result.filter((c) => c.needs_reply);
        case "ai_mode":
            return result.filter((c) => c.mode === "ai" && !c.needs_reply);
        case "admin_mode":
            return result.filter((c) => c.mode === "admin");
        default:
            return result;
    }
});

// Filter counts
const filterCounts = computed(() => ({
    all: allConversations.value.length,
    needs_reply: allConversations.value.filter((c) => c.needs_reply).length,
    ai_mode: allConversations.value.filter(
        (c) => c.mode === "ai" && !c.needs_reply
    ).length,
    admin_mode: allConversations.value.filter((c) => c.mode === "admin").length,
}));

// Switch filter without server request
const setFilter = (filterValue) => {
    currentFilter.value = filterValue;
};

// Select a conversation
const selectConversation = async (conversation) => {
    if (selectedConversationId.value === conversation.id) return;

    // Save current draft before switching
    if (selectedConversationId.value && replyForm.message.trim()) {
        saveDraft(replyForm.message);
    }

    selectedConversationId.value = conversation.id;
    isLoadingChat.value = true;

    // Load draft for new conversation
    replyForm.message = getDraftForConversation(conversation.id);

    // Reset textarea height
    nextTick(() => {
        if (textareaRef.value) {
            textareaRef.value.style.height = "auto";
            autoResizeTextarea();
        }
    });

    try {
        const response = await fetch(
            `/conversations/${conversation.id}/messages`
        );
        const data = await response.json();

        conversationData.value = data.conversation;
        messagesData.value = data.messages;

        nextTick(() => scrollToBottom());
    } catch (error) {
        console.error("Failed to load conversation:", error);
    } finally {
        isLoadingChat.value = false;
    }
};

const scrollToBottom = () => {
    nextTick(() => {
        const container = document.getElementById("messages-container");
        if (container) {
            container.scrollTop = container.scrollHeight;
        }
    });
};

const sendReply = () => {
    if (!conversationData.value) return;

    replyForm.post(route("conversations.reply", conversationData.value.id), {
        preserveScroll: true,
        onSuccess: () => {
            replyForm.message = "";
            // Clear draft after sending
            drafts.value.delete(conversationData.value.id);
            // Reset textarea height
            nextTick(() => {
                if (textareaRef.value) {
                    textareaRef.value.style.height = "auto";
                }
            });
            refreshChatData();
        },
    });
};

const toggleMode = () => {
    if (!conversationData.value) return;

    router.post(
        route("conversations.toggle-mode", conversationData.value.id),
        {},
        {
            preserveScroll: true,
            onSuccess: () => {
                refreshChatData();
                refreshConversationsList();
            },
        }
    );
};

const refreshConversationsList = () => {
    isLoading.value = true;
    router.reload({
        only: ["conversations"],
        preserveState: true,
        preserveScroll: true,
        onSuccess: (page) => {
            allConversations.value = page.props.conversations?.data || [];
        },
        onFinish: () => {
            isLoading.value = false;
        },
    });

    console.log("allConversations-refresh", allConversations);
};

const refreshChatData = async () => {
    if (!selectedConversationId.value) return;

    try {
        const response = await fetch(
            `/conversations/${selectedConversationId.value}/messages`
        );
        const data = await response.json();

        const oldCount = messagesData.value?.length || 0;
        const newCount = data.messages?.length || 0;

        conversationData.value = data.conversation;
        messagesData.value = data.messages;

        // Also update the conversation in the list
        const index = allConversations.value.findIndex(
            (c) => c.id === selectedConversationId.value
        );
        if (index !== -1) {
            allConversations.value[index] = {
                ...allConversations.value[index],
                last_message: data.conversation.last_message,
                last_message_direction:
                    data.conversation.last_message_direction,
                last_message_sender: data.conversation.last_message_sender,
                last_message_at: data.conversation.last_message_at,
                needs_reply: data.conversation.needs_reply,
                mode: data.conversation.mode,
            };
        }

        if (newCount > oldCount) {
            scrollToBottom();
        }
    } catch (error) {
        console.error("Failed to refresh chat:", error);
    }
};

// Combined refresh (kept for manual refresh if needed)
const refreshAll = () => {
    refreshConversationsList();
    if (selectedConversationId.value) {
        refreshChatData();
    }
};

// Setup Echo WebSocket listener when component mounts
onMounted(() => {
    // Subscribe to the merchant's private channel for real-time updates
    if (currentUserId.value && window.Echo) {
        echoChannel = window.Echo.private(
            `conversations.${currentUserId.value}`
        )
            .listen(".message.new", (event) => {
                console.log("New message received via WebSocket:", event);

                // Refresh the conversations list to update last message preview
                refreshConversationsList();

                // If the event is for the currently selected conversation, refresh chat
                if (event.conversation_id === selectedConversationId.value) {
                    refreshChatData();
                }
            })
            .listen(".conversation.updated", (event) => {
                console.log("Conversation updated via WebSocket:", event);

                // Refresh conversations list to show mode/escalation changes
                refreshConversationsList();

                // If the event is for the currently selected conversation, refresh chat metadata
                if (event.conversation_id === selectedConversationId.value) {
                    refreshChatData();
                }
            });

        console.log("Echo subscribed to conversations." + currentUserId.value);
    } else {
        console.warn(
            "Echo not available or user not logged in, falling back to polling"
        );
        // Fallback to polling if Echo is not available
        const pollInterval = setInterval(refreshAll, 5000);
        onUnmounted(() => clearInterval(pollInterval));
    }

    // Check if we have a selected conversation from URL (e.g., from Dashboard)
    const selectedFromUrl = props.selected;
    if (selectedFromUrl && allConversations.value.length > 0) {
        const selectedConv = allConversations.value.find(
            (c) => c.id === parseInt(selectedFromUrl)
        );
        if (selectedConv) {
            selectConversation(selectedConv);
            showMobileChat.value = true; // Show chat on mobile too
            return;
        }
    }

    // Auto-select first conversation if none selected and there are conversations
    if (!selectedConversationId.value && allConversations.value.length > 0) {
        selectConversation(allConversations.value[0]);
    }
});

// Cleanup Echo subscription when component unmounts
onUnmounted(() => {
    if (echoChannel) {
        echoChannel.stopListening(".message.new");
        echoChannel.stopListening(".conversation.updated");
        window.Echo?.leave(`conversations.${currentUserId.value}`);
        console.log(
            "Echo unsubscribed from conversations." + currentUserId.value
        );
    }
});

// Handle keyboard shortcut for sending
const handleKeydown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        sendReply();
    }
};

// Mobile: selected conversation view state
const showMobileChat = ref(false);

// Select conversation for mobile
const selectConversationMobile = (conversation) => {
    selectConversation(conversation);
    showMobileChat.value = true;
};

// Back button for mobile
const closeMobileChat = () => {
    showMobileChat.value = false;
};
</script>

<template>
    <Head title="Conversations" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">
                        Conversations
                    </h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Manage your customer conversations
                    </p>
                </div>
                <div class="flex items-center gap-3">
                    <div
                        v-if="isLoading"
                        class="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                    >
                        <svg
                            class="animate-spin h-4 w-4"
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
                        Syncing...
                    </div>
                    <div
                        v-else
                        class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-success-50 dark:bg-success-900/20 border border-success-200 dark:border-success-800"
                    >
                        <div
                            class="w-2 h-2 bg-success-500 rounded-full animate-pulse"
                        ></div>
                        <span
                            class="text-xs font-medium text-success-700 dark:text-success-400"
                            >Live</span
                        >
                    </div>
                </div>
            </div>
        </template>

        <div class="h-[calc(100vh-140px)]">
            <div class="mx-auto max-w-7xl h-full px-4 sm:px-6 lg:px-8 py-6">
                <div
                    class="h-full glass rounded-2xl overflow-hidden flex relative"
                >
                    <!-- Left Panel: Conversations List -->
                    <div
                        :class="[
                            'flex-shrink-0 flex flex-col bg-white/30 dark:bg-slate-800/30 border-r-2 border-primary-200 dark:border-primary-800',
                            'w-full lg:max-w-[395px] lg:w-1/3',
                            showMobileChat ? 'hidden lg:flex' : 'flex',
                        ]"
                    >
                        <!-- Search Bar -->
                        <div
                            class="p-4 border-b border-white/20 dark:border-white/10"
                        >
                            <div class="relative">
                                <svg
                                    class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                                    />
                                </svg>
                                <input
                                    v-model="searchQuery"
                                    type="text"
                                    placeholder="Search by name or phone..."
                                    class="w-full pl-10 pr-10 py-2.5 text-sm rounded-xl bg-white/50 dark:bg-slate-700/50 border border-white/30 dark:border-white/10 text-gray-700 dark:text-gray-200 placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all"
                                />
                                <button
                                    v-if="searchQuery"
                                    @click="searchQuery = ''"
                                    class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
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
                        </div>

                        <!-- Filter Tabs -->
                        <div
                            class="px-4 pb-4 border-b border-white/20 dark:border-white/10"
                        >
                            <div class="flex flex-wrap gap-2">
                                <button
                                    @click="setFilter('all')"
                                    :class="[
                                        'px-3 py-1.5 text-xs font-medium rounded-full transition-all duration-200',
                                        currentFilter === 'all'
                                            ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                                            : 'bg-white/50 dark:bg-slate-700/50 text-gray-600 dark:text-gray-300 hover:bg-white/80 dark:hover:bg-slate-600/50',
                                    ]"
                                >
                                    All
                                    <span class="ml-1 opacity-75">{{
                                        filterCounts.all
                                    }}</span>
                                </button>
                                <button
                                    @click="setFilter('needs_reply')"
                                    :class="[
                                        'px-3 py-1.5 text-xs font-medium rounded-full transition-all duration-200',
                                        currentFilter === 'needs_reply'
                                            ? 'bg-accent-500 text-white shadow-lg shadow-accent-500/30'
                                            : 'bg-white/50 dark:bg-slate-700/50 text-gray-600 dark:text-gray-300 hover:bg-white/80 dark:hover:bg-slate-600/50',
                                    ]"
                                >
                                    🔔 Needs Reply
                                    <span class="ml-1 opacity-75">{{
                                        filterCounts.needs_reply
                                    }}</span>
                                </button>
                                <button
                                    @click="setFilter('ai_mode')"
                                    :class="[
                                        'px-3 py-1.5 text-xs font-medium rounded-full transition-all duration-200',
                                        currentFilter === 'ai_mode'
                                            ? 'bg-success-500 text-white shadow-lg shadow-success-500/30'
                                            : 'bg-white/50 dark:bg-slate-700/50 text-gray-600 dark:text-gray-300 hover:bg-white/80 dark:hover:bg-slate-600/50',
                                    ]"
                                >
                                    🤖 AI
                                    <span class="ml-1 opacity-75">{{
                                        filterCounts.ai_mode
                                    }}</span>
                                </button>
                                <button
                                    @click="setFilter('admin_mode')"
                                    :class="[
                                        'px-3 py-1.5 text-xs font-medium rounded-full transition-all duration-200',
                                        currentFilter === 'admin_mode'
                                            ? 'bg-amber-500 text-white shadow-lg shadow-amber-500/30'
                                            : 'bg-white/50 dark:bg-slate-700/50 text-gray-600 dark:text-gray-300 hover:bg-white/80 dark:hover:bg-slate-600/50',
                                    ]"
                                >
                                    👤 Admin
                                    <span class="ml-1 opacity-75">{{
                                        filterCounts.admin_mode
                                    }}</span>
                                </button>
                            </div>
                        </div>

                        <!-- Conversations List -->
                        <div class="flex-1 overflow-y-auto">
                            <!-- Loading State -->
                            <div
                                v-if="
                                    isLoading && allConversations.length === 0
                                "
                                class="flex items-center justify-center h-full"
                            >
                                <div class="text-center">
                                    <svg
                                        class="animate-spin h-8 w-8 text-primary-500 mx-auto mb-3"
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
                                    <p
                                        class="text-gray-500 dark:text-gray-400 text-sm"
                                    >
                                        Loading conversations...
                                    </p>
                                </div>
                            </div>

                            <!-- Empty State -->
                            <div
                                v-else-if="filteredConversations.length === 0"
                                class="flex items-center justify-center h-full"
                            >
                                <div class="text-center p-6">
                                    <div
                                        class="w-16 h-16 bg-gray-100 dark:bg-slate-700/50 rounded-2xl flex items-center justify-center mx-auto mb-4"
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
                                                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                                            />
                                        </svg>
                                    </div>
                                    <p
                                        class="text-gray-500 dark:text-gray-400 font-medium"
                                    >
                                        No conversations found
                                    </p>
                                    <p
                                        class="text-gray-400 dark:text-gray-500 text-sm mt-1"
                                    >
                                        Try a different filter
                                    </p>
                                </div>
                            </div>

                            <!-- Conversation Items -->
                            <div
                                v-else
                                class="divide-y divide-white/10 dark:divide-white/5"
                            >
                                <button
                                    v-for="conversation in filteredConversations"
                                    :key="conversation.id"
                                    @click="
                                        selectConversationMobile(conversation)
                                    "
                                    :class="[
                                        'w-full text-left p-4 transition-all duration-200 hover:bg-white/50 dark:hover:bg-slate-700/50',
                                        selectedConversationId ===
                                        conversation.id
                                            ? 'bg-primary-50 dark:bg-primary-900/20 border-l-4 border-primary-500'
                                            : 'border-l-4 border-transparent',
                                    ]"
                                >
                                    <div class="flex items-start gap-3">
                                        <!-- Avatar -->
                                        <div class="relative flex-shrink-0">
                                            <div
                                                class="w-12 h-12 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-xl flex items-center justify-center text-white font-semibold text-lg shadow-lg"
                                            >
                                                {{
                                                    conversation.customer_name
                                                        ?.charAt(0)
                                                        ?.toUpperCase() || "?"
                                                }}
                                            </div>
                                            <!-- Status indicator -->
                                            <div
                                                v-if="conversation.needs_reply"
                                                class="absolute -top-1 -right-1 w-4 h-4 bg-accent-500 rounded-full border-2 border-white dark:border-slate-800 flex items-center justify-center"
                                            >
                                                <span
                                                    class="text-[8px] text-white"
                                                    >!</span
                                                >
                                            </div>
                                        </div>

                                        <!-- Content -->
                                        <div class="flex-1 min-w-0">
                                            <div
                                                class="flex items-center justify-between gap-2"
                                            >
                                                <span
                                                    class="font-semibold text-gray-900 dark:text-white truncate"
                                                >
                                                    {{
                                                        conversation.customer_name
                                                    }}
                                                </span>
                                                <span
                                                    class="text-xs text-gray-400 dark:text-gray-500 whitespace-nowrap"
                                                >
                                                    {{
                                                        conversation.last_message_at
                                                    }}
                                                </span>
                                            </div>
                                            <p
                                                class="text-sm text-gray-500 dark:text-gray-400 truncate mt-0.5"
                                            >
                                                <!-- Draft indicator -->
                                                <span
                                                    v-if="
                                                        getDraftForConversation(
                                                            conversation.id
                                                        )
                                                    "
                                                    class="text-accent-500 dark:text-accent-400 font-medium"
                                                    >Draft:
                                                    {{
                                                        getDraftForConversation(
                                                            conversation.id
                                                        )
                                                    }}</span
                                                >
                                                <!-- Normal last message -->
                                                <template v-else>
                                                    <span
                                                        v-if="
                                                            conversation.last_message_direction ===
                                                            'outbound'
                                                        "
                                                        class="text-primary-600 dark:text-primary-400 font-medium"
                                                        >You: </span
                                                    >{{
                                                        conversation.last_message
                                                    }}
                                                </template>
                                            </p>
                                            <div
                                                class="flex items-center gap-2 mt-2"
                                            >
                                                <span
                                                    v-if="
                                                        conversation.needs_reply
                                                    "
                                                    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-accent-100 dark:bg-accent-900/30 text-accent-700 dark:text-accent-300"
                                                >
                                                    Needs Reply
                                                </span>
                                                <span
                                                    v-else-if="
                                                        conversation.mode ===
                                                        'admin'
                                                    "
                                                    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300"
                                                >
                                                    👤 Admin
                                                </span>
                                                <span
                                                    v-else
                                                    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300"
                                                >
                                                    🤖 AI
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Right Panel: Chat View -->
                    <div
                        :class="[
                            'flex flex-col bg-white/20 dark:bg-slate-900/20',
                            'absolute lg:relative inset-0 lg:inset-auto flex-1',
                            'transition-transform duration-300 ease-in-out',
                            showMobileChat
                                ? 'translate-x-0'
                                : 'translate-x-full lg:translate-x-0',
                        ]"
                    >
                        <!-- No conversation selected -->
                        <div
                            v-if="!selectedConversationId"
                            class="flex-1 flex items-center justify-center"
                        >
                            <div class="text-center p-8">
                                <div
                                    class="w-24 h-24 bg-gradient-to-br from-primary-100 to-secondary-100 dark:from-primary-900/30 dark:to-secondary-900/30 rounded-3xl flex items-center justify-center mx-auto mb-6"
                                >
                                    <svg
                                        class="w-12 h-12 text-primary-500"
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
                                </div>
                                <h3
                                    class="text-xl font-semibold text-gray-900 dark:text-white mb-2"
                                >
                                    Select a conversation
                                </h3>
                                <p class="text-gray-500 dark:text-gray-400">
                                    Choose a conversation from the list to start
                                    chatting
                                </p>
                            </div>
                        </div>

                        <!-- Loading Chat -->
                        <div
                            v-else-if="isLoadingChat"
                            class="flex-1 flex items-center justify-center"
                        >
                            <div class="text-center">
                                <svg
                                    class="animate-spin h-10 w-10 text-primary-500 mx-auto mb-4"
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
                                <p class="text-gray-500 dark:text-gray-400">
                                    Loading conversation...
                                </p>
                            </div>
                        </div>

                        <!-- Chat Content -->
                        <template v-else-if="conversationData">
                            <!-- Chat Header -->
                            <div
                                class="flex items-center justify-between px-4 lg:px-6 py-4 border-b border-white/20 dark:border-white/10 bg-white/30 dark:bg-slate-800/30"
                            >
                                <div class="flex items-center gap-3 lg:gap-4">
                                    <!-- Mobile Back Button -->
                                    <button
                                        @click="closeMobileChat"
                                        class="lg:hidden w-10 h-10 rounded-xl bg-gray-100 dark:bg-slate-700 flex items-center justify-center text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-slate-600 transition-colors"
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
                                                d="M15 19l-7-7 7-7"
                                            />
                                        </svg>
                                    </button>
                                    <div
                                        class="w-12 h-12 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-xl flex items-center justify-center text-white font-semibold text-lg shadow-lg"
                                    >
                                        {{
                                            conversationData.customer_name
                                                ?.charAt(0)
                                                ?.toUpperCase() || "?"
                                        }}
                                    </div>
                                    <div>
                                        <h3
                                            class="font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ conversationData.customer_name }}
                                        </h3>
                                        <p
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{ conversationData.phone_number }}
                                        </p>
                                    </div>
                                </div>
                                <div class="flex items-center gap-3">
                                    <!-- Mode Badge -->
                                    <span
                                        :class="[
                                            'px-3 py-1.5 rounded-full text-sm font-medium',
                                            conversationData.mode === 'ai'
                                                ? 'bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300'
                                                : 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300',
                                        ]"
                                    >
                                        {{
                                            conversationData.mode === "ai"
                                                ? "🤖 AI Mode"
                                                : "👤 Admin Mode"
                                        }}
                                    </span>
                                    <!-- Toggle Mode Button -->
                                    <button
                                        @click="toggleMode"
                                        :class="[
                                            'px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200 shadow-lg',
                                            conversationData.mode === 'ai'
                                                ? 'bg-gradient-to-r from-amber-500 to-orange-500 text-white shadow-amber-500/30 hover:shadow-amber-500/50'
                                                : 'bg-gradient-to-r from-success-500 to-secondary-500 text-white shadow-success-500/30 hover:shadow-success-500/50',
                                        ]"
                                    >
                                        Switch to
                                        {{
                                            conversationData.mode === "ai"
                                                ? "Admin"
                                                : "AI"
                                        }}
                                    </button>
                                </div>
                            </div>

                            <!-- Escalation Alert - only show if still needs reply (admin hasn't responded yet) -->
                            <div
                                v-if="
                                    conversationData.escalation_reason &&
                                    conversationData.needs_reply
                                "
                                class="mx-4 lg:mx-6 mt-4 rounded-xl bg-accent-50 dark:bg-accent-900/20 border border-accent-200 dark:border-accent-800 p-4"
                            >
                                <div class="flex items-start gap-3">
                                    <div
                                        class="w-8 h-8 bg-accent-500 rounded-lg flex items-center justify-center flex-shrink-0"
                                    >
                                        <svg
                                            class="w-5 h-5 text-white"
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
                                    <div>
                                        <h4
                                            class="font-medium text-accent-800 dark:text-accent-200"
                                        >
                                            AI escalated this conversation
                                        </h4>
                                        <p
                                            class="text-sm text-accent-700 dark:text-accent-300 mt-1"
                                        >
                                            {{
                                                conversationData.escalation_reason
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <!-- Messages Area -->
                            <div
                                id="messages-container"
                                class="flex-1 overflow-y-auto p-6 space-y-4"
                                style="background-image: url('data:image/svg+xml,%3Csvg width=\'60\' height=\'60\' viewBox=\'0 0 60 60\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cg fill=\'none\' fill-rule=\'evenodd\'%3E%3Cg fill=\'%239C92AC\' fill-opacity=\'0.03\'%3E%3Cpath d=\'M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z\'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E\');"
                            >
                                <!-- Empty Messages -->
                                <div
                                    v-if="messagesData?.length === 0"
                                    class="flex items-center justify-center h-full"
                                >
                                    <div class="text-center">
                                        <div
                                            class="w-16 h-16 bg-gray-100 dark:bg-slate-700/50 rounded-2xl flex items-center justify-center mx-auto mb-4"
                                        >
                                            <span class="text-3xl">💬</span>
                                        </div>
                                        <p
                                            class="text-gray-500 dark:text-gray-400"
                                        >
                                            No messages yet
                                        </p>
                                    </div>
                                </div>

                                <!-- Message Bubbles -->
                                <div
                                    v-for="message in messagesData"
                                    :key="message.id"
                                    :class="[
                                        'flex',
                                        message.direction === 'inbound'
                                            ? 'justify-start'
                                            : 'justify-end',
                                    ]"
                                >
                                    <div
                                        :class="[
                                            'max-w-[70%] rounded-2xl px-4 py-3 shadow-sm',
                                            message.direction === 'inbound'
                                                ? 'bg-white dark:bg-slate-700 text-gray-900 dark:text-gray-100 rounded-tl-md'
                                                : message.sender_type === 'ai'
                                                ? 'bg-gradient-to-r from-success-500 to-secondary-500 text-white rounded-tr-md'
                                                : 'bg-gradient-to-r from-primary-500 to-primary-600 text-white rounded-tr-md',
                                        ]"
                                    >
                                        <!-- Image Message -->
                                        <div
                                            v-if="
                                                message.message_type ===
                                                    'image' && message.media_url
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
                                                    alt="Image"
                                                    class="max-w-full max-h-72 object-contain rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
                                                />
                                            </a>
                                        </div>
                                        <!-- Text Content (hide "[Image received]" if we have the actual image) -->
                                        <div
                                            v-if="
                                                !(
                                                    message.message_type ===
                                                        'image' &&
                                                    message.media_url
                                                )
                                            "
                                            class="text-sm whitespace-pre-wrap leading-relaxed formatted-message"
                                            v-html="
                                                formatWhatsAppText(
                                                    message.content
                                                )
                                            "
                                        ></div>
                                        <div
                                            class="mt-2 flex items-center justify-between gap-4"
                                        >
                                            <span
                                                :class="[
                                                    'text-xs',
                                                    message.direction ===
                                                    'inbound'
                                                        ? 'text-gray-400'
                                                        : 'text-white/70',
                                                ]"
                                            >
                                                {{ message.created_at }}
                                            </span>
                                            <span
                                                v-if="
                                                    message.direction ===
                                                    'outbound'
                                                "
                                                :class="[
                                                    'text-xs',
                                                    'text-white/70',
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
                            </div>

                            <!-- Reply Form -->
                            <div
                                class="p-4 border-t border-white/20 dark:border-white/10 bg-white/30 dark:bg-slate-800/30"
                            >
                                <form
                                    @submit.prevent="sendReply"
                                    class="flex items-end gap-4"
                                >
                                    <div class="flex-1 relative">
                                        <!-- Emoji Picker Backdrop (click outside to close) -->
                                        <div
                                            v-if="showEmojiPicker"
                                            class="fixed inset-0 z-40"
                                            @click="closeEmojiPicker"
                                        ></div>

                                        <!-- Emoji Picker -->
                                        <div
                                            v-if="showEmojiPicker"
                                            class="absolute bottom-full left-0 mb-2 w-80 bg-white dark:bg-slate-800 rounded-xl shadow-2xl border border-gray-200 dark:border-slate-600 overflow-hidden z-50"
                                        >
                                            <div
                                                class="max-h-64 overflow-y-auto p-3"
                                            >
                                                <div
                                                    v-for="category in emojiCategories"
                                                    :key="category.name"
                                                    class="mb-3"
                                                >
                                                    <h4
                                                        class="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2"
                                                    >
                                                        {{ category.name }}
                                                    </h4>
                                                    <div
                                                        class="flex flex-wrap gap-1"
                                                    >
                                                        <button
                                                            v-for="emoji in category.emojis"
                                                            :key="emoji"
                                                            type="button"
                                                            @click="
                                                                insertEmoji(
                                                                    emoji
                                                                )
                                                            "
                                                            class="w-8 h-8 flex items-center justify-center text-xl hover:bg-gray-100 dark:hover:bg-slate-700 rounded transition-colors"
                                                        >
                                                            {{ emoji }}
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="flex items-end gap-2">
                                            <!-- Emoji Button -->
                                            <button
                                                type="button"
                                                @click="toggleEmojiPicker"
                                                class="w-10 h-10 flex items-center justify-center text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-slate-600 rounded-lg transition-colors flex-shrink-0"
                                                title="Add emoji"
                                            >
                                                <span class="text-xl">😊</span>
                                            </button>

                                            <textarea
                                                ref="textareaRef"
                                                :value="replyForm.message"
                                                rows="1"
                                                class="flex-1 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-slate-600 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-primary-500 resize-none py-3 px-4 min-h-[44px] max-h-[150px] overflow-y-auto"
                                                placeholder="Type a message"
                                                :disabled="replyForm.processing"
                                                @keydown="handleKeydown"
                                                @input="handleTextareaInput"
                                            ></textarea>
                                        </div>
                                        <p
                                            v-if="replyForm.errors.message"
                                            class="mt-1 text-sm text-accent-600"
                                        >
                                            {{ replyForm.errors.message }}
                                        </p>
                                    </div>
                                    <button
                                        type="submit"
                                        :disabled="
                                            replyForm.processing ||
                                            !replyForm.message
                                        "
                                        class="w-12 h-12 bg-gradient-to-r from-primary-500 to-secondary-500 text-white rounded-xl flex items-center justify-center shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                                    >
                                        <svg
                                            v-if="!replyForm.processing"
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
                        </template>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
