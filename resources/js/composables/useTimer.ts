import {
    computed,
    onBeforeUnmount,
    ref,
} from 'vue';

export type TimerStatus =
    | 'idle'
    | 'running'
    | 'paused'
    | 'completed';

export interface TimerSnapshot {
    durationSeconds: number;
    remainingSeconds: number;
    status: TimerStatus;
    startedAt: string | null;
    pausedAt: string | null;
    endAt: number | null;
}

interface StoredTimerState {
    durationSeconds: number;
    remainingSeconds: number;
    status: TimerStatus;
    startedAt: string | null;
    pausedAt: string | null;
    endAt: number | null;
    savedAt: string;
}

const STORAGE_KEY = 'focura.active_timer';

const MIN_DURATION_SECONDS = 1;
const MAX_DURATION_SECONDS =
    24 * 60 * 60;

const durationSeconds = ref(25 * 60);
const remainingSeconds = ref(25 * 60);
const status = ref<TimerStatus>('idle');
const startedAt = ref<string | null>(null);
const pausedAt = ref<string | null>(null);
const endAt = ref<number | null>(null);

let intervalId: number | null = null;

const isRunning = computed(
    () => status.value === 'running',
);

const isPaused = computed(
    () => status.value === 'paused',
);

const isCompleted = computed(
    () => status.value === 'completed',
);

const formattedTime = computed(() => {
    const totalSeconds = Math.max(
        0,
        Math.floor(remainingSeconds.value),
    );

    const minutes = Math.floor(
        totalSeconds / 60,
    );

    const seconds = totalSeconds % 60;

    return `${String(minutes).padStart(
        2,
        '0',
    )}:${String(seconds).padStart(2, '0')}`;
});

function isValidDuration(
    value: unknown,
): value is number {
    return (
        typeof value === 'number' &&
        Number.isFinite(value) &&
        Number.isInteger(value) &&
        value >= MIN_DURATION_SECONDS &&
        value <= MAX_DURATION_SECONDS
    );
}

function isValidRemainingSeconds(
    value: unknown,
): value is number {
    return (
        typeof value === 'number' &&
        Number.isFinite(value) &&
        Number.isInteger(value) &&
        value >= 0 &&
        value <= MAX_DURATION_SECONDS
    );
}

function isValidTimestamp(
    value: unknown,
): value is string {
    if (typeof value !== 'string' || value === '') {
        return false;
    }

    const timestamp = Date.parse(value);

    return Number.isFinite(timestamp);
}

function isValidEndAt(
    value: unknown,
): value is number {
    return (
        typeof value === 'number' &&
        Number.isFinite(value) &&
        value > 0
    );
}

function isTimerStatus(
    value: unknown,
): value is TimerStatus {
    return (
        value === 'idle' ||
        value === 'running' ||
        value === 'paused' ||
        value === 'completed'
    );
}

function isValidStoredTimerState(
    value: unknown,
): value is StoredTimerState {
    if (
        typeof value !== 'object' ||
        value === null
    ) {
        return false;
    }

    const stored =
        value as Record<string, unknown>;

    if (
        !isValidDuration(
            stored.durationSeconds,
        ) ||
        !isValidRemainingSeconds(
            stored.remainingSeconds,
        ) ||
        !isTimerStatus(stored.status)
    ) {
        return false;
    }

    if (
        stored.startedAt !== null &&
        !isValidTimestamp(stored.startedAt)
    ) {
        return false;
    }

    if (
        stored.pausedAt !== null &&
        !isValidTimestamp(stored.pausedAt)
    ) {
        return false;
    }

    if (
        stored.endAt !== null &&
        !isValidEndAt(stored.endAt)
    ) {
        return false;
    }

    if (!isValidTimestamp(stored.savedAt)) {
        return false;
    }

    if (
        stored.remainingSeconds >
        stored.durationSeconds
    ) {
        return false;
    }

    switch (stored.status) {
        case 'running':
            return (
                stored.endAt !== null &&
                stored.startedAt !== null &&
                stored.pausedAt === null
            );

        case 'paused':
            return (
                stored.endAt === null &&
                stored.startedAt !== null &&
                stored.pausedAt !== null &&
                stored.remainingSeconds > 0
            );

        case 'completed':
            return (
                stored.endAt === null &&
                stored.remainingSeconds === 0
            );

        case 'idle':
            return (
                stored.endAt === null &&
                stored.startedAt === null &&
                stored.pausedAt === null &&
                stored.remainingSeconds ===
                    stored.durationSeconds
            );

        default:
            return false;
    }
}

function persist(): void {
    if (typeof window === 'undefined') {
        return;
    }

    const state: StoredTimerState = {
        durationSeconds:
            durationSeconds.value,
        remainingSeconds:
            remainingSeconds.value,
        status: status.value,
        startedAt: startedAt.value,
        pausedAt: pausedAt.value,
        endAt: endAt.value,
        savedAt: new Date().toISOString(),
    };

    localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify(state),
    );
}

function clearPersistedTimer(): void {
    if (typeof window === 'undefined') {
        return;
    }

    localStorage.removeItem(STORAGE_KEY);
}

function stopTicker(): void {
    if (intervalId !== null) {
        window.clearInterval(intervalId);
        intervalId = null;
    }
}

function markCompleted(): void {
    remainingSeconds.value = 0;
    status.value = 'completed';
    endAt.value = null;
    pausedAt.value = null;

    stopTicker();
    persist();
}

function updateTimer(): void {
    if (
        status.value !== 'running' ||
        endAt.value === null
    ) {
        return;
    }

    const now = Date.now();

    const difference = Math.max(
        0,
        endAt.value - now,
    );

    remainingSeconds.value = Math.min(
        durationSeconds.value,
        Math.ceil(difference / 1000),
    );

    if (difference <= 0) {
        markCompleted();

        return;
    }

    persist();
}

function startTicker(): void {
    stopTicker();

    updateTimer();

    if (status.value !== 'running') {
        return;
    }

    intervalId = window.setInterval(() => {
        updateTimer();
    }, 250);
}

function start(
    duration: number = durationSeconds.value,
): void {
    if (!isValidDuration(Math.floor(duration))) {
        return;
    }

    const normalizedDuration =
        Math.floor(duration);

    durationSeconds.value =
        normalizedDuration;

    remainingSeconds.value =
        normalizedDuration;

    status.value = 'running';

    const now = Date.now();

    startedAt.value =
        new Date(now).toISOString();

    pausedAt.value = null;

    endAt.value =
        now + normalizedDuration * 1000;

    persist();
    startTicker();
}

function pause(): void {
    if (
        status.value !== 'running' ||
        endAt.value === null
    ) {
        return;
    }

    updateTimer();

    if (
        status.value !== 'running' ||
        endAt.value === null
    ) {
        return;
    }

    remainingSeconds.value = Math.max(
        0,
        Math.min(
            durationSeconds.value,
            Math.ceil(
                (endAt.value - Date.now()) /
                    1000,
            ),
        ),
    );

    if (remainingSeconds.value <= 0) {
        markCompleted();

        return;
    }

    status.value = 'paused';

    pausedAt.value =
        new Date().toISOString();

    endAt.value = null;

    stopTicker();
    persist();
}

function resume(): void {
    if (
        status.value !== 'paused' ||
        remainingSeconds.value <= 0
    ) {
        return;
    }

    const now = Date.now();

    status.value = 'running';

    pausedAt.value = null;

    endAt.value =
        now + remainingSeconds.value * 1000;

    persist();
    startTicker();
}

function reset(): void {
    stopTicker();

    remainingSeconds.value =
        durationSeconds.value;

    status.value = 'idle';

    startedAt.value = null;
    pausedAt.value = null;
    endAt.value = null;

    clearPersistedTimer();
}

function setDuration(duration: number): void {
    const normalizedDuration =
        Math.floor(duration);

    if (
        !isValidDuration(normalizedDuration)
    ) {
        return;
    }

    if (
        status.value === 'running' ||
        status.value === 'paused'
    ) {
        return;
    }

    durationSeconds.value =
        normalizedDuration;

    remainingSeconds.value =
        normalizedDuration;

    status.value = 'idle';

    startedAt.value = null;
    pausedAt.value = null;
    endAt.value = null;

    clearPersistedTimer();
}

function restore(): boolean {
    if (typeof window === 'undefined') {
        return false;
    }

    const raw =
        localStorage.getItem(STORAGE_KEY);

    if (!raw) {
        return false;
    }

    try {
        const parsed: unknown =
            JSON.parse(raw);

        if (
            !isValidStoredTimerState(parsed)
        ) {
            clearPersistedTimer();

            return false;
        }

        const stored = parsed;

        durationSeconds.value =
            stored.durationSeconds;

        remainingSeconds.value =
            stored.remainingSeconds;

        status.value = stored.status;

        startedAt.value =
            stored.startedAt;

        pausedAt.value =
            stored.pausedAt;

        endAt.value =
            stored.endAt;

        if (status.value === 'running') {
            if (
                endAt.value === null ||
                startedAt.value === null
            ) {
                clearPersistedTimer();
                reset();

                return false;
            }

            if (endAt.value <= Date.now()) {
                markCompleted();

                return true;
            }

            updateTimer();

            if (status.value === 'running') {
                startTicker();
            }

            return true;
        }

        if (status.value === 'completed') {
            remainingSeconds.value = 0;
            endAt.value = null;
            persist();

            return true;
        }

        if (status.value === 'paused') {
            endAt.value = null;

            persist();

            return true;
        }

        endAt.value = null;

        persist();

        return true;
    } catch {
        clearPersistedTimer();

        return false;
    }
}

function snapshot(): TimerSnapshot {
    return {
        durationSeconds:
            durationSeconds.value,
        remainingSeconds:
            remainingSeconds.value,
        status: status.value,
        startedAt: startedAt.value,
        pausedAt: pausedAt.value,
        endAt: endAt.value,
    };
}

function restoreSnapshot(
    snapshotValue: TimerSnapshot,
): void {
    stopTicker();

    if (
        !isValidDuration(
            snapshotValue.durationSeconds,
        ) ||
        !isValidRemainingSeconds(
            snapshotValue.remainingSeconds,
        ) ||
        !isTimerStatus(
            snapshotValue.status,
        )
    ) {
        return;
    }

    durationSeconds.value =
        snapshotValue.durationSeconds;

    remainingSeconds.value =
        snapshotValue.remainingSeconds;

    status.value =
        snapshotValue.status;

    startedAt.value =
        snapshotValue.startedAt;

    pausedAt.value =
        snapshotValue.pausedAt;

    endAt.value =
        snapshotValue.endAt;

    if (
        status.value === 'running' &&
        endAt.value !== null
    ) {
        if (endAt.value <= Date.now()) {
            markCompleted();

            return;
        }

        startTicker();

        return;
    }

    if (status.value === 'completed') {
        remainingSeconds.value = 0;
        endAt.value = null;
    }

    if (status.value !== 'paused') {
        endAt.value = null;
    }

    persist();
}

function cleanup(): void {
    stopTicker();
}

export function useTimer() {
    onBeforeUnmount(cleanup);

    return {
        durationSeconds,
        remainingSeconds,
        status,
        startedAt,
        pausedAt,
        isRunning,
        isPaused,
        isCompleted,
        formattedTime,
        start,
        pause,
        resume,
        reset,
        setDuration,
        restore,
        snapshot,
        restoreSnapshot,
    };
}