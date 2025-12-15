<script setup>
import GuestLayout from "@/Layouts/GuestLayout.vue";
import { Head, Link, useForm } from "@inertiajs/vue3";

const props = defineProps({
    businessTypes: {
        type: Array,
        default: () => [{ value: "restaurant", label: "Restaurant Booking" }],
    },
});

const form = useForm({
    name: "",
    email: "",
    password: "",
    password_confirmation: "",
    business_type: "restaurant",
});

const submit = () => {
    form.post(route("register"), {
        onFinish: () => form.reset("password", "password_confirmation"),
    });
};
</script>

<template>
    <GuestLayout>
        <Head title="Register" />

        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
            Create an account
        </h2>
        <p class="text-gray-600 dark:text-white/60 mb-6">
            Start managing your business with AI
        </p>

        <form @submit.prevent="submit" class="space-y-5">
            <div>
                <label
                    for="name"
                    class="block text-sm font-medium text-gray-700 dark:text-white/80 mb-2"
                >
                    Your Name
                </label>
                <input
                    id="name"
                    type="text"
                    v-model="form.name"
                    class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all dark:bg-white/10 dark:border-white/20 dark:text-white dark:placeholder-white/40"
                    placeholder="John Doe"
                    required
                    autofocus
                    autocomplete="name"
                />
                <p v-if="form.errors.name" class="mt-2 text-sm text-red-400">
                    {{ form.errors.name }}
                </p>
            </div>

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
                    autocomplete="username"
                />
                <p v-if="form.errors.email" class="mt-2 text-sm text-red-400">
                    {{ form.errors.email }}
                </p>
            </div>

            <div>
                <label
                    for="business_type"
                    class="block text-sm font-medium text-gray-700 dark:text-white/80 mb-2"
                >
                    Business Type
                </label>
                <select
                    id="business_type"
                    v-model="form.business_type"
                    class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all dark:bg-white/10 dark:border-white/20 dark:text-white"
                    required
                >
                    <option
                        v-for="type in businessTypes"
                        :key="type.value"
                        :value="type.value"
                        class="dark:bg-slate-800"
                    >
                        {{ type.label }}
                    </option>
                </select>
                <p
                    v-if="form.errors.business_type"
                    class="mt-2 text-sm text-red-400"
                >
                    {{ form.errors.business_type }}
                </p>
            </div>

            <div>
                <label
                    for="password"
                    class="block text-sm font-medium text-gray-700 dark:text-white/80 mb-2"
                >
                    Password
                </label>
                <input
                    id="password"
                    type="password"
                    v-model="form.password"
                    class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all dark:bg-white/10 dark:border-white/20 dark:text-white dark:placeholder-white/40"
                    placeholder="••••••••"
                    required
                    autocomplete="new-password"
                />
                <p
                    v-if="form.errors.password"
                    class="mt-2 text-sm text-red-400"
                >
                    {{ form.errors.password }}
                </p>
            </div>

            <div>
                <label
                    for="password_confirmation"
                    class="block text-sm font-medium text-gray-700 dark:text-white/80 mb-2"
                >
                    Confirm Password
                </label>
                <input
                    id="password_confirmation"
                    type="password"
                    v-model="form.password_confirmation"
                    class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all dark:bg-white/10 dark:border-white/20 dark:text-white dark:placeholder-white/40"
                    placeholder="••••••••"
                    required
                    autocomplete="new-password"
                />
                <p
                    v-if="form.errors.password_confirmation"
                    class="mt-2 text-sm text-red-400"
                >
                    {{ form.errors.password_confirmation }}
                </p>
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
                    Creating account...
                </span>
                <span v-else>Create Account</span>
            </button>
        </form>

        <div class="mt-6 text-center">
            <p class="text-gray-600 dark:text-white/60 text-sm">
                Already have an account?
                <Link
                    :href="route('login')"
                    class="text-primary-400 hover:text-primary-300 font-medium transition-colors"
                >
                    Sign in
                </Link>
            </p>
        </div>
    </GuestLayout>
</template>
