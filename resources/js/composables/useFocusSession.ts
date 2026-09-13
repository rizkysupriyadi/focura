import { ref } from 'vue';

import {
    cancelFocusSession,
    completeFocusSession,
    createFocusSession,
    FocusSessionApiError,
    pauseFocusSession,
    recordSessionInterruption,
    resumeFocusSession,
} from '@/services/focusSessions';

import type {
    CancelFocusSessionPayload,
    CompleteFocusSessionPayload,
    CreateFocusSessionPayload,
    CreateSessionInterruptionPayload,
    FocusSession,
    PauseFocusSessionPayload,
    ResumeFocusSessionPayload,
    SessionPause,
} from '@/types/focusSession';

const STORAGE_KEY = 'focura.active_session';

interface StoredFocusSession {
    id: number;
    mode: FocusSession['mode'];
    title: string | null;
    status: FocusSession['status'];
    startedAt: string;
}

const session = ref<FocusSession | null>(null);

const isCreating = ref(false);
const isCompleting = ref(false);
const isPausing = ref(false);
const isResuming = ref(false);
const isCancelling = ref(false);

const error = ref<string | null>(null);

let completionPromise:
    | Promise<FocusSession | null>
    | null = null;

let pendingInterruptionPromises:
    Promise<boolean>[] = [];

const interruptionRequestKeys = new Set<string>();

function persistSession(): void {
    if (
        typeof window === 'undefined' ||
        !session.value
    ) {
        return;
    }

    const stored: StoredFocusSession = {
        id: session.value.id,
        mode: session.value.mode,
        title: session.value.title,
        status: session.value.status,
        startedAt: session.value.started_at,
    };

    localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify(stored),
    );
}

function clearPersistedSession(): void {
    if (typeof window === 'undefined') {
        return;
    }

    localStorage.removeItem(STORAGE_KEY);
}

function getStoredSession():
    | StoredFocusSession
    | null {
    if (typeof window === 'undefined') {
        return null;
    }

    const raw = localStorage.getItem(STORAGE_KEY);

    if (!raw) {
        return null;
    }

    try {
        const parsed: unknown = JSON.parse(raw);

        if (
            typeof parsed !== 'object' ||
            parsed === null
        ) {
            clearPersistedSession();

            return null;
        }

        const record =
            parsed as Record<string, unknown>;

        if (
            typeof record.id !== 'number' ||
            !Number.isInteger(record.id) ||
            record.id <= 0 ||
            (
                record.mode !== 'focus' &&
                record.mode !== 'relax'
            ) ||
            (
                record.title !== null &&
                typeof record.title !== 'string'
            ) ||
            (
                record.status !== 'active' &&
                record.status !== 'paused' &&
                record.status !== 'completed' &&
                record.status !== 'cancelled'
            ) ||
            typeof record.startedAt !== 'string' ||
            !Number.isFinite(
                new Date(
                    record.startedAt,
                ).getTime(),
            )
        ) {
            clearPersistedSession();

            return null;
        }

        return {
            id: record.id,
            mode: record.mode,
            title: record.title,
            status: record.status,
            startedAt: record.startedAt,
        };
    } catch {
        clearPersistedSession();

        return null;
    }
}

function getErrorMessage(
    caught: unknown,
): string {
    if (
        caught instanceof FocusSessionApiError
    ) {
        return caught.message;
    }

    if (caught instanceof Error) {
        return caught.message;
    }

    return 'Unable to synchronize the session with the server.';
}

function getInterruptionRequestKey(
    sessionId: number,
    payload: CreateSessionInterruptionPayload,
): string {
    return [
        sessionId,
        payload.started_at,
        payload.ended_at,
    ].join('|');
}

function removePendingInterruption(
    request: Promise<boolean>,
): void {
    pendingInterruptionPromises =
        pendingInterruptionPromises.filter(
            (pending) =>
                pending !== request,
        );
}

export function useFocusSession() {
    async function start(
        payload: CreateFocusSessionPayload,
    ): Promise<FocusSession | null> {
        if (isCreating.value) {
            return null;
        }

        isCreating.value = true;
        error.value = null;

        try {
            const created =
                await createFocusSession(
                    payload,
                );

            session.value = created;

            persistSession();

            return created;
        } catch (caught) {
            error.value =
                getErrorMessage(caught);

            return null;
        } finally {
            isCreating.value = false;
        }
    }

    function restore():
        | StoredFocusSession
        | null {
        return getStoredSession();
    }

    function setRecoveredSession(
        recovered: StoredFocusSession,
    ): void {
        session.value = {
            user_id: null,
            visitor_id: null,
            id: recovered.id,
            mode: recovered.mode,
            title: recovered.title,
            planned_duration_seconds: 0,
            actual_duration_seconds: 0,
            focused_duration_seconds: 0,
            interrupted_duration_seconds: 0,
            interruption_count: 0,
            focus_integrity: null,
            status: recovered.status,
            started_at: recovered.startedAt,
            ended_at: null,
            interruptions: [],
            pauses: [],
            created_at: null,
            updated_at: null,
        };

        error.value = null;
    }

    async function recordInterruption(
        payload: CreateSessionInterruptionPayload,
    ): Promise<boolean> {
        const sessionId = session.value?.id;

        if (!sessionId) {
            return false;
        }

        /*
         * Relax sessions must never create interruption
         * records. The backend also enforces this rule,
         * but keeping the guard here prevents unnecessary
         * requests.
         */
        if (
            session.value?.mode !== 'focus'
        ) {
            return false;
        }

        const requestKey =
            getInterruptionRequestKey(
                sessionId,
                payload,
            );

        /*
         * Prevent the same interruption from being
         * submitted more than once during the current
         * lifecycle.
         */
        if (
            interruptionRequestKeys.has(
                requestKey,
            )
        ) {
            return true;
        }

        interruptionRequestKeys.add(
            requestKey,
        );

        const request =
            recordSessionInterruption(
                sessionId,
                payload,
            )
                .then(() => true)
                .catch((caught) => {
                    error.value =
                        getErrorMessage(caught);

                    /*
                     * A failed request may be retried.
                     */
                    interruptionRequestKeys.delete(
                        requestKey,
                    );

                    return false;
                });

        pendingInterruptionPromises.push(
            request,
        );

        try {
            return await request;
        } finally {
            removePendingInterruption(request);
        }
    }

    async function waitForPendingInterruptions():
        Promise<void> {
        /*
         * Keep observing the queue because another
         * interruption may be registered while the
         * current batch is resolving.
         */
        while (
            pendingInterruptionPromises.length > 0
        ) {
            const pending = [
                ...pendingInterruptionPromises,
            ];

            await Promise.all(pending);
        }
    }

    async function pause(
        startedAt: string,
    ): Promise<SessionPause | null> {
        const sessionId = session.value?.id;

        if (
            !sessionId ||
            isPausing.value ||
            isResuming.value ||
            isCancelling.value ||
            isCompleting.value
        ) {
            return null;
        }

        isPausing.value = true;
        error.value = null;

        const payload:
            PauseFocusSessionPayload = {
            started_at: startedAt,
        };

        try {
            const paused =
                await pauseFocusSession(
                    sessionId,
                    payload,
                );

            if (session.value) {
                session.value = {
                    ...session.value,
                    status: 'paused',
                };

                persistSession();
            }

            return paused;
        } catch (caught) {
            error.value =
                getErrorMessage(caught);

            return null;
        } finally {
            isPausing.value = false;
        }
    }

    async function resume(
        endedAt: string,
    ): Promise<SessionPause | null> {
        const sessionId = session.value?.id;

        if (
            !sessionId ||
            isPausing.value ||
            isResuming.value ||
            isCancelling.value ||
            isCompleting.value
        ) {
            return null;
        }

        isResuming.value = true;
        error.value = null;

        const payload:
            ResumeFocusSessionPayload = {
            ended_at: endedAt,
        };

        try {
            const resumed =
                await resumeFocusSession(
                    sessionId,
                    payload,
                );

            if (session.value) {
                session.value = {
                    ...session.value,
                    status: 'active',
                };

                persistSession();
            }

            return resumed;
        } catch (caught) {
            error.value =
                getErrorMessage(caught);

            return null;
        } finally {
            isResuming.value = false;
        }
    }

    async function cancel(
        cancelledAt: string,
    ): Promise<FocusSession | null> {
        const sessionId = session.value?.id;

        if (!sessionId) {
            return null;
        }

        return cancelById(
            sessionId,
            cancelledAt,
        );
    }

    async function cancelById(
        sessionId: number,
        cancelledAt: string,
    ): Promise<FocusSession | null> {
        if (
            !Number.isInteger(sessionId) ||
            sessionId <= 0 ||
            isCancelling.value ||
            isCompleting.value
        ) {
            return null;
        }

        isCancelling.value = true;
        error.value = null;

        const payload:
            CancelFocusSessionPayload = {
            cancelled_at: cancelledAt,
        };

        try {
            const cancelled =
                await cancelFocusSession(
                    sessionId,
                    payload,
                );

            if (
                session.value?.id === sessionId
            ) {
                session.value = cancelled;
            }

            clearPersistedSession();

            return cancelled;
        } catch (caught) {
            error.value =
                getErrorMessage(caught);

            return null;
        } finally {
            isCancelling.value = false;
        }
    }

    async function complete(
        endedAt: string,
    ): Promise<FocusSession | null> {
        const sessionId = session.value?.id;

        if (!sessionId) {
            return null;
        }

        /*
         * Completion is idempotent on the frontend.
         * Multiple callers receive the same promise.
         */
        if (completionPromise) {
            return completionPromise;
        }

        if (
            session.value?.status ===
            'completed'
        ) {
            return session.value;
        }

        if (
            session.value?.status ===
            'cancelled'
        ) {
            return null;
        }

        isCompleting.value = true;
        error.value = null;

        const payload:
            CompleteFocusSessionPayload = {
            ended_at: endedAt,
        };

        completionPromise = (async () => {
            try {
                /*
                 * Wait for every interruption request,
                 * including requests added while an earlier
                 * batch is resolving.
                 */
                await waitForPendingInterruptions();

                /*
                 * The session can have been changed by
                 * another lifecycle operation while the
                 * interruption queue was resolving.
                 *
                 * Never complete a session that is no longer
                 * the same local session.
                 */
                if (
                    session.value?.id !== sessionId
                ) {
                    return null;
                }

                if (
                    session.value?.status ===
                    'cancelled'
                ) {
                    return null;
                }

                if (
                    session.value?.status ===
                    'completed'
                ) {
                    return session.value;
                }

                const completed =
                    await completeFocusSession(
                        sessionId,
                        payload,
                    );

                /*
                 * Only the same session may receive
                 * the completion result.
                 */
                if (
                    session.value?.id !== sessionId
                ) {
                    return null;
                }

                session.value = completed;

                clearPersistedSession();

                return completed;
            } catch (caught) {
                error.value =
                    getErrorMessage(caught);

                /*
                 * Persisted recovery state is intentionally
                 * retained so completion can be retried.
                 */
                return null;
            } finally {
                isCompleting.value = false;
                completionPromise = null;
            }
        })();

        return completionPromise;
    }

    function reset(): void {
        /*
         * Do not mutate pending promises here.
         *
         * Existing network requests are still owned by
         * their original lifecycle and must be allowed to
         * settle naturally. Clearing the queue here could
         * make completion/cancellation state appear settled
         * while a request is still in flight.
         */
        session.value = null;
        error.value = null;

        isCreating.value = false;
        isCompleting.value = false;
        isPausing.value = false;
        isResuming.value = false;
        isCancelling.value = false;

        completionPromise = null;

        interruptionRequestKeys.clear();

        clearPersistedSession();
    }

    return {
        session,
        isCreating,
        isCompleting,
        isPausing,
        isResuming,
        isCancelling,
        error,
        start,
        restore,
        setRecoveredSession,
        recordInterruption,
        waitForPendingInterruptions,
        pause,
        resume,
        cancel,
        cancelById,
        complete,
        reset,
    };
}
