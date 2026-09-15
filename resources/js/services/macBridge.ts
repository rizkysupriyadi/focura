import type {
    TimerSnapshot,
} from '@/composables/useTimer';

export interface MacBridgeState {
    mode: 'focus' | 'relax';
    status:
        | 'idle'
        | 'running'
        | 'paused'
        | 'completed';
    duration: number;
    remaining: number;
    startedAt: string | null;
    endAt: number | null;
    sessionId: number | null;
    title: string | null;
}

const BRIDGE_URL =
    'http://127.0.0.1:43127/state';

const SEND_INTERVAL_MS = 1000;

let lastSentAt = 0;
let pendingState: MacBridgeState | null = null;
let scheduledSendId: number | null = null;

function send(
    state: MacBridgeState,
): void {
    console.log(
        '[Focura MacBridge] sending',
        state,
    );

    void fetch(BRIDGE_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(state),
        credentials: 'omit',
    })
        .then((response) => {
            console.log(
                '[Focura MacBridge] response',
                response.status,
                state.remaining,
            );
        })
        .catch((error: unknown) => {
            console.error(
                '[Focura MacBridge] failed',
                error,
                state,
            );
        });
}

function flush(): void {
    scheduledSendId = null;

    if (!pendingState) {
        return;
    }

    const now = Date.now();
    const elapsed =
        now - lastSentAt;

    if (
        elapsed <
        SEND_INTERVAL_MS
    ) {
        scheduledSendId =
            window.setTimeout(
                flush,
                SEND_INTERVAL_MS -
                    elapsed,
            );

        return;
    }

    const state =
        pendingState;

    pendingState = null;
    lastSentAt = now;

    send(state);
}

export function publishMacBridgeState(
    state: MacBridgeState,
): void {
    pendingState = state;

    const now = Date.now();

    if (
        now - lastSentAt >=
            SEND_INTERVAL_MS &&
        scheduledSendId === null
    ) {
        flush();

        return;
    }

    if (
        scheduledSendId !== null
    ) {
        return;
    }

    scheduledSendId =
        window.setTimeout(
            flush,
            SEND_INTERVAL_MS,
        );
}

export function publishTimerSnapshot(
    snapshot: TimerSnapshot,
    mode: MacBridgeState['mode'],
    sessionId: number | null,
    title: string | null,
): void {
    publishMacBridgeState({
        mode,
        status: snapshot.status,
        duration:
            snapshot.durationSeconds,
        remaining:
            snapshot.remainingSeconds,
        startedAt:
            snapshot.startedAt,
        endAt:
            snapshot.endAt,
        sessionId,
        title,
    });
}
