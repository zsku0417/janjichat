<script setup>
import BaseModal from "@/Components/BaseModal.vue";
import InputError from "@/Components/InputError.vue";
import { useForm } from "@inertiajs/vue3";
import { ref, watch } from "vue";

const props = defineProps({
    show: Boolean,
    merchant: Object,
    businessTypes: Object,
});

const emit = defineEmits(["close", "success"]);

const showPassword = ref(false);
const showToken = ref(false);

const form = useForm({
    name: props.merchant?.name || "",
    email: props.merchant?.email || "",
    password: "",
    business_type: props.merchant?.business_type || "restaurant",
    whatsapp_phone_number_id: props.merchant?.whatsapp_phone_number_id || "",
    whatsapp_phone_number: props.merchant?.whatsapp_phone_number || "",
    whatsapp_access_token: "",
});

// Update form when merchant prop changes
watch(
    () => props.merchant,
    (newMerchant) => {
        if (newMerchant) {
            form.name = newMerchant.name;
            form.email = newMerchant.email;
            form.password = "";
            form.business_type = newMerchant.business_type;
            form.whatsapp_phone_number_id =
                newMerchant.whatsapp_phone_number_id || "";
            form.whatsapp_phone_number =
                newMerchant.whatsapp_phone_number || "";
            form.whatsapp_access_token = "";
        }
    },
    { immediate: true }
);

const submit = () => {
    form.patch(route("admin.merchants.update", props.merchant.id), {
        onSuccess: () => {
            emit("success");
        },
    });
};
</script>

<template>
    <BaseModal
        :show="show"
        title="Edit Merchant"
        icon="edit"
        size="2xl"
        @close="$emit('close')"
    >
        <template #content>
            <form @submit.prevent="submit" id="editMerchantForm">
                <div class="space-y-4">
                    <!-- Basic Info -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Business Name
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                v-model="form.name"
                                type="text"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                            <InputError
                                :message="form.errors.name"
                                class="mt-1"
                            />
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Email <span class="text-red-500">*</span>
                            </label>
                            <input
                                v-model="form.email"
                                type="email"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            />
                            <InputError
                                :message="form.errors.email"
                                class="mt-1"
                            />
                        </div>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                New Password
                                <span class="text-gray-400"
                                    >(leave blank to keep)</span
                                >
                            </label>
                            <div class="relative">
                                <input
                                    v-model="form.password"
                                    :type="showPassword ? 'text' : 'password'"
                                    class="w-full px-4 py-2.5 pr-12 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                />
                                <button
                                    type="button"
                                    @click="showPassword = !showPassword"
                                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                                >
                                    <svg
                                        v-if="!showPassword"
                                        class="h-5 w-5"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                                        />
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                                        />
                                    </svg>
                                    <svg
                                        v-else
                                        class="h-5 w-5"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"
                                        />
                                    </svg>
                                </button>
                            </div>
                            <InputError
                                :message="form.errors.password"
                                class="mt-1"
                            />
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                            >
                                Business Type
                            </label>
                            <div
                                class="w-full px-4 py-2.5 rounded-xl border-0 bg-gray-100 dark:bg-slate-600 text-gray-700 dark:text-gray-300 shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-500 cursor-not-allowed"
                            >
                                {{
                                    businessTypes[merchant?.business_type] ||
                                    merchant?.business_type
                                }}
                            </div>
                            <p
                                class="mt-2 text-xs text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/20 px-3 py-2 rounded-lg"
                            >
                                🔒 Business type cannot be changed. To change
                                it, please delete this merchant and create a new
                                one.
                            </p>
                        </div>
                    </div>

                    <!-- WhatsApp Config -->
                    <div
                        class="pt-4 border-t border-gray-200 dark:border-slate-600"
                    >
                        <h4
                            class="text-sm font-medium text-gray-900 dark:text-white mb-3"
                        >
                            WhatsApp Configuration
                        </h4>
                        <div class="grid grid-cols-1 gap-4">
                            <div>
                                <label
                                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                >
                                    Phone Number ID
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.whatsapp_phone_number_id"
                                    type="text"
                                    required
                                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                />
                                <InputError
                                    :message="
                                        form.errors.whatsapp_phone_number_id
                                    "
                                    class="mt-1"
                                />
                            </div>
                            <div>
                                <label
                                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                >
                                    WhatsApp Phone Number
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.whatsapp_phone_number"
                                    type="text"
                                    required
                                    placeholder="e.g. 60123456789"
                                    class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                />
                                <InputError
                                    :message="form.errors.whatsapp_phone_number"
                                    class="mt-1"
                                />
                            </div>
                            <div>
                                <label
                                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                                >
                                    Access Token
                                    <span class="text-gray-400"
                                        >(leave blank to keep)</span
                                    >
                                </label>
                                <div class="relative">
                                    <input
                                        v-model="form.whatsapp_access_token"
                                        :type="showToken ? 'text' : 'password'"
                                        placeholder="Enter new token to update"
                                        class="w-full px-4 py-2.5 pr-12 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                                    />
                                    <button
                                        type="button"
                                        @click="showToken = !showToken"
                                        class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                                    >
                                        <svg
                                            v-if="!showToken"
                                            class="h-5 w-5"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                            stroke="currentColor"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="2"
                                                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                                            />
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="2"
                                                d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                                            />
                                        </svg>
                                        <svg
                                            v-else
                                            class="h-5 w-5"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                            stroke="currentColor"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="2"
                                                d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"
                                            />
                                        </svg>
                                    </button>
                                </div>
                                <InputError
                                    :message="form.errors.whatsapp_access_token"
                                    class="mt-1"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </template>
        <template #footer>
            <button
                type="button"
                @click="$emit('close')"
                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Cancel
            </button>
            <button
                type="submit"
                form="editMerchantForm"
                :disabled="form.processing"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all"
            >
                {{ form.processing ? "Saving..." : "Save Changes" }}
            </button>
        </template>
    </BaseModal>
</template>
