import {
    computed,
    ref,
} from 'vue';

import {
    AuthApiError,
    getCurrentUser,
    login as loginApi,
    logout as logoutApi,
    register as registerApi,
} from '@/services/auth';
import { claimGuestSessions } from '@/services/focusSessions';
import type {
    AuthUser,
    LoginPayload,
    RegisterPayload,
} from '@/types/auth';

const user = ref<AuthUser | null>(null);
const isInitialized = ref(false);
const isLoading = ref(false);
const error = ref<string | null>(null);

let initializationPromise: Promise<void> | null = null;
let loginPromise: Promise<void> | null = null;
let registerPromise: Promise<void> | null = null;
let logoutPromise: Promise<void> | null = null;

function getErrorMessage(
    caught: unknown,
    fallback: string,
): string {
    if (caught instanceof AuthApiError) {
        return caught.message;
    }

    if (caught instanceof Error) {
        return caught.message;
    }

    return fallback;
}

export function useAuth() {
    const initializeAuth = async (): Promise<void> => {
        if (isInitialized.value) {
            return;
        }

        if (initializationPromise) {
            return initializationPromise;
        }

        initializationPromise = (async () => {
            isLoading.value = true;
            error.value = null;

            try {
                user.value = await getCurrentUser();
            } catch (caught) {
                error.value = getErrorMessage(
                    caught,
                    'Unable to initialize authentication.',
                );

                user.value = null;
            } finally {
                isLoading.value = false;
                isInitialized.value = true;
                initializationPromise = null;
            }
        })();

        return initializationPromise;
    };

    const login = async (
        payload: LoginPayload,
    ): Promise<void> => {
        if (loginPromise) {
            return loginPromise;
        }

        loginPromise = (async () => {
            isLoading.value = true;
            error.value = null;

            try {
                user.value = await loginApi(payload);

                try {
                    await claimGuestSessions();
                } catch {
                    // Authentication succeeded. Claiming guest
                    // sessions must not invalidate the login.
                }
            } catch (caught) {
                error.value = getErrorMessage(
                    caught,
                    'Unable to log in.',
                );

                throw caught;
            } finally {
                isLoading.value = false;
                loginPromise = null;
            }
        })();

        return loginPromise;
    };

    const register = async (
        payload: RegisterPayload,
    ): Promise<void> => {
        if (registerPromise) {
            return registerPromise;
        }

        registerPromise = (async () => {
            isLoading.value = true;
            error.value = null;

            try {
                user.value = await registerApi(payload);

                try {
                    await claimGuestSessions();
                } catch {
                    // Registration succeeded. Claiming guest
                    // sessions must not invalidate the account.
                }
            } catch (caught) {
                error.value = getErrorMessage(
                    caught,
                    'Unable to create your account.',
                );

                throw caught;
            } finally {
                isLoading.value = false;
                registerPromise = null;
            }
        })();

        return registerPromise;
    };

    const logout = async (): Promise<void> => {
        if (logoutPromise) {
            return logoutPromise;
        }

        logoutPromise = (async () => {
            isLoading.value = true;
            error.value = null;

            try {
                await logoutApi();
                user.value = null;
            } catch (caught) {
                error.value = getErrorMessage(
                    caught,
                    'Unable to log out.',
                );

                throw caught;
            } finally {
                isLoading.value = false;
                logoutPromise = null;
            }
        })();

        return logoutPromise;
    };

    const isAuthenticated = computed(
        () => user.value !== null,
    );

    return {
        user,
        isInitialized,
        isLoading,
        error,
        isAuthenticated,
        initializeAuth,
        login,
        register,
        logout,
    };
}
