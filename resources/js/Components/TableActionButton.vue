<script setup>
/**
 * TableActionButton - Icon button for DataTable actions
 *
 * Usage:
 *   <TableActionButton type="view" @click="viewItem(row)" />
 *   <TableActionButton type="edit" @click="editItem(row)" />
 *   <TableActionButton type="delete" @click="deleteItem(row)" />
 *   <TableActionButton icon="custom-icon" tooltip="Custom Action" @click="..." />
 */

const props = defineProps({
    // Predefined types: view, edit, delete, download, copy, cancel
    type: {
        type: String,
        default: null,
    },
    // Custom tooltip (overrides type default)
    tooltip: {
        type: String,
        default: null,
    },
    // Disabled state
    disabled: {
        type: Boolean,
        default: false,
    },
    // Loading state
    loading: {
        type: Boolean,
        default: false,
    },
    // Color variant: primary, success, warning, danger, neutral
    variant: {
        type: String,
        default: null, // Auto based on type
    },
});

const emit = defineEmits(["click"]);

// Type configurations
const typeConfig = {
    view: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />`,
        tooltip: "View",
        variant: "primary",
    },
    edit: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />`,
        tooltip: "Edit",
        variant: "warning",
    },
    delete: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />`,
        tooltip: "Delete",
        variant: "danger",
    },
    download: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />`,
        tooltip: "Download",
        variant: "success",
    },
    copy: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />`,
        tooltip: "Copy",
        variant: "neutral",
    },
    cancel: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />`,
        tooltip: "Cancel",
        variant: "danger",
    },
    confirm: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />`,
        tooltip: "Confirm",
        variant: "success",
    },
    refresh: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />`,
        tooltip: "Refresh",
        variant: "primary",
    },
    external: {
        icon: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />`,
        tooltip: "Open in New Tab",
        variant: "primary",
    },
};

// Resolved configuration
const config =
    props.type && typeConfig[props.type] ? typeConfig[props.type] : {};
const resolvedTooltip = props.tooltip || config.tooltip || "";
const resolvedVariant = props.variant || config.variant || "neutral";

// Variant styles
const variantStyles = {
    primary:
        "text-primary-500 hover:text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-900/20",
    success:
        "text-success-500 hover:text-success-600 hover:bg-success-50 dark:hover:bg-success-900/20",
    warning:
        "text-amber-500 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-amber-900/20",
    danger: "text-red-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20",
    neutral:
        "text-gray-500 hover:text-gray-700 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-gray-200 dark:hover:bg-slate-700",
};

const handleClick = (e) => {
    if (props.disabled || props.loading) return;
    emit("click", e);
};
</script>

<template>
    <button
        type="button"
        :disabled="disabled || loading"
        :title="resolvedTooltip"
        :class="[
            'w-8 h-8 flex items-center justify-center rounded-lg transition-all duration-200',
            'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500',
            disabled || loading
                ? 'opacity-50 cursor-not-allowed'
                : 'cursor-pointer',
            variantStyles[resolvedVariant],
        ]"
        @click="handleClick"
    >
        <!-- Loading spinner -->
        <svg
            v-if="loading"
            class="animate-spin w-4 h-4"
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

        <!-- Type-based icon -->
        <svg
            v-else-if="type && typeConfig[type]"
            class="w-4 h-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            v-html="config.icon"
        ></svg>

        <!-- Custom content slot -->
        <slot v-else></slot>
    </button>
</template>
