<script setup>
import { Link } from "@inertiajs/vue3";
import { ref } from "vue";

defineProps({
    isDark: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(["toggle-theme"]);

const mobileMenuOpen = ref(false);

const navLinks = [
    { label: "Features", href: "#features" },
    { label: "Solutions", href: "#solutions" },
    { label: "Stats", href: "#stats" },
];
</script>

<template>
    <nav
        class="sticky top-0 z-50 backdrop-blur-xl bg-white/80 dark:bg-slate-950/80 border-b border-slate-200/60 dark:border-slate-800/60 transition-colors duration-300"
    >
        <div class="max-w-7xl mx-auto px-5 sm:px-8 lg:px-12">
            <div class="flex items-center justify-between h-16 lg:h-18">
                <!-- Logo -->
                <a href="/" class="flex items-center">
                    <img 
                        src="/images/long-logo.png" 
                        alt="Janji Chat" 
                        class="h-10 sm:h-11 w-auto"
                    />
                </a>

                <!-- Nav Links - Desktop -->
                <div class="hidden md:flex items-center gap-1">
                    <a
                        v-for="link in navLinks"
                        :key="link.label"
                        :href="link.href"
                        class="px-4 py-2 rounded-lg text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 font-medium transition-all duration-200"
                    >
                        {{ link.label }}
                    </a>
                </div>

                <!-- Right Side -->
                <div class="flex items-center gap-3">
                    <!-- Theme Toggle -->
                    <button
                        @click="emit('toggle-theme')"
                        class="relative p-2.5 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors duration-200"
                        aria-label="Toggle theme"
                    >
                        <div class="relative w-5 h-5">
                            <!-- Sun Icon -->
                            <svg
                                :class="[
                                    'absolute inset-0 w-5 h-5 text-amber-500 transition-all duration-300',
                                    isDark
                                        ? 'opacity-100 rotate-0 scale-100'
                                        : 'opacity-0 -rotate-90 scale-50',
                                ]"
                                fill="currentColor"
                                viewBox="0 0 20 20"
                            >
                                <path
                                    fill-rule="evenodd"
                                    d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
                                    clip-rule="evenodd"
                                />
                            </svg>
                            <!-- Moon Icon -->
                            <svg
                                :class="[
                                    'absolute inset-0 w-5 h-5 text-slate-600 dark:text-slate-400 transition-all duration-300',
                                    isDark
                                        ? 'opacity-0 rotate-90 scale-50'
                                        : 'opacity-100 rotate-0 scale-100',
                                ]"
                                fill="currentColor"
                                viewBox="0 0 20 20"
                            >
                                <path
                                    d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"
                                />
                            </svg>
                        </div>
                    </button>

                    <!-- Mobile Menu Button -->
                    <button
                        @click="mobileMenuOpen = !mobileMenuOpen"
                        class="md:hidden p-2.5 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors duration-200"
                        aria-label="Toggle menu"
                    >
                        <svg
                            class="w-5 h-5 text-slate-600 dark:text-slate-400"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                v-if="!mobileMenuOpen"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M4 6h16M4 12h16M4 18h16"
                            />
                            <path
                                v-else
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M6 18L18 6M6 6l12 12"
                            />
                        </svg>
                    </button>

                    <!-- Login Button -->
                    <Link
                        :href="route('login')"
                        class="hidden sm:inline-flex px-5 py-2.5 rounded-lg bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-semibold shadow-md hover:shadow-lg transform hover:-translate-y-0.5 active:translate-y-0 transition-all duration-200"
                    >
                        Login
                    </Link>
                </div>
            </div>
        </div>

        <!-- Mobile Menu -->
        <Transition
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="opacity-0 -translate-y-2"
            enter-to-class="opacity-100 translate-y-0"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="opacity-100 translate-y-0"
            leave-to-class="opacity-0 -translate-y-2"
        >
            <div
                v-if="mobileMenuOpen"
                class="md:hidden border-t border-slate-200/60 dark:border-slate-800/60 bg-white/95 dark:bg-slate-950/95 backdrop-blur-xl"
            >
                <div class="px-5 py-4 space-y-1">
                    <a
                        v-for="link in navLinks"
                        :key="link.label"
                        :href="link.href"
                        @click="mobileMenuOpen = false"
                        class="block px-4 py-3 rounded-lg text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 font-medium transition-colors duration-200"
                    >
                        {{ link.label }}
                    </a>
                    <Link
                        :href="route('login')"
                        class="block w-full mt-4 px-4 py-3 rounded-lg bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-semibold text-center transition-colors duration-200"
                    >
                        Login
                    </Link>
                </div>
            </div>
        </Transition>
    </nav>
</template>