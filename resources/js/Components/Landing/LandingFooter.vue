<script setup>
defineProps({
    isDark: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(["toggle-theme"]);

const currentYear = new Date().getFullYear();

const footerLinks = [
    { label: "Features", href: "#features" },
    { label: "Solutions", href: "#solutions" },
    { label: "Stats", href: "#stats" },
];
</script>

<template>
    <footer class="relative border-t border-slate-200/60 dark:border-slate-800/60">
        <div class="max-w-7xl mx-auto px-5 sm:px-8 lg:px-12 py-16 lg:py-20">
            <!-- Main Footer Content -->
            <div class="grid lg:grid-cols-12 gap-12 lg:gap-8">
                <!-- Brand Column -->
                <div class="lg:col-span-5">
                    <!-- Logo -->
                    <a href="/" class="inline-block mb-6">
                        <img 
                            src="/images/long-logo.png" 
                            alt="Janji Chat" 
                            class="h-12 w-auto"
                        />
                    </a>

                    <p class="text-slate-600 dark:text-slate-400 max-w-sm mb-8 leading-relaxed">
                        Transform your customer service with AI-powered WhatsApp automation. 
                        Available 24/7, smart enough to understand your business.
                    </p>

                    <!-- Theme Toggle -->
                    <button
                        @click="emit('toggle-theme')"
                        class="inline-flex items-center gap-2.5 px-4 py-2.5 rounded-lg bg-slate-100/80 dark:bg-slate-800/80 backdrop-blur-sm text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors duration-200"
                    >
                        <template v-if="isDark">
                            <svg class="w-4 h-4 text-amber-500" fill="currentColor" viewBox="0 0 20 20">
                                <path
                                    fill-rule="evenodd"
                                    d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
                                    clip-rule="evenodd"
                                />
                            </svg>
                            <span class="text-sm font-medium">Light Mode</span>
                        </template>
                        <template v-else>
                            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"/>
                            </svg>
                            <span class="text-sm font-medium">Dark Mode</span>
                        </template>
                    </button>
                </div>

                <!-- Links Columns -->
                <div class="lg:col-span-7">
                    <div class="grid grid-cols-2 sm:grid-cols-3 gap-8">
                        <!-- Quick Links -->
                        <div>
                            <h4 class="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider mb-4">
                                Quick Links
                            </h4>
                            <ul class="space-y-3">
                                <li v-for="link in footerLinks" :key="link.label">
                                    <a
                                        :href="link.href"
                                        class="text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors duration-200"
                                    >
                                        {{ link.label }}
                                    </a>
                                </li>
                            </ul>
                        </div>

                        <!-- Legal -->
                        <div>
                            <h4 class="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider mb-4">
                                Legal
                            </h4>
                            <ul class="space-y-3">
                                <li>
                                    <a href="#" class="text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors duration-200">
                                        Privacy Policy
                                    </a>
                                </li>
                                <li>
                                    <a href="#" class="text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors duration-200">
                                        Terms of Service
                                    </a>
                                </li>
                            </ul>
                        </div>

                        <!-- Contact -->
                        <div>
                            <h4 class="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider mb-4">
                                Contact
                            </h4>
                            <ul class="space-y-3">
                                <li>
                                    <a href="mailto:hello@janjichat.com" class="text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors duration-200">
                                        hello@janjichat.com
                                    </a>
                                </li>
                                <li>
                                    <a href="#" class="inline-flex items-center gap-2 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors duration-200">
                                        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                                            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                                        </svg>
                                        WhatsApp
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bottom Bar -->
        <div class="border-t border-slate-200/60 dark:border-slate-800/60">
            <div class="max-w-7xl mx-auto px-5 sm:px-8 lg:px-12 py-6">
                <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
                    <p class="text-sm text-slate-500 dark:text-slate-400">
                        © {{ currentYear }} Janji Chat.
                    </p>

                </div>
            </div>
        </div>
    </footer>
</template>