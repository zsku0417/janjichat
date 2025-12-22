<script setup>
import { Head } from "@inertiajs/vue3";

const props = defineProps({
    merchant: Object,
    products: Array,
});

console.log("merchant", props.merchant);
console.log("products", props.products);
</script>

<template>
    <Head :title="`${merchant.name} - Products`" />

    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-gray-100">
        <!-- Header -->
        <header class="bg-white shadow-sm sticky top-0 z-10">
            <div class="max-w-6xl mx-auto px-4 py-4">
                <div class="flex items-center gap-4">
                    <!-- Logo -->
                    <div
                        v-if="merchant.logo_url"
                        class="w-12 h-12 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0"
                    >
                        <img
                            :src="merchant.logo_url"
                            :alt="merchant.name"
                            class="w-full h-full object-contain"
                        />
                    </div>
                    <div
                        v-else
                        class="w-12 h-12 rounded-xl bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center flex-shrink-0"
                    >
                        <span class="text-white font-bold text-xl">{{
                            merchant.name.charAt(0).toUpperCase()
                        }}</span>
                    </div>
                    <!-- Business Name -->
                    <h1 class="text-xl font-bold text-gray-900">
                        {{ merchant.name }}
                    </h1>
                </div>
            </div>
        </header>

        <!-- Main Content -->
        <main class="max-w-6xl mx-auto px-4 py-8">
            <!-- Page Title -->
            <div class="mb-8">
                <h2 class="text-2xl font-bold text-gray-900">Our Products</h2>
                <p class="text-gray-600 mt-1">
                    Browse our selection of {{ products.length }} products
                </p>
            </div>

            <!-- Products Grid -->
            <div
                v-if="products.length > 0"
                class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
            >
                <div
                    v-for="product in products"
                    :key="product.id"
                    class="bg-white rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 overflow-hidden group"
                >
                    <!-- Product Image Carousel -->
                    <div
                        class="aspect-square bg-gray-100 relative overflow-hidden group/image"
                    >
                        <template
                            v-if="
                                product.image_urls &&
                                product.image_urls.length > 0
                            "
                        >
                            <!-- Images -->
                            <div
                                class="w-full h-full flex transition-transform duration-500 ease-out"
                                :style="{
                                    transform: `translateX(-${
                                        (product.currentImageIndex || 0) * 100
                                    }%)`,
                                }"
                            >
                                <div
                                    v-for="(url, index) in product.image_urls"
                                    :key="index"
                                    class="w-full h-full flex-shrink-0"
                                >
                                    <img
                                        :src="url"
                                        :alt="`${product.name} - Image ${
                                            index + 1
                                        }`"
                                        class="w-full h-full object-cover"
                                    />
                                </div>
                            </div>

                            <!-- Navigation Dots (only if multiple images) -->
                            <div
                                v-if="product.image_urls.length > 1"
                                class="absolute bottom-2 left-0 right-0 flex justify-center gap-1.5 z-10"
                            >
                                <button
                                    v-for="(_, index) in product.image_urls"
                                    :key="index"
                                    @click.prevent="
                                        product.currentImageIndex = index
                                    "
                                    class="w-2 h-2 rounded-full transition-all shadow-sm"
                                    :class="
                                        (product.currentImageIndex || 0) ===
                                        index
                                            ? 'bg-white scale-110'
                                            : 'bg-white/50 hover:bg-white/80'
                                    "
                                ></button>
                            </div>

                            <!-- Arrows (only if multiple images) -->
                            <div
                                v-if="product.image_urls.length > 1"
                                class="absolute inset-x-0 top-1/2 -translate-y-1/2 flex justify-between px-2 opacity-0 group-hover/image:opacity-100 transition-opacity"
                            >
                                <button
                                    @click.prevent="
                                        product.currentImageIndex =
                                            ((product.currentImageIndex || 0) -
                                                1 +
                                                product.image_urls.length) %
                                            product.image_urls.length
                                    "
                                    class="p-1 rounded-full bg-black/30 hover:bg-black/50 text-white backdrop-blur-sm transition-colors"
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
                                            d="M15 19l-7-7 7-7"
                                        />
                                    </svg>
                                </button>
                                <button
                                    @click.prevent="
                                        product.currentImageIndex =
                                            ((product.currentImageIndex || 0) +
                                                1) %
                                            product.image_urls.length
                                    "
                                    class="p-1 rounded-full bg-black/30 hover:bg-black/50 text-white backdrop-blur-sm transition-colors"
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
                                            d="M9 5l7 7-7 7"
                                        />
                                    </svg>
                                </button>
                            </div>
                        </template>

                        <!-- Fallback Placeholder -->
                        <div
                            v-else
                            class="w-full h-full flex items-center justify-center"
                        >
                            <svg
                                class="w-16 h-16 text-gray-300"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="1.5"
                                    d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                                />
                            </svg>
                        </div>
                    </div>

                    <!-- Product Info -->
                    <div class="p-4">
                        <h3
                            class="font-semibold text-gray-900 mb-1 line-clamp-2"
                        >
                            {{ product.name }}
                        </h3>
                        <p
                            v-if="product.description"
                            class="text-sm text-gray-500 mb-3 line-clamp-2"
                        >
                            {{ product.description }}
                        </p>
                        <div
                            class="flex items-center justify-between pt-2 border-t border-gray-100"
                        >
                            <span class="text-lg font-bold text-primary-600">
                                {{ product.formatted_price }}
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Empty State -->
            <div
                v-else
                class="text-center py-16 bg-white rounded-2xl shadow-sm"
            >
                <svg
                    class="w-16 h-16 mx-auto text-gray-300 mb-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                    />
                </svg>
                <h3 class="text-lg font-medium text-gray-900 mb-1">
                    No products available
                </h3>
                <p class="text-gray-500">
                    This store hasn't added any products yet.
                </p>
            </div>
        </main>

        <!-- Footer -->
        <footer class="bg-white border-t border-gray-100 mt-16">
            <div
                class="max-w-6xl mx-auto px-4 py-6 text-center text-sm text-gray-500"
            >
                <p>
                    Powered by
                    <a
                        href="/"
                        class="text-primary-600 hover:text-primary-700 font-medium"
                        >Janji Chat</a
                    >
                </p>
            </div>
        </footer>
    </div>
</template>

<style scoped>
.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}
</style>
