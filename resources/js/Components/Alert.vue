<script setup>
import { ref, watch, onMounted, computed } from "vue";

const props = defineProps({
    type: {
        type: String,
        default: "info", // success, error, warning, info
        validator: (value) =>
            ["success", "error", "warning", "info"].includes(value),
    },
    message: {
        type: String,
        required: true,
    },
    dismissible: {
        type: Boolean,
        default: true,
    },
    autoDismiss: {
        type: Boolean,
        default: true,
    },
    autoDismissDelay: {
        type: Number,
        default: 8000, // 5 seconds
    },
});

const emit = defineEmits(["dismiss"]);

const isVisible = ref(true);
const isLeaving = ref(false);
let dismissTimeout = null;

const alertConfig = computed(() => {
    const configs = {
        success: {
            bgClass: "bg-green-50/50 dark:bg-green-900/20",
            borderClass: "border-green-200 dark:border-green-800",
            iconBgClass: "from-green-400 to-green-500",
            textClass: "text-green-800 dark:text-green-200",
            icon: "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z",
        },
        error: {
            bgClass: "bg-red-50/50 dark:bg-red-900/20",
            borderClass: "border-red-200 dark:border-red-800",
            iconBgClass: "from-red-400 to-red-500",
            textClass: "text-red-800 dark:text-red-200",
            icon: "M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z",
        },
        warning: {
            bgClass: "bg-amber-50/50 dark:bg-amber-900/20",
            borderClass: "border-amber-200 dark:border-amber-800",
            iconBgClass: "from-amber-400 to-amber-500",
            textClass: "text-amber-800 dark:text-amber-200",
            icon: "M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z",
        },
        info: {
            bgClass: "bg-blue-50/50 dark:bg-blue-900/20",
            borderClass: "border-blue-200 dark:border-blue-800",
            iconBgClass: "from-blue-400 to-blue-500",
            textClass: "text-blue-800 dark:text-blue-200",
            icon: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
        },
    };
    return configs[props.type];
});

const dismiss = () => {
    isLeaving.value = true;
    setTimeout(() => {
        isVisible.value = false;
        emit("dismiss");
    }, 300); // Match the transition duration
};

const clearTimeout = () => {
    if (dismissTimeout) {
        window.clearTimeout(dismissTimeout);
        dismissTimeout = null;
    }
};

const startAutoDismiss = () => {
    if (props.autoDismiss && props.autoDismissDelay > 0) {
        clearTimeout();
        dismissTimeout = window.setTimeout(() => {
            dismiss();
        }, props.autoDismissDelay);
    }
};

// Watch for message changes to restart auto-dismiss timer
watch(
    () => props.message,
    () => {
        isVisible.value = true;
        isLeaving.value = false;
        startAutoDismiss();
    }
);

onMounted(() => {
    startAutoDismiss();
});
</script>

<template>
    <Transition
        enter-active-class="transition-all duration-300 ease-out"
        enter-from-class="opacity-0 translate-y-[-10px]"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition-all duration-300 ease-in"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 translate-y-[-10px]"
    >
        <div
            v-if="isVisible && !isLeaving"
            :class="[
                'glass rounded-xl p-4 border shadow-lg',
                alertConfig.bgClass,
                alertConfig.borderClass,
            ]"
            role="alert"
        >
            <div class="flex items-center gap-3">
                <!-- Icon -->
                <div
                    :class="[
                        'w-8 h-8 bg-gradient-to-br rounded-lg flex items-center justify-center flex-shrink-0',
                        alertConfig.iconBgClass,
                    ]"
                >
                    <svg
                        class="w-5 h-5 text-white"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                    >
                        <path
                            fill-rule="evenodd"
                            :d="alertConfig.icon"
                            clip-rule="evenodd"
                        />
                    </svg>
                </div>

                <!-- Message -->
                <p
                    :class="[
                        'text-sm font-medium flex-1',
                        alertConfig.textClass,
                    ]"
                >
                    {{ message }}
                </p>

                <!-- Dismiss Button -->
                <button
                    v-if="dismissible"
                    @click="dismiss"
                    :class="[
                        'p-1 rounded-lg transition-all hover:bg-white/50 dark:hover:bg-black/20 flex-shrink-0',
                        alertConfig.textClass,
                    ]"
                    aria-label="Dismiss alert"
                >
                    <svg
                        class="w-4 h-4"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                    >
                        <path
                            fill-rule="evenodd"
                            d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                            clip-rule="evenodd"
                        />
                    </svg>
                </button>
            </div>
        </div>
    </Transition>
</template>
