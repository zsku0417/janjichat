<script setup>
import { Head } from "@inertiajs/vue3";
import { ref, computed, onMounted, watch } from "vue";

const props = defineProps({
    merchant: Object,
    products: Array,
});

// --- State ---
const cart = ref([]);
const isCartOpen = ref(false);
const orderType = ref("delivery"); // 'delivery' | 'pickup'
const deliveryAddress = ref("");
const requestedDatetime = ref("");
const isAnimatingCart = ref(false);
const showToast = ref(false);
const toastMessage = ref("");

// --- Toast Logic ---
const triggerToast = (message) => {
    toastMessage.value = message;
    showToast.value = true;
    setTimeout(() => {
        showToast.value = false;
    }, 3000);
};

// --- Cart Logic ---

// Load cart from localStorage on mount
onMounted(() => {
    const savedCart = localStorage.getItem(`cart_${props.merchant.id}`);
    if (savedCart) {
        cart.value = JSON.parse(savedCart);
    }
});

// Save cart to localStorage whenever it changes
watch(
    cart,
    (newCart) => {
        localStorage.setItem(
            `cart_${props.merchant.id}`,
            JSON.stringify(newCart)
        );
    },
    { deep: true }
);

// Lock body scroll when cart is open
watch(isCartOpen, (isOpen) => {
    if (isOpen) {
        document.body.classList.add("overflow-hidden");
    } else {
        document.body.classList.remove("overflow-hidden");
    }
});

const addToCart = (product) => {
    const existingItem = cart.value.find((item) => item.id === product.id);
    if (existingItem) {
        existingItem.quantity++;
    } else {
        cart.value.push({
            ...product,
            quantity: 1,
        });
    }

    // Animate cart button
    isAnimatingCart.value = true;
    setTimeout(() => (isAnimatingCart.value = false), 300);

    // Show toast
    triggerToast(`Added ${product.name} to cart`);

    // Open cart if first item
    if (cart.value.length === 1 && cart.value[0].quantity === 1) {
        isCartOpen.value = true;
    }
};

const removeFromCart = (productId) => {
    cart.value = cart.value.filter((item) => item.id !== productId);
};

const clearCart = () => {
    if (confirm("Are you sure you want to clear your cart?")) {
        cart.value = [];
    }
};

const updateQuantity = (productId, delta) => {
    const item = cart.value.find((item) => item.id === productId);
    if (item) {
        item.quantity += delta;
        if (item.quantity <= 0) {
            removeFromCart(productId);
        }
    }
};

const cartTotal = computed(() => {
    return cart.value.reduce(
        (total, item) => total + parseFloat(item.price) * item.quantity,
        0
    );
});

const cartItemCount = computed(() => {
    return cart.value.reduce((total, item) => total + item.quantity, 0);
});

const formatPrice = (price) => {
    return "RM " + parseFloat(price).toFixed(2);
};

// --- Checkout Logic ---

const formatDatetime = (datetimeStr) => {
    // Expected input: 2026-01-12T15:25
    if (!datetimeStr) return "";
    const date = new Date(datetimeStr);

    // Format: 12 January 2026 3:25pm
    const day = date.getDate();
    const month = date.toLocaleString("default", { month: "long" });
    const year = date.getFullYear();

    let hours = date.getHours();
    const minutes = date.getMinutes().toString().padStart(2, "0");
    const ampm = hours >= 12 ? "pm" : "am";
    hours = hours % 12;
    hours = hours ? hours : 12; // the hour '0' should be '12'

    return `${day} ${month} ${year} ${hours}:${minutes}${ampm}`;
};

const minDatetime = computed(() => {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const day = String(now.getDate()).padStart(2, "0");
    const hours = String(now.getHours()).padStart(2, "0");
    const minutes = String(now.getMinutes()).padStart(2, "0");
    return `${year}-${month}-${day}T${hours}:${minutes}`;
});

const isCheckoutDisabled = computed(() => {
    if (!requestedDatetime.value) return true;
    if (orderType.value === "delivery" && !deliveryAddress.value.trim())
        return true;
    return false;
});

const checkout = () => {
    if (!props.merchant.whatsapp_phone_number) {
        alert("This merchant hasn't set up WhatsApp yet.");
        return;
    }

    if (orderType.value === "delivery" && !deliveryAddress.value.trim()) {
        alert("Please enter a delivery address.");
        return;
    }

    // Build Message
    let message = `*I Want order*\n\n`;

    // Items
    message += `*Items:*\n`;
    cart.value.forEach((item) => {
        message += `${item.quantity}x ${item.name} (${formatPrice(
            item.price * item.quantity
        )})\n`;
    });

    message += `\n*Total: ${formatPrice(cartTotal.value)}*\n`;
    message += `------------------\n`;

    // Order Details
    message += `*Order Type:* ${
        orderType.value === "delivery" ? "Delivery 🛵" : "Pickup 🛍️"
    }\n`;

    if (requestedDatetime.value) {
        message += `*Requested Time:* ${formatDatetime(
            requestedDatetime.value
        )}\n`;
    }

    if (orderType.value === "delivery") {
        message += `*Delivery Address:*\n${deliveryAddress.value}\n`;
    }
    // Logic update: If pickup, do NOT include pickup address in the message sent to merchant
    // (but it is still shown in the cart UI for the user)

    // WhatsApp URL
    const phone = props.merchant.whatsapp_phone_number.replace(/\D/g, "");
    const url = `https://wa.me/${phone}?text=${encodeURIComponent(message)}`;

    window.open(url, "_blank");
};

// --- Animation Helpers ---
const getDelay = (index) => `${index * 100}ms`;

// --- General Utils ---
const getWhatsappUrl = (phone, text = "") => {
    if (!phone) return "#";
    const cleanPhone = phone.replace(/\D/g, "");
    const encodedText = encodeURIComponent(text);
    return `https://wa.me/${cleanPhone}?text=${encodedText}`;
};
</script>

<template>
    <Head :title="`${merchant.name} - Shop`" />

    <div
        class="min-h-screen bg-slate-50 font-sans selection:bg-primary-500 selection:text-white pb-24 sm:pb-0"
    >
        <!-- Toast Notification (Centered Top) -->
        <div
            class="fixed top-6 left-1/2 -translate-x-1/2 z-[60] bg-gray-900/90 backdrop-blur-md text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-4 transition-all duration-500 transform border border-white/10"
            :class="
                showToast
                    ? 'translate-y-0 opacity-100'
                    : '-translate-y-12 opacity-0 pointer-events-none'
            "
        >
            <div class="bg-green-500/20 p-2 rounded-full">
                <svg
                    class="w-5 h-5 text-green-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2.5"
                        d="M5 13l4 4L19 7"
                    />
                </svg>
            </div>
            <div>
                <p class="font-bold text-sm">Added to Cart</p>
                <p class="text-xs text-gray-300">{{ toastMessage }}</p>
            </div>
        </div>

        <!-- Abstract Background Shapes -->
        <div class="fixed inset-0 overflow-hidden pointer-events-none z-0">
            <div
                class="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-purple-200/40 rounded-full blur-3xl animate-blob mix-blend-multiply"
            ></div>
            <div
                class="absolute top-[-10%] right-[-10%] w-[50%] h-[50%] bg-cyan-200/40 rounded-full blur-3xl animate-blob animation-delay-2000 mix-blend-multiply"
            ></div>
            <div
                class="absolute -bottom-32 left-[20%] w-[50%] h-[50%] bg-pink-200/40 rounded-full blur-3xl animate-blob animation-delay-4000 mix-blend-multiply"
            ></div>
        </div>

        <!-- Glass Header -->
        <header
            class="sticky top-0 z-40 backdrop-blur-xl bg-white/80 border-b border-white/20 shadow-sm transition-all duration-300"
        >
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex items-center justify-between h-20">
                    <!-- Brand -->
                    <div class="flex items-center gap-4 group cursor-default">
                        <div class="relative">
                            <div
                                class="absolute -inset-1 bg-gradient-to-r from-primary-500 to-secondary-500 rounded-2xl blur opacity-25 group-hover:opacity-50 transition duration-500"
                            ></div>
                            <div
                                v-if="merchant.logo_url"
                                class="relative w-12 h-12 rounded-xl overflow-hidden bg-white shadow-sm ring-1 ring-black/5"
                            >
                                <img
                                    :src="merchant.logo_url"
                                    :alt="merchant.name"
                                    class="w-full h-full object-contain p-1"
                                />
                            </div>
                            <div
                                v-else
                                class="relative w-12 h-12 rounded-xl bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center shadow-lg text-white font-bold text-xl ring-1 ring-white/10"
                            >
                                {{ merchant.name.charAt(0).toUpperCase() }}
                            </div>
                        </div>
                        <h1
                            class="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600"
                        >
                            {{ merchant.name }}
                        </h1>
                    </div>

                    <!-- Cart Button (Desktop) -->
                    <button
                        @click="isCartOpen = true"
                        class="relative p-2 rounded-xl hover:bg-gray-100 transition-colors group"
                        :class="{ 'animate-bounce': isAnimatingCart }"
                    >
                        <svg
                            class="w-7 h-7 text-gray-700 group-hover:text-primary-600 transition-colors"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
                            />
                        </svg>
                        <span
                            v-if="cartItemCount > 0"
                            class="absolute -top-1 -right-1 bg-primary-500 text-white text-xs font-bold w-5 h-5 flex items-center justify-center rounded-full shadow-md border border-white transform scale-100 transition-transform duration-200"
                        >
                            {{ cartItemCount }}
                        </span>
                    </button>
                </div>
            </div>
        </header>

        <main
            class="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12"
        >
            <!-- Hero Section -->
            <div class="text-center mb-16 space-y-4 animate-fade-in-up">
                <span
                    class="inline-block px-4 py-1.5 rounded-full bg-primary-50 text-primary-600 text-sm font-semibold tracking-wide uppercase border border-primary-100 shadow-sm"
                >
                    Official Store
                </span>
                <h2
                    class="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-gray-900 via-gray-700 to-gray-900 tracking-tight pb-2"
                >
                    Discover Our Collection
                </h2>
                <p
                    class="text-lg text-gray-600 max-w-2xl mx-auto leading-relaxed"
                >
                    Explore our curated selection of high-quality products.
                    <br class="hidden sm:block" />
                    Add items to your cart and order via WhatsApp!
                </p>
            </div>

            <!-- Products Grid -->
            <div
                v-if="products.length > 0"
                class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8"
            >
                <div
                    v-for="(product, index) in products"
                    :key="product.id"
                    class="group bg-white rounded-3xl overflow-hidden hover:shadow-[0_20px_50px_-12px_rgba(0,0,0,0.1)] transition-all duration-500 border border-gray-100/50 backdrop-blur-sm relative flex flex-col animate-fade-in-up"
                    :style="{ animationDelay: getDelay(index) }"
                >
                    <!-- Floating Price Tag -->
                    <div class="absolute top-4 right-4 z-20">
                        <span
                            class="px-4 py-2 bg-white/90 backdrop-blur-md rounded-2xl shadow-lg border border-white/50 text-gray-900 font-bold text-sm tracking-wide"
                        >
                            {{ product.formatted_price }}
                        </span>
                    </div>

                    <!-- Image Carousel -->
                    <div
                        class="aspect-[4/3] bg-gray-50 relative overflow-hidden group/image"
                    >
                        <div
                            class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 z-10 pointer-events-none"
                        ></div>

                        <template
                            v-if="
                                product.image_urls &&
                                product.image_urls.length > 0
                            "
                        >
                            <div
                                class="w-full h-full flex transition-transform duration-500 cubic-bezier(0.4, 0, 0.2, 1)"
                                :style="{
                                    transform: `translateX(-${
                                        (product.currentImageIndex || 0) * 100
                                    }%)`,
                                }"
                            >
                                <div
                                    v-for="(url, idx) in product.image_urls"
                                    :key="idx"
                                    class="w-full h-full flex-shrink-0"
                                >
                                    <img
                                        :src="url"
                                        :alt="product.name"
                                        class="w-full h-full object-cover transform group-hover:scale-110 transition-transform duration-700 will-change-transform"
                                    />
                                </div>
                            </div>

                            <!-- Carousel Controls -->
                            <div
                                v-if="product.image_urls.length > 1"
                                class="absolute inset-x-0 bottom-4 z-20 flex justify-center gap-1.5 pointer-events-none"
                            >
                                <div
                                    v-for="(_, idx) in product.image_urls"
                                    :key="idx"
                                    class="w-1.5 h-1.5 rounded-full transition-all duration-300 shadow-sm"
                                    :class="
                                        (product.currentImageIndex || 0) === idx
                                            ? 'bg-white w-4'
                                            : 'bg-white/50'
                                    "
                                ></div>
                            </div>

                            <!-- Navigation Arrows -->
                            <div
                                v-if="product.image_urls.length > 1"
                                class="absolute inset-x-0 top-1/2 -translate-y-1/2 flex justify-between px-2 z-20 opacity-0 group-hover/image:opacity-100 transition-all duration-300 transform scale-90 group-hover/image:scale-100"
                            >
                                <button
                                    @click.prevent="
                                        product.currentImageIndex =
                                            ((product.currentImageIndex || 0) -
                                                1 +
                                                product.image_urls.length) %
                                            product.image_urls.length
                                    "
                                    class="p-2 rounded-full bg-white/90 shadow-lg text-gray-800 hover:bg-white transition-colors backdrop-blur-sm"
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
                                            stroke-width="2.5"
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
                                        class="w-4 h-4"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2.5"
                                            d="M9 5l7 7-7 7"
                                        />
                                    </svg>
                                </button>
                            </div>
                        </template>

                        <!-- Fallback Image -->
                        <div
                            v-else
                            class="w-full h-full flex items-center justify-center bg-gray-50"
                        >
                            <svg
                                class="w-12 h-12 text-gray-300"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="1.5"
                                    d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                                />
                            </svg>
                        </div>
                    </div>

                    <!-- Content -->
                    <div class="p-6 flex flex-col flex-grow">
                        <div class="flex-grow space-y-2">
                            <h3
                                class="font-bold text-lg text-gray-900 group-hover:text-primary-600 transition-colors line-clamp-1"
                                :title="product.name"
                            >
                                {{ product.name }}
                            </h3>
                            <p
                                class="text-sm text-gray-500 leading-relaxed line-clamp-2"
                            >
                                {{
                                    product.description ||
                                    "No description available for this product."
                                }}
                            </p>
                        </div>

                        <!-- Actions -->
                        <div
                            class="mt-6 pt-4 border-t border-gray-100/50 flex items-center justify-between gap-3"
                        >
                            <button
                                v-if="merchant.whatsapp_phone_number"
                                @click="addToCart(product)"
                                class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-gray-900 text-white text-sm font-medium rounded-xl hover:bg-gray-800 transition-all shadow-md hover:shadow-lg active:scale-95"
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
                                        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                                    />
                                </svg>
                                Add to Cart
                            </button>
                            <button
                                v-else
                                class="w-full px-4 py-2.5 bg-gray-100 text-gray-500 text-sm font-medium rounded-xl cursor-not-allowed"
                            >
                                Contact Unavailable
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Empty State -->
            <div
                v-else
                class="flex flex-col items-center justify-center py-20 bg-white/50 backdrop-blur-md rounded-3xl border border-white shadow-sm animate-fade-in-up"
            >
                <div
                    class="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mb-6 shadow-inner"
                >
                    <svg
                        class="w-10 h-10 text-gray-300"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="1.5"
                            d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                        />
                    </svg>
                </div>
                <h3 class="text-xl font-bold text-gray-900 mb-2">
                    No products found
                </h3>
                <p class="text-gray-500 max-w-md text-center">
                    It looks like this store hasn't added any products yet.
                    Check back soon!
                </p>
            </div>
        </main>

        <!-- Cart Logic (Slide Over) -->
        <div
            class="fixed inset-0 z-50 pointer-events-none"
            :class="{ 'pointer-events-auto': isCartOpen }"
        >
            <!-- Backdrop -->
            <div
                class="absolute inset-0 bg-black/50 transition-opacity duration-300"
                :class="isCartOpen ? 'opacity-100' : 'opacity-0'"
                @click="isCartOpen = false"
            ></div>

            <!-- Drawer -->
            <div
                class="absolute right-0 top-0 h-full w-full max-w-md bg-white shadow-2xl transition-transform duration-300 transform flex flex-col"
                :class="isCartOpen ? 'translate-x-0' : 'translate-x-full'"
            >
                <!-- Cart Header -->
                <div
                    class="p-4 border-b border-gray-100 flex items-center justify-between bg-white z-10"
                >
                    <h2
                        class="text-lg font-bold text-gray-900 flex items-center gap-2"
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
                                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
                            />
                        </svg>
                        Shopping Cart
                    </h2>
                    <div class="flex items-center gap-2">
                        <button
                            v-if="cart.length > 0"
                            @click="clearCart"
                            class="text-xs font-medium text-red-500 hover:text-red-600 px-2 py-1 rounded-lg hover:bg-red-50 transition-colors"
                        >
                            Clear Cart
                        </button>
                        <button
                            @click="isCartOpen = false"
                            class="p-2 hover:bg-gray-100 rounded-full transition-colors"
                        >
                            <svg
                                class="w-5 h-5 text-gray-500"
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
                </div>

                <!-- Cart Items -->
                <div class="flex-grow overflow-y-auto p-4 space-y-4">
                    <div
                        v-if="cart.length === 0"
                        class="flex flex-col items-center justify-center h-full text-center space-y-3"
                    >
                        <div
                            class="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center text-gray-300"
                        >
                            <svg
                                class="w-8 h-8"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
                                />
                            </svg>
                        </div>
                        <p class="text-gray-500 font-medium">
                            Your cart is empty
                        </p>
                        <button
                            @click="isCartOpen = false"
                            class="text-primary-600 hover:text-primary-700 text-sm font-medium"
                        >
                            Start Shopping
                        </button>
                    </div>

                    <transition-group name="list" tag="div" class="space-y-4">
                        <div
                            v-for="item in cart"
                            :key="item.id"
                            class="flex gap-4 p-3 bg-gray-50 rounded-xl border border-gray-100"
                        >
                            <!-- Thumbnail -->
                            <div
                                class="w-20 h-20 bg-white rounded-lg overflow-hidden flex-shrink-0 border border-gray-200"
                            >
                                <img
                                    v-if="
                                        item.image_urls &&
                                        item.image_urls.length > 0
                                    "
                                    :src="item.image_urls[0]"
                                    :alt="item.name"
                                    class="w-full h-full object-cover"
                                />
                                <div
                                    v-else
                                    class="w-full h-full flex items-center justify-center text-gray-300"
                                >
                                    <svg
                                        class="w-6 h-6"
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
                            </div>

                            <!-- Details -->
                            <div
                                class="flex-grow flex flex-col justify-between"
                            >
                                <div
                                    class="flex justify-between items-start gap-2"
                                >
                                    <h4
                                        class="font-medium text-gray-900 line-clamp-1"
                                    >
                                        {{ item.name }}
                                    </h4>
                                    <button
                                        @click="removeFromCart(item.id)"
                                        class="text-gray-400 hover:text-red-500 transition-colors"
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
                                                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                                            />
                                        </svg>
                                    </button>
                                </div>
                                <div class="flex justify-between items-end">
                                    <div
                                        class="text-sm font-bold text-gray-900"
                                    >
                                        {{ formatPrice(item.price) }}
                                    </div>

                                    <!-- Qty Control -->
                                    <div
                                        class="flex items-center gap-3 bg-white rounded-lg border border-gray-200 px-2 py-1 shadow-sm"
                                    >
                                        <button
                                            @click="updateQuantity(item.id, -1)"
                                            class="w-5 h-5 flex items-center justify-center text-gray-500 hover:text-gray-900 disabled:opacity-50"
                                        >
                                            -
                                        </button>
                                        <span
                                            class="text-sm font-medium w-4 text-center"
                                            >{{ item.quantity }}</span
                                        >
                                        <button
                                            @click="updateQuantity(item.id, 1)"
                                            class="w-5 h-5 flex items-center justify-center text-gray-500 hover:text-gray-900"
                                        >
                                            +
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </transition-group>
                </div>

                <!-- Footer / Checkout -->
                <div
                    v-if="cart.length > 0"
                    class="border-t border-gray-100 p-4 bg-gray-50 space-y-4"
                >
                    <!-- Order Type Selector -->
                    <div
                        class="grid grid-cols-2 gap-2 p-1 bg-white rounded-xl border border-gray-200"
                    >
                        <button
                            @click="orderType = 'delivery'"
                            class="px-4 py-2 text-sm font-medium rounded-lg transition-all"
                            :class="
                                orderType === 'delivery'
                                    ? 'bg-gray-900 text-white shadow-sm'
                                    : 'text-gray-500 hover:bg-gray-50'
                            "
                        >
                            Delivery
                        </button>
                        <button
                            @click="orderType = 'pickup'"
                            class="px-4 py-2 text-sm font-medium rounded-lg transition-all"
                            :class="
                                orderType === 'pickup'
                                    ? 'bg-gray-900 text-white shadow-sm'
                                    : 'text-gray-500 hover:bg-gray-50'
                            "
                        >
                            Pickup
                        </button>
                    </div>

                    <!-- Date/Time Picker -->
                    <div class="space-y-1 animate-fade-in-up">
                        <label class="text-xs font-medium text-gray-700 ml-1"
                            >Preferred Time</label
                        >
                        <input
                            type="datetime-local"
                            v-model="requestedDatetime"
                            :min="minDatetime"
                            class="w-full rounded-xl border-gray-200 focus:border-primary-500 focus:ring-primary-500 text-sm bg-white"
                        />
                    </div>

                    <!-- Address Input (if delivery) -->
                    <div
                        v-if="orderType === 'delivery'"
                        class="space-y-1 animate-fade-in-up"
                    >
                        <label class="text-xs font-medium text-gray-700 ml-1"
                            >Delivery Address</label
                        >
                        <textarea
                            v-model="deliveryAddress"
                            rows="2"
                            placeholder="Enter your full address..."
                            class="w-full rounded-xl border-gray-200 focus:border-primary-500 focus:ring-primary-500 resize-none text-sm bg-white"
                        ></textarea>
                    </div>

                    <!-- Pickup Info (if pickup) -->
                    <div
                        v-else
                        class="p-3 bg-blue-50 text-blue-800 rounded-xl text-sm border border-blue-100 animate-fade-in-up"
                    >
                        <p class="font-bold mb-1">Pickup Location:</p>
                        <p class="opacity-90">
                            {{
                                merchant.pickup_address ||
                                "Address not provided by merchant."
                            }}
                        </p>
                    </div>

                    <!-- Total -->
                    <div
                        class="flex justify-between items-center py-2 border-t border-gray-200 border-dashed"
                    >
                        <span class="text-gray-600 font-medium"
                            >Total Amount</span
                        >
                        <span class="text-2xl font-bold text-gray-900">{{
                            formatPrice(cartTotal)
                        }}</span>
                    </div>

                    <!-- Primary Action -->
                    <button
                        @click="checkout"
                        :disabled="isCheckoutDisabled"
                        class="w-full flex items-center justify-center gap-2 px-6 py-3.5 text-white font-bold rounded-2xl transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0 disabled:active:scale-100"
                        :class="
                            isCheckoutDisabled
                                ? 'bg-gray-400 shadow-none'
                                : 'bg-[#25D366] hover:bg-[#20bd5a]'
                        "
                    >
                        <svg
                            class="w-5 h-5"
                            fill="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.008-.57-.008-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"
                            />
                        </svg>
                        Place Order on WhatsApp
                    </button>

                    <p class="text-xs text-center text-gray-400">
                        This will open WhatsApp with your pre-filled order
                        details.
                    </p>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <footer
            class="relative z-10 mt-20 border-t border-gray-200/60 bg-white/50 backdrop-blur-sm"
        >
            <div
                class="max-w-7xl mx-auto px-4 py-12 flex flex-col items-center text-center space-y-4"
            >
                <p class="text-sm text-gray-500">
                    &copy; {{ new Date().getFullYear() }} {{ merchant.name }}.
                    All rights reserved.
                </p>
                <div class="flex items-center gap-2 text-xs text-gray-400">
                    <span>Powered by</span>
                    <a
                        href="/"
                        class="font-bold text-gray-600 hover:text-primary-600 transition-colors"
                        >Janji Chat</a
                    >
                </div>
            </div>
        </footer>

        <!-- Mobile Floating Cart Button (Visible only when cart has items) -->
        <button
            v-if="cartItemCount > 0"
            @click="isCartOpen = true"
            class="sm:hidden fixed bottom-6 right-6 z-50 w-14 h-14 bg-gray-900 text-white rounded-full shadow-2xl flex items-center justify-center hover:scale-110 active:scale-95 transition-all duration-300"
            :class="{ 'animate-bounce': isAnimatingCart }"
        >
            <div class="relative">
                <svg
                    class="w-6 h-6"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
                    />
                </svg>
                <span
                    class="absolute -top-2 -right-2 bg-primary-500 text-white text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full shadow-sm border border-gray-900"
                >
                    {{ cartItemCount }}
                </span>
            </div>
        </button>
    </div>
</template>

<style scoped>
/* Previous animations */
@keyframes blob {
    0% {
        transform: translate(0px, 0px) scale(1);
    }
    33% {
        transform: translate(30px, -50px) scale(1.1);
    }
    66% {
        transform: translate(-20px, 20px) scale(0.9);
    }
    100% {
        transform: translate(0px, 0px) scale(1);
    }
}
.animate-blob {
    animation: blob 7s infinite;
}
.animation-delay-2000 {
    animation-delay: 2s;
}
.animation-delay-4000 {
    animation-delay: 4s;
}

@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translateY(20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}
.animate-fade-in-up {
    animation: fadeInUp 0.8s ease-out forwards;
}

.cubic-bezier {
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}

.line-clamp-1 {
    display: -webkit-box;
    -webkit-line-clamp: 1;
    line-clamp: 1;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

/* List Transitions */
.list-enter-active,
.list-leave-active {
    transition: all 0.3s ease;
}
.list-enter-from,
.list-leave-to {
    opacity: 0;
    transform: translateX(30px);
}
</style>
