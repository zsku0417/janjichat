<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from "vue";

const props = defineProps({
    modelValue: {
        type: [String, Number],
        default: "",
    },
    options: {
        type: Array,
        default: () => [],
    },
    placeholder: {
        type: String,
        default: "Search...",
    },
    displayKey: {
        type: String,
        default: "name",
    },
    valueKey: {
        type: String,
        default: "id",
    },
    disabled: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(["update:modelValue", "select"]);

const searchQuery = ref("");
const isOpen = ref(false);
const highlightedIndex = ref(-1);
const containerRef = ref(null);
const inputRef = ref(null);

// Find selected option
const selectedOption = computed(() => {
    if (!props.modelValue) return null;
    return props.options.find(
        (opt) => opt[props.valueKey] === props.modelValue
    );
});

// Filter options based on search
const filteredOptions = computed(() => {
    if (!searchQuery.value) return props.options;
    const query = searchQuery.value.toLowerCase();
    return props.options.filter((opt) =>
        opt[props.displayKey].toLowerCase().includes(query)
    );
});

// Display value for input
const displayValue = computed(() => {
    if (isOpen.value) return searchQuery.value;
    return selectedOption.value ? selectedOption.value[props.displayKey] : "";
});

// Handle input focus
const handleFocus = () => {
    isOpen.value = true;
    searchQuery.value = "";
    highlightedIndex.value = -1;
};

// Handle input blur (delayed to allow click on option)
const handleBlur = () => {
    setTimeout(() => {
        isOpen.value = false;
        searchQuery.value = "";
    }, 200);
};

// Handle option selection
const selectOption = (option) => {
    emit("update:modelValue", option[props.valueKey]);
    emit("select", option);
    isOpen.value = false;
    searchQuery.value = "";
    inputRef.value?.blur();
};

// Clear selection
const clearSelection = () => {
    emit("update:modelValue", null);
    emit("select", null);
    searchQuery.value = "";
};

// Keyboard navigation
const handleKeydown = (e) => {
    if (!isOpen.value) {
        if (e.key === "ArrowDown" || e.key === "Enter") {
            isOpen.value = true;
            e.preventDefault();
        }
        return;
    }

    switch (e.key) {
        case "ArrowDown":
            e.preventDefault();
            highlightedIndex.value = Math.min(
                highlightedIndex.value + 1,
                filteredOptions.value.length - 1
            );
            break;
        case "ArrowUp":
            e.preventDefault();
            highlightedIndex.value = Math.max(highlightedIndex.value - 1, 0);
            break;
        case "Enter":
            e.preventDefault();
            if (
                highlightedIndex.value >= 0 &&
                filteredOptions.value[highlightedIndex.value]
            ) {
                selectOption(filteredOptions.value[highlightedIndex.value]);
            }
            break;
        case "Escape":
            isOpen.value = false;
            searchQuery.value = "";
            inputRef.value?.blur();
            break;
    }
};

// Close on outside click
const handleClickOutside = (e) => {
    if (containerRef.value && !containerRef.value.contains(e.target)) {
        isOpen.value = false;
        searchQuery.value = "";
    }
};

onMounted(() => {
    document.addEventListener("click", handleClickOutside);
});

onUnmounted(() => {
    document.removeEventListener("click", handleClickOutside);
});
</script>

<template>
    <div ref="containerRef" class="relative">
        <!-- Input -->
        <div class="relative">
            <input
                ref="inputRef"
                type="text"
                :value="displayValue"
                @input="searchQuery = $event.target.value"
                @focus="handleFocus"
                @blur="handleBlur"
                @keydown="handleKeydown"
                :placeholder="placeholder"
                :disabled="disabled"
                class="w-full px-3 py-2 pr-8 text-sm rounded-lg border-0 bg-white dark:bg-slate-600 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-500 focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
            />
            <!-- Clear button or dropdown arrow -->
            <div
                class="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1"
            >
                <button
                    v-if="selectedOption && !disabled"
                    type="button"
                    @click.stop="clearSelection"
                    class="p-0.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
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
                <svg
                    class="w-4 h-4 text-gray-400"
                    :class="{ 'rotate-180': isOpen }"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 9l-7 7-7-7"
                    />
                </svg>
            </div>
        </div>

        <!-- Dropdown -->
        <div
            v-if="isOpen"
            class="absolute z-50 w-full mt-1 bg-white dark:bg-slate-700 rounded-lg shadow-lg border border-gray-200 dark:border-slate-600 max-h-60 overflow-auto"
        >
            <div
                v-if="filteredOptions.length === 0"
                class="px-3 py-2 text-sm text-gray-500 dark:text-gray-400"
            >
                No products found
            </div>
            <button
                v-for="(option, index) in filteredOptions"
                :key="option[valueKey]"
                type="button"
                @click="selectOption(option)"
                @mouseenter="highlightedIndex = index"
                :class="[
                    'w-full text-left px-3 py-2 text-sm transition-colors',
                    highlightedIndex === index
                        ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300'
                        : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-600',
                    modelValue === option[valueKey] && 'font-medium',
                ]"
            >
                <div class="flex items-center justify-between">
                    <span>{{ option[displayKey] }}</span>
                    <span
                        v-if="option.price"
                        class="text-xs text-gray-500 dark:text-gray-400"
                    >
                        RM{{ Number(option.price).toFixed(2) }}
                    </span>
                </div>
            </button>
        </div>
    </div>
</template>
