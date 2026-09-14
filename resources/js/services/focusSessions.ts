import { getCsrfHeaders } from '@/lib/csrf';
import { getIdentityHeaders } from '@/lib/identity';
import { getVisitorId } from '@/lib/visitor';

import type { ClaimGuestSessionsResponse } from '@/types/auth';

import type {
    ApiResponse,
    ApiValidationErrors,
    CancelFocusSessionPayload,
    CompleteFocusSessionPayload,
    CreateFocusSessionPayload,
    CreateSessionInterruptionPayload,
    FocusInsights,
    FocusInsightsRange,
    FocusSession,
    FocusSessionMode,
    FocusSessionStatus,
    PaginatedFocusSessions,
    PauseFocusSessionPayload,
    ResumeFocusSessionPayload,
    SessionInterruption,
    SessionPause,
} from '@/types/focusSession';

const API_BASE_URL = '/api/v1';

interface ApiErrorPayload {
    message?: string;
    errors?: ApiValidationErrors;
}

export class FocusSessionApiError extends Error {
    readonly status: number;
    readonly errors: ApiValidationErrors;

    constructor(
        message: string,
        status: number,
        errors: ApiValidationErrors = {},
    ) {
        super(message);

        this.name = 'FocusSessionApiError';
        this.status = status;
        this.errors = errors;
    }
}

async function request<T>(
    path: string,
    options: RequestInit = {},
): Promise<T> {
    const identityHeaders =
        getIdentityHeaders();

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
                ...identityHeaders,
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

        throw new FocusSessionApiError(
            errorPayload.message ??
                'The request could not be completed.',
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


export async function claimGuestSessions(): Promise<number> {
    const visitorId = getVisitorId();

    if (!visitorId) {
        throw new Error(
            'Unable to identify this browser.',
        );
    }

    const response =
        await request<ClaimGuestSessionsResponse>(
            '/focus-sessions/claim',
            {
                method: 'POST',
                headers: {
                    'X-Visitor-Id': visitorId,
                },
            },
        );

    return response.data.claimed_count;
}

export async function getFocusInsights(
    range: FocusInsightsRange = '30d',
): Promise<FocusInsights> {
    const response =
        await request<ApiResponse<FocusInsights>>(
            `/insights?range=${encodeURIComponent(range)}`,
            {
                method: 'GET',
            },
        );

    return response.data;
}

export async function createFocusSession(
    payload: CreateFocusSessionPayload,
): Promise<FocusSession> {
    const response =
        await request<ApiResponse<FocusSession>>(
            '/focus-sessions',
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return response.data;
}

export interface ListFocusSessionsParams {
    mode?: FocusSessionMode;
    status?: FocusSessionStatus;
    range?: 'today';
    per_page?: number;
    page?: number;
}

export async function listFocusSessions(
    params: ListFocusSessionsParams = {},
): Promise<PaginatedFocusSessions> {
    const searchParams = new URLSearchParams();

    if (params.mode !== undefined) {
        searchParams.set(
            'mode',
            params.mode,
        );
    }

    if (params.status !== undefined) {
        searchParams.set(
            'status',
            params.status,
        );
    }

    if (params.range !== undefined) {
        searchParams.set(
            'range',
            params.range,
        );
    }

    if (params.per_page !== undefined) {
        searchParams.set(
            'per_page',
            String(params.per_page),
        );
    }

    if (params.page !== undefined) {
        searchParams.set(
            'page',
            String(params.page),
        );
    }

    const query =
        searchParams.toString();

    return request<PaginatedFocusSessions>(
        `/focus-sessions${query ? `?${query}` : ''}`,
        {
            method: 'GET',
        },
    );
}

export async function getFocusSession(
    sessionId: number,
): Promise<FocusSession> {
    const response =
        await request<ApiResponse<FocusSession>>(
            `/focus-sessions/${sessionId}`,
            {
                method: 'GET',
            },
        );

    return response.data;
}

export async function pauseFocusSession(
    sessionId: number,
    payload: PauseFocusSessionPayload,
): Promise<SessionPause> {
    const response =
        await request<ApiResponse<SessionPause>>(
            `/focus-sessions/${sessionId}/pause`,
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return response.data;
}

export async function resumeFocusSession(
    sessionId: number,
    payload: ResumeFocusSessionPayload,
): Promise<SessionPause> {
    const response =
        await request<ApiResponse<SessionPause>>(
            `/focus-sessions/${sessionId}/resume`,
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return response.data;
}

export async function cancelFocusSession(
    sessionId: number,
    payload: CancelFocusSessionPayload,
): Promise<FocusSession> {
    const response =
        await request<ApiResponse<FocusSession>>(
            `/focus-sessions/${sessionId}/cancel`,
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return response.data;
}

export async function completeFocusSession(
    sessionId: number,
    payload: CompleteFocusSessionPayload,
): Promise<FocusSession> {
    const response =
        await request<ApiResponse<FocusSession>>(
            `/focus-sessions/${sessionId}/complete`,
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return response.data;
}

export async function recordSessionInterruption(
    sessionId: number,
    payload: CreateSessionInterruptionPayload,
): Promise<SessionInterruption> {
    const response =
        await request<
            ApiResponse<{
                id: number;
                focus_session_id: number;
                started_at: string;
                ended_at: string | null;
                duration_seconds: number;
            }>
        >(
            `/focus-sessions/${sessionId}/interruptions`,
            {
                method: 'POST',
                body: JSON.stringify(payload),
            },
        );

    return {
        id: response.data.id,
        started_at: response.data.started_at,
        ended_at: response.data.ended_at,
        duration_seconds:
            response.data.duration_seconds,
    };
}
