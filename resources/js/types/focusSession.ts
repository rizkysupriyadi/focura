export type FocusSessionMode = 'focus' | 'relax';

export type FocusSessionStatus =
    | 'active'
    | 'paused'
    | 'completed'
    | 'cancelled';

export type FocusInsightsRange =
    | 'today'
    | '7d'
    | '30d'
    | '90d'
    | 'all';

export interface SessionInterruption {
    id: number;
    started_at: string;
    ended_at: string | null;
    duration_seconds: number;
}

export interface SessionPause {
    id: number;
    started_at: string;
    ended_at: string | null;
    duration_seconds: number;
}

export interface FocusSession {
    id: number;
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
    interruptions?: SessionInterruption[];
    pauses?: SessionPause[];
    created_at: string | null;
    updated_at: string | null;
    user_id: number | null;
    visitor_id: string | null;
}

export interface FocusInsightsSummary {
    sessions_completed: number;
    focus_sessions: number;
    relax_sessions: number;
    total_focus_time_seconds: number;
    total_interruption_time_seconds: number;
    average_session_duration_seconds: number;
    average_focus_integrity: number | null;
    focus_consistency: number | null;
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

export interface PaginatedFocusSessions {
    data: FocusSession[];
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
    from: number | null;
    to: number | null;
    first_page_url: string;
    last_page_url: string;
    next_page_url: string | null;
    prev_page_url: string | null;
    path: string;
}

export interface CreateFocusSessionPayload {
    mode: FocusSessionMode;
    title?: string | null;
    planned_duration_seconds: number;
    started_at: string;
}

export interface CompleteFocusSessionPayload {
    ended_at: string;
}

export interface CreateSessionInterruptionPayload {
    started_at: string;
    ended_at: string;
}

export interface PauseFocusSessionPayload {
    started_at: string;
}

export interface ResumeFocusSessionPayload {
    ended_at: string;
}

export interface CancelFocusSessionPayload {
    cancelled_at: string;
}

export interface ApiResponse<T> {
    data: T;
    message?: string;
}

export interface ApiValidationErrors {
    [field: string]: string[];
}