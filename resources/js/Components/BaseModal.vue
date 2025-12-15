<script setup>
/**
 * BaseModal - Reusable modal component with consistent styling
 *
 * Features:
 * - Glass morphism design matching the app theme
 * - Gradient icon header
 * - Body scroll lock when open
 * - Backdrop click to close (optional)
 * - Multiple size options
 *
 * Usage:
 *   <BaseModal :show="isOpen" title="Modal Title" icon="plus" @close="isOpen = false">
 *       <template #content>Your content here</template>
 *       <template #footer>Your action buttons</template>
 *   </BaseModal>
 */

import { watch, onUnmounted } from "vue";

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    title: {
        type: String,
        required: true,
    },
    // Icon type: plus, view, edit, delete, calendar, user, info, warning
    icon: {
        type: String,
        default: "info",
    },
    // Size: sm, md, lg, xl, full (ignored if customWidth is set)
    size: {
        type: String,
        default: "md",
    },
    // Custom width class: e.g. 'w-[200px]', 'w-[90vw]', 'max-w-3xl'
    customWidth: {
        type: String,
        default: null,
    },
    // Allow closing by clicking backdrop
    closeable: {
        type: Boolean,
        default: true,
    },
});

const emit = defineEmits(["close"]);

// Icon SVG paths
const iconPaths = {
    plus: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />',
    view: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />',
    edit: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />',
    delete: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />',
    calendar:
        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />',
    user: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />',
    info: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />',
    warning:
        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />',
};

// Size classes
const sizeClasses = {
    sm: "max-w-sm",
    md: "max-w-md",
    lg: "max-w-lg",
    xl: "max-w-xl",
    "2xl": "max-w-2xl",
    full: "max-w-4xl",
};

// Lock body scroll when modal is open
watch(
    () => props.show,
    (isOpen) => {
        if (isOpen) {
            document.body.style.overflow = "hidden";
        } else {
            document.body.style.overflow = "";
        }
    }
);

// Cleanup on unmount
onUnmounted(() => {
    document.body.style.overflow = "";
});

const handleBackdropClick = () => {
    if (props.closeable) {
        emit("close");
    }
};

const handleClose = () => {
    emit("close");
};
</script>

<template>
    <Teleport to="body">
        <Transition
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
        >
            <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto">
                <div class="flex min-h-screen items-center justify-center p-4">
                    <!-- Backdrop -->
                    <div
                        class="fixed inset-0 bg-black/50 backdrop-blur-sm"
                        @click="handleBackdropClick"
                    ></div>

                    <!-- Modal Content -->
                    <Transition
                        enter-active-class="transition-all duration-200"
                        enter-from-class="opacity-0 scale-95"
                        enter-to-class="opacity-100 scale-100"
                        leave-active-class="transition-all duration-150"
                        leave-from-class="opacity-100 scale-100"
                        leave-to-class="opacity-0 scale-95"
                    >
                        <div
                            v-if="show"
                            :class="[
                                'relative glass rounded-2xl shadow-2xl w-full p-6',
                                customWidth ||
                                    sizeClasses[size] ||
                                    sizeClasses.md,
                            ]"
                        >
                            <!-- Header -->
                            <div class="flex items-center justify-between mb-6">
                                <h3
                                    class="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-3"
                                >
                                    <div
                                        class="w-10 h-10 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-xl flex items-center justify-center flex-shrink-0"
                                    >
                                        <svg
                                            class="w-5 h-5 text-white"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                            v-html="
                                                iconPaths[icon] ||
                                                iconPaths.info
                                            "
                                        ></svg>
                                    </div>
                                    {{ title }}
                                </h3>
                                <button
                                    v-if="closeable"
                                    @click="handleClose"
                                    class="w-8 h-8 flex items-center justify-center rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors"
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

                            <!-- Content -->
                            <div class="modal-content">
                                <slot name="content"></slot>
                            </div>

                            <!-- Footer -->
                            <div
                                v-if="$slots.footer"
                                class="mt-6 flex justify-end gap-3"
                            >
                                <slot name="footer"></slot>
                            </div>
                        </div>
                    </Transition>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>
