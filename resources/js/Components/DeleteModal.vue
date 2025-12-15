<script setup>
import { ref, watch } from "vue";

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    title: {
        type: String,
        default: "Confirm Delete",
    },
    message: {
        type: String,
        default:
            "Are you sure you want to delete this item? This action cannot be undone.",
    },
    confirmText: {
        type: String,
        default: "Delete",
    },
    cancelText: {
        type: String,
        default: "Cancel",
    },
    processing: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(["close", "confirm"]);

const isOpen = ref(props.show);

watch(
    () => props.show,
    (val) => {
        isOpen.value = val;
    }
);

const close = () => {
    emit("close");
};

const confirm = () => {
    emit("confirm");
};

// Close on escape key
const handleKeydown = (e) => {
    if (e.key === "Escape" && isOpen.value) {
        close();
    }
};

// Add event listener
if (typeof window !== "undefined") {
    window.addEventListener("keydown", handleKeydown);
}
</script>

<template>
    <Teleport to="body">
        <Transition
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
        >
            <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto">
                <!-- Backdrop -->
                <div
                    class="fixed inset-0 bg-black/50 backdrop-blur-sm"
                    @click="close"
                ></div>

                <!-- Modal -->
                <div class="flex min-h-full items-center justify-center p-4">
                    <Transition
                        enter-active-class="transition duration-200 ease-out"
                        enter-from-class="opacity-0 scale-95"
                        enter-to-class="opacity-100 scale-100"
                        leave-active-class="transition duration-150 ease-in"
                        leave-from-class="opacity-100 scale-100"
                        leave-to-class="opacity-0 scale-95"
                    >
                        <div
                            v-if="show"
                            class="relative bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-md p-6 transform"
                        >
                            <!-- Icon -->
                            <div
                                class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/30 mb-4"
                            >
                                <svg
                                    class="h-7 w-7 text-red-600"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke-width="1.5"
                                    stroke="currentColor"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                                    />
                                </svg>
                            </div>

                            <!-- Title -->
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white text-center mb-2"
                            >
                                {{ title }}
                            </h3>

                            <!-- Message -->
                            <p
                                class="text-sm text-gray-500 dark:text-gray-400 text-center mb-6"
                            >
                                {{ message }}
                            </p>

                            <!-- Slot for extra content -->
                            <slot></slot>

                            <!-- Actions -->
                            <div class="flex gap-3 mt-6">
                                <button
                                    type="button"
                                    @click="close"
                                    :disabled="processing"
                                    class="flex-1 py-2.5 px-4 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-xl transition-colors disabled:opacity-50"
                                >
                                    {{ cancelText }}
                                </button>
                                <button
                                    type="button"
                                    @click="confirm"
                                    :disabled="processing"
                                    class="flex-1 py-2.5 px-4 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-xl shadow-lg shadow-red-500/30 transition-all disabled:opacity-50"
                                >
                                    <span
                                        v-if="processing"
                                        class="flex items-center justify-center gap-2"
                                    >
                                        <svg
                                            class="animate-spin h-4 w-4"
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
                                        Deleting...
                                    </span>
                                    <span v-else>{{ confirmText }}</span>
                                </button>
                            </div>
                        </div>
                    </Transition>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>
