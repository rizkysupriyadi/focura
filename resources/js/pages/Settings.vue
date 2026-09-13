<script setup lang="ts">
import { ref } from 'vue';
import { RouterLink } from 'vue-router';

import { useSettings } from '@/composables/useSettings';

const {
    settings,
    update,
    reset,
} = useSettings();

const feedbackMessage = ref<string | null>(null);
const durationError = ref<string | null>(null);
const notificationError = ref<string | null>(null);

function showFeedback(
    message: string,
): void {
    feedbackMessage.value = message;

    window.setTimeout(() => {
        feedbackMessage.value = null;
    }, 2500);
}

function parseDuration(
    value: string,
    minimum: number,
    maximum: number,
): number | null {
    const numericValue = Number(value);

    if (
        value.trim() === '' ||
        !Number.isFinite(numericValue)
    ) {
        return null;
    }

    const integerValue = Math.floor(
        numericValue,
    );

    if (
        integerValue < minimum ||
        integerValue > maximum
    ) {
        return null;
    }

    return integerValue;
}

function updateFocusDuration(
    event: Event,
): void {
    const target =
        event.target as HTMLInputElement;

    const value = parseDuration(
        target.value,
        1,
        180,
    );

    if (value === null) {
        durationError.value =
            'Focus duration must be between 1 and 180 minutes.';

        target.value = String(
            settings.value.focusDurationMinutes,
        );

        return;
    }

    durationError.value = null;

    update({
        focusDurationMinutes: value,
    });

    showFeedback(
        'Focus duration saved.',
    );
}

function updateShortBreakDuration(
    event: Event,
): void {
    const target =
        event.target as HTMLInputElement;

    const value = parseDuration(
        target.value,
        1,
        60,
    );

    if (value === null) {
        durationError.value =
            'Short break must be between 1 and 60 minutes.';

        target.value = String(
            settings.value
                .shortBreakDurationMinutes,
        );

        return;
    }

    durationError.value = null;

    update({
        shortBreakDurationMinutes: value,
    });

    showFeedback(
        'Short break duration saved.',
    );
}

function updateLongBreakDuration(
    event: Event,
): void {
    const target =
        event.target as HTMLInputElement;

    const value = parseDuration(
        target.value,
        1,
        120,
    );

    if (value === null) {
        durationError.value =
            'Long break must be between 1 and 120 minutes.';

        target.value = String(
            settings.value
                .longBreakDurationMinutes,
        );

        return;
    }

    durationError.value = null;

    update({
        longBreakDurationMinutes: value,
    });

    showFeedback(
        'Long break duration saved.',
    );
}

async function enableNotifications(): Promise<void> {
    notificationError.value = null;

    if (
        typeof window === 'undefined' ||
        !('Notification' in window)
    ) {
        update({
            completionNotificationEnabled: false,
        });

        notificationError.value =
            'Browser notifications are not supported on this device.';

        return;
    }

    if (Notification.permission === 'denied') {
        update({
            completionNotificationEnabled: false,
        });

        notificationError.value =
            'Notifications are blocked by your browser. Enable them in browser settings to use this feature.';

        return;
    }

    try {
        const permission =
            Notification.permission === 'default'
                ? await Notification.requestPermission()
                : Notification.permission;

        if (permission !== 'granted') {
            update({
                completionNotificationEnabled: false,
            });

            notificationError.value =
                'Notification permission was not granted.';

            return;
        }

        update({
            completionNotificationEnabled: true,
        });

        showFeedback(
            'Completion notifications enabled.',
        );
    } catch {
        update({
            completionNotificationEnabled: false,
        });

        notificationError.value =
            'Unable to request notification permission right now.';
    }
}

async function toggleNotifications(): Promise<void> {
    notificationError.value = null;

    if (
        settings.value
            .completionNotificationEnabled
    ) {
        update({
            completionNotificationEnabled: false,
        });

        showFeedback(
            'Completion notifications disabled.',
        );

        return;
    }

    await enableNotifications();
}

function updateInterruptionTracking(
    event: Event,
): void {
    const target =
        event.target as HTMLInputElement;

    update({
        interruptionTrackingEnabled:
            target.checked,
    });

    showFeedback(
        target.checked
            ? 'Interruption tracking enabled.'
            : 'Interruption tracking disabled.',
    );
}

function updateInterruptionWarnings(
    event: Event,
): void {
    const target =
        event.target as HTMLInputElement;

    update({
        interruptionWarningEnabled:
            target.checked,
    });

    showFeedback(
        target.checked
            ? 'Interruption warnings enabled.'
            : 'Interruption warnings disabled.',
    );
}

function updateCompletionSound(
    event: Event,
): void {
    const target =
        event.target as HTMLInputElement;

    update({
        completionSoundEnabled:
            target.checked,
    });

    showFeedback(
        target.checked
            ? 'Completion sound enabled.'
            : 'Completion sound disabled.',
    );
}

function updateAppearance(
    appearance: 'light' | 'dark',
): void {
    update({
        appearance,
    });

    showFeedback(
        appearance === 'dark'
            ? 'Dark mode enabled.'
            : 'Light mode enabled.',
    );
}

function resetSettings(): void {
    durationError.value = null;
    notificationError.value = null;

    reset();

    showFeedback(
        'Settings restored to defaults.',
    );
}

function updateInterruptionWarningSound(
    event: Event,
): void {
    const target =
        event.target as HTMLInputElement;

    update({
        interruptionWarningSoundEnabled:
            target.checked,
    });
}

</script>

<template>
    <main
        class="min-h-screen bg-slate-0 text-slate-900 dark:text-slate-100"
    >
        <div
            class="mx-auto max-w-4xl px-6 py-8 sm:px-8"
        >

            <section class="py-4">
                <p
                    class="text-sm font-medium text-blue-600"
                >
                    Preferences
                </p>

                <div
                    class="mt-2 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between"
                >
                    <div>
                        <h1
                            class="text-3xl font-semibold tracking-tight"
                        >
                            Settings
                        </h1>

                        <p
                            class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400"
                        >
                            Your preferences are stored locally
                            on this device.
                        </p>
                    </div>

                    <button
                        type="button"
                        class="text-sm font-medium text-slate-500 dark:text-slate-400 transition hover:text-red-600"
                        @click="resetSettings"
                    >
                        Reset defaults
                    </button>
                </div>

                <div
                    v-if="feedbackMessage"
                    class="mt-5 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-700"
                    role="status"
                    aria-live="polite"
                >
                    {{ feedbackMessage }}
                </div>

                <div class="mt-8 space-y-4">
                    <!-- Appearance -->
                    <div
                        class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 p-6"
                    >
                        <div
                            class="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between"
                        >
                            <div>
                                <h2
                                    class="font-semibold"
                                >
                                    Appearance
                                </h2>

                                <p
                                    class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400"
                                >
                                    Choose the interface appearance
                                    that feels comfortable for your
                                    workspace.
                                </p>
                            </div>

                            <div
                                class="grid grid-cols-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 p-1"
                                role="group"
                                aria-label="Appearance"
                            >
                                <button
                                    type="button"
                                    class="rounded-lg px-4 py-2 text-sm font-medium transition-colors"
                                    :class="
                                        settings.appearance === 'light'
                                            ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 shadow-sm ring-1 ring-slate-200 dark:ring-slate-600'
                                            : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100'
                                    "
                                    :aria-pressed="
                                        settings.appearance === 'light'
                                    "
                                    @click="
                                        updateAppearance('light')
                                    "
                                >
                                    Light
                                </button>

                                <button
                                    type="button"
                                    class="rounded-lg px-4 py-2 text-sm font-medium transition-colors"
                                    :class="
                                        settings.appearance === 'dark'
                                            ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 shadow-sm ring-1 ring-slate-200 dark:ring-slate-600'
                                            : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100'
                                    "
                                    :aria-pressed="
                                        settings.appearance === 'dark'
                                    "
                                    @click="
                                        updateAppearance('dark')
                                    "
                                >
                                    Dark
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Timer -->
                    <div
                        class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 p-6"
                    >
                        <h2
                            class="font-semibold"
                        >
                            Timer
                        </h2>

                        <p
                            class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400"
                        >
                            Configure the default duration
                            used when starting a new timer.
                        </p>

                        <div
                            class="mt-6 grid gap-5 sm:grid-cols-3"
                        >
                            <label
                                class="block"
                            >
                                <span
                                    class="text-sm font-medium text-slate-700 dark:text-slate-300"
                                >
                                    Focus
                                </span>

                                <div
                                    class="mt-2 flex items-center gap-2"
                                >
                                    <input
                                        :value="
                                            settings
                                                .focusDurationMinutes
                                        "
                                        type="number"
                                        min="1"
                                        max="180"
                                        inputmode="numeric"
                                        aria-label="Focus duration in minutes"
                                        class="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 px-4 py-2.5 text-sm font-medium text-slate-900 dark:text-slate-100 outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                                        @change="
                                            updateFocusDuration
                                        "
                                    />

                                    <span
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        min
                                    </span>
                                </div>
                            </label>

                            <label
                                class="block"
                            >
                                <span
                                    class="text-sm font-medium text-slate-700 dark:text-slate-300"
                                >
                                    Short break
                                </span>

                                <div
                                    class="mt-2 flex items-center gap-2"
                                >
                                    <input
                                        :value="
                                            settings
                                                .shortBreakDurationMinutes
                                        "
                                        type="number"
                                        min="1"
                                        max="60"
                                        inputmode="numeric"
                                        aria-label="Short break duration in minutes"
                                        class="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 px-4 py-2.5 text-sm font-medium text-slate-900 dark:text-slate-100 outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                                        @change="
                                            updateShortBreakDuration
                                        "
                                    />

                                    <span
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        min
                                    </span>
                                </div>
                            </label>

                            <label
                                class="block"
                            >
                                <span
                                    class="text-sm font-medium text-slate-700 dark:text-slate-300"
                                >
                                    Long break
                                </span>

                                <div
                                    class="mt-2 flex items-center gap-2"
                                >
                                    <input
                                        :value="
                                            settings
                                                .longBreakDurationMinutes
                                        "
                                        type="number"
                                        min="1"
                                        max="120"
                                        inputmode="numeric"
                                        aria-label="Long break duration in minutes"
                                        class="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 px-4 py-2.5 text-sm font-medium text-slate-900 dark:text-slate-100 outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                                        @change="
                                            updateLongBreakDuration
                                        "
                                    />

                                    <span
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        min
                                    </span>
                                </div>
                            </label>
                        </div>

                        <p
                            v-if="durationError"
                            class="mt-4 text-xs font-medium text-red-600"
                            role="alert"
                        >
                            {{ durationError }}
                        </p>

                        <p
                            class="mt-5 text-xs leading-5 text-slate-400 dark:text-slate-500"
                        >
                            Changes apply to the next timer.
                            An active or paused timer is not
                            changed.
                        </p>
                    </div>

                    <!-- Focus -->
                    <div
                        class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 p-6"
                    >
                        <h2
                            class="font-semibold"
                        >
                            Focus
                        </h2>

                        <p
                            class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400"
                        >
                            Configure how Focura measures
                            interruptions during Focus Mode.
                        </p>

                        <div
                            class="mt-6 divide-y divide-slate-100 dark:divide-slate-700"
                        >
                            <label
                                class="flex cursor-pointer items-start justify-between gap-4 py-4 first:pt-0 last:pb-0"
                            >
                                <div>
                                    <p
                                        class="text-sm font-medium text-slate-800 dark:text-slate-200"
                                    >
                                        Interruption tracking
                                    </p>

                                    <p
                                        class="mt-1 text-sm leading-5 text-slate-500 dark:text-slate-400"
                                    >
                                        Track when you leave the
                                        Focura page during a
                                        Focus session.
                                    </p>
                                </div>

                                <input
                                    type="checkbox"
                                    class="mt-1 h-4 w-4 rounded border-slate-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500"
                                    :checked="
                                        settings
                                            .interruptionTrackingEnabled
                                    "
                                    @change="
                                        updateInterruptionTracking
                                    "
                                />
                            </label>

                            <label
                                class="flex cursor-pointer items-start justify-between gap-4 py-4"
                            >
                                <div>
                                    <p
                                        class="text-sm font-medium text-slate-800 dark:text-slate-200"
                                    >
                                        Interruption warnings
                                    </p>

                                    <p
                                        class="mt-1 text-sm leading-5 text-slate-500 dark:text-slate-400"
                                    >
                                        Show a warning when you
                                        return after an
                                        interruption.
                                    </p>
                                </div>

                                <input
                                    type="checkbox"
                                    class="mt-1 h-4 w-4 rounded border-slate-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500"
                                    :checked="
                                        settings
                                            .interruptionWarningEnabled
                                    "
                                    @change="
                                        updateInterruptionWarnings
                                    "
                                />
                            </label>
                        </div>
                    </div>

                    <!-- Notifications & Audio -->
                    <div
                        class="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 p-6"
                    >
                        <h2
                            class="font-semibold"
                        >
                            Notifications &amp; Audio
                        </h2>

                        <p
                            class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400"
                        >
                            Choose how Focura should notify
                            you when a session finishes.
                        </p>

                        <div
                            class="mt-6 divide-y divide-slate-100 dark:divide-slate-700"
                        >
                            <label
                                class="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-x-6 py-4 first:pt-0"
                            >
                                <div>
                                    <p
                                        class="text-sm font-medium text-slate-800 dark:text-slate-200"
                                    >
                                        Completion notification
                                    </p>

                                    <p
                                        class="mt-1 text-sm leading-5 text-slate-500 dark:text-slate-400"
                                    >
                                        Show a browser notification
                                        when a timer completes.
                                    </p>
                                </div>

                                <input
                                    type="checkbox"
                                    class="mt-1 h-4 w-4 shrink-0 rounded border-slate-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500"
                                    :checked="
                                        settings
                                            .completionNotificationEnabled
                                    "
                                    @change="
                                        toggleNotifications
                                    "
                                />
                            </label>

                            <p
                                v-if="notificationError"
                                class="py-3 text-xs font-medium leading-5 text-amber-700 dark:text-amber-400"
                                role="alert"
                            >
                                {{ notificationError }}
                            </p>

                            <label
                                class="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-x-6 py-4"
                            >
                                <div>
                                    <p
                                        class="text-sm font-medium text-slate-800 dark:text-slate-200"
                                    >
                                        Completion sound
                                    </p>

                                    <p
                                        class="mt-1 text-sm leading-5 text-slate-500 dark:text-slate-400"
                                    >
                                        Play a short sound when a
                                        timer completes.
                                    </p>
                                </div>

                                <input
                                    type="checkbox"
                                    class="mt-1 h-4 w-4 shrink-0 rounded border-slate-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500"
                                    :checked="
                                        settings
                                            .completionSoundEnabled
                                    "
                                    @change="
                                        updateCompletionSound
                                    "
                                />
                            </label>

                            <label
                                class="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-x-6 py-4 last:pb-0"
                            >
                                <div>
                                    <p
                                        class="text-sm font-medium text-slate-800 dark:text-slate-200"
                                    >
                                        Interruption warning sound
                                    </p>

                                    <p
                                        class="mt-1 text-sm leading-5 text-slate-500 dark:text-slate-400"
                                    >
                                        Play a subtle sound when you return
                                        after an interruption.
                                    </p>
                                </div>

                                <input
                                    type="checkbox"
                                    class="mt-1 h-4 w-4 shrink-0 rounded border-slate-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500"
                                    :checked="
                                        settings
                                            .interruptionWarningSoundEnabled
                                    "
                                    @change="
                                        updateInterruptionWarningSound
                                    "
                                />
                            </label>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </main>
</template>