import {
    computed,
    onBeforeUnmount,
    ref,
    type Ref,
} from 'vue';

export interface Interruption {
    startedAt: string;
    endedAt: string;
    durationSeconds: number;
}

export interface InterruptionSnapshot {
    interruptions: Interruption[];
    activeStartedAt: string | null;
    interruptedDurationSeconds: number;
    interruptionCount: number;
}

const interruptions = ref<Interruption[]>([]);
const activeStartedAt = ref<string | null>(null);
const isTracking = ref(false);

/**
 * Reactive clock used to update active interruption duration.
 *
 * The value itself is not important. Its purpose is to provide
 * a reactive dependency for computed interruption duration.
 */
const elapsedTick = ref(0);

let elapsedIntervalId: number | null = null;

function nowIso(): string {
    return new Date().toISOString();
}

function calculateDurationSeconds(
    startedAt: string,
    endedAt: string,
): number {
    const started = new Date(startedAt).getTime();
    const ended = new Date(endedAt).getTime();

    if (
        !Number.isFinite(started) ||
        !Number.isFinite(ended)
    ) {
        return 0;
    }

    return Math.max(
        0,
        Math.floor((ended - started) / 1000),
    );
}

function startInterruption(): void {
    if (
        !isTracking.value ||
        activeStartedAt.value !== null
    ) {
        return;
    }

    activeStartedAt.value = nowIso();
}

function finishInterruption(): Interruption | null {
    if (activeStartedAt.value === null) {
        return null;
    }

    const startedAt = activeStartedAt.value;
    const endedAt = nowIso();

    const interruption: Interruption = {
        startedAt,
        endedAt,
        durationSeconds:
            calculateDurationSeconds(
                startedAt,
                endedAt,
            ),
    };

    interruptions.value.push(interruption);

    activeStartedAt.value = null;

    return interruption;
}

function handleVisibilityChange(): void {
    if (!isTracking.value) {
        return;
    }

    if (document.visibilityState === 'hidden') {
        startInterruption();

        return;
    }

    finishInterruption();
}

function handleWindowBlur(): void {
    if (!isTracking.value) {
        return;
    }

    startInterruption();
}

function handleWindowFocus(): void {
    if (!isTracking.value) {
        return;
    }

    /**
     * A focus event can happen while the document is still hidden
     * in some browser lifecycle situations. In that case the
     * interruption must remain active until the document becomes
     * visible again.
     */
    if (
        document.visibilityState !== 'visible'
    ) {
        return;
    }

    finishInterruption();
}

const activeInterruptedDurationSeconds =
    computed(() => {
        /**
         * Read the reactive tick so Vue recalculates this computed
         * value while an interruption is active.
         */
        elapsedTick.value;

        if (activeStartedAt.value === null) {
            return 0;
        }

        const started = new Date(
            activeStartedAt.value,
        ).getTime();

        if (!Number.isFinite(started)) {
            return 0;
        }

        return Math.max(
            0,
            Math.floor(
                (Date.now() - started) / 1000,
            ),
        );
    });

const interruptedDurationSeconds =
    computed(() => {
        const completedDuration =
            interruptions.value.reduce(
                (
                    total,
                    interruption,
                ) =>
                    total +
                    interruption.durationSeconds,
                0,
            );

        return (
            completedDuration +
            activeInterruptedDurationSeconds.value
        );
    });

const interruptionCount = computed(() => {
    return (
        interruptions.value.length +
        (activeStartedAt.value !== null
            ? 1
            : 0)
    );
});

const isInterrupted = computed(() => {
    return activeStartedAt.value !== null;
});

function startTicker(): void {
    stopTicker();

    elapsedIntervalId =
        window.setInterval(() => {
            if (
                activeStartedAt.value === null
            ) {
                return;
            }

            elapsedTick.value += 1;
        }, 1000);
}

function stopTicker(): void {
    if (elapsedIntervalId !== null) {
        window.clearInterval(
            elapsedIntervalId,
        );

        elapsedIntervalId = null;
    }
}

function startTracking(): void {
    if (
        typeof window === 'undefined' ||
        isTracking.value
    ) {
        return;
    }

    isTracking.value = true;

    document.addEventListener(
        'visibilitychange',
        handleVisibilityChange,
    );

    window.addEventListener(
        'blur',
        handleWindowBlur,
    );

    window.addEventListener(
        'focus',
        handleWindowFocus,
    );

    startTicker();
}

function stopTracking(): void {
    if (
        typeof window === 'undefined' ||
        !isTracking.value
    ) {
        return;
    }

    /**
     * Finish an active interruption before disabling
     * tracking so the interruption is not left open
     * in the frontend state.
     */
    finishInterruption();

    isTracking.value = false;

    document.removeEventListener(
        'visibilitychange',
        handleVisibilityChange,
    );

    window.removeEventListener(
        'blur',
        handleWindowBlur,
    );

    window.removeEventListener(
        'focus',
        handleWindowFocus,
    );

    stopTicker();
}

function reset(): void {
    stopTracking();

    interruptions.value = [];
    activeStartedAt.value = null;
    elapsedTick.value = 0;
}

function snapshot(): InterruptionSnapshot {
    return {
        interruptions:
            interruptions.value.map(
                (interruption) => ({
                    ...interruption,
                }),
            ),
        activeStartedAt:
            activeStartedAt.value,
        interruptedDurationSeconds:
            interruptedDurationSeconds.value,
        interruptionCount:
            interruptionCount.value,
    };
}

export function useInterruption(
    sessionStatus: Ref<
        'idle' |
        'running' |
        'paused' |
        'completed'
    >,
    enabled: Ref<boolean>,
) {
    onBeforeUnmount(() => {
        stopTracking();
    });

    function syncTracking(): void {
        const shouldTrack =
            enabled.value &&
            sessionStatus.value === 'running';

        if (
            shouldTrack &&
            !isTracking.value
        ) {
            startTracking();
        }

        if (
            !shouldTrack &&
            isTracking.value
        ) {
            stopTracking();
        }
    }

    return {
        interruptions,
        activeStartedAt,
        isInterrupted,
        isTracking,
        interruptedDurationSeconds,
        interruptionCount,
        startTracking,
        stopTracking,
        startInterruption,
        finishInterruption,
        syncTracking,
        reset,
        snapshot,
    };
}