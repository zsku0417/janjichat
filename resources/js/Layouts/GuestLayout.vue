<script setup>
import { Link } from '@inertiajs/vue3';
import ThemeToggle from '@/Components/ThemeToggle.vue';
</script>

<template>
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-slate-50 via-purple-50 to-cyan-50 dark:from-slate-900 dark:via-purple-900 dark:to-slate-900 relative overflow-hidden transition-colors duration-300">
        <!-- Theme Toggle -->
        <div class="absolute top-4 right-4 z-50">
            <ThemeToggle />
        </div>

        <!-- Animated Background Elements -->
        <div class="absolute inset-0 overflow-hidden pointer-events-none">
            <div class="absolute -top-40 -right-40 w-80 h-80 bg-purple-300/30 dark:bg-purple-500/20 rounded-full mix-blend-multiply filter blur-3xl animate-pulse"></div>
            <div class="absolute top-40 -left-40 w-80 h-80 bg-cyan-300/30 dark:bg-cyan-500/20 rounded-full mix-blend-multiply filter blur-3xl animate-pulse animation-delay-200"></div>
            <div class="absolute -bottom-40 left-1/2 w-80 h-80 bg-pink-300/30 dark:bg-pink-500/20 rounded-full mix-blend-multiply filter blur-3xl animate-pulse animation-delay-500"></div>
        </div>
        
        <!-- Content -->
        <div class="relative z-10 w-full max-w-md px-6">
            <!-- Logo -->
            <div class="text-center mb-8">
                <Link href="/" class="inline-flex flex-col items-center gap-3">
                    <div class="w-16 h-16 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-2xl flex items-center justify-center shadow-2xl shadow-primary-500/30">
                        <span class="text-3xl">🍽️</span>
                    </div>
                    <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-800 via-purple-600 to-cyan-600 dark:from-white dark:via-purple-200 dark:to-cyan-200 bg-clip-text text-transparent">
                        Janji Chat
                    </h1>
                </Link>
            </div>
            
            <!-- Glass Card -->
            <div class="glass dark:glass-dark rounded-3xl p-8 shadow-2xl border border-white/40 dark:border-white/10 transition-colors duration-300">
                <slot />
            </div>
            
            <!-- Footer -->
            <p class="text-center text-gray-500 dark:text-white/40 text-sm mt-8 transition-colors duration-300">
                © {{ new Date().getFullYear() }} Janji Chat. All rights reserved.
            </p>
        </div>
    </div>
</template>

<style scoped>
.glass-dark {
    background: rgba(15, 23, 42, 0.7);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
}
</style>
