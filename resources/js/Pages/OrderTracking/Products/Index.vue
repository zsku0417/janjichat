<script setup>
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout.vue';
import DeleteModal from '@/Components/DeleteModal.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';

const props = defineProps({
    products: Object,
});

// Delete modal state
const showDeleteModal = ref(false);
const productToDelete = ref(null);
const isDeleting = ref(false);

const toggleActive = (product) => {
    router.post(route('products.toggle-active', product.id), {}, {
        preserveScroll: true,
    });
};

const openDeleteModal = (product) => {
    productToDelete.value = product;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    productToDelete.value = null;
};

const confirmDelete = () => {
    if (!productToDelete.value) return;
    
    isDeleting.value = true;
    router.delete(route('products.destroy', productToDelete.value.id), {
        onFinish: () => {
            isDeleting.value = false;
            closeDeleteModal();
        },
    });
};
</script>

<template>
    <Head title="Products" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-2xl font-bold text-gradient">Products</h2>
                    <p class="text-gray-500 text-sm mt-1">Manage your product catalog</p>
                </div>
                <Link :href="route('products.create')" class="btn-gradient flex items-center gap-2">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                    </svg>
                    Add Product
                </Link>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <!-- Products Grid -->
                <div v-if="products.data?.length" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <div v-for="product in products.data" :key="product.id" class="glass rounded-2xl overflow-hidden group">
                        <!-- Product Image Placeholder -->
                        <div class="h-48 bg-gradient-to-br from-primary-100 to-secondary-100 flex items-center justify-center">
                            <svg class="w-16 h-16 text-primary-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                            </svg>
                        </div>
                        
                        <div class="p-5">
                            <div class="flex items-start justify-between">
                                <div>
                                    <h3 class="font-semibold text-gray-900">{{ product.name }}</h3>
                                    <p class="text-xl font-bold text-primary-600 mt-1">RM {{ Number(product.price).toFixed(2) }}</p>
                                </div>
                                <button
                                    @click="toggleActive(product)"
                                    :class="[
                                        'px-2 py-1 text-xs font-medium rounded-full transition-all',
                                        product.is_active 
                                            ? 'bg-green-100 text-green-700 hover:bg-green-200' 
                                            : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                                    ]"
                                >
                                    {{ product.is_active ? 'Active' : 'Inactive' }}
                                </button>
                            </div>
                            
                            <p v-if="product.description" class="text-sm text-gray-500 mt-2 line-clamp-2">
                                {{ product.description }}
                            </p>
                            
                            <div class="flex items-center gap-2 mt-4 pt-4 border-t border-gray-100">
                                <Link :href="route('products.edit', product.id)" class="flex-1 text-center py-2 px-3 text-sm font-medium text-primary-600 hover:bg-primary-50 rounded-lg transition-all">
                                    Edit
                                </Link>
                                <button @click="openDeleteModal(product)" class="flex-1 text-center py-2 px-3 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg transition-all">
                                    Delete
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Empty State -->
                <div v-else class="glass rounded-2xl p-12 text-center">
                    <div class="w-20 h-20 bg-gradient-to-br from-primary-100 to-secondary-100 rounded-2xl flex items-center justify-center mx-auto mb-6">
                        <svg class="w-10 h-10 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                        </svg>
                    </div>
                    <h3 class="text-lg font-semibold text-gray-900 mb-2">No products yet</h3>
                    <p class="text-gray-500 mb-6">Start by adding your first product to the catalog.</p>
                    <Link :href="route('products.create')" class="btn-gradient inline-flex items-center gap-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                        </svg>
                        Add Your First Product
                    </Link>
                </div>

                <!-- Pagination -->
                <div v-if="products.data?.length && products.last_page > 1" class="mt-8 flex justify-center gap-2">
                    <Link
                        v-for="link in products.links"
                        :key="link.label"
                        :href="link.url"
                        :class="[
                            'px-4 py-2 rounded-lg text-sm font-medium transition-all',
                            link.active ? 'bg-primary-500 text-white' : 'bg-white text-gray-600 hover:bg-gray-50',
                            !link.url && 'opacity-50 cursor-not-allowed'
                        ]"
                        v-html="link.label"
                    />
                </div>
            </div>
        </div>

        <!-- Delete Modal -->
        <DeleteModal
            :show="showDeleteModal"
            title="Delete Product"
            :message="`Are you sure you want to delete '${productToDelete?.name}'? This action cannot be undone.`"
            :processing="isDeleting"
            @close="closeDeleteModal"
            @confirm="confirmDelete"
        />
    </AuthenticatedLayout>
</template>
