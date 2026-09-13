<script setup lang="ts">
import {
    computed,
    ref,
} from 'vue';
import {
    RouterLink,
    useRoute,
    useRouter,
} from 'vue-router';

import { AuthApiError } from '@/services/auth';
import { useAuth } from '@/composables/useAuth';

const route = useRoute();
const router = useRouter();

const {
    login,
    isLoading,
} = useAuth();

const email = ref('');
const password = ref('');
const remember = ref(false);

const formError = ref<string | null>(null);
const emailError = ref<string | null>(null);
const passwordError = ref<string | null>(null);

const redirectPath = computed(() => {
    const redirect = route.query.redirect;

    if (
        typeof redirect === 'string' &&
        redirect.startsWith('/') &&
        !redirect.startsWith('//') &&
        redirect !== '/login' &&
        redirect !== '/register'
    ) {
        return redirect;
    }

    return '/focus';
});

function clearErrors(): void {
    formError.value = null;
    emailError.value = null;
    passwordError.value = null;
}

function validate(): boolean {
    clearErrors();

    let valid = true;

    if (!email.value.trim()) {
        emailError.value = 'Email is required.';
        valid = false;
    }

    if (!password.value) {
        passwordError.value = 'Password is required.';
        valid = false;
    }

    return valid;
}

function applyApiErrors(
    error: AuthApiError,
): void {
    emailError.value =
        error.errors.email?.[0] ?? null;

    passwordError.value =
        error.errors.password?.[0] ?? null;

    formError.value =
        emailError.value ||
        passwordError.value
            ? null
            : error.message;
}

async function submit(): Promise<void> {
    if (!validate()) {
        return;
    }

    formError.value = null;

    try {
        await login({
            email: email.value.trim(),
            password: password.value,
            remember: remember.value,
        });

        await router.replace(
            redirectPath.value,
        );
    } catch (caught) {
        if (caught instanceof AuthApiError) {
            applyApiErrors(caught);
            return;
        }

        formError.value =
            'Unable to log in right now. Please try again.';
    }
}
</script>

<template>
    <main
        class="min-h-screen bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100"
    >
        <div
            class="mx-auto flex min-h-screen max-w-md flex-col px-6 py-8 sm:px-8"
        >
            <header class="flex items-center justify-between">
                <RouterLink
                    to="/"
                    class="text-xl font-semibold tracking-tight"
                >
                    Focura
                </RouterLink>

                <RouterLink
                    to="/"
                    class="text-sm font-medium text-slate-500 dark:text-slate-400 transition hover:text-slate-900 dark:hover:text-slate-100"
                >
                    Back
                </RouterLink>
            </header>

            <section
                class="flex flex-1 flex-col justify-center py-16"
            >
                <div>
                    <p
                        class="text-sm font-medium text-blue-600"
                    >
                        Welcome back
                    </p>

                    <h1
                        class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-50"
                    >
                        Log in to Focura
                    </h1>

                    <p
                        class="mt-3 text-sm leading-6 text-slate-500 dark:text-slate-400"
                    >
                        Continue your focus history and insights.
                    </p>
                </div>

                <form
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
                            for="login-email"
                            class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            Email
                        </label>

                        <input
                            id="login-email"
                            v-model="email"
                            type="email"
                            autocomplete="email"
                            inputmode="email"
                            class="mt-2 block w-full rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-950 px-3.5 py-2.5 text-sm text-slate-900 dark:text-slate-100 outline-none transition placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                            placeholder="you@example.com"
                            :aria-invalid="emailError ? 'true' : 'false'"
                            :aria-describedby="
                                emailError
                                    ? 'login-email-error'
                                    : undefined
                            "
                        />

                        <p
                            v-if="emailError"
                            id="login-email-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ emailError }}
                        </p>
                    </div>

                    <div>
                        <label
                            for="login-password"
                            class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            Password
                        </label>

                        <input
                            id="login-password"
                            v-model="password"
                            type="password"
                            autocomplete="current-password"
                            class="mt-2 block w-full rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-950 px-3.5 py-2.5 text-sm text-slate-900 dark:text-slate-100 outline-none transition placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                            placeholder="Enter your password"
                            :aria-invalid="passwordError ? 'true' : 'false'"
                            :aria-describedby="
                                passwordError
                                    ? 'login-password-error'
                                    : undefined
                            "
                        />

                        <p
                            v-if="passwordError"
                            id="login-password-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ passwordError }}
                        </p>
                    </div>

                    <label
                        class="flex cursor-pointer items-center gap-2.5 text-sm text-slate-600 dark:text-slate-400"
                    >
                        <input
                            v-model="remember"
                            type="checkbox"
                            class="h-4 w-4 rounded border-slate-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500"
                        />

                        Remember me
                    </label>

                    <button
                        type="submit"
                        :disabled="isLoading"
                        class="flex w-full items-center justify-center rounded-xl bg-blue-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        {{
                            isLoading
                                ? 'Logging in...'
                                : 'Log in'
                        }}
                    </button>
                </form>

                <p
                    class="mt-7 text-center text-sm text-slate-500 dark:text-slate-400"
                >
                    Don't have an account?
                    <RouterLink
                        :to="{
                            name: 'register',
                            query: route.query.redirect
                                ? {
                                      redirect:
                                          route.query.redirect,
                                  }
                                : undefined,
                        }"
                        class="font-medium text-blue-600 transition hover:text-blue-700"
                    >
                        Create account
                    </RouterLink>
                </p>

                <p
                    class="mt-4 text-center text-xs leading-5 text-slate-400 dark:text-slate-500"
                >
                    You can continue using Focura without an account.
                </p>
            </section>
        </div>
    </main>
</template>
