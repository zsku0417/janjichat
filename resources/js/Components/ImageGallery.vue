<script setup>
/**
 * ImageGallery - Lightbox style image gallery viewer
 */

import { ref, watch, computed } from "vue";

const props = defineProps({
    images: {
        type: Array,
        default: () => [],
    },
    initialIndex: {
        type: Number,
        default: 0,
    },
    show: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(["close"]);

const currentIndex = ref(props.initialIndex);

watch(
    () => props.initialIndex,
    (newIndex) => {
        currentIndex.value = newIndex;
    }
);

watch(
    () => props.show,
    (isShow) => {
        if (isShow) {
            document.body.style.overflow = "hidden";
        } else {
            document.body.style.overflow = "";
        }
    }
);

const currentImage = computed(() => {
    return props.images[currentIndex.value] || null;
});

const canGoPrev = computed(() => currentIndex.value > 0);
const canGoNext = computed(() => currentIndex.value < props.images.length - 1);

const goToPrev = () => {
    if (canGoPrev.value) {
        currentIndex.value--;
    }
};

const goToNext = () => {
    if (canGoNext.value) {
        currentIndex.value++;
    }
};

const goToIndex = (index) => {
    currentIndex.value = index;
};

const handleKeydown = (e) => {
    if (!props.show) return;

    if (e.key === "Escape") {
        emit("close");
    } else if (e.key === "ArrowLeft") {
        goToPrev();
    } else if (e.key === "ArrowRight") {
        goToNext();
    }
};

// Add keyboard listener
if (typeof window !== "undefined") {
    window.addEventListener("keydown", handleKeydown);
}
</script>

<template>
    <Teleport to="body">
        <Transition
            enter-active-class="transition-opacity duration-200"
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-active-class="transition-opacity duration-150"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
        >
            <div
                v-if="show"
                class="fixed inset-0 z-[500] flex items-center justify-center"
            >
                <!-- Backdrop -->
                <div
                    class="absolute inset-0 bg-black/90"
                    @click="emit('close')"
                ></div>

                <!-- Close Button -->
                <button
                    @click="emit('close')"
                    class="absolute top-4 right-4 z-10 w-10 h-10 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
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
                            d="M6 18L18 6M6 6l12 12"
                        />
                    </svg>
                </button>

                <!-- Image Counter -->
                <div
                    class="absolute top-4 left-4 z-10 px-3 py-1.5 rounded-full bg-white/10 text-white text-sm font-medium"
                >
                    {{ currentIndex + 1 }} / {{ images.length }}
                </div>

                <!-- Main Image -->
                <div
                    class="relative z-10 max-w-[90vw] max-h-[80vh] flex items-center justify-center"
                >
                    <img
                        v-if="currentImage"
                        :src="currentImage"
                        alt="Gallery image"
                        class="max-w-full max-h-[80vh] object-contain rounded-lg shadow-2xl"
                    />
                </div>

                <!-- Navigation Arrows -->
                <button
                    v-if="canGoPrev"
                    @click="goToPrev"
                    class="absolute left-4 z-10 w-12 h-12 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
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
                            d="M15 19l-7-7 7-7"
                        />
                    </svg>
                </button>

                <button
                    v-if="canGoNext"
                    @click="goToNext"
                    class="absolute right-4 z-10 w-12 h-12 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
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
                            d="M9 5l7 7-7 7"
                        />
                    </svg>
                </button>

                <!-- Thumbnail Strip -->
                <div
                    v-if="images.length > 1"
                    class="absolute bottom-6 left-1/2 -translate-x-1/2 z-10 flex gap-2 p-2 rounded-xl bg-white/10 backdrop-blur-sm"
                >
                    <button
                        v-for="(img, index) in images"
                        :key="index"
                        @click="goToIndex(index)"
                        :class="[
                            'w-14 h-14 rounded-lg overflow-hidden border-2 transition-all',
                            currentIndex === index
                                ? 'border-white scale-105'
                                : 'border-transparent opacity-60 hover:opacity-100',
                        ]"
                    >
                        <img
                            :src="img"
                            alt=""
                            class="w-full h-full object-cover"
                        />
                    </button>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>
