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
    register,
    isLoading,
} = useAuth();

const name = ref('');
const email = ref('');
const password = ref('');
const passwordConfirmation = ref('');

const showPassword = ref(false);
const showPasswordConfirmation = ref(false);

const formError = ref<string | null>(null);
const nameError = ref<string | null>(null);
const emailError = ref<string | null>(null);
const passwordError = ref<string | null>(null);
const passwordConfirmationError =
    ref<string | null>(null);

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
    nameError.value = null;
    emailError.value = null;
    passwordError.value = null;
    passwordConfirmationError.value = null;
}

function validate(): boolean {
    clearErrors();

    let valid = true;

    if (!name.value.trim()) {
        nameError.value = 'Name is required.';
        valid = false;
    }

    if (!email.value.trim()) {
        emailError.value = 'Email is required.';
        valid = false;
    }

    if (!password.value) {
        passwordError.value = 'Password is required.';
        valid = false;
    }

    if (!passwordConfirmation.value) {
        passwordConfirmationError.value =
            'Please confirm your password.';
        valid = false;
    }

    if (
        password.value &&
        passwordConfirmation.value &&
        password.value !== passwordConfirmation.value
    ) {
        passwordConfirmationError.value =
            'Passwords do not match.';
        valid = false;
    }

    return valid;
}

function applyApiErrors(
    error: AuthApiError,
): void {
    nameError.value =
        error.errors.name?.[0] ?? null;

    emailError.value =
        error.errors.email?.[0] ?? null;

    passwordError.value =
        error.errors.password?.[0] ?? null;

    passwordConfirmationError.value =
        error.errors.password_confirmation?.[0] ??
        null;

    formError.value =
        nameError.value ||
        emailError.value ||
        passwordError.value ||
        passwordConfirmationError.value
            ? null
            : error.message;
}

async function submit(): Promise<void> {
    if (!validate()) {
        return;
    }

    formError.value = null;

    try {
        await register({
            name: name.value.trim(),
            email: email.value.trim(),
            password: password.value,
            password_confirmation:
                passwordConfirmation.value,
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
            'Unable to create your account right now. Please try again.';
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
                class="flex flex-1 flex-col justify-center py-12"
            >
                <div>
                    <p
                        class="text-sm font-medium text-blue-600"
                    >
                        Start with intention
                    </p>

                    <h1
                        class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-50"
                    >
                        Create your account
                    </h1>

                    <p
                        class="mt-3 text-sm leading-6 text-slate-500 dark:text-slate-400"
                    >
                        Keep your focus history and insights across sessions.
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
                            for="register-name"
                            class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            Name
                        </label>

                        <input
                            id="register-name"
                            v-model="name"
                            type="text"
                            autocomplete="name"
                            class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-600 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
                            placeholder="Your name"
                            :aria-invalid="
                                nameError
                                    ? 'true'
                                    : 'false'
                            "
                            :aria-describedby="
                                nameError
                                    ? 'register-name-error'
                                    : undefined
                            "
                        />

                        <p
                            v-if="nameError"
                            id="register-name-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ nameError }}
                        </p>
                    </div>

                    <div>
                        <label
                            for="register-email"
                            class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            Email
                        </label>

                        <input
                            id="register-email"
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
                                    ? 'register-email-error'
                                    : undefined
                            "
                        />

                        <p
                            v-if="emailError"
                            id="register-email-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ emailError }}
                        </p>
                    </div>

                    <div>
                        <label
                            for="register-password"
                            class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            Password
                        </label>

                        <div class="relative mt-2">
                            <input
                                id="register-password"
                                v-model="password"
                                :type="
                                    showPassword
                                        ? 'text'
                                        : 'password'
                                "
                                autocomplete="new-password"
                                class="block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 pr-11 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-600 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
                                placeholder="At least 8 characters"
                                :aria-invalid="
                                    passwordError
                                        ? 'true'
                                        : 'false'
                                "
                                :aria-describedby="
                                    passwordError
                                        ? 'register-password-error'
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
                            id="register-password-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ passwordError }}
                        </p>
                    </div>

                    <div>
                        <label
                            for="register-password-confirmation"
                            class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            Confirm password
                        </label>

                        <div class="relative mt-2">
                            <input
                                id="register-password-confirmation"
                                v-model="passwordConfirmation"
                                :type="
                                    showPasswordConfirmation
                                        ? 'text'
                                        : 'password'
                                "
                                autocomplete="new-password"
                                class="block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 pr-11 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-600 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
                                placeholder="Repeat your password"
                                :aria-invalid="
                                    passwordConfirmationError
                                        ? 'true'
                                        : 'false'
                                "
                                :aria-describedby="
                                    passwordConfirmationError
                                        ? 'register-password-confirmation-error'
                                        : undefined
                                "
                            />

                            <button
                                type="button"
                                class="absolute inset-y-0 right-0 flex w-11 items-center justify-center text-slate-400 transition hover:text-slate-600 focus:outline-none focus-visible:text-blue-600 dark:text-slate-500 dark:hover:text-slate-300 dark:focus-visible:text-blue-400"
                                :aria-label="
                                    showPasswordConfirmation
                                        ? 'Hide password confirmation'
                                        : 'Show password confirmation'
                                "
                                :aria-pressed="
                                    showPasswordConfirmation
                                "
                                @click="
                                    showPasswordConfirmation =
                                        !showPasswordConfirmation
                                "
                            >
                                <svg
                                    v-if="!showPasswordConfirmation"
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
                            v-if="passwordConfirmationError"
                            id="register-password-confirmation-error"
                            class="mt-1.5 text-sm text-red-600"
                        >
                            {{ passwordConfirmationError }}
                        </p>
                    </div>

                    <button
                        type="submit"
                        :disabled="isLoading"
                        class="flex w-full items-center justify-center rounded-xl bg-blue-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        {{
                            isLoading
                                ? 'Creating account...'
                                : 'Create account'
                        }}
                    </button>
                </form>

                <p
                    class="mt-7 text-center text-sm text-slate-500 dark:text-slate-400"
                >
                    Already have an account?

                    <RouterLink
                        :to="{
                            name: 'login',
                            query: route.query.redirect
                                ? {
                                      redirect:
                                          route.query.redirect,
                                  }
                                : undefined,
                        }"
                        class="font-medium text-blue-600 transition hover:text-blue-700"
                    >
                        Log in
                    </RouterLink>
                </p>

                <p
                    class="mt-4 text-center text-xs leading-5 text-slate-400 dark:text-slate-500"
                >
                    No account is required to start focusing.
                </p>
            </section>
        </div>
    </main>
</template>