<script setup>
import GuestLayout from "@/Layouts/GuestLayout.vue";
import { Head, useForm, router } from "@inertiajs/vue3";
import { ref, onMounted, onUnmounted, computed } from "vue";

const props = defineProps({
    email: {
        type: String,
        required: true,
    },
});

const form = useForm({
    email: props.email,
    code: "",
});

const digits = ref(["", "", "", "", "", ""]);
const inputRefs = ref([]);
const timeLeft = ref(600); // 10 minutes in seconds
let timerInterval = null;

const formattedTime = computed(() => {
    const minutes = Math.floor(timeLeft.value / 60);
    const seconds = timeLeft.value % 60;
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
});

const isExpired = computed(() => timeLeft.value <= 0);

const handleInput = (index, event) => {
    const value = event.target.value;

    // Only allow digits
    if (!/^\d*$/.test(value)) {
        digits.value[index] = "";
        return;
    }

    digits.value[index] = value.slice(-1);

    // Auto-focus next input
    if (value && index < 5) {
        inputRefs.value[index + 1]?.focus();
    }

    // Update form code
    form.code = digits.value.join("");

    // Auto-submit when all digits filled
    if (digits.value.every((d) => d !== "")) {
        submit();
    }
};

const handleKeydown = (index, event) => {
    if (event.key === "Backspace" && !digits.value[index] && index > 0) {
        inputRefs.value[index - 1]?.focus();
    }
};

const handlePaste = (event) => {
    event.preventDefault();
    const paste = event.clipboardData
        .getData("text")
        .replace(/\D/g, "")
        .slice(0, 6);

    for (let i = 0; i < 6; i++) {
        digits.value[i] = paste[i] || "";
    }

    form.code = digits.value.join("");

    if (paste.length === 6) {
        submit();
    }
};

const submit = () => {
    if (form.code.length !== 6 || form.processing) return;

    form.post(route("verify.code"), {
        preserveScroll: true,
    });
};

const resendCode = () => {
    router.post(
        route("verify.code.resend"),
        { email: props.email },
        {
            preserveScroll: true,
            onSuccess: () => {
                timeLeft.value = 600;
                digits.value = ["", "", "", "", "", ""];
                form.code = "";
            },
        }
    );
};

onMounted(() => {
    timerInterval = setInterval(() => {
        if (timeLeft.value > 0) {
            timeLeft.value--;
        }
    }, 1000);

    inputRefs.value[0]?.focus();
});

onUnmounted(() => {
    if (timerInterval) {
        clearInterval(timerInterval);
    }
});
</script>

<template>
    <GuestLayout>
        <Head title="Verify Email" />

        <div class="text-center mb-6">
            <div
                class="w-16 h-16 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-2xl flex items-center justify-center mx-auto mb-4"
            >
                <svg
                    class="w-8 h-8 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                    />
                </svg>
            </div>
            <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                Check your email
            </h2>
            <p class="text-gray-600 dark:text-white/60">
                We've sent a 6-digit code to<br />
                <span
                    class="text-primary-600 dark:text-primary-400 font-medium"
                    >{{ email }}</span
                >
            </p>
        </div>

        <form @submit.prevent="submit" class="space-y-6">
            <!-- 6-digit code input -->
            <div class="flex justify-center gap-3" @paste="handlePaste">
                <input
                    v-for="(digit, index) in digits"
                    :key="index"
                    :ref="(el) => (inputRefs[index] = el)"
                    type="text"
                    inputmode="numeric"
                    maxlength="1"
                    :value="digit"
                    @input="handleInput(index, $event)"
                    @keydown="handleKeydown(index, $event)"
                    class="w-12 h-14 text-center text-2xl font-bold bg-gray-50 border border-gray-200 rounded-xl text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all dark:bg-white/10 dark:border-white/20 dark:text-white"
                    :class="{ 'border-red-500': form.errors.code }"
                    :disabled="form.processing || isExpired"
                />
            </div>

            <p v-if="form.errors.code" class="text-center text-sm text-red-400">
                {{ form.errors.code }}
            </p>

            <!-- Timer -->
            <div class="text-center">
                <div
                    v-if="!isExpired"
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gray-100 dark:bg-white/10"
                >
                    <svg
                        class="w-4 h-4 text-gray-500 dark:text-white/60"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                    </svg>
                    <span class="text-sm text-gray-600 dark:text-white/60"
                        >Code expires in</span
                    >
                    <span
                        class="text-sm font-semibold"
                        :class="
                            timeLeft <= 60 ? 'text-red-400' : 'text-primary-400'
                        "
                    >
                        {{ formattedTime }}
                    </span>
                </div>
                <div v-else class="text-red-400 text-sm">
                    ⚠️ Code has expired
                </div>
            </div>

            <button
                type="submit"
                :disabled="
                    form.processing || form.code.length !== 6 || isExpired
                "
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
                    Verifying...
                </span>
                <span v-else>Verify & Sign In</span>
            </button>
        </form>

        <div class="mt-6 text-center">
            <p class="text-gray-600 dark:text-white/60 text-sm">
                Didn't receive the code?
                <button
                    @click="resendCode"
                    class="text-primary-400 hover:text-primary-300 font-medium transition-colors"
                    :disabled="form.processing"
                >
                    Resend
                </button>
            </p>
        </div>

        <!-- Success message -->
        <div
            v-if="$page.props.flash?.success"
            class="mt-4 p-3 rounded-xl bg-green-500/20 border border-green-500/30 text-green-400 text-sm text-center"
        >
            {{ $page.props.flash.success }}
        </div>
    </GuestLayout>
</template>
