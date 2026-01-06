<script setup>
/**
 * OrderFormModal - Create/Edit Order Modal using BaseModal
 */

import { ref, computed, watch } from "vue";
import { useForm } from "@inertiajs/vue3";
import BaseModal from "@/Components/BaseModal.vue";
import SearchComboBox from "@/Components/SearchComboBox.vue";

const props = defineProps({
    show: Boolean,
    order: Object, // null for create, object for edit
    products: Array,
});

const emit = defineEmits(["close", "saved"]);

// Form state
const form = useForm({
    customer_name: "",
    customer_phone: "",
    fulfillment_type: "pickup",
    delivery_address: "",
    requested_datetime: "",
    notes: "",
    status: "pending_payment",
    items: [],
});

// Reset form when modal opens
watch(
    () => props.show,
    (newVal) => {
        if (newVal) {
            if (props.order) {
                // Edit mode - populate form
                form.customer_name = props.order.customer_name || "";
                form.customer_phone = props.order.customer_phone || "";
                form.fulfillment_type =
                    props.order.fulfillment_type || "pickup";
                form.delivery_address = props.order.delivery_address || "";
                form.requested_datetime = formatDatetimeLocal(
                    props.order.requested_datetime
                );
                form.notes = props.order.notes || "";
                form.status = props.order.status || "pending_payment";
                form.items = (props.order.items || []).map((item) => ({
                    product_id: item.product_id,
                    product_name: item.product_name,
                    quantity: item.quantity,
                    unit_price: parseFloat(item.unit_price),
                }));
            } else {
                // Create mode - reset form
                form.reset();
                form.items = [];
                form.fulfillment_type = "pickup";
                form.status = "pending_payment";
                // Set default datetime to tomorrow noon
                const tomorrow = new Date();
                tomorrow.setDate(tomorrow.getDate() + 1);
                tomorrow.setHours(12, 0, 0, 0);
                form.requested_datetime = formatDatetimeLocal(tomorrow);
            }
        }
    }
);

const formatDatetimeLocal = (date) => {
    if (!date) return "";
    const d = new Date(date);
    const pad = (n) => n.toString().padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(
        d.getDate()
    )}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

const isEditMode = computed(() => !!props.order);
const modalTitle = computed(() =>
    isEditMode.value ? "Edit Order" : "Create Order"
);
const modalIcon = computed(() => (isEditMode.value ? "edit" : "plus"));

// Item management
const addItem = () => {
    form.items.push({
        product_id: null,
        product_name: "",
        quantity: 1,
        unit_price: 0,
    });
};

const removeItem = (index) => {
    form.items.splice(index, 1);
};

const handleProductSelect = (index, product) => {
    if (product) {
        form.items[index].product_id = product.id;
        form.items[index].product_name = product.name;
        form.items[index].unit_price = parseFloat(product.price);
    } else {
        form.items[index].product_id = null;
    }
};

// Computed totals
const totalAmount = computed(() => {
    return form.items.reduce((sum, item) => {
        return sum + item.quantity * item.unit_price;
    }, 0);
});

// Status options
const statusOptions = [
    {
        value: "pending_payment",
        label: "Pending Payment",
        color: "text-amber-600",
    },
    { value: "processing", label: "Processing", color: "text-blue-600" },
    { value: "completed", label: "Completed", color: "text-green-600" },
    { value: "cancelled", label: "Cancelled", color: "text-red-600" },
];

// Submit
const submit = () => {
    if (isEditMode.value) {
        form.put(route("orders.update", props.order.id), {
            onSuccess: () => {
                emit("saved");
                emit("close");
            },
        });
    } else {
        form.post(route("orders.store"), {
            onSuccess: () => {
                emit("saved");
                emit("close");
            },
        });
    }
};

const close = () => {
    form.clearErrors();
    emit("close");
};
</script>

<template>
    <BaseModal
        :show="show"
        :title="modalTitle"
        :icon="modalIcon"
        customWidth="max-w-3xl"
        @close="close"
    >
        <template #content>
            <form @submit.prevent="submit" class="space-y-6">
                <!-- Customer Info -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Customer Name *
                        </label>
                        <input
                            v-model="form.customer_name"
                            type="text"
                            required
                            class="w-full px-4 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            placeholder="John Doe"
                        />
                        <p
                            v-if="form.errors.customer_name"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ form.errors.customer_name }}
                        </p>
                    </div>
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Phone Number *
                        </label>
                        <input
                            v-model="form.customer_phone"
                            type="text"
                            required
                            class="w-full px-4 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                            placeholder="60123456789"
                        />
                        <p
                            v-if="form.errors.customer_phone"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ form.errors.customer_phone }}
                        </p>
                    </div>
                </div>

                <!-- Order Items -->
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300"
                        >
                            Order Items *
                        </label>
                        <button
                            type="button"
                            @click="addItem"
                            class="px-3 py-1.5 text-sm font-medium text-primary-600 dark:text-primary-400 bg-primary-50 dark:bg-primary-900/30 hover:bg-primary-100 dark:hover:bg-primary-900/50 rounded-lg transition-colors"
                        >
                            + Add Item
                        </button>
                    </div>

                    <p
                        v-if="form.errors.items"
                        class="mb-2 text-sm text-red-600"
                    >
                        {{ form.errors.items }}
                    </p>

                    <div
                        v-if="form.items.length === 0"
                        class="text-center py-8 bg-gray-50 dark:bg-slate-700/50 rounded-xl border-2 border-dashed border-gray-200 dark:border-slate-600"
                    >
                        <p class="text-gray-500 dark:text-gray-400">
                            No items added yet. Click "Add Item" to start.
                        </p>
                    </div>

                    <div
                        v-else
                        class="space-y-3 max-h-[200px] overflow-y-auto pr-1"
                    >
                        <div
                            v-for="(item, index) in form.items"
                            :key="index"
                            class="flex items-start gap-3 p-3 bg-gray-50 dark:bg-slate-700/50 rounded-xl"
                        >
                            <!-- Product Search -->
                            <div class="flex-1">
                                <label
                                    class="block text-xs text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Product
                                </label>
                                <SearchComboBox
                                    v-model="item.product_id"
                                    :options="products"
                                    placeholder="Search product..."
                                    displayKey="name"
                                    valueKey="id"
                                    @select="
                                        (product) =>
                                            handleProductSelect(index, product)
                                    "
                                />
                            </div>

                            <!-- Quantity -->
                            <div class="w-20">
                                <label
                                    class="block text-xs text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Qty
                                </label>
                                <input
                                    v-model.number="item.quantity"
                                    type="number"
                                    min="1"
                                    class="w-full px-3 py-2 text-sm rounded-lg border-0 bg-white dark:bg-slate-600 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-500 focus:ring-2 focus:ring-primary-500"
                                />
                            </div>

                            <!-- Unit Price -->
                            <div class="w-28">
                                <label
                                    class="block text-xs text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Price (RM)
                                </label>
                                <div
                                    class="w-full px-3 py-2 text-sm rounded-lg bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300 ring-1 ring-inset ring-gray-200 dark:ring-slate-600"
                                >
                                    {{ item.unit_price?.toFixed(2) || "0.00" }}
                                </div>
                            </div>

                            <!-- Subtotal -->
                            <div class="w-24 text-right">
                                <label
                                    class="block text-xs text-gray-500 dark:text-gray-400 mb-1"
                                >
                                    Subtotal
                                </label>
                                <p
                                    class="py-2 text-sm font-medium text-gray-900 dark:text-white"
                                >
                                    RM{{
                                        (
                                            item.quantity * item.unit_price
                                        ).toFixed(2)
                                    }}
                                </p>
                            </div>

                            <!-- Remove -->
                            <button
                                type="button"
                                @click="removeItem(index)"
                                class="mt-6 p-2 text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors"
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
                                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                                    />
                                </svg>
                            </button>
                        </div>
                    </div>

                    <!-- Total -->
                    <div
                        v-if="form.items.length > 0"
                        class="mt-4 flex justify-end"
                    >
                        <div
                            class="px-4 py-2 bg-primary-50 dark:bg-primary-900/30 rounded-xl"
                        >
                            <span
                                class="text-sm text-gray-600 dark:text-gray-400"
                            >
                                Total:
                            </span>
                            <span
                                class="ml-2 text-lg font-bold text-primary-600 dark:text-primary-400"
                            >
                                RM{{ totalAmount.toFixed(2) }}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Fulfillment & DateTime -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Fulfillment Type *
                        </label>
                        <div class="flex gap-4">
                            <label
                                class="flex items-center gap-2 cursor-pointer"
                            >
                                <input
                                    type="radio"
                                    v-model="form.fulfillment_type"
                                    value="pickup"
                                    class="w-4 h-4 text-primary-600 focus:ring-primary-500"
                                />
                                <span class="text-gray-700 dark:text-gray-300"
                                    >🏪 Pickup</span
                                >
                            </label>
                            <label
                                class="flex items-center gap-2 cursor-pointer"
                            >
                                <input
                                    type="radio"
                                    v-model="form.fulfillment_type"
                                    value="delivery"
                                    class="w-4 h-4 text-primary-600 focus:ring-primary-500"
                                />
                                <span class="text-gray-700 dark:text-gray-300"
                                    >🚚 Delivery</span
                                >
                            </label>
                        </div>
                    </div>
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Requested Date/Time *
                        </label>
                        <input
                            v-model="form.requested_datetime"
                            type="datetime-local"
                            required
                            class="w-full px-4 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                        />
                        <p
                            v-if="form.errors.requested_datetime"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ form.errors.requested_datetime }}
                        </p>
                    </div>
                </div>

                <!-- Delivery Address (conditional) -->
                <div v-if="form.fulfillment_type === 'delivery'">
                    <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                        Delivery Address *
                    </label>
                    <textarea
                        v-model="form.delivery_address"
                        rows="2"
                        required
                        class="w-full px-4 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                        placeholder="123 Main Street, City"
                    ></textarea>
                    <p
                        v-if="form.errors.delivery_address"
                        class="mt-1 text-sm text-red-600"
                    >
                        {{ form.errors.delivery_address }}
                    </p>
                </div>

                <!-- Status -->
                <div>
                    <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                        Status *
                    </label>
                    <select
                        v-model="form.status"
                        required
                        class="w-full px-4 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                    >
                        <option
                            v-for="status in statusOptions"
                            :key="status.value"
                            :value="status.value"
                        >
                            {{ status.label }}
                        </option>
                    </select>
                </div>

                <!-- Notes -->
                <div>
                    <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                        Notes
                    </label>
                    <textarea
                        v-model="form.notes"
                        rows="2"
                        class="w-full px-4 py-2 rounded-lg border-0 bg-gray-50 dark:bg-slate-700 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500"
                        placeholder="Special instructions..."
                    ></textarea>
                </div>
            </form>
        </template>

        <template #footer>
            <button
                type="button"
                @click="close"
                class="px-5 py-2.5 text-sm font-semibold text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors"
            >
                Cancel
            </button>
            <button
                type="button"
                @click="submit"
                :disabled="form.processing || form.items.length === 0"
                class="px-5 py-2.5 text-sm font-semibold text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
                <span v-if="form.processing" class="flex items-center gap-2">
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
                    Saving...
                </span>
                <span v-else>{{
                    isEditMode ? "Update Order" : "Create Order"
                }}</span>
            </button>
        </template>
    </BaseModal>
</template>
