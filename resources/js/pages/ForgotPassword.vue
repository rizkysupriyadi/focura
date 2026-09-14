<script setup lang="ts">
import { ref } from 'vue';
import {
    RouterLink,
    useRouter,
} from 'vue-router';

import {
    AuthApiError,
    forgotPassword,
} from '@/services/auth';

const router = useRouter();

const email = ref('');

const isLoading = ref(false);
const formError = ref<string | null>(null);
const emailError = ref<string | null>(null);
const successMessage = ref<string | null>(null);

function clearErrors(): void {
    formError.value = null;
    emailError.value = null;
}

function validate(): boolean {
    clearErrors();

    if (!email.value.trim()) {
        emailError.value = 'Email is required.';
        return false;
    }

    return true;
}

function applyApiErrors(
    error: AuthApiError,
): void {
    emailError.value =
        error.errors.email?.[0] ?? null;

    formError.value =
        emailError.value
            ? null
            : error.message;
}

async function submit(): Promise<void> {
    if (!validate()) {
        return;
    }

    isLoading.value = true;
    successMessage.value = null;

    try {
        const response = await forgotPassword({
            email: email.value.trim(),
        });

        successMessage.value = response.message;
    } catch (caught) {
        if (caught instanceof AuthApiError) {
            applyApiErrors(caught);
        } else {
            formError.value =
                'Unable to send the reset email right now. Please try again.';
        }
    } finally {
        isLoading.value = false;
    }
}

function goToLogin(): void {
    void router.push({
        name: 'login',
    });
}
</script>

<template>
    <main
        class="min-h-screen bg-white text-slate-900 dark:bg-slate-950 dark:text-slate-100"
    >
        <div
            class="mx-auto flex min-h-screen max-w-md flex-col px-6 py-8 sm:px-8"
        >
            <section
                class="flex flex-1 flex-col justify-center py-16"
            >
                <div>
                    <p
                        class="text-sm font-medium text-blue-600"
                    >
                        Account recovery
                    </p>

                    <h1
                        class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-50"
                    >
                        Forgot your password?
                    </h1>

                    <p
                        class="mt-3 text-sm leading-6 text-slate-500 dark:text-slate-400"
                    >
                        Enter your email and we’ll send you a secure password reset link.
                    </p>
                </div>

                <div
                    v-if="successMessage"
                    class="mt-8 rounded-lg border border-green-200 bg-green-50 px-4 py-4 text-sm leading-6 text-green-700"
                    role="status"
                >
                    {{ successMessage }}
                </div>

                <form
                    v-else
                    class="mt-8 space-y-5"
                    novalidate
                    @submit.prevent="submit"
                >
                    <div
                        v-if="formError"
                        class="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm leading-6 text-red-700"
                        role="alert"
                    >
                        {{ formError }}
                    </div>

                    <div>
                        <label
                            for="forgot-password-email"
                            class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            Email
                        </label>

                        <input
                            id="forgot-password-email"
                            v-model="email"
                            type="email"
                            autocomplete="email"
                            inputmode="email"
                            class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-600 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
                            placeholder="you@example.com"
                            :aria-invalid="
                                emailError
                                    ? 'true'
                                    : 'false'
                            "
                            :aria-describedby="
                                emailError
                                    ? 'forgot-password-email-error'
                                    : undefined
                            "
                        />

                        <p
                            v-if="emailError"
                            id="forgot-password-email-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ emailError }}
                        </p>
                    </div>

                    <button
                        type="submit"
                        :disabled="isLoading"
                        class="flex w-full items-center justify-center rounded-xl bg-blue-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        {{
                            isLoading
                                ? 'Sending...'
                                : 'Send reset link'
                        }}
                    </button>
                </form>

                <div
                    v-if="successMessage"
                    class="mt-6"
                >
                    <button
                        type="button"
                        class="flex w-full items-center justify-center rounded-xl border border-slate-300 px-6 py-3 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-900"
                        @click="goToLogin"
                    >
                        Back to login
                    </button>
                </div>

                <p
                    v-else
                    class="mt-7 text-center text-sm text-slate-500 dark:text-slate-400"
                >
                    Remember your password?

                    <RouterLink
                        :to="{ name: 'login' }"
                        class="font-medium text-blue-600 transition hover:text-blue-700"
                    >
                        Log in
                    </RouterLink>
                </p>
            </section>
        </div>
    </main>
</template>