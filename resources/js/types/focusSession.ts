export type FocusSessionMode = 'focus' | 'relax';

export type FocusSessionStatus =
    | 'active'
    | 'paused'
    | 'completed'
    | 'cancelled';

export interface SessionInterruption {
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

    created_at: string | null;
    updated_at: string | null;
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