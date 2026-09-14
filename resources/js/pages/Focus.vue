<script setup lang="ts">
import {
    computed,
    onMounted,
    onUnmounted,
    ref,
    watch,
} from 'vue';

import { useFocusSession } from '@/composables/useFocusSession';
import { useSettings } from '@/composables/useSettings';
import { useInterruption } from '@/composables/useInterruption';
import { getVisitorId } from '@/lib/visitor';
import { useTimer } from '@/composables/useTimer';
import { useAudio } from '@/composables/useAudio';
import { useFocusMusic } from '@/composables/useFocusMusic';
import {
    cancelFocusSession,
    FocusSessionApiError,
} from '@/services/focusSessions';
import {
    getNotificationPermission,
    requestNotificationPermission,
    showNotification,
} from '@/services/notifications';

type TimerMode = 'focus' | 'relax';

const TIMER_STORAGE_KEY = 'focura.active_timer';
const SESSION_STORAGE_KEY = 'focura.active_session';

const timer = useTimer();
const focusSession = useFocusSession();
const settings = useSettings();
const audio = useAudio();
const focusMusic = useFocusMusic();

const mode = ref<TimerMode>('focus');
const task = ref('');
const customMinutes = ref(
    settings.settings.value.focusDurationMinutes,
);
const showCustom = ref(false);

const hasRecoveredTimer = ref(false);
const isLifecycleActionPending = ref(false);
const isCompletionNotificationShown = ref(false);

/*
|--------------------------------------------------------------------------
| LOCAL-FIRST LIFECYCLE SYNC
|--------------------------------------------------------------------------
|
| Timer state is authoritative for the UI.
| Backend lifecycle requests are synchronized sequentially in the
| background so an older request cannot overtake a newer action.
|
*/

let lifecycleSyncQueue: Promise<void> = Promise.resolve();

function queueLifecycleSync(
    task: () => Promise<void>,
): void {
    lifecycleSyncQueue =
        lifecycleSyncQueue
            .then(task)
            .catch((caught) => {
                focusSession.error.value =
                    getApiErrorMessage(caught);
            });
}

const isActionPending = computed(() => {
    return focusSession.isCompleting.value;
});

const presets = computed(() => [
    {
        label: `${settings.settings.value.focusDurationMinutes} min`,
        minutes:
            settings.settings.value.focusDurationMinutes,
    },
    {
        label: '45 min',
        minutes: 45,
    },
    {
        label: '50 min',
        minutes: 50,
    },
]);

const interruptionTrackingEnabled = computed(
    () =>
        mode.value === 'focus' &&
        settings.settings.value
            .interruptionTrackingEnabled,
);

const interruption = useInterruption(
    timer.status,
    interruptionTrackingEnabled,
);

watch(
    interruptionTrackingEnabled,
    () => {
        interruption.syncTracking();
    },
);

const currentDurationSeconds = computed(
    () => timer.durationSeconds.value,
);

const currentStatus = computed(
    () => timer.status.value,
);

const showInterruptionWarning = ref(false);

const lastInterruption = ref<{
    durationSeconds: number;
} | null>(null);

const modeLabel = computed(() => {
    return mode.value === 'focus'
        ? 'Focus Mode'
        : 'Relax Mode';
});

const statusLabel = computed(() => {
    switch (currentStatus.value) {
        case 'running':
            return mode.value === 'focus'
                ? 'Focusing'
                : 'Relaxing';

        case 'paused':
            return 'Paused';

        case 'completed':
            return 'Completed';

        default:
            return 'Ready';
    }
});

const interruptedSeconds = computed(() => {
    return interruption.interruptedDurationSeconds.value;
});

const interruptionCount = computed(() => {
    return interruption.interruptionCount.value;
});

const elapsedSeconds = computed(() => {
    return Math.max(
        0,
        timer.durationSeconds.value -
            timer.remainingSeconds.value,
    );
});

const focusedSeconds = computed(() => {
    return Math.max(
        0,
        elapsedSeconds.value -
            interruptedSeconds.value,
    );
});

const focusIntegrity = computed(() => {
    const elapsed = elapsedSeconds.value;

    if (elapsed <= 0) {
        return 100;
    }

    return Math.min(
        100,
        Math.max(
            0,
            Math.round(
                (focusedSeconds.value / elapsed) *
                    100,
            ),
        ),
    );
});

const interruptionDurationLabel = computed(() => {
    const seconds = interruptedSeconds.value;

    if (seconds < 60) {
        return `${seconds}s`;
    }

    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;

    if (remainingSeconds === 0) {
        return `${minutes}m`;
    }

    return `${minutes}m ${remainingSeconds}s`;
});

const focusedDurationLabel = computed(() => {
    const seconds = focusedSeconds.value;
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;

    if (remainingSeconds === 0) {
        return `${minutes}m`;
    }

    return `${minutes}m ${remainingSeconds}s`;
});

const interruptionWarningText = computed(() => {
    const seconds =
        lastInterruption.value?.durationSeconds ?? 0;

    if (seconds < 60) {
        return `You were away for ${seconds} seconds.`;
    }

    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;

    if (remainingSeconds === 0) {
        return `You were away for ${minutes} minutes.`;
    }

    return `You were away for ${minutes}m ${remainingSeconds}s.`;
});

const selectedDurationSeconds = computed(() => {
    if (showCustom.value) {
        return Math.max(
            1,
            Math.floor(customMinutes.value * 60),
        );
    }

    return currentDurationSeconds.value;
});

/*
|--------------------------------------------------------------------------
| LOCAL STORAGE SNAPSHOTS
|--------------------------------------------------------------------------
|
| useTimer menyimpan endAt ke localStorage.
| Kita capture raw state sebelum optimistic action sehingga
| rollback dapat mengembalikan timer ke timestamp sebelumnya.
|
*/

function captureStorage(
    key: string,
): string | null {
    if (typeof window === 'undefined') {
        return null;
    }

    return localStorage.getItem(key);
}

function restoreStorage(
    key: string,
    value: string | null,
): void {
    if (typeof window === 'undefined') {
        return;
    }

    if (value === null) {
        localStorage.removeItem(key);
        return;
    }

    localStorage.setItem(key, value);
}

function restoreTimerFromStorage(
    previousState: string | null,
): void {
    /*
     * reset terlebih dahulu untuk memastikan ticker lama berhenti.
     * Setelah itu state lama dimasukkan kembali dan timer di-restore.
     */
    timer.reset();

    restoreStorage(
        TIMER_STORAGE_KEY,
        previousState,
    );

    if (previousState !== null) {
        timer.restore();
    }
}

function persistSessionFallback(): void {
    if (
        typeof window === 'undefined' ||
        !focusSession.session.value
    ) {
        return;
    }

    const currentSession =
        focusSession.session.value;

    localStorage.setItem(
        SESSION_STORAGE_KEY,
        JSON.stringify({
            id: currentSession.id,
            mode: currentSession.mode,
            title: currentSession.title,
            status: currentSession.status,
            startedAt: currentSession.started_at,
        }),
    );
}

function restoreSessionState(
    previousSession:
        | NonNullable<typeof focusSession.session.value>
        | null,
    previousStorage: string | null,
): void {
    focusSession.session.value =
        previousSession;

    if (previousStorage !== null) {
        restoreStorage(
            SESSION_STORAGE_KEY,
            previousStorage,
        );
        return;
    }

    if (previousSession) {
        persistSessionFallback();
    }
}

function getApiErrorMessage(
    caught: unknown,
): string {
    if (caught instanceof FocusSessionApiError) {
        return caught.message;
    }

    if (caught instanceof Error) {
        return caught.message;
    }

    return 'Unable to synchronize the session with the server.';
}

/*
|--------------------------------------------------------------------------
| TIMER / DURATION
|--------------------------------------------------------------------------
*/

function selectPreset(minutes: number): void {
    if (
        currentStatus.value === 'running' ||
        currentStatus.value === 'paused' ||
        isLifecycleActionPending.value
    ) {
        return;
    }

    showCustom.value = false;

    timer.setDuration(
        minutes * 60,
    );
}

function applyCustomDuration(): void {
    const minutes = Number(
        customMinutes.value,
    );

    if (
        !Number.isFinite(minutes) ||
        minutes <= 0
    ) {
        return;
    }

    if (
        currentStatus.value === 'running' ||
        currentStatus.value === 'paused' ||
        isLifecycleActionPending.value
    ) {
        return;
    }

    customMinutes.value = Math.min(
        180,
        Math.max(
            1,
            Math.floor(minutes),
        ),
    );

    showCustom.value = true;

    timer.setDuration(
        customMinutes.value * 60,
    );
}

async function requestCompletionNotificationPermission(): Promise<void> {
    if (
        !settings.settings.value
            .completionNotificationEnabled
    ) {
        return;
    }

    const permission =
        getNotificationPermission();

    if (
        permission === 'unsupported' ||
        permission === 'denied' ||
        permission === 'granted'
    ) {
        return;
    }

    try {
        await requestNotificationPermission();
    } catch {
        /*
         * Permission failure must never prevent
         * the timer from starting.
         */
    }
}


/*
|--------------------------------------------------------------------------
| START
|--------------------------------------------------------------------------
|
| Timer berjalan langsung di browser.
| API create berjalan setelahnya.
|
*/

async function startTimer(): Promise<void> {
    if (
        currentStatus.value === 'running' ||
        currentStatus.value === 'paused' ||
        focusSession.isCreating.value
    ) {
        return;
    }

    interruption.reset();
    showInterruptionWarning.value = false;
    lastInterruption.value = null;
    isCompletionNotificationShown.value = false;
    focusSession.reset();

    /*
     * Notification permission must never block the timer.
     */
    void requestCompletionNotificationPermission();

    const startedAt = new Date();
    const durationSeconds =
        selectedDurationSeconds.value;

    const payload = {
        mode: mode.value,
        title:
            mode.value === 'focus'
                ? task.value.trim() || null
                : null,
        planned_duration_seconds:
            durationSeconds,
        started_at:
            startedAt.toISOString(),
    };

    /*
     * Start the local timer immediately.
     */
    timer.start(durationSeconds);
    interruption.syncTracking();
    hasRecoveredTimer.value = false;
    updateDocumentTitle();

    /*
     * Create the backend session in the background.
     */
    queueLifecycleSync(async () => {
        const created =
            await focusSession.start(payload);

        if (!created) {
            /*
             * Do not overwrite a newer user action.
             */
            if (
                currentStatus.value === 'running' &&
                !focusSession.session.value
            ) {
                timer.reset();
                interruption.reset();
                updateDocumentTitle();
            }

            return;
        }

        hasRecoveredTimer.value = false;
    });
}

/*
|--------------------------------------------------------------------------
| PAUSE
|--------------------------------------------------------------------------
|
| Timer pause langsung.
| Jika API gagal, state timer sebelum pause dikembalikan.
|
*/

async function pauseTimer(): Promise<void> {
    if (currentStatus.value !== 'running') {
        return;
    }

    const pausedAt = new Date().toISOString();

    /*
     * Pause locally immediately.
     */
    timer.pause();
    interruption.syncTracking();
    updateDocumentTitle();

    /*
     * Synchronize with the backend in the background.
     */
    queueLifecycleSync(async () => {
        while (focusSession.isCreating.value) {
            await new Promise<void>((resolve) => {
                window.setTimeout(resolve, 25);
            });
        }

        if (!focusSession.session.value) {
            return;
        }

        await focusSession.pause(pausedAt);
    });
}

/*
|--------------------------------------------------------------------------
| RESUME
|--------------------------------------------------------------------------
|
| Timer resume langsung.
| Jika API gagal, timer dikembalikan ke paused state.
|
*/

async function resumeTimer(): Promise<void> {
    if (currentStatus.value !== 'paused') {
        return;
    }

    const resumedAt = new Date().toISOString();

    /*
     * Resume locally immediately.
     */
    timer.resume();
    interruption.syncTracking();
    updateDocumentTitle();

    /*
     * Synchronize with the backend in the background.
     */
    queueLifecycleSync(async () => {
        while (focusSession.isCreating.value) {
            await new Promise<void>((resolve) => {
                window.setTimeout(resolve, 25);
            });
        }

        if (!focusSession.session.value) {
            return;
        }

        await focusSession.resume(resumedAt);
    });
}

/*
|--------------------------------------------------------------------------
| RESET
|--------------------------------------------------------------------------
|
| Reset aktif/paused:
| 1. Simpan state lama.
| 2. Reset UI langsung.
| 3. Cancel backend secara async.
| 4. Jika gagal, rollback.
|
| Completed:
| Tidak perlu request cancel karena session sudah selesai.
|
*/

async function resetTimer(): Promise<void> {
    if (focusSession.isCompleting.value) {
        return;
    }

    const previousSession =
        focusSession.session.value;

    const sessionId =
        previousSession?.id ?? null;

    /*
     * Reset the local timer immediately.
     */
    timer.reset();
    interruption.reset();

    focusSession.session.value = null;
    focusSession.error.value = null;

    hasRecoveredTimer.value = false;
    showInterruptionWarning.value = false;
    lastInterruption.value = null;

    updateDocumentTitle();

    if (!sessionId) {
        return;
    }

    /*
     * Cancel the backend session in the background.
     *
     * This is queued behind any previous pause/resume request.
     */
    queueLifecycleSync(async () => {
        while (focusSession.isCreating.value) {
            await new Promise<void>((resolve) => {
                window.setTimeout(resolve, 25);
            });
        }

        await cancelFocusSession(
            sessionId,
            {
                cancelled_at:
                    new Date().toISOString(),
            },
        );

        if (typeof window !== 'undefined') {
            localStorage.removeItem(
                SESSION_STORAGE_KEY,
            );
        }
    });
}

/*
|--------------------------------------------------------------------------
| DISCARD RECOVERED TIMER
|--------------------------------------------------------------------------
|
| Sama seperti Reset, tetapi khusus recovery banner.
| Backend tetap dibatalkan menggunakan ID session yang ditemukan.
|
*/

async function discardRecoveredTimer(): Promise<void> {
    if (
        isLifecycleActionPending.value ||
        focusSession.isCompleting.value
    ) {
        return;
    }

    const recoveredSession =
        focusSession.session.value;

    if (!recoveredSession) {
        timer.reset();
        interruption.reset();

        hasRecoveredTimer.value = false;
        showInterruptionWarning.value = false;
        lastInterruption.value = null;

        updateDocumentTitle();

        return;
    }

    const previousTimerState =
        captureStorage(
            TIMER_STORAGE_KEY,
        );

    const previousSessionState =
        captureStorage(
            SESSION_STORAGE_KEY,
        );

    const sessionId =
        recoveredSession.id;

    const cancelledAt =
        new Date().toISOString();

    /*
     * Optimistic UI:
     * recovery banner langsung hilang.
     */
    timer.reset();
    interruption.reset();

    focusSession.session.value =
        null;

    focusSession.error.value = null;

    hasRecoveredTimer.value = false;
    showInterruptionWarning.value = false;
    lastInterruption.value = null;

    updateDocumentTitle();

    isLifecycleActionPending.value = true;

    try {
await cancelFocusSession(
    sessionId,
    {
        cancelled_at: new Date().toISOString(),
    },
);

        if (
            typeof window !== 'undefined'
        ) {
            localStorage.removeItem(
                SESSION_STORAGE_KEY,
            );
        }
    } catch (caught) {
        /*
         * Cancel gagal.
         * Recovery dikembalikan supaya user tidak kehilangan session.
         */
        focusSession.error.value =
            getApiErrorMessage(caught);

        restoreTimerFromStorage(
            previousTimerState,
        );

        restoreSessionState(
            recoveredSession,
            previousSessionState,
        );

        hasRecoveredTimer.value = true;
    } finally {
        isLifecycleActionPending.value = false;
        updateDocumentTitle();
    }
}

/*
|--------------------------------------------------------------------------
| RECOVERED TIMER RESUME
|--------------------------------------------------------------------------
|
| Running:
| - backend sudah active
| - cukup aktifkan interruption tracking
|
| Paused:
| - timer langsung resume
| - API resume dikirim setelahnya
| - rollback jika gagal
|
*/

async function resumeRecoveredTimer(): Promise<void> {
    if (
        isLifecycleActionPending.value ||
        focusSession.isCompleting.value
    ) {
        return;
    }

    const recoveredStatus =
        currentStatus.value;

    if (
        recoveredStatus === 'running'
    ) {
        interruption.syncTracking();

        hasRecoveredTimer.value = false;

        updateDocumentTitle();

        return;
    }

    if (
        recoveredStatus !== 'paused'
    ) {
        return;
    }

    if (!focusSession.session.value) {
        return;
    }

    const previousTimerState =
        captureStorage(
            TIMER_STORAGE_KEY,
        );

    /*
     * Optimistic resume.
     */
    timer.resume();
    interruption.syncTracking();

    hasRecoveredTimer.value = false;

    isLifecycleActionPending.value = true;

    try {
        const resumed =
            await focusSession.resume(
                new Date().toISOString(),
            );

        if (resumed) {
            return;
        }

        /*
         * API gagal.
         * Kembalikan recovery ke paused.
         */
        restoreTimerFromStorage(
            previousTimerState,
        );

        interruption.syncTracking();

        hasRecoveredTimer.value = true;
    } finally {
        isLifecycleActionPending.value = false;
        updateDocumentTitle();
    }
}

/*
|--------------------------------------------------------------------------
| MODE
|--------------------------------------------------------------------------
*/

function switchMode(
    nextMode: TimerMode,
): void {
    if (
        currentStatus.value === 'running' ||
        currentStatus.value === 'paused' ||
        isActionPending.value
    ) {
        return;
    }

    mode.value = nextMode;

    if (nextMode === 'focus') {
        customMinutes.value =
            settings.settings.value
                .focusDurationMinutes;

        showCustom.value = false;

        timer.setDuration(
            settings.focusDurationSeconds.value,
        );

        return;
    }

    customMinutes.value =
        settings.settings.value
            .shortBreakDurationMinutes;

    showCustom.value = true;

    timer.setDuration(
        settings.shortBreakDurationSeconds.value,
    );
}

/*
|--------------------------------------------------------------------------
| INTERRUPTION
|--------------------------------------------------------------------------
*/

function dismissInterruptionWarning(): void {
    showInterruptionWarning.value = false;
}

async function syncCompletedInterruption(
    interruptionRecord: {
        startedAt: string;
        endedAt: string;
    },
): Promise<boolean> {
    return focusSession.recordInterruption({
        started_at: interruptionRecord.startedAt,
        ended_at: interruptionRecord.endedAt,
    });
}

/*
|--------------------------------------------------------------------------
| DOCUMENT TITLE
|--------------------------------------------------------------------------
*/

function formatClockTitle(): string {
    return timer.formattedTime.value;
}

function updateDocumentTitle(): void {
    if (
        mode.value === 'focus' &&
        interruption.isInterrupted.value
    ) {
        document.title =
            'Focus interrupted · Focura';

        return;
    }

    if (
        currentStatus.value === 'running'
    ) {
        document.title =
            `${formatClockTitle()} · Focura`;

        return;
    }

    if (
        currentStatus.value === 'paused'
    ) {
        document.title =
            `Paused · ${formatClockTitle()} · Focura`;

        return;
    }

    if (
        currentStatus.value === 'completed'
    ) {
        document.title =
            'Focus complete · Focura';

        return;
    }

    document.title =
        'Focura — Focus with intention.';
}


function showCompletionNotification(): void {
    if (
        !settings.settings.value
            .completionNotificationEnabled
    ) {
        return;
    }

    const title =
        mode.value === 'focus'
            ? 'Focus complete'
            : 'Relax complete';

    const body =
        mode.value === 'focus'
            ? 'Your focus session has finished.'
            : 'Your break has finished.';

    showNotification({
        title,
        body,
        tag: 'focura-session-complete',
    });
}

function notifySessionCompleted(): void {
    if (
        settings.settings.value
            .completionSoundEnabled
    ) {
        audio.playCompletionSound();
    }

    showCompletionNotification();
}

/*
|--------------------------------------------------------------------------
| COMPLETE
|--------------------------------------------------------------------------
*/

async function finalizeInterruptionBeforeCompletion(): Promise<void> {
    /*
     * If an interruption is still active when the timer
     * completes, finalize it first.
     *
     * This is intentionally explicit instead of relying
     * on the interruption watcher to run before completion.
     */
    if (interruption.isInterrupted.value) {
        const finalized =
            interruption.finishInterruption();

        if (finalized) {
            lastInterruption.value = {
                durationSeconds:
                    finalized.durationSeconds,
            };

            showInterruptionWarning.value =
                settings.settings.value
                    .interruptionWarningEnabled;

            await syncCompletedInterruption(
                finalized,
            );
        }
    }

    /*
     * Wait for all interruption requests, including any
     * request queued during the finalization step.
     */
    await focusSession.waitForPendingInterruptions();
}

async function completeSession(): Promise<void> {
    if (
        !focusSession.session.value ||
        focusSession.isCompleting.value
    ) {
        return;
    }

    /*
     * 8E:
     * Interruption finalization and synchronization are
     * explicitly completed before the backend completion
     * request is allowed to start.
     */
    await finalizeInterruptionBeforeCompletion();

    /*
     * The timer/session may have changed while interruption
     * synchronization was pending.
     */
    if (!focusSession.session.value) {
        return;
    }

    if (
        focusSession.session.value.status ===
        'cancelled'
    ) {
        return;
    }

    const completed =
        await focusSession.complete(
            new Date().toISOString(),
        );

    /*
     * Backend remains the source of truth.
     */
    if (!completed) {
        return;
    }

    /*
     * Notification and sound are emitted exactly once
     * for the current frontend lifecycle.
     */
    if (
        isCompletionNotificationShown.value
    ) {
        return;
    }

    isCompletionNotificationShown.value = true;

    notifySessionCompleted();
}

/*
|--------------------------------------------------------------------------
| WATCHERS
|--------------------------------------------------------------------------
*/

watch(
    () => timer.status.value,
    async (
        status,
        previousStatus,
    ) => {
        if (
            status !== 'completed' ||
            previousStatus === 'completed'
        ) {
            return;
        }

        await completeSession();

        updateDocumentTitle();
    },
);

watch(
    () => interruption.isInterrupted.value,
    async (
        isInterrupted,
        wasInterrupted,
    ) => {
        if (
            wasInterrupted &&
            !isInterrupted
        ) {
            const latest =
                interruption.interruptions.value[
                    interruption.interruptions.value.length - 1
                ];

            if (latest) {
                lastInterruption.value = {
                    durationSeconds:
                        latest.durationSeconds,
                };

                showInterruptionWarning.value =
                    settings.settings.value
                        .interruptionWarningEnabled;

                if (
    settings.settings.value
        .interruptionWarningSoundEnabled
) {
    audio.playInterruptionWarningSound();
}

                /*
                 * Normal interruption lifecycle.
                 *
                 * Completion has its own explicit finalization
                 * path, so this watcher no longer determines
                 * whether completion is safe to start.
                 */
                await syncCompletedInterruption(
                    latest,
                );
            }
        }

        updateDocumentTitle();
    },
);

/*
 * Keep the browser tab title synchronized with the
 * visible timer value while the timer is running.
 */
watch(
    () => timer.formattedTime.value,
    () => {
        updateDocumentTitle();
    },
);

/*
|--------------------------------------------------------------------------
| MOUNT / RECOVERY
|--------------------------------------------------------------------------
*/

onMounted(() => {
    const restored =
        timer.restore();

    const recoveredSession =
        focusSession.restore();

    if (
        restored &&
        recoveredSession &&
        (
            currentStatus.value ===
                'running' ||
            currentStatus.value ===
                'paused'
        )
    ) {
        mode.value =
            recoveredSession.mode;

        task.value =
            recoveredSession.title ?? '';

        focusSession.setRecoveredSession(
            recoveredSession,
        );

        hasRecoveredTimer.value =
            true;
    }

    updateDocumentTitle();
});

onUnmounted(() => {
    document.title =
        'Focura — Focus with intention.';
});
</script>

<template>
    <main
        class="min-h-screen bg-slate-0 dark:bg-slate-950 text-slate-900 dark:text-slate-100"
    >
        <div
            class="mx-auto flex min-h-screen w-full max-w-5xl flex-col px-4 py-6 sm:px-6 lg:px-8"
        >

            <!-- Recovery -->
            <section
                v-if="hasRecoveredTimer"
                class="mt-6 rounded-2xl border border-blue-200 bg-blue-50 p-4"
                role="alert"
            >
                <div
                    class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
                >
                    <div>
                        <p
                            class="text-sm font-semibold text-slate-900 dark:text-slate-100"
                        >
                            {{
                                currentStatus ===
                                'paused'
                                    ? 'A paused timer was found.'
                                    : 'An active timer was found.'
                            }}
                        </p>

                        <p
                            class="mt-1 text-sm text-slate-600 dark:text-slate-400"
                        >
                            {{
                                currentStatus ===
                                'paused'
                                    ? 'Your previous session is paused and ready to resume.'
                                    : 'Your previous timer is still running.'
                            }}
                        </p>
                    </div>

                    <div
                        class="flex flex-wrap gap-2"
                    >
                        <button
                            type="button"
                            class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
                            :disabled="isActionPending"
                            @click="resumeRecoveredTimer"
                        >
                            Resume
                        </button>

                        <button
                            type="button"
                            class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 transition hover:bg-slate-50 dark:hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-60"
                            :disabled="isActionPending"
                            @click="discardRecoveredTimer"
                        >
                            Discard
                        </button>
                    </div>
                </div>
            </section>

            <!-- Main -->
            <section
                class="flex flex-1 flex-col justify-center py-10"
            >
                <div
                    class="mx-auto w-full max-w-3xl"
                >
                    <!-- Intro -->
                    <div class="text-center">
                        <p
                            class="text-sm font-medium text-blue-600"
                        >
                            {{ modeLabel }}
                        </p>

                        <h1
                            class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-50 sm:text-4xl"
                        >
                            {{
                                mode === 'focus'
                                    ? 'Protect your attention.'
                                    : 'Give your mind a break.'
                            }}
                        </h1>

                        <p
                            class="mx-auto mt-3 max-w-xl text-sm leading-6 text-slate-500 dark:text-slate-400 sm:text-base"
                        >
                            {{
                                mode === 'focus'
                                    ? 'Stay with one thing at a time and build awareness of your focus.'
                                    : 'Step away from focused work and let your attention recover.'
                            }}
                        </p>
                    </div>

                    <!-- Mode selector -->
                    <div
                        class="mx-auto mt-8 flex w-fit rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-1"
                        role="tablist"
                        aria-label="Timer mode"
                    >
                        <button
                            type="button"
                            role="tab"
                            :aria-selected="
                                mode === 'focus'
                            "
                            class="rounded-xl px-5 py-2.5 text-sm font-medium transition"
                            :class="
                                mode === 'focus'
                                    ? 'bg-blue-600 text-white shadow-sm'
                                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-700'
                            "
                            :disabled="isActionPending"
                            @click="
                                switchMode('focus')
                            "
                        >
                            Focus
                        </button>

                        <button
                            type="button"
                            role="tab"
                            :aria-selected="
                                mode === 'relax'
                            "
                            class="rounded-xl px-5 py-2.5 text-sm font-medium transition"
                            :class="
                                mode === 'relax'
                                    ? 'bg-blue-600 text-white shadow-sm'
                                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-700'
                            "
                            :disabled="isActionPending"
                            @click="
                                switchMode('relax')
                            "
                        >
                            Relax
                        </button>
                    </div>

                    <!-- Task -->
                    <div
                        v-if="mode === 'focus'"
                        class="mx-auto mt-8 max-w-xl"
                    >
                        <label
                            for="focus-task"
                            class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300"
                        >
                            What are you focusing on?
                        </label>

                        <input
                            id="focus-task"
                            v-model="task"
                            type="text"
                            maxlength="200"
                            placeholder="e.g. Finish project documentation"
                            class="w-full rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 shadow-sm outline-none transition placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                            :disabled="isActionPending"
                        />
                    </div>

                    <!-- Duration -->
                    <div
                        v-if="currentStatus === 'idle'"
                        class="mt-8"
                    >
                        <div
                            class="flex flex-wrap items-center justify-center gap-2"
                        >
                            <button
                                v-for="preset in presets"
                                :key="preset.minutes"
                                type="button"
                                class="rounded-xl border px-4 py-2 text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-60"
                                :class="
                                    !showCustom &&
                                    currentDurationSeconds ===
                                        preset.minutes *
                                            60
                                        ? 'border-blue-600 bg-blue-50 text-blue-700'
                                        : 'border-slate-200 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 hover:border-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700'
                                "
                                :disabled="
                                    isActionPending
                                "
                                @click="
                                    selectPreset(
                                        preset.minutes,
                                    )
                                "
                            >
                                {{ preset.label }}
                            </button>

                            <button
                                type="button"
                                class="rounded-xl border px-4 py-2 text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-60"
                                :class="
                                    showCustom
                                        ? 'border-blue-600 bg-blue-50 text-blue-700'
                                        : 'border-slate-200 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 hover:border-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700'
                                "
                                :disabled="
                                    isActionPending
                                "
                                @click="
                                    showCustom = true
                                "
                            >
                                Custom
                            </button>
                        </div>

                        <div
                            v-if="showCustom"
                            class="mx-auto mt-4 flex max-w-xs items-center gap-2"
                        >
                            <label
                                for="custom-minutes"
                                class="sr-only"
                            >
                                Custom duration in minutes
                            </label>

                            <input
                                id="custom-minutes"
                                v-model.number="
                                    customMinutes
                                "
                                type="number"
                                min="1"
                                max="180"
                                inputmode="numeric"
                                class="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2.5 text-center text-sm font-medium text-slate-900 dark:text-slate-100 outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                                :disabled="
                                    isActionPending
                                "
                                @change="
                                    applyCustomDuration()
                                "
                            />

                            <span
                                class="shrink-0 text-sm text-slate-500 dark:text-slate-400"
                            >
                                minutes
                            </span>
                        </div>
                    </div>

                    <!-- Interruption warning -->
                    <div
                        v-if="
                            mode === 'focus' &&
                            showInterruptionWarning
                        "
                        class="mt-8 rounded-2xl border border-amber-200 bg-amber-50 p-4"
                        role="alert"
                        aria-live="polite"
                    >
                        <div
                            class="flex items-start gap-3"
                        >
                            <div
                                class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-amber-100 text-sm font-bold text-amber-700"
                                aria-hidden="true"
                            >
                                !
                            </div>

                            <div
                                class="min-w-0 flex-1"
                            >
                                <p
                                    class="text-sm font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    Focus interrupted.
                                </p>

                                <p
                                    class="mt-1 text-sm leading-6 text-slate-600 dark:text-slate-400"
                                >
                                    {{ interruptionWarningText }}
                                    This interruption has been
                                    recorded.
                                </p>

                                <button
                                    type="button"
                                    class="mt-3 text-sm font-medium text-blue-600 hover:text-blue-700"
                                    @click="
                                        dismissInterruptionWarning()
                                    "
                                >
                                    Resume Focus
                                </button>
                            </div>

                            <button
                                type="button"
                                class="text-slate-400 dark:text-slate-500 transition hover:text-slate-600 dark:hover:text-slate-300"
                                aria-label="Dismiss interruption warning"
                                @click="
                                    dismissInterruptionWarning()
                                "
                            >
                                ×
                            </button>
                        </div>
                    </div>

                    <!-- Timer -->
                    <div
                        class="mt-8 rounded-3xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-8 shadow-sm sm:p-12"
                    >
                        <div class="text-center">
                            <div
                                class="flex items-center justify-center gap-2"
                            >
                                <span
                                    class="inline-flex h-2.5 w-2.5 rounded-full"
                                    :class="
                                        currentStatus ===
                                        'running'
                                            ? mode ===
                                              'focus'
                                                ? 'bg-green-500'
                                                : 'bg-blue-500'
                                            : currentStatus ===
                                              'paused'
                                              ? 'bg-amber-500'
                                              : currentStatus ===
                                                'completed'
                                                ? 'bg-green-500'
                                                : 'bg-slate-300'
                                    "
                                    aria-hidden="true"
                                />

                                <span
                                    class="text-sm font-medium text-slate-500 dark:text-slate-400"
                                >
                                    {{ statusLabel }}
                                </span>
                            </div>

                            <div
                                class="mt-6 font-mono text-7xl font-semibold tracking-tight tabular-nums text-slate-950 dark:text-slate-50 sm:text-8xl"
                                role="timer"
                                aria-live="off"
                                :aria-label="
                                    `${timer.formattedTime.value} remaining`
                                "
                            >
                                {{ timer.formattedTime }}
                            </div>

                            <p
                                v-if="
                                    mode === 'focus' &&
                                    currentStatus ===
                                        'running'
                                "
                                class="mt-4 text-sm text-slate-400 dark:text-slate-500"
                            >
                                Stay with the task.
                            </p>

                            <p
                                v-else-if="
                                    mode === 'relax' &&
                                    currentStatus ===
                                        'running'
                                "
                                class="mt-4 text-sm text-slate-400 dark:text-slate-500"
                            >
                                Take your time.
                            </p>

                            <p
                                v-else-if="
                                    currentStatus ===
                                    'paused'
                                "
                                class="mt-4 text-sm text-amber-600"
                            >
                                Timer paused.
                            </p>

                            <p
                                v-else-if="
                                    currentStatus ===
                                    'completed'
                                "
                                class="mt-4 text-sm text-green-600"
                            >
                                Session complete.
                            </p>
                        </div>

                        <!-- Controls -->
                        <div
                            class="mt-8 flex flex-wrap items-center justify-center gap-3"
                        >
                            <button
                                v-if="
                                    currentStatus ===
                                    'idle'
                                "
                                type="button"
                                class="rounded-2xl bg-blue-600 px-7 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-100 disabled:cursor-not-allowed disabled:opacity-60"
                                @click="startTimer"
                            >
                                Start
                                {{
                                    mode === 'focus'
                                        ? 'Focus'
                                        : 'Relax'
                                }}
                            </button>

                            <button
                                v-else-if="
                                    currentStatus ===
                                    'running'
                                "
                                type="button"
                                class="rounded-2xl bg-slate-900 px-7 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800 focus:outline-none focus:ring-4 focus:ring-slate-200 disabled:cursor-not-allowed disabled:opacity-60"
                                @click="pauseTimer"
                            >
                                Pause
                            </button>

                            <button
                                v-else-if="
                                    currentStatus ===
                                    'paused'
                                "
                                type="button"
                                class="rounded-2xl bg-blue-600 px-7 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-100 disabled:cursor-not-allowed disabled:opacity-60"
                                @click="resumeTimer"
                            >
                                Resume
                            </button>

                            <button
                                v-if="
                                    currentStatus ===
                                        'running' ||
                                    currentStatus ===
                                        'paused' ||
                                    currentStatus ===
                                        'completed'
                                "
                                type="button"
                                class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-6 py-3 text-sm font-medium text-slate-700 dark:text-slate-300 transition hover:bg-slate-50 dark:hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-60"
                                @click="resetTimer"
                            >
                                Reset
                            </button>
                        </div>
                    </div>

                    <!-- Focus Music -->
                    <section
                        v-if="mode === 'focus'"
                        class="mt-6 rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 shadow-sm sm:p-6"
                    >
                        <div
                            class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
                        >
                            <div>
                                <p
                                    class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                                >
                                    Focus Music
                                </p>

                                <h2
                                    class="mt-1 text-base font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    Stay with your focus.
                                </h2>

                                <p
                                    class="mt-1 max-w-xl text-sm leading-6 text-slate-500 dark:text-slate-400"
                                >
                                    Play music from YouTube or Spotify
                                    while you work. Music is independent
                                    from Focus Integrity and interruptions.
                                </p>
                            </div>

                            <span
                                class="inline-flex w-fit items-center gap-2 rounded-full bg-slate-50 dark:bg-slate-800 px-3 py-1.5 text-xs font-medium text-slate-500 dark:text-slate-400"
                            >
                                <svg
                                    class="h-4 w-4"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="1.8"
                                    aria-hidden="true"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M9 18V5l12-2v13"
                                    />
                                    <circle
                                        cx="6"
                                        cy="18"
                                        r="3"
                                    />
                                    <circle
                                        cx="18"
                                        cy="16"
                                        r="3"
                                    />
                                </svg>

                                {{ focusMusic.sourceLabel }}
                            </span>
                        </div>

                        <div class="mt-5">
                            <div
                                class="flex flex-wrap gap-2"
                                role="group"
                                aria-label="Music source"
                            >
                                <button
                                    type="button"
                                    class="rounded-xl border px-4 py-2 text-sm font-medium transition"
                                    :class="
                                        focusMusic.source.value === 'off'
                                            ? 'border-blue-600 bg-blue-50 text-blue-700'
                                            : 'border-slate-200 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 hover:border-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700'
                                    "
                                    @click="
                                        focusMusic.selectSource('off')
                                    "
                                >
                                    Off
                                </button>

                                <button
                                    type="button"
                                    class="rounded-xl border px-4 py-2 text-sm font-medium transition"
                                    :class="
                                        focusMusic.source.value === 'youtube'
                                            ? 'border-blue-600 bg-blue-50 text-blue-700'
                                            : 'border-slate-200 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 hover:border-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700'
                                    "
                                    @click="
                                        focusMusic.selectSource('youtube')
                                    "
                                >
                                    YouTube
                                </button>

                                <button
                                    type="button"
                                    class="rounded-xl border px-4 py-2 text-sm font-medium transition"
                                    :class="
                                        focusMusic.source.value === 'spotify'
                                            ? 'border-blue-600 bg-blue-50 text-blue-700'
                                            : 'border-slate-200 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 hover:border-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700'
                                    "
                                    @click="
                                        focusMusic.selectSource('spotify')
                                    "
                                >
                                    Spotify
                                </button>
                            </div>

                            <div
                                v-if="
                                    focusMusic.source.value !== 'off'
                                "
                                class="mt-4"
                            >
                                <label
                                    for="focus-music-url"
                                    class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300"
                                >
                                    {{ focusMusic.sourceLabel }} URL
                                </label>

                                <div
                                    class="flex flex-col gap-2 sm:flex-row"
                                >
                                    <input
                                        id="focus-music-url"
                                        v-model="focusMusic.draftUrl.value"
                                        type="url"
                                        :placeholder="
                                            focusMusic.source.value === 'youtube'
                                                ? 'Paste a YouTube video or playlist URL'
                                                : 'Paste a Spotify track, playlist, or album URL'
                                        "
                                        class="min-w-0 flex-1 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 outline-none transition placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                                        @keyup.enter="
                                            focusMusic.loadMusic()
                                        "
                                    />

                                    <button
                                        type="button"
                                        class="rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-100"
                                        @click="
                                            focusMusic.loadMusic()
                                        "
                                    >
                                        Load music
                                    </button>
                                </div>

                                <p
                                    v-if="focusMusic.error.value"
                                    class="mt-2 text-xs font-medium leading-5 text-red-600"
                                    role="alert"
                                >
                                    {{ focusMusic.error.value }}
                                </p>
                            </div>

                            <div
                                v-if="focusMusic.hasPlayer.value"
                                class="mt-5 overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800"
                            >
                                <div
                                    class="relative w-full"
                                    :class="
                                        focusMusic.source.value === 'spotify'
                                            ? 'min-h-[152px]'
                                            : 'aspect-video'
                                    "
                                >
                                    <iframe
                                        :src="focusMusic.embedUrl.value ?? undefined"
                                        :title="
                                            `${focusMusic.sourceLabel} focus music player`
                                        "
                                        class="absolute inset-0 h-full w-full border-0"
                                        allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"
                                        loading="lazy"
                                        allowfullscreen
                                    />
                                </div>

                                <div
                                    class="flex flex-col gap-2 border-t border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
                                >
                                    <p
                                        class="min-w-0 truncate text-xs text-slate-500 dark:text-slate-400"
                                    >
                                        Music is controlled by the
                                        {{ focusMusic.sourceLabel }} player.
                                    </p>

                                    <button
                                        type="button"
                                        class="shrink-0 text-xs font-medium text-slate-500 dark:text-slate-400 transition hover:text-red-600"
                                        @click="
                                            focusMusic.clearMusic()
                                        "
                                    >
                                        Remove music
                                    </button>
                                </div>
                            </div>
                        </div>
                    </section>

                    <!-- Focus Integrity -->
                    <div
                        v-if="mode === 'focus'"
                        class="mt-6 grid gap-3 sm:grid-cols-3"
                    >
                        <div
                            class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 shadow-sm"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                            >
                                Focus Integrity
                            </p>

                            <p
                                class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-50"
                            >
                                {{ focusIntegrity }}%
                            </p>

                            <div
                                class="mt-4 h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700"
                                aria-hidden="true"
                            >
                                <div
                                    class="h-full rounded-full bg-blue-600 transition-all duration-300"
                                    :style="{
                                        width: `${focusIntegrity}%`,
                                    }"
                                />
                            </div>

                            <p
                                class="mt-2 text-xs leading-5 text-slate-400 dark:text-slate-500"
                            >
                                Based on focused time versus planned time.
                            </p>
                        </div>

                        <div
                            class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 shadow-sm"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                            >
                                Focused
                            </p>

                            <p
                                class="mt-2 text-3xl font-semibold tracking-tight text-green-600"
                            >
                                {{ focusedDurationLabel }}
                            </p>

                            <p
                                class="mt-2 text-xs leading-5 text-slate-400 dark:text-slate-500"
                            >
                                Time spent in focused work.
                            </p>
                        </div>

                        <div
                            class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 shadow-sm"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                            >
                                Interrupted
                            </p>

                            <p
                                class="mt-2 text-3xl font-semibold tracking-tight text-amber-600"
                            >
                                {{ interruptionDurationLabel }}
                            </p>

                            <p
                                class="mt-2 text-xs leading-5 text-slate-400 dark:text-slate-500"
                            >
                                {{ interruptionCount }}
                                {{
                                    interruptionCount ===
                                    1
                                        ? 'interruption'
                                        : 'interruptions'
                                }}
                            </p>
                        </div>
                    </div>

                    <!-- Current task -->
                    <div
                        v-if="
                            mode === 'focus' &&
                            task.trim()
                        "
                        class="mt-6 rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 shadow-sm"
                    >
                        <p
                            class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                        >
                            Current focus
                        </p>

                        <p
                            class="mt-2 break-words text-sm font-medium leading-6 text-slate-800 dark:text-slate-200"
                        >
                            {{ task }}
                        </p>
                    </div>

                    <!-- Philosophy -->
                    <p
                        class="mx-auto mt-8 max-w-lg text-center text-xs leading-5 text-slate-400 dark:text-slate-500"
                    >
                        {{
                            mode === 'focus'
                                ? 'Focura does not try to control your attention. It helps you become aware of it.'
                                : 'Rest is part of focused work.'
                        }}
                    </p>
                </div>
            </section>
        </div>
    </main>
</template>