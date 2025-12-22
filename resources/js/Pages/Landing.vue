<script setup>
import { Head, Link } from "@inertiajs/vue3";
import { ref, onMounted, onUnmounted } from "vue";
import LandingHeader from "@/Components/Landing/LandingHeader.vue";
import LandingFooter from "@/Components/Landing/LandingFooter.vue";
import LandingChatWidget from "@/Components/Landing/LandingChatWidget.vue";

// Dark mode toggle
const isDark = ref(false);

onMounted(() => {
    const savedTheme = localStorage.getItem("theme");
    if (savedTheme) {
        isDark.value = savedTheme === "dark";
    } else {
        isDark.value = window.matchMedia(
            "(prefers-color-scheme: dark)"
        ).matches;
    }
    updateTheme();
});

const toggleTheme = () => {
    isDark.value = !isDark.value;
    localStorage.setItem("theme", isDark.value ? "dark" : "light");
    updateTheme();
};

const updateTheme = () => {
    if (isDark.value) {
        document.documentElement.classList.add("dark");
    } else {
        document.documentElement.classList.remove("dark");
    }
};

// Animated counter for stats
const stats = ref([
    {
        value: 0,
        target: 10000,
        suffix: "+",
        label: "Messages Processed",
        icon: "💬",
    },
    {
        value: 0,
        target: 500,
        suffix: "+",
        label: "Active Businesses",
        icon: "🏢",
    },
    {
        value: 0,
        target: 99,
        suffix: "%",
        label: "Customer Satisfaction",
        icon: "⭐",
    },
    {
        value: 0,
        target: 24,
        suffix: "/7",
        label: "AI Availability",
        icon: "🤖",
    },
]);

let statsAnimated = false;
const animateCounters = () => {
    if (statsAnimated) return;
    statsAnimated = true;
    stats.value.forEach((stat, index) => {
        const duration = 2000;
        const steps = 60;
        const increment = stat.target / steps;
        let current = 0;
        const interval = setInterval(() => {
            current += increment;
            if (current >= stat.target) {
                stats.value[index].value = stat.target;
                clearInterval(interval);
            } else {
                stats.value[index].value = Math.floor(current);
            }
        }, duration / steps);
    });
};

// Intersection observer for animations
let observer = null;
onMounted(() => {
    observer = new IntersectionObserver(
        (entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    entry.target.classList.add("animate-in");
                    if (entry.target.id === "stats-section") {
                        animateCounters();
                    }
                }
            });
        },
        { threshold: 0.1 }
    );

    setTimeout(() => {
        document.querySelectorAll(".animate-on-scroll").forEach((el) => {
            observer.observe(el);
        });
    }, 100);
});

onUnmounted(() => {
    if (observer) observer.disconnect();
});

// Features data
const features = [
    {
        icon: "💬",
        title: "AI-Powered Chat",
        description:
            "Smart conversations powered by GPT-4o-mini that understand context and respond naturally in any language.",
        color: "emerald",
    },
    {
        icon: "📚",
        title: "Knowledge Base",
        description:
            "Upload your documents (PDF, DOCX, TXT) and let AI learn from them to answer customer questions accurately.",
        color: "blue",
    },
    {
        icon: "📅",
        title: "Smart Booking",
        description:
            "Automated table reservations with real-time availability checking and customer reminders.",
        color: "amber",
    },
    {
        icon: "🛒",
        title: "Order Management",
        description:
            "Full order tracking system with pickup/delivery options and payment verification.",
        color: "rose",
    },
    {
        icon: "🔔",
        title: "Smart Escalation",
        description:
            "AI knows when to escalate to human support with email notifications and escalation reasons.",
        color: "violet",
    },
    {
        icon: "🏢",
        title: "Multi-Tenant",
        description:
            "Each business gets their own WhatsApp number, knowledge base, and conversation history.",
        color: "cyan",
    },
];

// Business types
const businessTypes = [
    {
        icon: "🍽️",
        name: "Restaurant",
        description: "Perfect for cafes, restaurants, and food businesses",
        features: [
            "Table Booking",
            "Reservation Management",
            "Auto Reminders",
            "Operating Hours",
        ],
    },
    {
        icon: "🛍️",
        name: "E-Commerce",
        description: "Ideal for online stores and retail businesses",
        features: [
            "Product Catalog",
            "Order Tracking",
            "Payment Verification",
            "Delivery Management",
        ],
    },
];

// Chat messages for demo
const chatMessages = [
    {
        type: "customer",
        text: "Hi! I want to book a table for 4 people tonight",
        time: "10:30",
    },
    {
        type: "ai",
        text: "Great! I'd be happy to help you book a table for 4 tonight! 🍽️\n\nWhat time would you prefer?",
        time: "10:31",
    },
    {
        type: "customer",
        text: "7:30 PM please",
        time: "10:32",
    },
    {
        type: "ai",
        text: "Perfect! I've reserved Table 5 for you ✨",
        time: "10:32",
        hasCard: true,
    },
];

// Mouse parallax effect
const mouseX = ref(0);
const mouseY = ref(0);

const handleMouseMove = (e) => {
    const rect = e.currentTarget.getBoundingClientRect();
    mouseX.value = (e.clientX - rect.left - rect.width / 2) / 50;
    mouseY.value = (e.clientY - rect.top - rect.height / 2) / 50;
};

const getFeatureColorClasses = (color) => {
    const colors = {
        emerald: "bg-emerald-50 dark:bg-emerald-950/30",
        blue: "bg-blue-50 dark:bg-blue-950/30",
        amber: "bg-amber-50 dark:bg-amber-950/30",
        rose: "bg-rose-50 dark:bg-rose-950/30",
        violet: "bg-violet-50 dark:bg-violet-950/30",
        cyan: "bg-cyan-50 dark:bg-cyan-950/30",
    };
    return colors[color] || colors.emerald;
};
</script>

<template>
    <Head title="Janji Chat - AI WhatsApp Chatbot for Business" />

    <div
        class="min-h-screen bg-slate-50 dark:bg-slate-950 transition-colors duration-500 relative"
        @mousemove="handleMouseMove"
    >
        <!-- Global Background - Covers entire page -->
        <div class="fixed inset-0 overflow-hidden pointer-events-none">
            <!-- Gradient Orbs -->
            <div
                class="absolute -top-40 -left-40 w-[600px] h-[600px] bg-emerald-400/20 dark:bg-emerald-600/10 rounded-full blur-[120px]"
                :style="{
                    transform: `translate(${mouseX * 1.5}px, ${
                        mouseY * 1.5
                    }px)`,
                }"
            ></div>
            <div
                class="absolute top-1/3 -right-40 w-[500px] h-[500px] bg-cyan-400/15 dark:bg-cyan-600/10 rounded-full blur-[120px]"
                :style="{
                    transform: `translate(${-mouseX}px, ${mouseY}px)`,
                }"
            ></div>
            <div
                class="absolute top-2/3 -left-20 w-[400px] h-[400px] bg-amber-400/10 dark:bg-amber-600/5 rounded-full blur-[100px]"
            ></div>
            <div
                class="absolute bottom-1/4 right-1/4 w-[350px] h-[350px] bg-teal-400/10 dark:bg-teal-600/5 rounded-full blur-[100px]"
            ></div>

            <!-- Dot Pattern -->
            <div
                class="absolute inset-0 opacity-[0.015] dark:opacity-[0.03]"
                style="
                    background-image: radial-gradient(
                        circle at 1px 1px,
                        currentColor 1px,
                        transparent 0
                    );
                    background-size: 40px 40px;
                "
            ></div>
        </div>

        <!-- Header -->
        <LandingHeader :is-dark="isDark" @toggle-theme="toggleTheme" />

        <!-- Hero Section -->
        <section
            class="relative pt-20 sm:pt-28 lg:pt-32 pb-24 lg:pb-32 px-5 sm:px-8 lg:px-12"
        >
            <div class="max-w-7xl mx-auto">
                <div class="grid lg:grid-cols-2 gap-16 lg:gap-24 items-center">
                    <!-- Left Content -->
                    <div class="text-center lg:text-left">
                        <!-- Badge -->
                        <div
                            class="inline-flex items-center gap-2.5 px-4 py-2 rounded-full bg-white/80 dark:bg-slate-900/80 backdrop-blur-sm border border-slate-200 dark:border-slate-800 shadow-sm mb-8 animate-on-scroll"
                        >
                            <span class="relative flex h-2 w-2">
                                <span
                                    class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"
                                ></span>
                                <span
                                    class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"
                                ></span>
                            </span>
                            <span
                                class="text-sm font-medium text-slate-600 dark:text-slate-400"
                            >
                                AI-Powered WhatsApp Automation
                            </span>
                        </div>

                        <!-- Headline -->
                        <h1
                            class="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-bold tracking-tight mb-8 animate-on-scroll"
                        >
                            <span
                                class="text-slate-900 dark:text-white block leading-[1.1]"
                            >
                                Transform Your
                            </span>
                            <span
                                class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 via-cyan-600 to-teal-600 dark:from-emerald-400 dark:via-cyan-400 dark:to-teal-400 block leading-[1.1] mt-2"
                            >
                                Customer Service
                            </span>
                        </h1>

                        <!-- Subheadline -->
                        <p
                            class="text-lg sm:text-xl text-slate-600 dark:text-slate-400 mb-12 max-w-xl mx-auto lg:mx-0 animate-on-scroll leading-relaxed"
                        >
                            Let AI handle your WhatsApp conversations 24/7.
                            Smart bookings, automated orders, and intelligent
                            responses that understand your business.
                        </p>

                        <!-- CTA Buttons -->
                        <div
                            class="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start animate-on-scroll"
                        >
                            <Link
                                :href="route('login')"
                                class="group relative px-8 py-4 rounded-xl bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-semibold text-lg shadow-lg shadow-slate-900/10 dark:shadow-white/10 hover:shadow-xl hover:shadow-slate-900/20 dark:hover:shadow-white/20 transform hover:-translate-y-0.5 active:translate-y-0 transition-all duration-300 flex items-center justify-center gap-3"
                            >
                                <span>Get Started Free</span>
                                <svg
                                    class="w-5 h-5 group-hover:translate-x-1 transition-transform duration-300"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M17 8l4 4m0 0l-4 4m4-4H3"
                                    />
                                </svg>
                            </Link>
                            <a
                                href="#features"
                                class="group px-8 py-4 rounded-xl bg-white/80 dark:bg-slate-900/80 backdrop-blur-sm text-slate-700 dark:text-slate-300 font-semibold text-lg border border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700 hover:shadow-lg transform hover:-translate-y-0.5 active:translate-y-0 transition-all duration-300 flex items-center justify-center gap-3"
                            >
                                <svg
                                    class="w-5 h-5 text-emerald-500"
                                    fill="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path d="M8 5v14l11-7z" />
                                </svg>
                                <span>See How It Works</span>
                            </a>
                        </div>
                    </div>

                    <!-- Right Content - Phone Mockup -->
                    <div class="relative animate-on-scroll">
                        <!-- Phone Frame -->
                        <div
                            class="relative max-w-[360px] mx-auto"
                            :style="{
                                transform: `perspective(1000px) rotateX(${
                                    mouseY * 0.1
                                }deg) rotateY(${-mouseX * 0.1}deg)`,
                            }"
                        >
                            <!-- Glow Effect -->
                            <div
                                class="absolute -inset-4 bg-gradient-to-r from-emerald-500/20 via-cyan-500/20 to-teal-500/20 rounded-[3.5rem] blur-2xl opacity-60"
                            ></div>

                            <!-- Phone Body -->
                            <div
                                class="relative bg-slate-900 rounded-[2.5rem] p-2.5 shadow-2xl shadow-slate-900/40 dark:shadow-black/60"
                            >
                                <!-- Dynamic Island -->
                                <div
                                    class="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-7 bg-slate-900 rounded-b-2xl z-10 flex items-center justify-center pt-1"
                                >
                                    <div
                                        class="w-16 h-4 bg-slate-800 rounded-full"
                                    ></div>
                                </div>

                                <!-- Screen -->
                                <div
                                    class="bg-white dark:bg-slate-900 rounded-[2rem] overflow-hidden"
                                >
                                    <!-- WhatsApp Header -->
                                    <div
                                        class="bg-[#075E54] text-white px-4 py-3 pt-9"
                                    >
                                        <div class="flex items-center gap-3">
                                            <button
                                                class="p-1 -ml-1 opacity-80"
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
                                            <div
                                                class="w-9 h-9 rounded-full bg-white/20 flex items-center justify-center"
                                            >
                                                <span class="text-lg">🤖</span>
                                            </div>
                                            <div class="flex-1">
                                                <p
                                                    class="font-semibold text-sm"
                                                >
                                                    Janji Chat AI
                                                </p>
                                                <p
                                                    class="text-[11px] text-white/70"
                                                >
                                                    online
                                                </p>
                                            </div>
                                            <div class="flex gap-5 opacity-80">
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
                                                        d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                                                    />
                                                </svg>
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
                                                        d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                                                    />
                                                </svg>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Chat Messages -->
                                    <div
                                        class="p-3 space-y-2.5 bg-[#ECE5DD] dark:bg-slate-800 h-[340px] overflow-hidden"
                                    >
                                        <template
                                            v-for="(msg, idx) in chatMessages"
                                            :key="idx"
                                        >
                                            <!-- Customer Message -->
                                            <div
                                                v-if="msg.type === 'customer'"
                                                class="flex justify-end"
                                            >
                                                <div
                                                    class="bg-[#DCF8C6] dark:bg-emerald-700 text-slate-800 dark:text-white px-3 py-2 rounded-lg rounded-tr-sm max-w-[80%] shadow-sm"
                                                >
                                                    <p
                                                        class="text-[13px] leading-relaxed"
                                                    >
                                                        {{ msg.text }}
                                                    </p>
                                                    <p
                                                        class="text-[10px] text-slate-500 dark:text-emerald-200/70 text-right mt-0.5 flex items-center justify-end gap-1"
                                                    >
                                                        {{ msg.time }}
                                                        <svg
                                                            class="w-3.5 h-3.5 text-blue-500 dark:text-blue-400"
                                                            fill="currentColor"
                                                            viewBox="0 0 24 24"
                                                        >
                                                            <path
                                                                d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"
                                                            />
                                                            <path
                                                                d="M12 16.17L7.83 12l-1.42 1.41L12 19 24 7l-1.41-1.41z"
                                                                style="
                                                                    transform: translateX(
                                                                        -3px
                                                                    );
                                                                "
                                                            />
                                                        </svg>
                                                    </p>
                                                </div>
                                            </div>

                                            <!-- AI Response -->
                                            <div
                                                v-else
                                                class="flex justify-start"
                                            >
                                                <div
                                                    class="bg-white dark:bg-slate-700 text-slate-800 dark:text-white px-3 py-2 rounded-lg rounded-tl-sm max-w-[80%] shadow-sm"
                                                >
                                                    <p
                                                        class="text-[13px] leading-relaxed whitespace-pre-line"
                                                    >
                                                        {{ msg.text }}
                                                    </p>

                                                    <!-- Booking Card -->
                                                    <div
                                                        v-if="msg.hasCard"
                                                        class="mt-2 p-2.5 bg-slate-50 dark:bg-slate-600 rounded-lg"
                                                    >
                                                        <div
                                                            class="flex items-center gap-2 mb-2"
                                                        >
                                                            <span
                                                                class="w-5 h-5 bg-emerald-500 rounded-full flex items-center justify-center"
                                                            >
                                                                <svg
                                                                    class="w-3 h-3 text-white"
                                                                    fill="none"
                                                                    stroke="currentColor"
                                                                    viewBox="0 0 24 24"
                                                                >
                                                                    <path
                                                                        stroke-linecap="round"
                                                                        stroke-linejoin="round"
                                                                        stroke-width="3"
                                                                        d="M5 13l4 4L19 7"
                                                                    />
                                                                </svg>
                                                            </span>
                                                            <span
                                                                class="font-semibold text-emerald-600 dark:text-emerald-400 text-xs"
                                                            >
                                                                Booking
                                                                Confirmed
                                                            </span>
                                                        </div>
                                                        <div
                                                            class="space-y-1 text-[11px] text-slate-600 dark:text-slate-300"
                                                        >
                                                            <p>
                                                                📅 Today, 7:30
                                                                PM
                                                            </p>
                                                            <p>👥 4 guests</p>
                                                            <p>🪑 Table 5</p>
                                                        </div>
                                                    </div>

                                                    <p
                                                        class="text-[10px] text-slate-400 dark:text-slate-500 mt-1"
                                                    >
                                                        {{ msg.time }}
                                                    </p>
                                                </div>
                                            </div>
                                        </template>
                                    </div>

                                    <!-- Input Area -->
                                    <div
                                        class="bg-[#F0F0F0] dark:bg-slate-900 px-2 py-2 flex items-center gap-2"
                                    >
                                        <button class="p-2 text-slate-500">
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
                                                    d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                                                />
                                            </svg>
                                        </button>
                                        <div
                                            class="flex-1 bg-white dark:bg-slate-800 rounded-full px-4 py-2 flex items-center"
                                        >
                                            <span class="text-slate-400 text-sm"
                                                >Message</span
                                            >
                                        </div>
                                        <button class="p-2 text-slate-500">
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
                                                    d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"
                                                />
                                            </svg>
                                        </button>
                                        <button
                                            class="w-10 h-10 rounded-full bg-[#075E54] flex items-center justify-center"
                                        >
                                            <svg
                                                class="w-5 h-5 text-white"
                                                fill="currentColor"
                                                viewBox="0 0 24 24"
                                            >
                                                <path
                                                    d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z"
                                                />
                                                <path
                                                    d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z"
                                                />
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Features Section -->
        <section
            id="features"
            class="relative py-24 lg:py-32 px-5 sm:px-8 lg:px-12"
        >
            <div class="max-w-7xl mx-auto">
                <!-- Section Header -->
                <div class="text-center mb-16 lg:mb-20 animate-on-scroll">
                    <span
                        class="inline-block px-4 py-1.5 rounded-full bg-emerald-100/80 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 text-sm font-semibold mb-6 backdrop-blur-sm"
                    >
                        Features
                    </span>
                    <h2
                        class="text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 dark:text-white mb-6"
                    >
                        Everything You Need
                    </h2>
                    <p
                        class="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto leading-relaxed"
                    >
                        Powerful features to automate your customer service and
                        grow your business effortlessly
                    </p>
                </div>

                <!-- Features Grid -->
                <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8">
                    <div
                        v-for="(feature, index) in features"
                        :key="feature.title"
                        class="group animate-on-scroll"
                        :style="{ transitionDelay: `${index * 75}ms` }"
                    >
                        <div
                            class="relative h-full p-8 rounded-2xl bg-white/70 dark:bg-slate-900/70 backdrop-blur-sm border border-slate-200/80 dark:border-slate-800/80 hover:border-slate-300 dark:hover:border-slate-700 hover:shadow-xl hover:shadow-slate-200/50 dark:hover:shadow-slate-900/50 transition-all duration-500 group-hover:-translate-y-1"
                        >
                            <!-- Icon -->
                            <div
                                class="w-14 h-14 rounded-xl flex items-center justify-center text-2xl mb-6 transition-transform duration-300 group-hover:scale-110"
                                :class="getFeatureColorClasses(feature.color)"
                            >
                                {{ feature.icon }}
                            </div>

                            <!-- Content -->
                            <h3
                                class="text-xl font-bold text-slate-900 dark:text-white mb-3"
                            >
                                {{ feature.title }}
                            </h3>
                            <p
                                class="text-slate-600 dark:text-slate-400 leading-relaxed"
                            >
                                {{ feature.description }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Business Types Section -->
        <section
            id="solutions"
            class="relative py-24 lg:py-32 px-5 sm:px-8 lg:px-12"
        >
            <div class="max-w-7xl mx-auto">
                <!-- Section Header -->
                <div class="text-center mb-16 lg:mb-20 animate-on-scroll">
                    <span
                        class="inline-block px-4 py-1.5 rounded-full bg-cyan-100/80 dark:bg-cyan-900/30 text-cyan-700 dark:text-cyan-400 text-sm font-semibold mb-6 backdrop-blur-sm"
                    >
                        Solutions
                    </span>
                    <h2
                        class="text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 dark:text-white mb-6"
                    >
                        Built for Your Business
                    </h2>
                    <p
                        class="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto leading-relaxed"
                    >
                        Specialized solutions tailored for different business
                        types and industries
                    </p>
                </div>

                <!-- Business Type Cards -->
                <div class="grid lg:grid-cols-2 gap-8 max-w-5xl mx-auto">
                    <div
                        v-for="(business, index) in businessTypes"
                        :key="business.name"
                        class="group animate-on-scroll"
                        :style="{ transitionDelay: `${index * 100}ms` }"
                    >
                        <div
                            class="relative h-full p-8 lg:p-10 rounded-2xl bg-white/70 dark:bg-slate-900/70 backdrop-blur-sm border border-slate-200/80 dark:border-slate-800/80 hover:border-slate-300 dark:hover:border-slate-700 hover:shadow-2xl hover:shadow-slate-200/50 dark:hover:shadow-slate-900/50 transition-all duration-500 group-hover:-translate-y-1"
                        >
                            <!-- Icon & Title -->
                            <div class="flex items-start gap-5 mb-8">
                                <div
                                    class="w-16 h-16 rounded-2xl bg-slate-100/80 dark:bg-slate-800/80 flex items-center justify-center text-3xl flex-shrink-0"
                                >
                                    {{ business.icon }}
                                </div>
                                <div>
                                    <h3
                                        class="text-2xl font-bold text-slate-900 dark:text-white mb-2"
                                    >
                                        {{ business.name }}
                                    </h3>
                                    <p
                                        class="text-slate-600 dark:text-slate-400"
                                    >
                                        {{ business.description }}
                                    </p>
                                </div>
                            </div>

                            <!-- Features List -->
                            <ul class="space-y-4">
                                <li
                                    v-for="feat in business.features"
                                    :key="feat"
                                    class="flex items-center gap-3 text-slate-700 dark:text-slate-300"
                                >
                                    <div
                                        class="w-5 h-5 rounded-full bg-emerald-100 dark:bg-emerald-900/50 flex items-center justify-center flex-shrink-0"
                                    >
                                        <svg
                                            class="w-3 h-3 text-emerald-600 dark:text-emerald-400"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="3"
                                                d="M5 13l4 4L19 7"
                                            />
                                        </svg>
                                    </div>
                                    <span class="font-medium">{{ feat }}</span>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Stats Section -->
        <section
            id="stats"
            class="relative py-24 lg:py-32 px-5 sm:px-8 lg:px-12"
        >
            <div id="stats-section" class="max-w-5xl mx-auto animate-on-scroll">
                <div
                    class="relative p-10 lg:p-14 rounded-3xl bg-slate-900/95 dark:bg-slate-800/95 backdrop-blur-sm overflow-hidden"
                >
                    <!-- Background Pattern -->
                    <div
                        class="absolute inset-0 opacity-5"
                        style="
                            background-image: radial-gradient(
                                circle at 2px 2px,
                                white 1px,
                                transparent 0
                            );
                            background-size: 32px 32px;
                        "
                    ></div>

                    <!-- Gradient Accent -->
                    <div
                        class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-emerald-500 via-cyan-500 to-teal-500"
                    ></div>

                    <div
                        class="relative grid grid-cols-2 lg:grid-cols-4 gap-8 lg:gap-12"
                    >
                        <div
                            v-for="stat in stats"
                            :key="stat.label"
                            class="text-center"
                        >
                            <div class="text-3xl mb-4">{{ stat.icon }}</div>
                            <div
                                class="text-4xl sm:text-5xl font-bold text-white mb-2"
                            >
                                {{ stat.value.toLocaleString()
                                }}{{ stat.suffix }}
                            </div>
                            <div class="text-slate-400 font-medium">
                                {{ stat.label }}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- CTA Section -->
        <section class="relative py-24 lg:py-32 px-5 sm:px-8 lg:px-12">
            <div class="max-w-3xl mx-auto text-center animate-on-scroll">
                <h2
                    class="text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 dark:text-white mb-6"
                >
                    Ready to Transform<br class="hidden sm:block" />
                    Your Business?
                </h2>
                <p
                    class="text-lg text-slate-600 dark:text-slate-400 mb-12 max-w-xl mx-auto leading-relaxed"
                >
                    Join hundreds of businesses using Janji Chat to deliver
                    exceptional customer experiences around the clock.
                </p>
                <Link
                    :href="route('login')"
                    class="group inline-flex items-center gap-3 px-10 py-5 rounded-xl bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-bold text-lg shadow-lg shadow-slate-900/10 dark:shadow-white/10 hover:shadow-xl hover:shadow-slate-900/20 dark:hover:shadow-white/20 transform hover:-translate-y-0.5 active:translate-y-0 transition-all duration-300"
                >
                    <span>Start Now — It's Free</span>
                    <svg
                        class="w-5 h-5 group-hover:translate-x-1 transition-transform duration-300"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M17 8l4 4m0 0l-4 4m4-4H3"
                        />
                    </svg>
                </Link>
            </div>
        </section>

        <!-- Footer -->
        <LandingFooter :is-dark="isDark" @toggle-theme="toggleTheme" />

        <!-- AI Chat Widget -->
        <LandingChatWidget :is-dark="isDark" />
    </div>
</template>

<style scoped>
/* Scroll animation classes */
.animate-on-scroll {
    opacity: 0;
    transform: translateY(24px);
    transition: opacity 0.7s cubic-bezier(0.4, 0, 0.2, 1),
        transform 0.7s cubic-bezier(0.4, 0, 0.2, 1);
}

.animate-on-scroll.animate-in {
    opacity: 1;
    transform: translateY(0);
}
</style>
