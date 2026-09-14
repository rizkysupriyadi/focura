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
const resetSuccess = computed(
    () => route.query.reset === 'success',
);

const showPassword = ref(false);

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

                <div
                    v-if="resetSuccess"
                    class="rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm leading-6 text-green-700"
                    role="status"
                >
                    Your password has been reset successfully. You can now log in.
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
                            class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-600 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
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

                        <div class="relative mt-2">
                            <input
                                id="login-password"
                                v-model="password"
                                :type="
                                    showPassword
                                        ? 'text'
                                        : 'password'
                                "
                                autocomplete="current-password"
                                class="block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 pr-11 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-600 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
                                placeholder="Enter your password"
                                :aria-invalid="
                                    passwordError
                                        ? 'true'
                                        : 'false'
                                "
                                :aria-describedby="
                                    passwordError
                                        ? 'login-password-error'
                                        : undefined
                                "
                            />

                            <button
                                type="button"
                                class="absolute inset-y-0 right-0 flex w-11 items-center justify-center text-slate-400 transition hover:text-slate-600 focus:outline-none focus-visible:text-blue-600 dark:text-slate-500 dark:hover:text-slate-300 dark:focus-visible:text-blue-400"
                                :aria-label="
                                    showPassword
                                        ? 'Hide password'
                                        : 'Show password'
                                "
                                :aria-pressed="showPassword"
                                @click="
                                    showPassword =
                                        !showPassword
                                "
                            >
                                <svg
                                    v-if="!showPassword"
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="1.8"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    class="h-5 w-5"
                                    aria-hidden="true"
                                >
                                    <path
                                        d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6Z"
                                    />
                                    <circle
                                        cx="12"
                                        cy="12"
                                        r="2.5"
                                    />
                                </svg>

                                <svg
                                    v-else
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="1.8"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    class="h-5 w-5"
                                    aria-hidden="true"
                                >
                                    <path
                                        d="M3 3l18 18"
                                    />
                                    <path
                                        d="M10.6 5.1A10.8 10.8 0 0 1 12 5c6 0 9.5 7 9.5 7a16.5 16.5 0 0 1-3.2 3.9"
                                    />
                                    <path
                                        d="M6.7 6.7C3.8 8.4 2.5 12 2.5 12a16.8 16.8 0 0 0 5.3 5.2A9.6 9.6 0 0 0 12 19c1 0 1.9-.2 2.7-.5"
                                    />
                                    <path
                                        d="M9.9 9.9a3 3 0 0 0 4.2 4.2"
                                    />
                                </svg>
                            </button>
                        </div>

                        <p
                            v-if="passwordError"
                            id="login-password-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ passwordError }}
                        </p>
                    </div>

                    <div class="flex justify-end">
    <RouterLink
        :to="{ name: 'forgot-password' }"
        class="text-sm font-medium text-blue-600 transition hover:text-blue-700"
    >
        Forgot password?
    </RouterLink>
</div>

                    <label
                        class="flex cursor-pointer items-center gap-2.5 text-sm text-slate-600 dark:text-slate-400"
                    >
                        <input
                            v-model="remember"
                            type="checkbox"
                            class="h-4 w-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500 dark:border-slate-600"
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