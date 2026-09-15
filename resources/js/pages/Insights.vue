<script setup lang="ts">

import { useAuth } from '@/composables/useAuth';

import {
    computed,
    onMounted,
    ref,
} from 'vue';

import {
    FocusSessionApiError,
    getFocusInsights,
} from '@/services/focusSessions';

import {
    downloadInsightPng,
    generateInsightSharePng,
    shareInsightPng,
} from '@/services/insightShare';

import type {
    InsightShareBackground,
    InsightShareFormat,
} from '@/services/insightShare';

import type {
    FocusInsights,
    FocusInsightsRange,
    FocusInsightsTrendPoint,
} from '@/types/focusSession';

const ranges: Array<{
    value: FocusInsightsRange;
    label: string;
}> = [
    {
        value: 'today',
        label: 'Today',
    },
    {
        value: '7d',
        label: '7 days',
    },
    {
        value: '30d',
        label: '30 days',
    },
    {
        value: '90d',
        label: '90 days',
    },
    {
        value: 'all',
        label: 'All time',
    },
];

const selectedRange = ref<FocusInsightsRange>('30d');
const insights = ref<FocusInsights | null>(null);

const isLoading = ref(true);
const isChangingRange = ref(false);
const error = ref<string | null>(null);

let requestSequence = 0;

const { user } = useAuth();

const accountName = computed(
    () => user.value?.name?.trim() || 'Focura',
);

const isShareOpen = ref(false);
const shareFormats: Array<{
    value: InsightShareFormat;
    label: string;
}> = [
    {
        value: 'classic',
        label: 'Classic',
    },
    {
        value: 'minimal',
        label: 'Minimal',
    },
    {
        value: 'metrics',
        label: 'Metrics',
    },
    {
        value: 'profile',
        label: 'Profile',
    },
];

const shareFormat =
    ref<InsightShareFormat>('classic');

const shareBackground =
    ref<InsightShareBackground>('solid');

const shareTouchStartX = ref<number | null>(null);
const sharePreviewUrl = ref<string | null>(null);
const shareBlob = ref<Blob | null>(null);
const isGeneratingShare = ref(false);
const isSharingInsight = ref(false);
const shareError = ref<string | null>(null);

function openShare(): void {
    if (!insights.value || !hasCompletedSessions.value) {
        return;
    }

    shareError.value = null;
    shareFormat.value = 'classic';
    shareBackground.value = 'solid';
    isShareOpen.value = true;

    void generateSharePreview();
}

function closeShare(): void {
    isShareOpen.value = false;
    shareError.value = null;

    if (sharePreviewUrl.value) {
        URL.revokeObjectURL(sharePreviewUrl.value);
    }

    sharePreviewUrl.value = null;
    shareBlob.value = null;
}

async function generateSharePreview(): Promise<void> {
    if (!insights.value) {
        return;
    }

    isGeneratingShare.value = true;
    shareError.value = null;

    try {
        const blob = await generateInsightSharePng({
            insights: insights.value,
            range: selectedRange.value,
            format: shareFormat.value,
            background: shareBackground.value,
            accountName: accountName.value,
        });

        if (sharePreviewUrl.value) {
            URL.revokeObjectURL(sharePreviewUrl.value);
        }

        shareBlob.value = blob;
        sharePreviewUrl.value =
            URL.createObjectURL(blob);
    } catch (caught) {
        shareBlob.value = null;

        if (sharePreviewUrl.value) {
            URL.revokeObjectURL(sharePreviewUrl.value);
        }

        sharePreviewUrl.value = null;

        shareError.value =
            caught instanceof Error
                ? caught.message
                : 'Unable to generate the insight image.';
    } finally {
        isGeneratingShare.value = false;
    }
}

async function changeShareFormat(
    format: InsightShareFormat,
): Promise<void> {
    if (
        shareFormat.value === format ||
        isGeneratingShare.value
    ) {
        return;
    }

    shareFormat.value = format;

    await generateSharePreview();
}

function changeShareFormatByOffset(
    offset: number,
): void {
    if (isGeneratingShare.value) {
        return;
    }

    const currentIndex =
        shareFormats.findIndex(
            (format) =>
                format.value === shareFormat.value,
        );

    const nextIndex =
        (currentIndex + offset + shareFormats.length) %
        shareFormats.length;

    void changeShareFormat(
        shareFormats[nextIndex].value,
    );
}

function handleShareTouchStart(
    event: TouchEvent,
): void {
    shareTouchStartX.value =
        event.changedTouches[0]?.clientX ?? null;
}

function handleShareTouchEnd(
    event: TouchEvent,
): void {
    const startX = shareTouchStartX.value;
    const endX =
        event.changedTouches[0]?.clientX ?? null;

    shareTouchStartX.value = null;

    if (
        startX === null ||
        endX === null
    ) {
        return;
    }

    const distance = endX - startX;

    if (Math.abs(distance) < 45) {
        return;
    }

    if (distance < 0) {
        changeShareFormatByOffset(1);
    } else {
        changeShareFormatByOffset(-1);
    }
}

async function changeShareBackground(
    background: InsightShareBackground,
): Promise<void> {
    if (
        shareBackground.value === background ||
        isGeneratingShare.value
    ) {
        return;
    }

    shareBackground.value = background;

    await generateSharePreview();
}

async function shareInsight(): Promise<void> {
    if (
        !shareBlob.value ||
        isSharingInsight.value
    ) {
        return;
    }

    isSharingInsight.value = true;
    shareError.value = null;

    try {
        const shared = await shareInsightPng(
            shareBlob.value,
            selectedRange.value,
        );

        if (!shared) {
            downloadInsightPng(
                shareBlob.value,
                selectedRange.value,
            );
        }
    } catch (caught) {
        if (
            caught instanceof DOMException &&
            caught.name === 'AbortError'
        ) {
            return;
        }

        shareError.value =
            caught instanceof Error
                ? caught.message
                : 'Unable to share the insight image.';
    } finally {
        isSharingInsight.value = false;
    }
}

function downloadShareImage(): void {
    if (!shareBlob.value) {
        return;
    }

    downloadInsightPng(
        shareBlob.value,
        selectedRange.value,
    );
}

async function loadInsights(
    range: FocusInsightsRange,
): Promise<void> {

    const sequence = ++requestSequence;

    if (insights.value === null) {
        isLoading.value = true;
    } else {
        isChangingRange.value = true;
    }

    error.value = null;

    try {
        const result = await getFocusInsights(range);

        if (sequence !== requestSequence) {
            return;
        }

        insights.value = result;
    } catch (caught) {
        if (sequence !== requestSequence) {
            return;
        }

        if (caught instanceof FocusSessionApiError) {
            error.value = caught.message;
        } else if (caught instanceof Error) {
            error.value = caught.message;
        } else {
            error.value =
                'Unable to load your insights right now.';
        }
    } finally {
        if (sequence === requestSequence) {
            isLoading.value = false;
            isChangingRange.value = false;
        }
    }
}

async function changeRange(
    range: FocusInsightsRange,
): Promise<void> {
    if (
        range === selectedRange.value &&
        !isLoading.value
    ) {
        return;
    }

    if (isChangingRange.value) {
        return;
    }

    selectedRange.value = range;

    await loadInsights(range);
}

async function retry(): Promise<void> {
    await loadInsights(
        selectedRange.value,
    );
}

const summary = computed(() =>
    insights.value?.summary ?? {
        sessions_completed: 0,
        focus_sessions: 0,
        relax_sessions: 0,
        total_focus_time_seconds: 0,
        total_interruption_time_seconds: 0,
        average_session_duration_seconds: 0,
        average_focus_integrity: null,
        focus_consistency: null,
    },
);

const interruptionSummary = computed(() =>
    insights.value?.interruptions ?? {
        total_count: 0,
        total_duration_seconds: 0,
        average_duration_seconds: 0,
        sessions_interrupted: 0,
    },
);

const trend = computed(
    () => insights.value?.trend ?? [],
);

const normalizedTrend = computed<
    FocusInsightsTrendPoint[]
>(() => {
    const points = trend.value;

    if (points.length === 0) {
        return [];
    }

    if (
        selectedRange.value === 'all' ||
        selectedRange.value === 'today'
    ) {
        return points;
    }

    const lastDate = new Date(
        `${points[points.length - 1].date}T00:00:00`,
    );

    if (Number.isNaN(lastDate.getTime())) {
        return points;
    }

    const dayCount =
        selectedRange.value === '7d'
            ? 7
            : selectedRange.value === '30d'
                ? 30
                : 90;

    const firstDate = new Date(lastDate);
    firstDate.setDate(
        firstDate.getDate() - (dayCount - 1),
    );

    const pointMap = new Map(
        points.map((point) => [
            point.date,
            point,
        ]),
    );

    const normalized: FocusInsightsTrendPoint[] = [];

    for (
        let index = 0;
        index < dayCount;
        index += 1
    ) {
        const date = new Date(firstDate);
        date.setDate(
            firstDate.getDate() + index,
        );

        const dateKey = [
            date.getFullYear(),
            String(date.getMonth() + 1).padStart(2, '0'),
            String(date.getDate()).padStart(2, '0'),
        ].join('-');

        normalized.push(
            pointMap.get(dateKey) ?? {
                date: dateKey,
                sessions_completed: 0,
                focus_sessions: 0,
                relax_sessions: 0,
                focus_time_seconds: 0,
                interruption_time_seconds: 0,
                actual_time_seconds: 0,
                focus_integrity: null,
            },
        );
    }

    return normalized;
});

const hasCompletedSessions = computed(
    () =>
        summary.value.sessions_completed > 0,
);

const hasTrendData = computed(() =>
    normalizedTrend.value.some(
        (point) =>
            point.sessions_completed > 0 ||
            point.focus_time_seconds > 0 ||
            point.actual_time_seconds > 0,
    ),
);

const trendMaxFocusTime = computed(() =>
    Math.max(
        1,
        ...normalizedTrend.value.map(
            (point) =>
                point.focus_time_seconds,
        ),
    ),
);

const trendPoints = computed(() => {
    const points = normalizedTrend.value;

    if (points.length === 0) {
        return '';
    }

    const width = 760;
    const height = 220;
    const paddingX = 16;
    const paddingY = 20;

    const chartWidth =
        width - paddingX * 2;
    const chartHeight =
        height - paddingY * 2;

    if (points.length === 1) {
        const point = points[0];

        const x = width / 2;
        const y =
            height -
            paddingY -
            (
                point.focus_time_seconds /
                trendMaxFocusTime.value
            ) *
                chartHeight;

        return `${x},${y}`;
    }

    return points
        .map((point, index) => {
            const x =
                paddingX +
                (
                    index /
                    (points.length - 1)
                ) *
                    chartWidth;

            const y =
                height -
                paddingY -
                (
                    point.focus_time_seconds /
                    trendMaxFocusTime.value
                ) *
                    chartHeight;

            return `${x},${y}`;
        })
        .join(' ');
});

const trendAreaPoints = computed(() => {
    const points = normalizedTrend.value;

    if (points.length === 0) {
        return '';
    }

    const width = 760;
    const height = 220;
    const paddingX = 16;
    const paddingY = 20;

    const chartWidth =
        width - paddingX * 2;
    const chartHeight =
        height - paddingY * 2;

    const linePoints = points.map(
        (point, index) => {
            const x =
                points.length === 1
                    ? width / 2
                    : paddingX +
                      (
                          index /
                          (points.length - 1)
                      ) *
                          chartWidth;

            const y =
                height -
                paddingY -
                (
                    point.focus_time_seconds /
                    trendMaxFocusTime.value
                ) *
                    chartHeight;

            return `${x},${y}`;
        },
    );

    const firstX =
        points.length === 1
            ? width / 2
            : paddingX;

    const lastX =
        points.length === 1
            ? width / 2
            : width - paddingX;

    const baseline =
        height - paddingY;

    return [
        `${firstX},${baseline}`,
        ...linePoints,
        `${lastX},${baseline}`,
    ].join(' ');
});

const firstTrendDate = computed(() => {
    const first = normalizedTrend.value[0];

    return first
        ? formatShortDate(first.date)
        : '';
});

const lastTrendDate = computed(() => {
    const last =
        normalizedTrend.value[normalizedTrend.value.length - 1];

    return last
        ? formatShortDate(last.date)
        : '';
});

const averageFocusIntegrityLabel = computed(
    () =>
        summary.value.average_focus_integrity ===
        null
            ? '—'
            : `${formatNumber(
                  summary.value
                      .average_focus_integrity,
              )}%`,
);

const focusConsistencyLabel = computed(
    () =>
        summary.value.focus_consistency === null
            ? '—'
            : `${formatNumber(
                  summary.value.focus_consistency,
              )}%`,
);

function formatNumber(
    value: number,
): string {
    return new Intl.NumberFormat(
        'en-US',
        {
            maximumFractionDigits: 2,
        },
    ).format(value);
}

function formatDuration(
    seconds: number,
): string {
    const safeSeconds = Math.max(
        0,
        Math.round(seconds),
    );

    const hours = Math.floor(
        safeSeconds / 3600,
    );

    const minutes = Math.floor(
        (safeSeconds % 3600) / 60,
    );

    if (hours > 0) {
        return `${hours}h ${minutes}m`;
    }

    if (minutes > 0) {
        return `${minutes}m`;
    }

    return `${safeSeconds}s`;
}

function formatShortDate(
    value: string,
): string {
    const date = new Date(
        `${value}T00:00:00`,
    );

    if (Number.isNaN(date.getTime())) {
        return value;
    }

    return new Intl.DateTimeFormat(
        'en-US',
        {
            month: 'short',
            day: 'numeric',
        },
    ).format(date);
}

function formatTrendTooltipDate(
    value: string,
): string {
    const date = new Date(
        `${value}T00:00:00`,
    );

    if (Number.isNaN(date.getTime())) {
        return value;
    }

    return new Intl.DateTimeFormat(
        'en-US',
        {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
        },
    ).format(date);
}

function trendPointX(
    index: number,
): number {
    const width = 760;
    const paddingX = 16;
    const chartWidth =
        width - paddingX * 2;

    if (normalizedTrend.value.length <= 1) {
        return width / 2;
    }

    return (
        paddingX +
        (
            index /
            (trend.value.length - 1)
        ) *
            chartWidth
    );
}

function trendPointY(
    point: FocusInsightsTrendPoint,
): number {
    const height = 220;
    const paddingY = 20;
    const chartHeight =
        height - paddingY * 2;

    return (
        height -
        paddingY -
        (
            point.focus_time_seconds /
            trendMaxFocusTime.value
        ) *
            chartHeight
    );
}

function trendPointLabel(
    point: FocusInsightsTrendPoint,
): string {
    return [
        formatTrendTooltipDate(point.date),
        `${formatDuration(
            point.focus_time_seconds,
        )} focused`,
        `${point.sessions_completed} ${
            point.sessions_completed === 1
                ? 'session'
                : 'sessions'
        }`,
    ].join(' · ');
}

onMounted(() => {
    void loadInsights(
        selectedRange.value,
    );
});
</script>

<template>
    <main
        class="min-h-screen bg-slate-0 text-slate-900 dark:bg-slate-950 dark:text-slate-100"
    >
        <div
            class="mx-auto max-w-6xl px-6 py-8 sm:px-8 lg:px-12"
        >
            <section class="py-8 sm:py-12">
                <div
                    class="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between"
                >
                    <div>
                        <p
                            class="text-sm font-medium text-blue-600"
                        >
                            Insights
                        </p>

                        <h1
                            class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-100"
                        >
                            Your focus pattern
                        </h1>

                        <p
                            class="mt-2 max-w-xl text-sm leading-6 text-slate-500 dark:text-slate-400"
                        >
                            See how consistently you
                            protect your attention over
                            time.
                        </p>
                    </div>

                    <div
                        class="flex w-full flex-col gap-3 sm:w-auto sm:flex-row sm:items-center"
                    >
                        <div
                            class="inline-flex w-full overflow-x-auto rounded-xl border border-slate-200 bg-white p-1 shadow-sm sm:w-auto dark:border-slate-700 dark:bg-slate-900"
                            aria-label="Insights date range"
                        >
                            <button
                                v-for="range in ranges"
                                :key="range.value"
                                type="button"
                                class="whitespace-nowrap rounded-lg px-3 py-2 text-sm font-medium transition"
                                :class="selectedRange === range.value ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-700 hover:text-slate-900 dark:hover:text-slate-100'"
                                :aria-pressed="
                                    selectedRange ===
                                    range.value
                                "
                                :disabled="
                                    isLoading ||
                                    isChangingRange ||
                                    isGeneratingShare ||
                                    isSharingInsight
                                "
                                @click="
                                    changeRange(
                                        range.value,
                                    )
                                "
                            >
                                {{ range.label }}
                            </button>
                        </div>

                        <button
                            type="button"
                            class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                            :disabled="
                                isLoading ||
                                isChangingRange ||
                                isGeneratingShare ||
                                isSharingInsight ||
                                !hasCompletedSessions
                            "
                            @click="openShare"
                        >
                            <svg
                                class="h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="1.8"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M12 16V4m0 0 4.5 4.5M12 4 7.5 8.5M5 13v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5"
                                />
                            </svg>

                            {{
                                isLoading ||
                                isChangingRange
                                    ? 'Loading…'
                                    : 'Share'
                            }}
                        </button>
                    </div>
                </div>

                <div
                    v-if="error"
                    class="mt-8 rounded-2xl border border-red-200 bg-red-50 p-5"
                    role="alert"
                >
                    <div
                        class="flex items-start gap-3"
                    >
                        <div
                            class="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-red-100 text-red-600"
                        >
                            <svg
                                class="h-5 w-5"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="1.8"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M12 9v3.5m0 3h.01M10.29 3.86 2.82 17a2 2 0 0 0 1.74 3h14.88a2 2 0 0 0 1.74-3L13.71 3.86a2 2 0 0 0-3.42 0Z"
                                />
                            </svg>
                        </div>

                        <div class="min-w-0">
                            <p
                                class="font-medium text-red-900"
                            >
                                Unable to load insights
                            </p>

                            <p
                                class="mt-1 text-sm leading-6 text-red-700"
                            >
                                {{ error }}
                            </p>

                            <button
                                type="button"
                                class="mt-3 text-sm font-medium text-red-700 underline underline-offset-2 hover:text-red-900"
                                :disabled="isLoading"
                                @click="retry"
                            >
                                Try again
                            </button>
                        </div>
                    </div>
                </div>

                <div
                    v-if="isLoading"
                    class="mt-8 space-y-5"
                    aria-busy="true"
                    aria-label="Loading insights"
                >
                    <div
                        class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4"
                    >
                        <div
                            v-for="index in 4"
                            :key="index"
                            class="h-32 animate-pulse rounded-2xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"
                        />
                    </div>

                    <div
                        class="h-80 animate-pulse rounded-2xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"
                    />

                    <div
                        class="grid grid-cols-1 gap-5 lg:grid-cols-2"
                    >
                        <div
                            class="h-48 animate-pulse rounded-2xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"
                        />

                        <div
                            class="h-48 animate-pulse rounded-2xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"
                        />
                    </div>
                </div>

                <template
                    v-else-if="!error && insights"
                >
                    <div
                        class="mt-8 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4"
                    >
                        <article
                            class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                            >
                                Focus time
                            </p>

                            <p
                                class="mt-2 text-3xl font-semibold tracking-tight text-blue-600"
                            >
                                {{
                                    formatDuration(
                                        summary.total_focus_time_seconds,
                                    )
                                }}
                            </p>

                            <p
                                class="mt-2 text-xs leading-5 text-slate-400 dark:text-slate-500"
                            >
                                Focus mode only
                            </p>
                        </article>

                        <article
                            class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                            >
                                Sessions
                            </p>

                            <p
                                class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-100"
                            >
                                {{
                                    summary.sessions_completed
                                }}
                            </p>

                            <p
                                class="mt-2 text-xs leading-5 text-slate-400 dark:text-slate-500"
                            >
                                {{
                                    summary.focus_sessions
                                }}
                                focus ·
                                {{
                                    summary.relax_sessions
                                }}
                                relax
                            </p>
                        </article>

                        <article
                            class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                            >
                                Focus Integrity
                            </p>

                            <p
                                class="mt-2 text-3xl font-semibold tracking-tight text-green-600"
                            >
                                {{
                                    averageFocusIntegrityLabel
                                }}
                            </p>

                            <p
                                class="mt-2 text-xs leading-5 text-slate-400 dark:text-slate-500"
                            >
                                Average across focus
                                sessions
                            </p>
                        </article>

                        <article
                            class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900"
                        >
                            <p
                                class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                            >
                                Consistency
                            </p>

                            <p
                                class="mt-2 text-3xl font-semibold tracking-tight text-slate-950 dark:text-slate-100"
                            >
                                {{
                                    focusConsistencyLabel
                                }}
                            </p>

                            <p
                                class="mt-2 text-xs leading-5 text-slate-400 dark:text-slate-500"
                            >
                                Focused time vs actual
                                focus time
                            </p>
                        </article>
                    </div>

                    <section
                        class="mt-5 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900"
                    >
                        <div
                            class="flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between"
                        >
                            <div>
                                <h2
                                    class="text-base font-semibold text-slate-950 dark:text-slate-100"
                                >
                                    Focus over time
                                </h2>

                                <p
                                    class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                                >
                                    Daily focused time for
                                    the selected period.
                                </p>
                            </div>

                            <div
                                v-if="trend.length > 0"
                                class="text-xs text-slate-400 dark:text-slate-500"
                            >
                                {{ firstTrendDate }}
                                <span
                                    class="mx-1"
                                >
                                    →
                                </span>
                                {{ lastTrendDate }}
                            </div>
                        </div>

                        <div
                            v-if="hasTrendData"
                            class="mt-6"
                        >
                            <div
                                class="overflow-x-auto"
                            >
                                <svg
                                    class="min-w-[640px]"
                                    viewBox="0 0 760 220"
                                    preserveAspectRatio="none"
                                    role="img"
                                    aria-label="Daily focused time trend"
                                >
                                    <line
                                        x1="16"
                                        y1="20"
                                        x2="744"
                                        y2="20"
                                        stroke="currentColor"
                                        class="text-slate-100"
                                        stroke-width="1"
                                    />

                                    <line
                                        x1="16"
                                        y1="110"
                                        x2="744"
                                        y2="110"
                                        stroke="currentColor"
                                        class="text-slate-100"
                                        stroke-width="1"
                                    />

                                    <line
                                        x1="16"
                                        y1="200"
                                        x2="744"
                                        y2="200"
                                        stroke="currentColor"
                                        class="text-slate-200"
                                        stroke-width="1"
                                    />

                                    <polygon
                                        :points="
                                            trendAreaPoints
                                        "
                                        fill="currentColor"
                                        class="text-blue-50"
                                    />

                                    <polyline
                                        :points="
                                            trendPoints
                                        "
                                        fill="none"
                                        stroke="currentColor"
                                        class="text-blue-600"
                                        stroke-width="2.5"
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                    />

                                    <g
                                        v-for="(
                                            point, index
                                        ) in trend"
                                        :key="point.date"
                                    >
                                        <circle
                                            :cx="
                                                trendPointX(
                                                    index,
                                                )
                                            "
                                            :cy="
                                                trendPointY(
                                                    point,
                                                )
                                            "
                                            r="4"
                                            fill="white"
                                            stroke="currentColor"
                                            class="text-blue-600"
                                            stroke-width="2"
                                        >
                                            <title>
                                                {{
                                                    trendPointLabel(
                                                        point,
                                                    )
                                                }}
                                            </title>
                                        </circle>
                                    </g>
                                </svg>
                            </div>

                            <div
                                class="mt-3 flex items-center justify-between text-xs text-slate-400 dark:text-slate-500"
                            >
                                <span>
                                    {{ firstTrendDate }}
                                </span>

                                <span>
                                    Focused time
                                </span>

                                <span>
                                    {{ lastTrendDate }}
                                </span>
                            </div>
                        </div>

                        <div
                            v-else
                            class="mt-6 rounded-xl border border-slate-100 bg-slate-50 p-8 text-center dark:border-slate-700 dark:bg-slate-800"
                        >
                            <p
                                class="text-sm font-medium text-slate-700 dark:text-slate-300"
                            >
                                No focus activity in this
                                period
                            </p>

                            <p
                                class="mt-1 text-sm text-slate-400 dark:text-slate-500"
                            >
                                Completed focus sessions
                                will appear here.
                            </p>
                        </div>
                    </section>

                    <div
                        class="mt-5 grid grid-cols-1 gap-5 lg:grid-cols-2"
                    >
                        <section
                            class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900"
                        >
                            <div
                                class="flex items-start justify-between gap-4"
                            >
                                <div>
                                    <h2
                                        class="text-base font-semibold text-slate-950 dark:text-slate-100"
                                    >
                                        Interruptions
                                    </h2>

                                    <p
                                        class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                                    >
                                        Recorded interruptions
                                        during completed
                                        focus sessions.
                                    </p>
                                </div>

                                <div
                                    class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-50 text-amber-600"
                                >
                                    <svg
                                        class="h-5 w-5"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                        stroke-width="1.8"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            d="M12 9v4m0 3h.01M10.29 3.86 2.82 17a2 2 0 0 0 1.74 3h14.88a2 2 0 0 0 1.74-3L13.71 3.86a2 2 0 0 0-3.42 0Z"
                                        />
                                    </svg>
                                </div>
                            </div>

                            <div
                                class="mt-6 grid grid-cols-2 gap-4"
                            >
                                <div
                                    class="rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                                    >
                                        Count
                                    </p>

                                    <p
                                        class="mt-1 text-2xl font-semibold text-slate-950 dark:text-slate-100"
                                    >
                                        {{
                                            interruptionSummary.total_count
                                        }}
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                                    >
                                        Time
                                    </p>

                                    <p
                                        class="mt-1 text-2xl font-semibold text-amber-600"
                                    >
                                        {{
                                            formatDuration(
                                                interruptionSummary.total_duration_seconds,
                                            )
                                        }}
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                                    >
                                        Average
                                    </p>

                                    <p
                                        class="mt-1 text-2xl font-semibold text-slate-950 dark:text-slate-100"
                                    >
                                        {{
                                            formatDuration(
                                                interruptionSummary.average_duration_seconds,
                                            )
                                        }}
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-4 dark:bg-slate-800"
                                >
                                    <p
                                        class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400"
                                    >
                                        Sessions
                                    </p>

                                    <p
                                        class="mt-1 text-2xl font-semibold text-slate-950 dark:text-slate-100"
                                    >
                                        {{
                                            interruptionSummary.sessions_interrupted
                                        }}
                                    </p>
                                </div>
                            </div>
                        </section>

                        <section
                            class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900"
                        >
                            <h2
                                class="text-base font-semibold text-slate-950 dark:text-slate-100"
                            >
                                Session rhythm
                            </h2>

                            <p
                                class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                            >
                                A simple view of how your
                                completed sessions are
                                distributed.
                            </p>

                            <div
                                class="mt-6 space-y-5"
                            >
                                <div>
                                    <div
                                        class="flex items-center justify-between text-sm"
                                    >
                                        <span
                                            class="font-medium text-slate-700 dark:text-slate-300"
                                        >
                                            Focus
                                        </span>

                                        <span
                                            class="text-slate-500 dark:text-slate-400"
                                        >
                                            {{
                                                summary.focus_sessions
                                            }}
                                        </span>
                                    </div>

                                    <div
                                        class="mt-2 h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700"
                                    >
                                        <div
                                            class="h-full rounded-full bg-blue-600 transition-all duration-500"
                                            :style="{
                                                width: `${
                                                    summary.sessions_completed >
                                                    0
                                                        ? (summary.focus_sessions /
                                                              summary.sessions_completed) *
                                                          100
                                                        : 0
                                                }%`,
                                            }"
                                        />
                                    </div>
                                </div>

                                <div>
                                    <div
                                        class="flex items-center justify-between text-sm"
                                    >
                                        <span
                                            class="font-medium text-slate-700 dark:text-slate-300"
                                        >
                                            Relax
                                        </span>

                                        <span
                                            class="text-slate-500 dark:text-slate-400"
                                        >
                                            {{
                                                summary.relax_sessions
                                            }}
                                        </span>
                                    </div>

                                    <div
                                        class="mt-2 h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700"
                                    >
                                        <div
                                            class="h-full rounded-full bg-slate-400 transition-all duration-500"
                                            :style="{
                                                width: `${
                                                    summary.sessions_completed >
                                                    0
                                                        ? (summary.relax_sessions /
                                                              summary.sessions_completed) *
                                                          100
                                                        : 0
                                                }%`,
                                            }"
                                        />
                                    </div>
                                </div>

                                <div
                                    class="border-t border-slate-100 pt-5 dark:border-slate-700"
                                >
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <span
                                            class="text-sm text-slate-500 dark:text-slate-400"
                                        >
                                            Average session
                                        </span>

                                        <span
                                            class="text-sm font-semibold text-slate-950 dark:text-slate-100"
                                        >
                                            {{
                                                formatDuration(
                                                    summary.average_session_duration_seconds,
                                                )
                                            }}
                                        </span>
                                    </div>

                                    <div
                                        class="mt-3 flex items-center justify-between"
                                    >
                                        <span
                                            class="text-sm text-slate-500 dark:text-slate-400"
                                        >
                                            Interruption time
                                        </span>

                                        <span
                                            class="text-sm font-semibold text-amber-600"
                                        >
                                            {{
                                                formatDuration(
                                                    summary.total_interruption_time_seconds,
                                                )
                                            }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </section>
                    </div>

                    <div
                        v-if="!hasCompletedSessions"
                        class="mt-5 rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm dark:border-slate-700 dark:bg-slate-900"
                    >
                        <div
                            class="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-50 text-blue-600"
                        >
                            <svg
                                class="h-6 w-6"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="1.7"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M12 6v6l4 2m5-2a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
                                />
                            </svg>
                        </div>

                        <h2
                            class="mt-4 text-base font-semibold text-slate-950 dark:text-slate-100"
                        >
                            Your insights will grow with
                            your sessions
                        </h2>

                        <p
                            class="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500 dark:text-slate-400"
                        >
                            Complete a focus or relax
                            session to start building your
                            personal pattern.
                        </p>
                    </div>
                </template>
            </section>
        </div>
        <div
            v-if="isShareOpen"
            class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm"
            role="dialog"
            aria-modal="true"
            aria-labelledby="share-insight-title"
            @click.self="closeShare"
        >
            <div
                class="flex max-h-[calc(100vh-2rem)] w-full max-w-xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-slate-900"
            >
                <div
                    class="flex items-center justify-between border-b border-slate-200 px-5 py-4 dark:border-slate-700"
                >
                    <div>
                        <h2
                            id="share-insight-title"
                            class="text-base font-semibold text-slate-950 dark:text-slate-100"
                        >
                            Share your focus
                        </h2>

                        <p
                            class="mt-1 text-sm text-slate-500 dark:text-slate-400"
                        >
                            Choose a design and share your progress.
                        </p>
                    </div>

                    <button
                        type="button"
                        class="rounded-lg p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800 dark:hover:text-slate-200"
                        aria-label="Close share dialog"
                        @click="closeShare"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            stroke-width="1.8"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="m6 6 12 12M18 6 6 18"
                            />
                        </svg>
                    </button>
                </div>

                <div class="min-h-0 overflow-y-auto px-5 py-5">
                    <div
                        class="relative"
                        @touchstart="handleShareTouchStart"
                        @touchend="handleShareTouchEnd"
                    >
                        <button
                            type="button"
                            class="absolute left-0 top-1/2 z-10 hidden -translate-y-1/2 rounded-full border border-slate-200 bg-white p-2 text-slate-600 shadow-md transition hover:bg-slate-50 sm:flex dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                            aria-label="Previous share design"
                            :disabled="isGeneratingShare"
                            @click="changeShareFormatByOffset(-1)"
                        >
                            <svg
                                class="h-5 w-5"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="1.8"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="m15 18-6-6 6-6"
                                />
                            </svg>
                        </button>

                        <div
                            class="flex justify-center overflow-hidden px-0 sm:px-10"
                        >
                            <div
                                class="w-full max-w-[360px] overflow-hidden rounded-xl shadow-xl"
                                :class="
                                    shareBackground === 'transparent'
                                        ? 'bg-slate-200 dark:bg-slate-700'
                                        : 'bg-slate-950'
                                "
                            >
                                <div
                                    v-if="isGeneratingShare"
                                    class="flex aspect-[4/5] items-center justify-center bg-slate-950"
                                >
                                    <div class="text-center">
                                        <svg
                                            class="mx-auto h-8 w-8 animate-spin text-white"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                        >
                                            <circle
                                                class="opacity-25"
                                                cx="12"
                                                cy="12"
                                                r="10"
                                                stroke="currentColor"
                                                stroke-width="3"
                                            />
                                            <path
                                                class="opacity-90"
                                                fill="currentColor"
                                                d="M4 12a8 8 0 0 1 8-8v3a5 5 0 0 0-5 5H4Z"
                                            />
                                        </svg>

                                        <p
                                            class="mt-3 text-sm text-white/70"
                                        >
                                            Preparing your share image…
                                        </p>
                                    </div>
                                </div>

                                <img
                                    v-else-if="sharePreviewUrl"
                                    :src="sharePreviewUrl"
                                    alt="Focura focus insights share preview"
                                    class="block h-auto w-full select-none"
                                    draggable="false"
                                />

                                <div
                                    v-else
                                    class="flex aspect-[4/5] items-center justify-center bg-slate-950 p-6 text-center"
                                >
                                    <p
                                        class="text-sm text-white/70"
                                    >
                                        Preview unavailable.
                                    </p>
                                </div>
                            </div>
                        </div>

                        <button
                            type="button"
                            class="absolute right-0 top-1/2 z-10 hidden -translate-y-1/2 rounded-full border border-slate-200 bg-white p-2 text-slate-600 shadow-md transition hover:bg-slate-50 sm:flex dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                            aria-label="Next share design"
                            :disabled="isGeneratingShare"
                            @click="changeShareFormatByOffset(1)"
                        >
                            <svg
                                class="h-5 w-5"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="1.8"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="m9 18 6-6-6-6"
                                />
                            </svg>
                        </button>
                    </div>

                    <div
                        class="mt-4 flex items-center justify-center gap-2"
                    >
                        <button
                            v-for="format in shareFormats"
                            :key="format.value"
                            type="button"
                            class="rounded-full px-3.5 py-1.5 text-xs font-semibold transition"
                            :class="
                                shareFormat === format.value
                                    ? 'bg-slate-950 text-white dark:bg-white dark:text-slate-950'
                                    : 'bg-slate-100 text-slate-500 hover:text-slate-900 dark:bg-slate-800 dark:text-slate-400 dark:hover:text-slate-100'
                            "
                            :disabled="isGeneratingShare"
                            @click="changeShareFormat(format.value)"
                        >
                            {{ format.label }}
                        </button>
                    </div>

                    <div class="mt-5">
                        <p
                            class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400"
                        >
                            Background
                        </p>

                        <div
                            class="grid grid-cols-2 gap-2 rounded-xl bg-slate-100 p-1 dark:bg-slate-800"
                        >
                            <button
                                type="button"
                                class="rounded-lg px-3 py-2.5 text-sm font-medium transition"
                                :class="
                                    shareBackground === 'solid'
                                        ? 'bg-white text-slate-950 shadow-sm dark:bg-slate-700 dark:text-white'
                                        : 'text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100'
                                "
                                :disabled="isGeneratingShare"
                                @click="
                                    changeShareBackground(
                                        'solid',
                                    )
                                "
                            >
                                Solid
                            </button>

                            <button
                                type="button"
                                class="rounded-lg px-3 py-2.5 text-sm font-medium transition"
                                :class="
                                    shareBackground === 'transparent'
                                        ? 'bg-white text-slate-950 shadow-sm dark:bg-slate-700 dark:text-white'
                                        : 'text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100'
                                "
                                :disabled="isGeneratingShare"
                                @click="
                                    changeShareBackground(
                                        'transparent',
                                    )
                                "
                            >
                                Transparent
                            </button>
                        </div>
                    </div>

                    <div
                        v-if="shareError"
                        class="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm leading-6 text-red-700"
                        role="alert"
                    >
                        {{ shareError }}
                    </div>
                </div>

                <div
                    class="flex flex-col gap-2 border-t border-slate-200 px-5 py-4 sm:flex-row sm:justify-end dark:border-slate-700"
                >
                    <button
                        type="button"
                        class="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:bg-slate-800"
                        :disabled="
                            isGeneratingShare ||
                            !shareBlob
                        "
                        @click="downloadShareImage"
                    >
                        <svg
                            class="h-4 w-4"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            stroke-width="1.8"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M12 4v11m0 0 4-4m-4 4-4-4M5 20h14"
                            />
                        </svg>

                        Download PNG
                    </button>

                    <button
                        type="button"
                        class="inline-flex items-center justify-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                        :disabled="
                            isGeneratingShare ||
                            isSharingInsight ||
                            !shareBlob
                        "
                        @click="shareInsight"
                    >
                        <svg
                            v-if="!isSharingInsight"
                            class="h-4 w-4"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            stroke-width="1.8"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M12 16V4m0 0 4.5 4.5M12 4 7.5 8.5M5 13v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5"
                            />
                        </svg>

                        <svg
                            v-else
                            class="h-4 w-4 animate-spin"
                            fill="none"
                            viewBox="0 0 24 24"
                        >
                            <circle
                                class="opacity-25"
                                cx="12"
                                cy="12"
                                r="10"
                                stroke="currentColor"
                                stroke-width="3"
                            />
                            <path
                                class="opacity-90"
                                fill="currentColor"
                                d="M4 12a8 8 0 0 1 8-8v3a5 5 0 0 0-5 5H4Z"
                            />
                        </svg>

                        {{ isSharingInsight ? 'Sharing…' : 'Share image' }}
                    </button>
                </div>
            </div>
        </div>
    </main>
</template>