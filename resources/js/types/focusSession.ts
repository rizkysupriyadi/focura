export type FocusSessionMode = 'focus' | 'relax';

export type FocusSessionStatus =
    | 'active'
    | 'paused'
    | 'completed'
    | 'cancelled';

export interface ApiValidationErrors {
    [field: string]: string[];
}

export interface ApiResponse<T> {
    data: T;
    message?: string;
}

export interface SessionInterruption {
    id: number;
    focus_session_id: number;
    started_at: string;
    ended_at: string | null;
    duration_seconds: number;
    created_at?: string | null;
    updated_at?: string | null;
}

export interface SessionPause {
    id: number;
    focus_session_id: number;
    started_at: string;
    ended_at: string | null;
    duration_seconds: number;
    created_at?: string | null;
    updated_at?: string | null;
}

export interface FocusSession {
    id: number;

    user_id: number | null;
    visitor_id: string | null;

    mode: FocusSessionMode;
    title: string | null;

    planned_duration_seconds: number;
    actual_duration_seconds: number;
    focused_duration_seconds: number;
    interrupted_duration_seconds: number;
    interruption_count: number;
    focus_integrity: number | null;

    status: FocusSessionStatus;

    started_at: string;
    ended_at: string | null;

    interruptions: SessionInterruption[];
    pauses: SessionPause[];

    created_at: string | null;
    updated_at: string | null;
}

export interface CreateFocusSessionPayload {
    mode: FocusSessionMode;
    title?: string | null;
    planned_duration_seconds: number;
    started_at: string;
    visitor_id?: string | null;
}

export interface CompleteFocusSessionPayload {
    ended_at: string;
}

export interface CancelFocusSessionPayload {
    cancelled_at: string;
}

export interface PauseFocusSessionPayload {
    started_at: string;
}

export interface ResumeFocusSessionPayload {
    ended_at: string;
}

export interface CreateSessionInterruptionPayload {
    started_at: string;
    ended_at: string;
}

export type FocusInsightsRange = 'today' | '7d' | '30d' | '90d' | 'all';

export interface FocusInsightsSummary {
    sessions_completed: number;
    total_focus_time_seconds: number;
    total_interruption_time_seconds: number;
    average_session_duration_seconds: number;
    average_focus_integrity: number | null;
    focus_consistency: number | null;
    focus_sessions: number;
    relax_sessions: number;
}

export interface FocusInsightsTrendPoint {
    date: string;
    sessions_completed: number;
    focus_sessions: number;
    relax_sessions: number;
    focus_time_seconds: number;
    interruption_time_seconds: number;
    actual_time_seconds: number;
    focus_integrity: number | null;
}

export interface FocusInsightsInterruptions {
    total_count: number;
    total_duration_seconds: number;
    average_duration_seconds: number;
    sessions_interrupted: number;
}

export interface FocusInsights {
    summary: FocusInsightsSummary;
    trend: FocusInsightsTrendPoint[];
    interruptions: FocusInsightsInterruptions;
}

export interface FocusSessionPaginationMeta {
    current_page: number;
    from: number | null;
    last_page: number;
    per_page: number;
    to: number | null;
    total: number;
    path: string;
}

export interface FocusSessionPaginationLinks {
    first: string;
    last: string;
    prev: string | null;
    next: string | null;
}

export interface PaginatedFocusSessions {
    data: FocusSession[];
    meta: FocusSessionPaginationMeta;
    links: FocusSessionPaginationLinks;
}
