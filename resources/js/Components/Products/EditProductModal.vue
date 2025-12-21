<script setup>
/**
 * EditProductModal - Edit product details with image upload (max 3 images)
 */

import { watch, ref, computed } from "vue";
import { useForm, router } from "@inertiajs/vue3";
import BaseModal from "@/Components/BaseModal.vue";
import axios from "axios";

const MAX_IMAGES = 3;

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    product: {
        type: Object,
        default: null,
    },
});

const emit = defineEmits(["close", "updated"]);

const form = useForm({
    name: "",
    price: "",
    description: "",
    is_active: true,
});

// Existing images from the product
const existingImages = ref([]);
// IDs of images to delete
const imagesToDelete = ref([]);
// New images to upload
const newImages = ref([]);
// Preview URLs for new images
const newImagePreviews = ref([]);
// Processing state
const isProcessing = ref(false);

// Total image count
const totalImageCount = computed(() => {
    return existingImages.value.length + newImagePreviews.value.length;
});

// Can add more images
const canAddMoreImages = computed(() => {
    return totalImageCount.value < MAX_IMAGES;
});

// Watch for product changes to populate form
watch(
    () => props.product,
    (product) => {
        if (product) {
            form.name = product.name || "";
            form.price = product.price || "";
            form.description = product.description || "";
            form.is_active = product.is_active ?? true;

            // Load existing images from media relationship
            existingImages.value = (product.media || []).map((m) => ({
                id: m.id,
                url: m.url || m.metadata?.secure_url,
                name: m.original_name,
            }));

            // Reset delete and new lists
            imagesToDelete.value = [];
            newImages.value = [];
            newImagePreviews.value = [];
        }
    },
    { immediate: true }
);

// Handle file selection
const handleFileSelect = (event) => {
    const files = Array.from(event.target.files);
    const remainingSlots = MAX_IMAGES - totalImageCount.value;
    const filesToAdd = files.slice(0, remainingSlots);

    filesToAdd.forEach((file) => {
        newImages.value.push(file);

        const reader = new FileReader();
        reader.onload = (e) => {
            newImagePreviews.value.push({
                url: e.target.result,
                name: file.name,
            });
        };
        reader.readAsDataURL(file);
    });

    event.target.value = "";
};

// Remove an existing image
const removeExistingImage = (imageId) => {
    imagesToDelete.value.push(imageId);
    existingImages.value = existingImages.value.filter(
        (img) => img.id !== imageId
    );
};

// Remove a new image before upload
const removeNewImage = (index) => {
    newImages.value.splice(index, 1);
    newImagePreviews.value.splice(index, 1);
};

const submitForm = async () => {
    if (!props.product || isProcessing.value) return;

    isProcessing.value = true;

    try {
        // First, delete images that were marked for deletion
        for (const mediaId of imagesToDelete.value) {
            await axios.delete(
                route("products.images.delete", [props.product.id, mediaId])
            );
        }

        // Upload new images if any
        if (newImages.value.length > 0) {
            const formData = new FormData();
            newImages.value.forEach((file, index) => {
                formData.append(`images[${index}]`, file);
            });

            await axios.post(
                route("products.images.upload", props.product.id),
                formData,
                {
                    headers: { "Content-Type": "multipart/form-data" },
                }
            );
        }

        // Update product details
        form.patch(route("products.update", props.product.id), {
            preserveScroll: true,
            onSuccess: () => {
                isProcessing.value = false;
                emit("updated");
                emit("close");
            },
            onError: () => {
                isProcessing.value = false;
            },
        });
    } catch (error) {
        console.error("Error updating product:", error);
        isProcessing.value = false;
    }
};

const handleClose = () => {
    // Prevent closing while processing
    if (isProcessing.value) return;

    form.reset();
    form.clearErrors();
    imagesToDelete.value = [];
    newImages.value = [];
    newImagePreviews.value = [];
    emit("close");
};
</script>

<template>
    <BaseModal
        :show="show"
        title="Edit Product"
        icon="edit"
        size="lg"
        :closeable="!isProcessing"
        @close="handleClose"
    >
        <template #content>
            <form @submit.prevent="submitForm" id="editProductForm">
                <div class="space-y-4">
                    <!-- Product Images Section -->
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
                        >
                            Product Images ({{ totalImageCount }}/{{
                                MAX_IMAGES
                            }})
                        </label>

                        <!-- Existing Images + New Previews -->
                        <div class="grid grid-cols-4 gap-3 mb-3">
                            <!-- Existing images -->
                            <div
                                v-for="image in existingImages"
                                :key="image.id"
                                class="relative aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-slate-700 group"
                            >
                                <img
                                    :src="image.url"
                                    :alt="image.name"
                                    class="w-full h-full object-cover"
                                />
                                <button
                                    type="button"
                                    @click="removeExistingImage(image.id)"
                                    :disabled="isProcessing"
                                    class="absolute top-1 right-1 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity disabled:opacity-50"
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

                            <!-- New image previews -->
                            <div
                                v-for="(preview, index) in newImagePreviews"
                                :key="'new-' + index"
                                class="relative aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-slate-700 group border-2 border-dashed border-primary-300 dark:border-primary-600"
                            >
                                <img
                                    :src="preview.url"
                                    :alt="preview.name"
                                    class="w-full h-full object-cover"
                                />
                                <div
                                    class="absolute inset-0 bg-primary-500/20 flex items-center justify-center"
                                >
                                    <span
                                        class="text-xs font-medium text-primary-700 dark:text-primary-300 bg-white/80 dark:bg-slate-800/80 px-2 py-1 rounded"
                                        >New</span
                                    >
                                </div>
                                <button
                                    type="button"
                                    @click="removeNewImage(index)"
                                    :disabled="isProcessing"
                                    class="absolute top-1 right-1 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity disabled:opacity-50"
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

                            <!-- Add Image Button - only show if under limit -->
                            <label
                                v-if="canAddMoreImages"
                                class="aspect-square rounded-xl border-2 border-dashed border-gray-300 dark:border-slate-600 hover:border-primary-400 dark:hover:border-primary-500 flex flex-col items-center justify-center cursor-pointer transition-colors bg-gray-50 dark:bg-slate-800"
                            >
                                <svg
                                    class="w-8 h-8 text-gray-400 dark:text-gray-500 mb-1"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M12 4v16m8-8H4"
                                    />
                                </svg>
                                <span
                                    class="text-xs text-gray-500 dark:text-gray-400"
                                    >Add</span
                                >
                                <input
                                    type="file"
                                    accept="image/*"
                                    multiple
                                    class="hidden"
                                    @change="handleFileSelect"
                                    :disabled="isProcessing"
                                />
                            </label>
                        </div>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                            Max {{ MAX_IMAGES }} images. 5MB each. Supported:
                            JPG, PNG, GIF, WebP
                        </p>
                    </div>

                    <!-- Product Name -->
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Product Name *
                        </label>
                        <input
                            v-model="form.name"
                            type="text"
                            required
                            :disabled="isProcessing"
                            class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
                            placeholder="e.g., Classic Burger"
                        />
                        <p
                            v-if="form.errors.name"
                            class="mt-1 text-sm text-red-600 dark:text-red-400"
                        >
                            {{ form.errors.name }}
                        </p>
                    </div>

                    <!-- Price -->
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Price (RM) *
                        </label>
                        <div class="relative">
                            <span
                                class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400"
                                >RM</span
                            >
                            <input
                                v-model="form.price"
                                type="number"
                                step="0.01"
                                min="0"
                                required
                                :disabled="isProcessing"
                                class="w-full px-4 py-2.5 pl-12 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
                                placeholder="0.00"
                            />
                        </div>
                        <p
                            v-if="form.errors.price"
                            class="mt-1 text-sm text-red-600 dark:text-red-400"
                        >
                            {{ form.errors.price }}
                        </p>
                    </div>

                    <!-- Description -->
                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                        >
                            Description
                        </label>
                        <textarea
                            v-model="form.description"
                            rows="3"
                            :disabled="isProcessing"
                            class="w-full px-4 py-2.5 rounded-xl border-0 bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-200 dark:ring-slate-600 focus:ring-2 focus:ring-primary-500 resize-none disabled:opacity-50"
                            placeholder="Describe your product..."
                        ></textarea>
                    </div>

                    <!-- Active Status -->
                    <div class="flex items-center gap-3">
                        <button
                            type="button"
                            @click="form.is_active = !form.is_active"
                            :disabled="isProcessing"
                            :class="[
                                'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50',
                                form.is_active
                                    ? 'bg-primary-500'
                                    : 'bg-gray-200 dark:bg-slate-600',
                            ]"
                        >
                            <span
                                :class="[
                                    'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                                    form.is_active
                                        ? 'translate-x-5'
                                        : 'translate-x-0',
                                ]"
                            />
                        </button>
                        <span class="text-sm text-gray-700 dark:text-gray-300">
                            {{
                                form.is_active
                                    ? "Product is active and visible"
                                    : "Product is hidden"
                            }}
                        </span>
                    </div>
                </div>
            </form>
        </template>

        <template #footer>
            <button
                type="button"
                @click="handleClose"
                :disabled="isProcessing"
                class="px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-700 rounded-xl ring-1 ring-inset ring-gray-200 dark:ring-slate-600 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
                Cancel
            </button>
            <button
                type="submit"
                form="editProductForm"
                :disabled="isProcessing"
                class="px-5 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 disabled:opacity-50 transition-all flex items-center gap-2"
            >
                <svg
                    v-if="isProcessing"
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
                    ></circle>
                    <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                </svg>
                {{ isProcessing ? "Saving..." : "Save Changes" }}
            </button>
        </template>
    </BaseModal>
</template>
