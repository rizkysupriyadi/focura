<script setup lang="ts">
import {
    computed,
    onMounted,
    ref,
    watch,
} from 'vue';
import { RouterLink } from 'vue-router';

import AppShell from '@/layouts/AppShell.vue';
import { listFocusSessions } from '@/services/focusSessions';
import type {
    FocusSession,
    FocusSessionMode,
    FocusSessionStatus,
} from '@/types/focusSession';

const sessions = ref<FocusSession[]>([]);

const currentPage = ref(1);
const lastPage = ref(1);
const total = ref(0);

const perPage = 20;

const selectedMode =
    ref<FocusSessionMode | ''>('');

const selectedStatus =
    ref<FocusSessionStatus | ''>('completed');

const selectedRange =
    ref<'today' | ''>('');

const isLoading = ref(false);
const errorMessage = ref('');

const showingFrom = computed(() => {
    return total.value === 0
        ? 0
        : (currentPage.value - 1) * perPage + 1;
});

const showingTo = computed(() => {
    return total.value === 0
        ? 0
        : Math.min(
            currentPage.value * perPage,
            total.value,
        );
});

function formatDuration(
    seconds: number,
): string {
    const totalSeconds = Math.max(
        0,
        Math.round(seconds),
    );

    const hours = Math.floor(
        totalSeconds / 3600,
    );

    const minutes = Math.floor(
        (totalSeconds % 3600) / 60,
    );

    if (hours > 0) {
        return `${hours}h ${minutes}m`;
    }

    return `${minutes}m`;
}

function formatDate(
    value: string | null,
): string {
    if (!value) {
        return '—';
    }

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
        return '—';
    }

    return new Intl.DateTimeFormat(
        'en',
        {
            dateStyle: 'medium',
            timeStyle: 'short',
        },
    ).format(date);
}

function getModeLabel(
    mode: FocusSessionMode,
): string {
    return mode === 'focus'
        ? 'Focus'
        : 'Relax';
}

function getStatusLabel(
    status: FocusSessionStatus,
): string {
    switch (status) {
        case 'completed':
            return 'Completed';

        case 'active':
            return 'Active';

        case 'paused':
            return 'Paused';

        case 'cancelled':
            return 'Cancelled';

        default:
            return status;
    }
}

function getModeClasses(
    mode: FocusSessionMode,
): string {
    if (mode === 'focus') {
        return [
            'bg-blue-50',
            'text-blue-700',
            'ring-blue-600/10',
            'dark:bg-blue-500/10',
            'dark:text-blue-300',
        ].join(' ');
    }

    return [
        'bg-slate-100',
        'text-slate-700',
        'ring-slate-600/10',
        'dark:bg-slate-800',
        'dark:text-slate-300',
    ].join(' ');
}

function getStatusClasses(
    status: FocusSessionStatus,
): string {
    switch (status) {
        case 'completed':
            return [
                'bg-emerald-50',
                'text-emerald-700',
                'ring-emerald-600/10',
                'dark:bg-emerald-500/10',
                'dark:text-emerald-300',
            ].join(' ');

        case 'active':
            return [
                'bg-blue-50',
                'text-blue-700',
                'ring-blue-600/10',
                'dark:bg-blue-500/10',
                'dark:text-blue-300',
            ].join(' ');

        case 'paused':
            return [
                'bg-amber-50',
                'text-amber-700',
                'ring-amber-600/10',
                'dark:bg-amber-500/10',
                'dark:text-amber-300',
            ].join(' ');

        case 'cancelled':
            return [
                'bg-red-50',
                'text-red-700',
                'ring-red-600/10',
                'dark:bg-red-500/10',
                'dark:text-red-300',
            ].join(' ');

        default:
            return [
                'bg-slate-100',
                'text-slate-700',
                'ring-slate-600/10',
                'dark:bg-slate-800',
                'dark:text-slate-300',
            ].join(' ');
    }
}

async function loadSessions(): Promise<void> {
    isLoading.value = true;
    errorMessage.value = '';

    try {
        const response =
            await listFocusSessions({
                page: currentPage.value,
                per_page: perPage,
                mode:
                    selectedMode.value ||
                    undefined,
                status:
                    selectedStatus.value ||
                    undefined,
                range:
                    selectedRange.value ||
                    undefined,
            });

        sessions.value = response.data;
        currentPage.value =
            response.current_page;
        lastPage.value =
            response.last_page;
        total.value =
            response.total;
    } catch (error) {
        errorMessage.value =
            error instanceof Error
                ? error.message
                : 'Unable to load sessions.';
    } finally {
        isLoading.value = false;
    }
}

function resetToFirstPage(): void {
    if (currentPage.value !== 1) {
        currentPage.value = 1;
        return;
    }

    void loadSessions();
}

function goToPreviousPage(): void {
    if (
        currentPage.value <= 1 ||
        isLoading.value
    ) {
        return;
    }

    currentPage.value -= 1;
}

function goToNextPage(): void {
    if (
        currentPage.value >= lastPage.value ||
        isLoading.value
    ) {
        return;
    }

    currentPage.value += 1;
}

watch(
    [
        selectedMode,
        selectedStatus,
        selectedRange,
    ],
    () => {
        resetToFirstPage();
    },
);

watch(
    currentPage,
    (page, previousPage) => {
        if (page === previousPage) {
            return;
        }

        void loadSessions();
    },
);

onMounted(() => {
    void loadSessions();
});
</script>

<template>
    <AppShell>
        <main
            class="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:px-8"
        >
            <div
                class="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"
            >
                <div>
                    <p
                        class="mb-2 text-sm font-medium text-blue-600 dark:text-blue-400"
                    >
                        History
                    </p>

                    <h1
                        class="text-2xl font-semibold tracking-tight text-slate-900 dark:text-slate-100"
                    >
                        Sessions
                    </h1>

                    <p
                        class="mt-2 max-w-2xl text-sm leading-6 text-slate-500 dark:text-slate-400"
                    >
                        Review your completed focus sessions and
                        understand how you spend your attention.
                    </p>
                </div>
            </div>

            <section
                class="mb-6 rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900"
                aria-label="Session filters"
            >
                <div
                    class="grid gap-4 sm:grid-cols-3"
                >
                    <label class="block">
                        <span
                            class="mb-2 block text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                        >
                            Mode
                        </span>

                        <select
                            v-model="selectedMode"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
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
                    </label>

                    <label class="block">
                        <span
                            class="mb-2 block text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                        >
                            Status
                        </span>

                        <select
                            v-model="selectedStatus"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
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
                    </label>

                    <label class="block">
                        <span
                            class="mb-2 block text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                        >
                            Date
                        </span>

                        <select
                            v-model="selectedRange"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        >
                            <option value="">
                                All time
                            </option>

                            <option value="today">
                                Today
                            </option>
                        </select>
                    </label>
                </div>
            </section>

            <div
                v-if="errorMessage"
                class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300"
                role="alert"
            >
                {{ errorMessage }}
            </div>

            <section
                class="overflow-hidden rounded-xl border border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-900"
            >
                <div
                    class="flex flex-col gap-3 border-b border-slate-200 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6 dark:border-slate-800"
                >
                    <div>
                        <h2
                            class="text-sm font-semibold text-slate-900 dark:text-slate-100"
                        >
                            Session history
                        </h2>

                        <p
                            class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                        >
                            Showing
                            {{ showingFrom }}–{{ showingTo }}
                            of
                            {{ total }}
                            sessions
                        </p>
                    </div>

                    <p
                        v-if="isLoading"
                        class="text-sm text-slate-500 dark:text-slate-400"
                        aria-live="polite"
                    >
                        Loading…
                    </p>
                </div>

                <div
                    v-if="
                        !isLoading &&
                        sessions.length === 0
                    "
                    class="px-6 py-16 text-center"
                >
                    <h3
                        class="text-sm font-semibold text-slate-900 dark:text-slate-100"
                    >
                        No sessions found
                    </h3>

                    <p
                        class="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500 dark:text-slate-400"
                    >
                        Try changing the filters or complete a focus
                        session to see it here.
                    </p>
                </div>

                <div
                    v-else
                    class="divide-y divide-slate-200 dark:divide-slate-800"
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
                        class="block px-4 py-4 transition hover:bg-slate-50 sm:px-6 dark:hover:bg-slate-800/50"
                    >
                        <div
                            class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between"
                        >
                            <div
                                class="min-w-0 flex-1"
                            >
                                <div
                                    class="flex flex-wrap items-center gap-2"
                                >
                                    <span
                                        class="inline-flex rounded-full px-2.5 py-1 text-xs font-medium ring-1 ring-inset"
                                        :class="
                                            getModeClasses(
                                                session.mode,
                                            )
                                        "
                                    >
                                        {{
                                            getModeLabel(
                                                session.mode,
                                            )
                                        }}
                                    </span>

                                    <span
                                        class="inline-flex rounded-full px-2.5 py-1 text-xs font-medium ring-1 ring-inset"
                                        :class="
                                            getStatusClasses(
                                                session.status,
                                            )
                                        "
                                    >
                                        {{
                                            getStatusLabel(
                                                session.status,
                                            )
                                        }}
                                    </span>
                                </div>

                                <h3
                                    class="mt-2 truncate text-sm font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    {{
                                        session.title ||
                                        'Untitled session'
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
                                class="flex shrink-0 items-center gap-6"
                            >
                                <div>
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                    >
                                        Duration
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold tabular-nums text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            formatDuration(
                                                session.actual_duration_seconds,
                                            )
                                        }}
                                    </p>
                                </div>

                                <div
                                    v-if="
                                        session.mode ===
                                        'focus'
                                    "
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500"
                                    >
                                        Integrity
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold tabular-nums text-slate-900 dark:text-slate-100"
                                    >
                                        {{
                                            session.focus_integrity !==
                                            null
                                                ? `${Math.round(session.focus_integrity)}%`
                                                : '—'
                                        }}
                                    </p>
                                </div>

                                <svg
                                    class="h-5 w-5 text-slate-400"
                                    viewBox="0 0 20 20"
                                    fill="currentColor"
                                    aria-hidden="true"
                                >
                                    <path
                                        fill-rule="evenodd"
                                        d="M7.21 14.77a.75.75 0 0 1 .02-1.06L10.94 10 7.23 6.29a.75.75 0 1 1 1.06-1.06l4.24 4.24a.75.75 0 0 1 0 1.06l-4.24 4.24a.75.75 0 0 1-1.06.02Z"
                                        clip-rule="evenodd"
                                    />
                                </svg>
                            </div>
                        </div>
                    </RouterLink>
                </div>

                <div
                    v-if="lastPage > 1"
                    class="flex flex-col gap-3 border-t border-slate-200 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6 dark:border-slate-800"
                >
                    <p
                        class="text-sm tabular-nums text-slate-500 dark:text-slate-400"
                    >
                        Page {{ currentPage }} of
                        {{ lastPage }}
                    </p>

                    <div
                        class="flex items-center gap-2"
                    >
                        <button
                            type="button"
                            class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                            :disabled="
                                currentPage <= 1 ||
                                isLoading
                            "
                            @click="
                                goToPreviousPage
                            "
                        >
                            Previous
                        </button>

                        <button
                            type="button"
                            class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                            :disabled="
                                currentPage >=
                                    lastPage ||
                                isLoading
                            "
                            @click="goToNextPage"
                        >
                            Next
                        </button>
                    </div>
                </div>
            </section>
        </main>
    </AppShell>
</template>