<script setup>
import { ref, watch } from "vue";

const props = defineProps({
    tabs: {
        type: Array,
        required: true,
        // Format: [{ key: 'info', label: 'Basic Info', icon: '...' }, ...]
    },
    modelValue: String, // Active tab key
});

const emit = defineEmits(["update:modelValue"]);

const activeTab = ref(props.modelValue || props.tabs[0]?.key);

watch(
    () => props.modelValue,
    (newValue) => {
        if (newValue) {
            activeTab.value = newValue;
        }
    }
);

const selectTab = (key) => {
    activeTab.value = key;
    emit("update:modelValue", key);
};
</script>

<template>
    <div class="border-b border-gray-200 dark:border-slate-600">
        <nav class="-mb-px flex space-x-4" aria-label="Tabs">
            <button
                v-for="tab in tabs"
                :key="tab.key"
                @click="selectTab(tab.key)"
                :class="[
                    activeTab === tab.key
                        ? 'border-primary-500 text-primary-600 dark:text-primary-400'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300',
                    'group inline-flex items-center gap-2 py-3 px-1 border-b-2 font-medium text-sm transition-colors',
                ]"
            >
                <span v-if="tab.icon" v-html="tab.icon" class="w-5 h-5"></span>
                {{ tab.label }}
                <span
                    v-if="tab.badge"
                    :class="[
                        activeTab === tab.key
                            ? 'bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:text-primary-300'
                            : 'bg-gray-100 text-gray-600 dark:bg-slate-700 dark:text-gray-400',
                        'ml-1 py-0.5 px-2 rounded-full text-xs font-medium',
                    ]"
                >
                    {{ tab.badge }}
                </span>
            </button>
        </nav>
    </div>
</template>
