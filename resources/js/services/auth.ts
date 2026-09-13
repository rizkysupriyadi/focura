import { getCsrfHeaders } from '@/lib/csrf';

import type {
    AuthResponse,
    AuthUser,
    LoginPayload,
    LogoutResponse,
    RegisterPayload,
} from '@/types/auth';

const API_BASE_URL = '/api/v1';

export interface AuthValidationErrors {
    [field: string]: string[];
}

export class AuthApiError extends Error {
    readonly status: number;
    readonly errors: AuthValidationErrors;

    constructor(
        message: string,
        status: number,
        errors: AuthValidationErrors = {},
    ) {
        super(message);

        this.name = 'AuthApiError';
        this.status = status;
        this.errors = errors;
    }
}

interface ApiErrorPayload {
    message?: string;
    errors?: AuthValidationErrors;
}

async function request<T>(
    path: string,
    options: RequestInit = {},
): Promise<T> {
    const method = (
        options.method ?? 'GET'
    ).toUpperCase();

    const csrfHeaders =
        method !== 'GET' &&
        method !== 'HEAD' &&
        method !== 'OPTIONS'
            ? getCsrfHeaders()
            : {};

    const response = await fetch(
        `${API_BASE_URL}${path}`,
        {
            ...options,
            credentials: 'same-origin',
            headers: {
                Accept: 'application/json',
                'Content-Type': 'application/json',
                ...csrfHeaders,
                ...options.headers,
            },
        },
    );

    let payload: unknown = null;

    try {
        payload = await response.json();
    } catch {
        payload = null;
    }

    if (!response.ok) {
        const errorPayload =
            isApiErrorPayload(payload)
                ? payload
                : {};

        throw new AuthApiError(
            errorPayload.message ??
                'The authentication request could not be completed.',
            response.status,
            errorPayload.errors ?? {},
        );
    }

    return payload as T;
}

function isApiErrorPayload(
    value: unknown,
): value is ApiErrorPayload {
    if (
        typeof value !== 'object' ||
        value === null
    ) {
        return false;
    }

    const record =
        value as Record<string, unknown>;

    return (
        typeof record.message === 'string' ||
        (
            typeof record.errors === 'object' &&
            record.errors !== null
        )
    );
}

export async function getCurrentUser(): Promise<AuthUser | null> {
    try {
        const response =
            await request<AuthResponse>(
                '/auth/me',
                {
                    method: 'GET',
                },
            );

        return response.data;
    } catch (caught) {
        if (
            caught instanceof AuthApiError &&
            caught.status === 401
        ) {
            return null;
        }

        throw caught;
    }
}

export async function login(
    payload: LoginPayload,
): Promise<AuthUser> {
    const response =
        await request<AuthResponse>(
            '/auth/login',
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return response.data;
}

export async function register(
    payload: RegisterPayload,
): Promise<AuthUser> {
    const response =
        await request<AuthResponse>(
            '/auth/register',
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return response.data;
}

export async function logout(): Promise<void> {
    await request<LogoutResponse>(
        '/auth/logout',
        {
            method: 'POST',
        },
    );
}
