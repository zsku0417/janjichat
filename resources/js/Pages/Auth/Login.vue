<script setup>
import GuestLayout from "@/Layouts/GuestLayout.vue";
import { Head, Link, useForm } from "@inertiajs/vue3";
import { ref } from "vue";
defineProps({
    canResetPassword: {
        type: Boolean,
    },
    status: {
        type: String,
    },
});

const showPassword = ref(false);

const form = useForm({
    email: "",
    password: "",
    remember: false,
});

const demoAccounts = [
    {
        label: "👤 Admin",
        email: "admin@example.com",
        password: "password",
    },
    {
        label: "🍽️ Restaurant",
        email: "restaurant@example.com",
        password: "password",
    },
    {
        label: "🏦 E-commerce",
        email: "shop@example.com",
        password: "password",
    },
];

const quickLogin = (account) => {
    form.email = account.email;
    form.password = account.password;
};

const submit = () => {
    form.post(route("login"), {
        onFinish: () => form.reset("password"),
    });
};
</script>

<template>
    <GuestLayout>
        <Head title="Log in" />

        <div v-if="status" class="mb-4 text-sm font-medium text-green-400">
            {{ status }}
        </div>

        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
            Welcome back
        </h2>
        <p class="text-gray-600 dark:text-white/60 mb-6">
            Sign in to your account
        </p>

        <form @submit.prevent="submit" class="space-y-5">
            <div>
                <label
                    for="email"
                    class="block text-sm font-medium text-gray-700 dark:text-white/80 mb-2"
                >
                    Email
                </label>
                <input
                    id="email"
                    type="email"
                    v-model="form.email"
                    class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all dark:bg-white/10 dark:border-white/20 dark:text-white dark:placeholder-white/40"
                    placeholder="you@example.com"
                    required
                    autofocus
                    autocomplete="username"
                />
                <p v-if="form.errors.email" class="mt-2 text-sm text-red-400">
                    {{ form.errors.email }}
                </p>
            </div>

            <div>
                <label
                    for="password"
                    class="block text-sm font-medium text-gray-700 dark:text-white/80 mb-2"
                >
                    Password
                </label>
                <div class="relative">
                    <input
                        id="password"
                        :type="showPassword ? 'text' : 'password'"
                        v-model="form.password"
                        class="w-full px-4 py-3 pr-12 bg-gray-50 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all dark:bg-white/10 dark:border-white/20 dark:text-white dark:placeholder-white/40"
                        placeholder="••••••••"
                        required
                        autocomplete="current-password"
                    />
                    <button
                        type="button"
                        @click="showPassword = !showPassword"
                        class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                    >
                        <svg
                            v-if="!showPassword"
                            class="h-5 w-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                            />
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                            />
                        </svg>
                        <svg
                            v-else
                            class="h-5 w-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"
                            />
                        </svg>
                    </button>
                </div>
                <p
                    v-if="form.errors.password"
                    class="mt-2 text-sm text-red-400"
                >
                    {{ form.errors.password }}
                </p>
            </div>

            <div class="flex items-center justify-between">
                <label class="flex items-center">
                    <input
                        type="checkbox"
                        v-model="form.remember"
                        class="w-4 h-4 rounded border-gray-300 bg-white text-primary-500 focus:ring-primary-500 focus:ring-offset-0 dark:border-white/20 dark:bg-white/10"
                    />
                    <span class="ml-2 text-sm text-gray-600 dark:text-white/60"
                        >Remember me</span
                    >
                </label>

                <Link
                    v-if="canResetPassword"
                    :href="route('password.request')"
                    class="text-sm text-primary-400 hover:text-primary-300 transition-colors"
                >
                    Forgot password?
                </Link>
            </div>

            <button
                type="submit"
                :disabled="form.processing"
                class="w-full py-3 px-4 bg-gradient-to-r from-primary-500 to-secondary-500 text-white font-semibold rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-xl hover:shadow-primary-500/40 transform hover:-translate-y-0.5 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
                <span
                    v-if="form.processing"
                    class="flex items-center justify-center gap-2"
                >
                    <svg
                        class="animate-spin h-5 w-5"
                        xmlns="http://www.w3.org/2000/svg"
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
                    Signing in...
                </span>
                <span v-else>Sign in</span>
            </button>
        </form>

        <!-- Quick Login for Demo -->
        <div class="mt-6 pt-6 border-t border-gray-200 dark:border-white/10">
            <p
                class="text-gray-500 dark:text-white/40 text-xs text-center mb-3"
            >
                Quick login (Demo accounts)
            </p>
            <div class="flex gap-2">
                <button
                    v-for="account in demoAccounts"
                    :key="account.email"
                    type="button"
                    @click="quickLogin(account)"
                    class="flex-1 py-2 px-3 text-xs font-medium rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 hover:text-gray-900 transition-all dark:border-white/20 dark:text-white/70 dark:hover:bg-white/10 dark:hover:text-white"
                >
                    {{ account.label }}
                </button>
            </div>
        </div>
    </GuestLayout>
</template>
