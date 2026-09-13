<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { RouterLink, useRoute } from 'vue-router';

import {
    FocusSessionApiError,
    getFocusSession,
} from '@/services/focusSessions';
import type {
    FocusSession,
    FocusSessionStatus,
} from '@/types/focusSession';

const route = useRoute();

const session = ref<FocusSession | null>(null);
const isLoading = ref(true);
const errorMessage = ref<string | null>(null);

function formatDuration(seconds: number): string {
    const totalSeconds = Math.max(
        0,
        Math.floor(seconds),
    );

    const minutes = Math.floor(totalSeconds / 60);
    const remainingSeconds = totalSeconds % 60;

    if (minutes === 0) {
        return `${remainingSeconds}s`;
    }

    if (remainingSeconds === 0) {
        return `${minutes}m`;
    }

    return `${minutes}m ${remainingSeconds}s`;
}

function formatDate(value: string | null): string {
    if (!value) {
        return '—';
    }

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
        return 'Unknown date';
    }

    return new Intl.DateTimeFormat('en', {
        dateStyle: 'medium',
        timeStyle: 'short',
    }).format(date);
}

function formatIntegrity(
    value: number | null,
): string {
    if (value === null) {
        return '—';
    }

    return `${Math.round(value)}%`;
}

function getModeLabel(
    mode: FocusSession['mode'],
): string {
    return mode === 'focus' ? 'Focus' : 'Relax';
}

function getStatusLabel(
    status: FocusSessionStatus,
): string {
    switch (status) {
        case 'active':
            return 'Active';

        case 'paused':
            return 'Paused';

        case 'completed':
            return 'Completed';

        case 'cancelled':
            return 'Cancelled';
    }
}

function getStatusClasses(
    status: FocusSessionStatus,
): string {
    switch (status) {
        case 'completed':
            return 'bg-emerald-50 text-emerald-700';

        case 'cancelled':
            return 'bg-red-50 text-red-700';

        case 'active':
            return 'bg-blue-50 text-blue-700';

        case 'paused':
            return 'bg-amber-50 text-amber-700';
    }
}

function getIntegrityClasses(
    value: number | null,
): string {
    if (value === null) {
        return 'text-slate-400';
    }

    if (value >= 80) {
        return 'text-emerald-600';
    }

    if (value >= 50) {
        return 'text-amber-600';
    }

    return 'text-red-600';
}

function getIntegrityBackgroundClasses(
    value: number | null,
): string {
    if (value === null) {
        return 'bg-slate-100';
    }

    if (value >= 80) {
        return 'bg-emerald-50';
    }

    if (value >= 50) {
        return 'bg-amber-50';
    }

    return 'bg-red-50';
}

function getIntegrityDescription(
    value: number | null,
): string {
    if (value === null) {
        return 'Focus Integrity is not available for this session.';
    }

    if (value >= 80) {
        return 'Strong focus consistency with limited interruption.';
    }

    if (value >= 50) {
        return 'Moderate focus consistency. Some attention was lost during the session.';
    }

    return 'Low focus consistency. Frequent or extended interruptions affected the session.';
}

function getStatusDescription(
    status: FocusSessionStatus,
): string {
    switch (status) {
        case 'completed':
            return 'This session finished normally.';

        case 'cancelled':
            return 'This session was cancelled before completion.';

        case 'active':
            return 'This session is currently active.';

        case 'paused':
            return 'This session is currently paused.';
    }
}

const focusProgressPercentage = computed(() => {
    if (!session.value) {
        return 0;
    }

    const planned =
        session.value.planned_duration_seconds;

    if (planned <= 0) {
        return 0;
    }

    return Math.min(
        100,
        Math.max(
            0,
            (session.value.focused_duration_seconds /
                planned) *
                100,
        ),
    );
});

const interruptionPercentage = computed(() => {
    if (!session.value) {
        return 0;
    }

    const actual =
        session.value.actual_duration_seconds;

    if (actual <= 0) {
        return 0;
    }

    return Math.min(
        100,
        Math.max(
            0,
            (session.value.interrupted_duration_seconds /
                actual) *
                100,
        ),
    );
});

const sessionDurationLabel = computed(() => {
    if (!session.value) {
        return '—';
    }

    if (
        session.value.actual_duration_seconds > 0
    ) {
        return formatDuration(
            session.value.actual_duration_seconds,
        );
    }

    return formatDuration(
        session.value.focused_duration_seconds,
    );
});

async function loadSession(): Promise<void> {
    isLoading.value = true;
    errorMessage.value = null;
    session.value = null;

    try {
        const rawId = route.params.id;

        if (typeof rawId !== 'string') {
            throw new Error(
                'The session ID is invalid.',
            );
        }

        const sessionId = Number(rawId);

        if (
            !Number.isInteger(sessionId) ||
            sessionId <= 0
        ) {
            throw new Error(
                'The session ID is invalid.',
            );
        }

        session.value = await getFocusSession(
            sessionId,
        );
    } catch (caught: unknown) {
        if (caught instanceof FocusSessionApiError) {
            errorMessage.value = caught.message;
        } else if (caught instanceof Error) {
            errorMessage.value = caught.message;
        } else {
            errorMessage.value =
                'Unable to load this session.';
        }
    } finally {
        isLoading.value = false;
    }
}

function retry(): void {
    void loadSession();
}

onMounted(() => {
    void loadSession();
});
</script>

<template>
    <main class="min-h-screen bg-slate-0 text-slate-900 dark:bg-slate-950 dark:text-slate-100">
        <div
            class="mx-auto max-w-5xl px-6 py-8 sm:px-8 lg:px-12"
        >

            <section class="py-4">
                <!-- Loading -->
                <div
                    v-if="isLoading"
                    class="space-y-6"
                    aria-busy="true"
                    aria-label="Loading session details"
                >
                    <div
                        class="h-4 w-24 animate-pulse rounded bg-slate-200 dark:bg-slate-600"
                    />

                    <div
                        class="h-10 w-72 animate-pulse rounded bg-slate-200 dark:bg-slate-600"
                    />

                    <div
                        class="h-5 w-52 animate-pulse rounded bg-slate-200 dark:bg-slate-600"
                    />

                    <div
                        class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
                    >
                        <div
                            v-for="index in 4"
                            :key="index"
                            class="h-32 animate-pulse rounded-2xl bg-white dark:bg-slate-900"
                        />
                    </div>

                    <div
                        class="grid gap-6 lg:grid-cols-2"
                    >
                        <div
                            class="h-64 animate-pulse rounded-2xl bg-white dark:bg-slate-900"
                        />

                        <div
                            class="h-64 animate-pulse rounded-2xl bg-white dark:bg-slate-900"
                        />
                    </div>
                </div>

                <!-- Error -->
                <div
                    v-else-if="errorMessage"
                    class="rounded-2xl border border-slate-200 bg-white p-8 text-center dark:border-slate-700 dark:bg-slate-900"
                >
                    <div
                        class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-50 text-red-600"
                        aria-hidden="true"
                    >
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.8"
                            class="h-6 w-6"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M12 9v4m0 4h.01M10.3 3.7 2.9 17a2 2 0 0 0 1.75 3h14.7a2 2 0 0 0 1.75-3L13.7 3.7a2 2 0 0 0-3.4 0Z"
                            />
                        </svg>
                    </div>

                    <h1
                        class="mt-4 text-lg font-semibold"
                    >
                        Unable to load session
                    </h1>

                    <p
                        class="mx-auto mt-2 max-w-md text-sm text-slate-500 dark:text-slate-400"
                    >
                        {{ errorMessage }}
                    </p>

                    <div
                        class="mt-5 flex flex-wrap justify-center gap-3"
                    >
                        <button
                            type="button"
                            class="rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-blue-700"
                            @click="retry"
                        >
                            Try again
                        </button>

                        <RouterLink
                            to="/sessions"
                            class="rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-700"
                        >
                            Back to history
                        </RouterLink>
                    </div>
                </div>

                <!-- Session -->
                <div
                    v-else-if="session"
                    class="space-y-6"
                >
                    <!-- Header -->
                    <div>
                        <p
                            class="text-sm font-medium text-blue-600"
                        >
                            {{ getModeLabel(session.mode) }}
                            session
                        </p>

                        <div
                            class="mt-2 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
                        >
                            <div class="min-w-0">
                                <h1
                                    class="text-3xl font-semibold tracking-tight text-slate-900 dark:text-slate-100"
                                >
                                    {{
                                        session.title ||
                                        `${getModeLabel(session.mode)} session`
                                    }}
                                </h1>

                                <p
                                    class="mt-2 text-sm text-slate-500 dark:text-slate-400"
                                >
                                    Started
                                    {{
                                        formatDate(
                                            session.started_at,
                                        )
                                    }}
                                </p>
                            </div>

                            <span
                                class="w-fit shrink-0 rounded-full px-3 py-1.5 text-sm font-medium"
                                :class="getStatusClasses( session.status, )"
                            >
                                {{
                                    getStatusLabel(
                                        session.status,
                                    )
                                }}
                            </span>
                        </div>

                        <p
                            class="mt-4 text-sm text-slate-500 dark:text-slate-400"
                        >
                            {{
                                getStatusDescription(
                                    session.status,
                                )
                            }}
                        </p>
                    </div>

                    <!-- Primary metrics -->
                    <div
                        class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
                    >
                        <div
                            class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700 dark:bg-slate-900"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                            >
                                Planned
                            </p>

                            <p
                                class="mt-2 text-2xl font-semibold text-slate-900 dark:text-slate-100"
                            >
                                {{
                                    formatDuration(
                                        session.planned_duration_seconds,
                                    )
                                }}
                            </p>

                            <p
                                class="mt-1 text-xs text-slate-400 dark:text-slate-500"
                            >
                                Intended session length
                            </p>
                        </div>

                        <div
                            class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700 dark:bg-slate-900"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                            >
                                Actual
                            </p>

                            <p
                                class="mt-2 text-2xl font-semibold text-slate-900 dark:text-slate-100"
                            >
                                {{
                                    formatDuration(
                                        session.actual_duration_seconds,
                                    )
                                }}
                            </p>

                            <p
                                class="mt-1 text-xs text-slate-400 dark:text-slate-500"
                            >
                                Time recorded for session
                            </p>
                        </div>

                        <div
                            class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700 dark:bg-slate-900"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                            >
                                Focused
                            </p>

                            <p
                                class="mt-2 text-2xl font-semibold text-slate-900 dark:text-slate-100"
                            >
                                {{
                                    formatDuration(
                                        session.focused_duration_seconds,
                                    )
                                }}
                            </p>

                            <p
                                class="mt-1 text-xs text-slate-400 dark:text-slate-500"
                            >
                                Time spent focused
                            </p>
                        </div>

                        <div
                            class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700 dark:bg-slate-900"
                            :class="getIntegrityBackgroundClasses( session.focus_integrity, )"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                            >
                                Focus Integrity
                            </p>

                            <p
                                class="mt-2 text-2xl font-semibold"
                                :class="getIntegrityClasses( session.focus_integrity, )"
                            >
                                {{
                                    formatIntegrity(
                                        session.focus_integrity,
                                    )
                                }}
                            </p>

                            <p
                                class="mt-1 text-xs text-slate-500 dark:text-slate-400"
                            >
                                Focus consistency
                            </p>
                        </div>
                    </div>

                    <!-- Focus Integrity -->
                    <section
                        class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
                    >
                        <div
                            class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
                        >
                            <div>
                                <h2
                                    class="font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    Focus Integrity
                                </h2>

                                <p
                                    class="mt-1 max-w-2xl text-sm text-slate-500 dark:text-slate-400"
                                >
                                    Focus Integrity compares focused time against
                                    the intended session duration.
                                </p>
                            </div>

                            <span
                                class="text-lg font-semibold"
                                :class="getIntegrityClasses( session.focus_integrity, )"
                            >
                                {{
                                    formatIntegrity(
                                        session.focus_integrity,
                                    )
                                }}
                            </span>
                        </div>

                        <div class="mt-6">
                            <div
                                class="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700"
                                role="progressbar"
                                aria-label="Focused time compared with planned duration"
                                :aria-valuenow="
                                    Math.round(
                                        focusProgressPercentage,
                                    )
                                "
                                aria-valuemin="0"
                                aria-valuemax="100"
                            >
                                <div
                                    class="h-full rounded-full bg-blue-600 transition-all"
                                    :style="{
                                        width: `${focusProgressPercentage}%`,
                                    }"
                                />
                            </div>

                            <div
                                class="mt-3 flex items-center justify-between gap-4 text-xs text-slate-500 dark:text-slate-400"
                            >
                                <span>
                                    {{
                                        formatDuration(
                                            session.focused_duration_seconds,
                                        )
                                    }}
                                    focused
                                </span>

                                <span>
                                    {{
                                        formatDuration(
                                            session.planned_duration_seconds,
                                        )
                                    }}
                                    planned
                                </span>
                            </div>
                        </div>

                        <div
                            class="mt-5 rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                        >
                            <p
                                class="text-sm text-slate-600 dark:text-slate-400"
                            >
                                {{
                                    getIntegrityDescription(
                                        session.focus_integrity,
                                    )
                                }}
                            </p>
                        </div>
                    </section>

                    <!-- Metrics + interruptions -->
                    <div
                        class="grid gap-6 lg:grid-cols-2"
                    >
                        <section
                            class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
                        >
                            <div>
                                <h2
                                    class="font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    Session metrics
                                </h2>

                                <p
                                    class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                                >
                                    A breakdown of how this session progressed.
                                </p>
                            </div>

                            <dl
                                class="mt-5 divide-y divide-slate-100 dark:divide-slate-700"
                            >
                                <div
                                    class="flex items-center justify-between gap-4 py-3"
                                >
                                    <dt
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        Mode
                                    </dt>

                                    <dd
                                        class="text-sm font-medium text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            getModeLabel(
                                                session.mode,
                                            )
                                        }}
                                    </dd>
                                </div>

                                <div
                                    class="flex items-center justify-between gap-4 py-3"
                                >
                                    <dt
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        Session duration
                                    </dt>

                                    <dd
                                        class="text-sm font-medium text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            sessionDurationLabel
                                        }}
                                    </dd>
                                </div>

                                <div
                                    class="flex items-center justify-between gap-4 py-3"
                                >
                                    <dt
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        Interrupted time
                                    </dt>

                                    <dd
                                        class="text-sm font-medium text-amber-600"
                                    >
                                        {{
                                            formatDuration(
                                                session.interrupted_duration_seconds,
                                            )
                                        }}
                                    </dd>
                                </div>

                                <div
                                    class="flex items-center justify-between gap-4 py-3"
                                >
                                    <dt
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        Interruptions
                                    </dt>

                                    <dd
                                        class="text-sm font-medium text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            session.interruption_count
                                        }}
                                    </dd>
                                </div>

                                <div
                                    class="flex items-center justify-between gap-4 py-3"
                                >
                                    <dt
                                        class="text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        Ended
                                    </dt>

                                    <dd
                                        class="text-right text-sm font-medium text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            formatDate(
                                                session.ended_at,
                                            )
                                        }}
                                    </dd>
                                </div>
                            </dl>

                            <div
                                class="mt-5 rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                            >
                                <div
                                    class="flex items-center justify-between gap-4"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                    >
                                        Interrupted share
                                    </p>

                                    <p
                                        class="text-sm font-semibold text-amber-600"
                                    >
                                        {{
                                            Math.round(
                                                interruptionPercentage,
                                            )
                                        }}%
                                    </p>
                                </div>

                                <div
                                    class="mt-3 h-1.5 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-600"
                                >
                                    <div
                                        class="h-full rounded-full bg-amber-400 transition-all"
                                        :style="{
                                            width: `${interruptionPercentage}%`,
                                        }"
                                    />
                                </div>
                            </div>
                        </section>

                        <section
                            class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
                        >
                            <div
                                class="flex items-start justify-between gap-4"
                            >
                                <div>
                                    <h2
                                        class="font-semibold text-slate-900 dark:text-slate-100"
                                    >
                                        Interruptions
                                    </h2>

                                    <p
                                        class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        Moments when attention left the session.
                                    </p>
                                </div>

                                <span
                                    class="shrink-0 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700"
                                >
                                    {{
                                        session.interruption_count
                                    }}
                                </span>
                            </div>

                            <div
                                v-if="
                                    !session.interruptions ||
                                    session.interruptions.length === 0
                                "
                                class="mt-5 rounded-xl bg-slate-50 p-5 text-center dark:bg-slate-800"
                            >
                                <div
                                    class="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-emerald-50 text-emerald-600"
                                    aria-hidden="true"
                                >
                                    <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        stroke="currentColor"
                                        stroke-width="1.8"
                                        class="h-5 w-5"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            d="m5 12 4 4L19 6"
                                        />
                                    </svg>
                                </div>

                                <p
                                    class="mt-3 text-sm font-medium text-slate-700 dark:text-slate-300"
                                >
                                    No interruptions recorded
                                </p>

                                <p
                                    class="mt-1 text-xs text-slate-500 dark:text-slate-400"
                                >
                                    Attention remained uninterrupted during this session.
                                </p>
                            </div>

                            <div
                                v-else
                                class="mt-5 space-y-3"
                            >
                                <div
                                    v-for="(
                                        interruption,
                                        index
                                    ) in session.interruptions"
                                    :key="
                                        interruption.id
                                    "
                                    class="rounded-xl bg-slate-50 px-4 py-3 dark:bg-slate-800"
                                >
                                    <div
                                        class="flex items-center justify-between gap-4"
                                    >
                                        <div class="min-w-0">
                                            <p
                                                class="text-sm font-medium text-slate-900 dark:text-slate-100"
                                            >
                                                Interruption
                                                {{
                                                    index + 1
                                                }}
                                            </p>

                                            <p
                                                class="mt-1 text-xs text-slate-500 dark:text-slate-400"
                                            >
                                                {{
                                                    formatDate(
                                                        interruption.started_at,
                                                    )
                                                }}
                                            </p>
                                        </div>

                                        <p
                                            class="shrink-0 text-sm font-semibold text-amber-600"
                                        >
                                            {{
                                                formatDuration(
                                                    interruption.duration_seconds,
                                                )
                                            }}
                                        </p>
                                    </div>

                                    <div
                                        class="mt-3 flex items-center justify-between gap-4 border-t border-slate-200 pt-3 text-xs text-slate-400 dark:border-slate-700 dark:text-slate-500"
                                    >
                                        <span>
                                            Started
                                        </span>

                                        <span>
                                            {{
                                                formatDate(
                                                    interruption.started_at,
                                                )
                                            }}
                                        </span>
                                    </div>

                                    <div
                                        class="mt-1 flex items-center justify-between gap-4 text-xs text-slate-400 dark:text-slate-500"
                                    >
                                        <span>
                                            Ended
                                        </span>

                                        <span>
                                            {{
                                                formatDate(
                                                    interruption.ended_at,
                                                )
                                            }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </section>
                    </div>

                    <!-- Timeline -->
                    <section
                        class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
                    >
                        <div>
                            <h2
                                class="font-semibold text-slate-900 dark:text-slate-100"
                            >
                                Session timeline
                            </h2>

                            <p
                                class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                            >
                                The recorded lifecycle of this session.
                            </p>
                        </div>

                        <div
                            class="mt-6 grid gap-4 sm:grid-cols-2"
                        >
                            <div
                                class="rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                            >
                                <div
                                    class="flex items-center gap-3"
                                >
                                    <div
                                        class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-50 text-blue-600"
                                        aria-hidden="true"
                                    >
                                        <svg
                                            xmlns="http://www.w3.org/2000/svg"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            stroke="currentColor"
                                            stroke-width="1.8"
                                            class="h-5 w-5"
                                        >
                                            <circle
                                                cx="12"
                                                cy="12"
                                                r="8.5"
                                            />

                                            <path
                                                stroke-linecap="round"
                                                d="M12 7v5l3 2"
                                            />
                                        </svg>
                                    </div>

                                    <div class="min-w-0">
                                        <p
                                            class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                        >
                                            Started
                                        </p>

                                        <p
                                            class="mt-1 text-sm font-medium text-slate-900 dark:text-slate-100"
                                        >
                                            {{
                                                formatDate(
                                                    session.started_at,
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <div
                                class="rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                            >
                                <div
                                    class="flex items-center gap-3"
                                >
                                    <div
                                        class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400"
                                        aria-hidden="true"
                                    >
                                        <svg
                                            xmlns="http://www.w3.org/2000/svg"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            stroke="currentColor"
                                            stroke-width="1.8"
                                            class="h-5 w-5"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                d="M6 6v12M18 6v12M6 12h12"
                                            />
                                        </svg>
                                    </div>

                                    <div class="min-w-0">
                                        <p
                                            class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                        >
                                            Ended
                                        </p>

                                        <p
                                            class="mt-1 text-sm font-medium text-slate-900 dark:text-slate-100"
                                        >
                                            {{
                                                formatDate(
                                                    session.ended_at,
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>

                    <!-- Footer action -->
                    <div
                        class="flex flex-wrap items-center justify-between gap-4 border-t border-slate-200 pt-6 dark:border-slate-700"
                    >
                        <p
                            class="text-sm text-slate-500 dark:text-slate-400"
                        >
                            Session details are based on the recorded session data.
                        </p>

                        <RouterLink
                            to="/sessions"
                            class="rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-700"
                        >
                            Back to history
                        </RouterLink>
                    </div>
                </div>
            </section>
        </div>
    </main>
</template>