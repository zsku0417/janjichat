<script setup>
import { useForm, router } from "@inertiajs/vue3";
import { ref } from "vue";

const props = defineProps({
    settings: Object,
});

const emit = defineEmits(["saved"]);

// Order tracking settings form
const form = useForm({
    pickup_address: props.settings?.pickup_address || "",
    order_prefix: props.settings?.order_prefix || "ORD",
    payment_message: props.settings?.payment_message || "",
});

// Logo state
const logoUrl = ref(props.settings?.logo_url || null);
const logoInput = ref(null);
const isUploadingLogo = ref(false);
const isDeletingLogo = ref(false);

const saveSettings = () => {
    form.patch(route("settings.order-tracking.update"), {
        onSuccess: () => emit("saved"),
    });
};

const triggerLogoUpload = () => {
    logoInput.value?.click();
};

const handleLogoChange = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    isUploadingLogo.value = true;

    const formData = new FormData();
    formData.append("logo", file);

    router.post(route("settings.logo.upload"), formData, {
        forceFormData: true,
        onSuccess: () => {
            // Reload to get new logo URL
            router.reload({ only: ["orderTrackingSettings"] });
        },
        onFinish: () => {
            isUploadingLogo.value = false;
            if (logoInput.value) logoInput.value.value = "";
        },
    });
};

const deleteLogo = () => {
    if (!confirm("Are you sure you want to delete your logo?")) return;

    isDeletingLogo.value = true;

    router.delete(route("settings.logo.delete"), {
        onSuccess: () => {
            logoUrl.value = null;
        },
        onFinish: () => {
            isDeletingLogo.value = false;
        },
    });
};
</script>

<template>
    <form @submit.prevent="saveSettings" class="space-y-6">
        <!-- Logo Upload Section -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
            >
                Business Logo
            </label>
            <div class="flex items-start gap-4">
                <!-- Logo Preview -->
                <div
                    class="w-24 h-24 rounded-xl bg-gray-100 dark:bg-slate-700 border-2 border-dashed border-gray-300 dark:border-slate-500 flex items-center justify-center overflow-hidden"
                >
                    <img
                        v-if="settings?.logo_url"
                        :src="settings.logo_url"
                        alt="Business Logo"
                        class="w-full h-full object-contain"
                    />
                    <svg
                        v-else
                        class="w-10 h-10 text-gray-400 dark:text-slate-500"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                    </svg>
                </div>

                <!-- Upload/Delete Actions -->
                <div class="flex flex-col gap-2">
                    <input
                        ref="logoInput"
                        type="file"
                        accept="image/jpeg,image/png,image/webp"
                        class="hidden"
                        @change="handleLogoChange"
                    />
                    <button
                        type="button"
                        @click="triggerLogoUpload"
                        :disabled="isUploadingLogo"
                        class="px-4 py-2 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-lg hover:shadow-md disabled:opacity-50 transition-all flex items-center gap-2"
                    >
                        <svg
                            v-if="!isUploadingLogo"
                            class="w-4 h-4"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
                            />
                        </svg>
                        <svg
                            v-else
                            class="w-4 h-4 animate-spin"
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
                            />
                            <path
                                class="opacity-75"
                                fill="currentColor"
                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                            />
                        </svg>
                        {{ isUploadingLogo ? "Uploading..." : "Upload Logo" }}
                    </button>
                    <button
                        v-if="settings?.logo_url"
                        type="button"
                        @click="deleteLogo"
                        :disabled="isDeletingLogo"
                        class="px-4 py-2 text-sm font-medium text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30 disabled:opacity-50 transition-all"
                    >
                        {{ isDeletingLogo ? "Deleting..." : "Remove Logo" }}
                    </button>
                </div>
            </div>
            <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                This logo will be displayed on your white-label product page.
                Recommended size: 400x400px. Max file size: 2MB.
            </p>
        </div>

        <!-- Pickup Address -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
                Pickup Address
            </label>
            <textarea
                v-model="form.pickup_address"
                rows="3"
                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                placeholder="Enter your business pickup address..."
            ></textarea>
        </div>

        <!-- Order Prefix -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
                Order Prefix
            </label>
            <input
                v-model="form.order_prefix"
                type="text"
                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                placeholder="ORD"
            />
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                Orders will be numbered as {{ form.order_prefix }}-001,
                {{ form.order_prefix }}-002, etc.
            </p>
        </div>

        <!-- Payment Message -->
        <div>
            <label
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
                Payment Instructions
            </label>
            <textarea
                v-model="form.payment_message"
                rows="4"
                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                placeholder="Bank: ABC Bank
Account Name: Your Business Name
Account Number: 1234567890

Or scan QR code..."
            ></textarea>
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                This message will be shown after order confirmation. Use
                <code class="px-1 py-0.5 bg-gray-100 dark:bg-slate-600 rounded"
                    >{amount}</code
                >
                to insert the payment amount.
            </p>
        </div>

        <!-- Save Button -->
        <div class="flex justify-end">
            <button
                type="submit"
                :disabled="form.processing"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
            >
                {{
                    form.processing
                        ? "Saving..."
                        : "Save E-commerce Settings"
                }}
            </button>
        </div>
    </form>
</template>
