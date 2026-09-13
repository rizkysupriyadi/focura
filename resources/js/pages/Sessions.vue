<script setup lang="ts">
import { onMounted, ref, watch } from 'vue';
import { RouterLink } from 'vue-router';

import {
    FocusSessionApiError,
    listFocusSessions,
} from '@/services/focusSessions';
import type {
    FocusSession,
    FocusSessionMode,
    FocusSessionStatus,
} from '@/types/focusSession';

const sessions = ref<FocusSession[]>([]);
const currentPage = ref(1);
const lastPage = ref(1);
const total = ref(0);

const selectedMode = ref<FocusSessionMode | ''>('');
const selectedStatus = ref<FocusSessionStatus | ''>('completed');

const isLoading = ref(false);
const errorMessage = ref<string | null>(null);

let requestSequence = 0;

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

function getModeLabel(
    mode: FocusSessionMode,
): string {
    return mode === 'focus' ? 'Focus' : 'Relax';
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

async function loadSessions(
    page = 1,
): Promise<void> {
    const sequence = ++requestSequence;

    isLoading.value = true;
    errorMessage.value = null;

    try {
        const result = await listFocusSessions(
            {
                mode:
                    selectedMode.value === ''
                        ? undefined
                        : selectedMode.value,
                status:
                    selectedStatus.value === ''
                        ? undefined
                        : selectedStatus.value,
                page,
                per_page: 10,
            },
        );

        if (sequence !== requestSequence) {
            return;
        }

        sessions.value = result.data;
        currentPage.value = result.current_page;
        lastPage.value = result.last_page;
        total.value = result.total;
    } catch (caught: unknown) {
        if (sequence !== requestSequence) {
            return;
        }

        if (caught instanceof FocusSessionApiError) {
            errorMessage.value = caught.message;
        } else if (caught instanceof Error) {
            errorMessage.value = caught.message;
        } else {
            errorMessage.value =
                'Unable to load your session history.';
        }

        sessions.value = [];
    } finally {
        if (sequence === requestSequence) {
            isLoading.value = false;
        }
    }
}

function changePage(page: number): void {
    if (
        page < 1 ||
        page > lastPage.value ||
        page === currentPage.value ||
        isLoading.value
    ) {
        return;
    }

    void loadSessions(page);
}

function retry(): void {
    void loadSessions(currentPage.value);
}

watch(
    [selectedMode, selectedStatus],
    () => {
        void loadSessions(1);
    },
);

onMounted(() => {
    void loadSessions();
});
</script>

<template>
    <main class="min-h-screen bg-slate-0 text-slate-900 dark:bg-slate-950 dark:text-slate-100">
        <div
            class="mx-auto max-w-6xl px-6 py-8 sm:px-8 lg:px-12"
        >
            <section class="py-4">
                <p class="text-sm font-medium text-blue-600">
                    History
                </p>

                <div
                    class="mt-2 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"
                >
                    <div>
                        <h1
                            class="text-3xl font-semibold tracking-tight"
                        >
                            Focus Sessions
                        </h1>

                        <p
                            class="mt-2 text-sm text-slate-500 dark:text-slate-400"
                        >
                            Review your completed focus sessions
                            and focus consistency.
                        </p>
                    </div>

                    <div
                        v-if="!isLoading && total > 0"
                        class="text-sm text-slate-500 dark:text-slate-400"
                    >
                        {{ total }}
                        {{ total === 1 ? 'session' : 'sessions' }}
                    </div>
                </div>

                <div
                    class="mt-8 rounded-2xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"
                >
                    <div
                        class="flex flex-col gap-4 border-b border-slate-200 p-5 sm:flex-row sm:items-center sm:justify-between dark:border-slate-700"
                    >
                        <div>
                            <h2
                                class="font-semibold text-slate-900 dark:text-slate-100"
                            >
                                Session history
                            </h2>

                            <p
                                class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                            >
                                Browse your focus activity.
                            </p>
                        </div>

                        <div
                            class="flex flex-col gap-3 sm:flex-row"
                        >
                            <label class="sr-only" for="mode-filter">
                                Filter by mode
                            </label>

                            <select
                                id="mode-filter"
                                v-model="selectedMode"
                                class="rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:focus:ring-blue-950"
                            >
                                <option value="">
                                    All modes
                                </option>

                                <option value="focus">
                                    Focus
                                </option>

                                <option value="relax">
                                    Relax
                                </option>
                            </select>

                            <label
                                class="sr-only"
                                for="status-filter"
                            >
                                Filter by status
                            </label>

                            <select
                                id="status-filter"
                                v-model="selectedStatus"
                                class="rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:focus:ring-blue-950"
                            >
                                <option value="">
                                    All statuses
                                </option>

                                <option value="completed">
                                    Completed
                                </option>

                                <option value="active">
                                    Active
                                </option>

                                <option value="paused">
                                    Paused
                                </option>

                                <option value="cancelled">
                                    Cancelled
                                </option>
                            </select>
                        </div>
                    </div>

                    <!-- Loading -->
                    <div
                        v-if="isLoading"
                        class="divide-y divide-slate-100 dark:divide-slate-700"
                    >
                        <div
                            v-for="index in 5"
                            :key="index"
                            class="p-6"
                        >
                            <div
                                class="animate-pulse space-y-4"
                            >
                                <div
                                    class="flex items-center justify-between"
                                >
                                    <div
                                        class="h-4 w-24 rounded bg-slate-200 dark:bg-slate-600"
                                    />

                                    <div
                                        class="h-6 w-20 rounded-full bg-slate-200 dark:bg-slate-600"
                                    />
                                </div>

                                <div
                                    class="h-5 w-48 rounded bg-slate-200 dark:bg-slate-600"
                                />

                                <div
                                    class="h-4 w-64 rounded bg-slate-200 dark:bg-slate-600"
                                />

                                <div
                                    class="grid gap-3 sm:grid-cols-4"
                                >
                                    <div
                                        class="h-12 rounded bg-slate-100 dark:bg-slate-700"
                                    />

                                    <div
                                        class="h-12 rounded bg-slate-100 dark:bg-slate-700"
                                    />

                                    <div
                                        class="h-12 rounded bg-slate-100 dark:bg-slate-700"
                                    />

                                    <div
                                        class="h-12 rounded bg-slate-100 dark:bg-slate-700"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Error -->
                    <div
                        v-else-if="errorMessage"
                        class="p-8 text-center"
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

                        <h2
                            class="mt-4 text-lg font-semibold"
                        >
                            Unable to load session history
                        </h2>

                        <p
                            class="mx-auto mt-2 max-w-md text-sm text-slate-500 dark:text-slate-400"
                        >
                            {{ errorMessage }}
                        </p>

                        <button
                            type="button"
                            class="mt-5 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-blue-700"
                            @click="retry"
                        >
                            Try again
                        </button>
                    </div>

                    <!-- Empty -->
                    <div
                        v-else-if="sessions.length === 0"
                        class="p-8 text-center"
                    >
                        <div
                            class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-slate-500 dark:bg-slate-700 dark:text-slate-400"
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
                                    d="M12 6v6l4 2m6-2a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z"
                                />
                            </svg>
                        </div>

                        <h2
                            class="mt-4 text-lg font-semibold"
                        >
                            No sessions found
                        </h2>

                        <p
                            class="mx-auto mt-2 max-w-md text-sm text-slate-500 dark:text-slate-400"
                        >
                            {{
                                selectedMode ||
                                selectedStatus
                                    ? 'Try changing your filters or start a new focus session.'
                                    : 'Your completed focus sessions will appear here.'
                            }}
                        </p>

                        <RouterLink
                            to="/focus"
                            class="mt-5 inline-flex rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-blue-700"
                        >
                            Start a focus session
                        </RouterLink>
                    </div>

                    <!-- Sessions -->
                    <div
                        v-else
                        class="divide-y divide-slate-100 dark:divide-slate-700"
                    >
                        <RouterLink
                            v-for="session in sessions"
                            :key="session.id"
                            :to="{
                                name: 'session-detail',
                                params: {
                                    id: session.id,
                                },
                            }"
                            class="block p-6 transition hover:bg-slate-50/70 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500"
                        >
                            <div
                                class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
                            >
                                <div class="min-w-0">
                                    <div
                                        class="flex flex-wrap items-center gap-2"
                                    >
                                        <span
                                            class="text-sm font-medium text-blue-600"
                                        >
                                            {{
                                                getModeLabel(
                                                    session.mode,
                                                )
                                            }}
                                        </span>

                                        <span
                                            class="rounded-full px-2.5 py-1 text-xs font-medium"
                                            :class="getStatusClasses( session.status, )"
                                        >
                                            {{
                                                getStatusLabel(
                                                    session.status,
                                                )
                                            }}
                                        </span>
                                    </div>

                                    <h3
                                        class="mt-2 truncate text-base font-semibold text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            session.title ||
                                            `${getModeLabel(session.mode)} session`
                                        }}
                                    </h3>

                                    <p
                                        class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        {{
                                            formatDate(
                                                session.started_at,
                                            )
                                        }}
                                    </p>
                                </div>

                                <div
                                    class="flex shrink-0 items-center gap-1 text-sm font-medium text-slate-400 dark:text-slate-500"
                                >
                                    View details

                                    <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        viewBox="0 0 20 20"
                                        fill="currentColor"
                                        class="h-4 w-4"
                                        aria-hidden="true"
                                    >
                                        <path
                                            fill-rule="evenodd"
                                            d="M7.21 14.77a.75.75 0 0 1 .02-1.06L10.94 10 7.23 6.29a.75.75 0 0 1 1.06-1.06l4.24 4.24a.75.75 0 0 1 0 1.06l-4.24 4.24a.75.75 0 0 1-1.08 0Z"
                                            clip-rule="evenodd"
                                        />
                                    </svg>
                                </div>
                            </div>

                            <div
                                class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-4"
                            >
                                <div
                                    class="rounded-xl bg-slate-50 p-3 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                    >
                                        Planned
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            formatDuration(
                                                session.planned_duration_seconds,
                                            )
                                        }}
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-3 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                    >
                                        Actual
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            formatDuration(
                                                session.actual_duration_seconds,
                                            )
                                        }}
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-3 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                    >
                                        Interruptions
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            session.interruption_count
                                        }}
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-3 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                    >
                                        Focus Integrity
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold"
                                        :class="getIntegrityClasses( session.focus_integrity, )"
                                    >
                                        {{
                                            formatIntegrity(
                                                session.focus_integrity,
                                            )
                                        }}
                                    </p>
                                </div>
                            </div>
                        </RouterLink>
                    </div>

                    <!-- Pagination -->
                    <div
                        v-if="lastPage > 1"
                        class="flex items-center justify-between border-t border-slate-200 px-5 py-4 dark:border-slate-700"
                    >
                        <p
                            class="text-sm text-slate-500 dark:text-slate-400"
                        >
                            Page
                            <span
                                class="font-medium text-slate-700 dark:text-slate-300"
                            >
                                {{ currentPage }}
                            </span>
                            of
                            <span
                                class="font-medium text-slate-700 dark:text-slate-300"
                            >
                                {{ lastPage }}
                            </span>
                        </p>

                        <div class="flex gap-2">
                            <button
                                type="button"
                                :disabled="
                                    currentPage === 1 ||
                                    isLoading
                                "
                                class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-700"
                                @click="
                                    changePage(
                                        currentPage - 1,
                                    )
                                "
                            >
                                Previous
                            </button>

                            <button
                                type="button"
                                :disabled="
                                    currentPage ===
                                        lastPage ||
                                    isLoading
                                "
                                class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-700"
                                @click="
                                    changePage(
                                        currentPage + 1,
                                    )
                                "
                            >
                                Next
                            </button>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </main>
</template>