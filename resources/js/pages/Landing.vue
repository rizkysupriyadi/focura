<script setup lang="ts">
import {
    computed,
    onBeforeUnmount,
    onMounted,
    ref,
} from 'vue';
import { RouterLink } from 'vue-router';
import FocuraLogo from '@/components/FocuraLogo.vue';

const isScrolled = ref(false);
const visibleSections = ref<Record<string, boolean>>({});

const demoSeconds = ref(24 * 60 + 32);

let timerInterval: number | null = null;
let observer: IntersectionObserver | null = null;

const demoMinutes = computed(() =>
    Math.floor(demoSeconds.value / 60)
        .toString()
        .padStart(2, '0'),
);

const demoRemainingSeconds = computed(() =>
    (demoSeconds.value % 60)
        .toString()
        .padStart(2, '0'),
);

const demoProgress = computed(() => {
    const total = 25 * 60;

    return ((total - demoSeconds.value) / total) * 100;
});

function handleScroll(): void {
    isScrolled.value = window.scrollY > 20;
}

function scrollToSection(id: string): void {
    document
        .getElementById(id)
        ?.scrollIntoView({
            behavior: 'smooth',
            block: 'start',
        });
}

function isSectionVisible(id: string): boolean {
    return visibleSections.value[id] === true;
}

function setSectionVisible(id: string): void {
    if (!id || visibleSections.value[id]) {
        return;
    }

    visibleSections.value = {
        ...visibleSections.value,
        [id]: true,
    };
}

function observeSections(): void {
    const elements =
        document.querySelectorAll<HTMLElement>(
            '[data-reveal]',
        );

    if (elements.length === 0) {
        return;
    }

    if (typeof IntersectionObserver === 'undefined') {
        elements.forEach((element) => {
            if (element.id) {
                setSectionVisible(element.id);
            }
        });

        return;
    }

    observer = new IntersectionObserver(
        (entries) => {
            for (const entry of entries) {
                if (!entry.isIntersecting) {
                    continue;
                }

                const element =
                    entry.target as HTMLElement;

                if (!element.id) {
                    continue;
                }

                setSectionVisible(element.id);

                observer?.unobserve(element);
            }
        },
        {
            threshold: 0.12,
            rootMargin: '0px 0px -80px 0px',
        },
    );

    elements.forEach((element) => {
        if (element.id) {
            observer?.observe(element);
        }
    });
}

function startDemoTimer(): void {
    timerInterval = window.setInterval(() => {
        demoSeconds.value -= 1;

        if (demoSeconds.value <= 0) {
            demoSeconds.value = 25 * 60;
        }
    }, 1000);
}

onMounted(() => {
    window.addEventListener(
        'scroll',
        handleScroll,
        { passive: true },
    );

    observeSections();
    startDemoTimer();
});

onBeforeUnmount(() => {
    window.removeEventListener(
        'scroll',
        handleScroll,
    );

    observer?.disconnect();

    if (timerInterval !== null) {
        window.clearInterval(timerInterval);
    }
});
</script>

<template>
    <main
        class="min-h-screen overflow-hidden bg-white text-slate-900"
    >
        <!-- =========================================================
             NAVBAR
        ========================================================== -->

        <header
            class="fixed inset-x-0 top-0 z-50 transition-all duration-300"
            :class="
                isScrolled
                    ? 'border-b border-slate-200/80 bg-white/90 shadow-sm backdrop-blur-xl'
                    : 'bg-transparent'
            "
        >
            <div
                class="mx-auto flex h-20 max-w-7xl items-center justify-between px-5 sm:px-8 lg:px-10"
            >

<RouterLink
    to="/"
    class="group inline-flex items-center"
>
    <FocuraLogo
        :size="36"
        :show-wordmark="true"
        logo-class="bg-blue-600 text-white transition duration-300 group-hover:bg-blue-700"
        wordmark-class="text-lg font-semibold tracking-tight text-slate-950"
    />
</RouterLink>

                <nav
                    class="hidden items-center gap-8 md:flex"
                    aria-label="Main navigation"
                >
                    <button
                        type="button"
                        class="text-sm font-medium text-slate-500 transition hover:text-slate-950"
                        @click="scrollToSection('features')"
                    >
                        Features
                    </button>

                    <button
                        type="button"
                        class="text-sm font-medium text-slate-500 transition hover:text-slate-950"
                        @click="scrollToSection('how-it-works')"
                    >
                        How it works
                    </button>

                    <button
                        type="button"
                        class="text-sm font-medium text-slate-500 transition hover:text-slate-950"
                        @click="scrollToSection('insights')"
                    >
                        Insights
                    </button>
                </nav>

                <div class="flex items-center gap-2">
                    <RouterLink
                        to="/login"
                        class="hidden rounded-lg px-3.5 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-950 sm:block"
                    >
                        Log in
                    </RouterLink>

                    <RouterLink
                        to="/focus"
                        class="rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-blue-700 hover:shadow-md"
                    >
                        Start focusing
                    </RouterLink>
                </div>
            </div>
        </header>

        <!-- =========================================================
             HERO
        ========================================================== -->

        <section
            id="hero"
            class="relative overflow-hidden pt-28 sm:pt-32 lg:pt-36"
        >
            <div
                class="pointer-events-none absolute left-1/2 top-0 h-[520px] w-[900px] -translate-x-1/2 rounded-full bg-blue-50/80 blur-3xl"
            />

            <div
                class="relative mx-auto max-w-7xl px-5 sm:px-8 lg:px-10"
            >
                <div class="mx-auto max-w-4xl text-center">
                    <div
                        class="animate-fade-up inline-flex items-center gap-2 rounded-full border border-blue-100 bg-blue-50 px-3.5 py-1.5 text-xs font-semibold text-blue-700"
                    >
                        <span
                            class="h-1.5 w-1.5 animate-pulse rounded-full bg-blue-600"
                        />
                        Focus with intention.
                    </div>

                    <h1
                        class="animate-fade-up animation-delay-100 mt-7 text-5xl font-semibold tracking-[-0.04em] text-slate-950 sm:text-6xl lg:text-8xl"
                    >
                        Your attention
                        <span class="text-blue-600">
                            deserves focus.
                        </span>
                    </h1>

                    <p
                        class="animate-fade-up animation-delay-200 mx-auto mt-7 max-w-2xl text-base leading-7 text-slate-500 sm:text-lg sm:leading-8"
                    >
                        A calm workspace to focus on what matters,
                        understand interruptions, and build a clearer
                        picture of how you work.
                    </p>

                    <div
                        class="animate-fade-up animation-delay-300 mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row"
                    >
                        <RouterLink
                            to="/focus"
                            class="group flex w-full items-center justify-center gap-2 rounded-xl bg-blue-600 px-6 py-3.5 text-sm font-semibold text-white shadow-lg shadow-blue-600/15 transition duration-300 hover:-translate-y-1 hover:bg-blue-700 hover:shadow-xl hover:shadow-blue-600/20 sm:w-auto"
                        >
                            Start focusing

                            <svg
                                viewBox="0 0 20 20"
                                fill="none"
                                class="h-4 w-4 transition-transform duration-300 group-hover:translate-x-1"
                                aria-hidden="true"
                            >
                                <path
                                    d="M4 10H16M11 5L16 10L11 15"
                                    stroke="currentColor"
                                    stroke-width="1.7"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                />
                            </svg>
                        </RouterLink>

                        <button
                            type="button"
                            class="w-full rounded-xl border border-slate-200 bg-white px-6 py-3.5 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:bg-slate-50 sm:w-auto"
                            @click="scrollToSection('how-it-works')"
                        >
                            See how it works
                        </button>
                    </div>

                    <p
                        class="mt-4 text-xs font-medium text-slate-400"
                    >
                        No account required to start.
                    </p>
                </div>

                <!-- Product preview -->

                <div
                    class="animate-fade-up animation-delay-400 relative mx-auto mt-16 max-w-5xl sm:mt-20"
                >
                    <div
                        class="absolute -inset-4 rounded-[2rem] bg-blue-100/60 blur-3xl"
                    />

                    <div
                        class="relative overflow-hidden rounded-[1.5rem] border border-slate-200 bg-white shadow-2xl shadow-slate-900/10 sm:rounded-[2rem]"
                    >
                        <!-- Browser chrome -->

                        <div
                            class="flex h-11 items-center justify-between border-b border-slate-100 bg-slate-50/90 px-4 sm:h-12 sm:px-5"
                        >
                            <div class="flex items-center gap-1.5">
                                <span class="h-2.5 w-2.5 rounded-full bg-slate-300" />
                                <span class="h-2.5 w-2.5 rounded-full bg-slate-300" />
                                <span class="h-2.5 w-2.5 rounded-full bg-slate-300" />
                            </div>

                            <div
                                class="hidden h-6 w-48 rounded-md bg-white shadow-sm sm:block"
                            />

                            <span class="w-12" />
                        </div>

                        <div
                            class="grid min-h-[390px] bg-white lg:grid-cols-[210px_1fr]"
                        >
                            <!-- Sidebar -->

                            <aside
                                class="hidden border-r border-slate-100 bg-slate-50/50 p-5 lg:block"
                            >
                                <div class="flex items-center gap-2">
<div class="flex items-center">
    <FocuraLogo
        :size="28"
        :show-wordmark="true"
        logo-class="bg-blue-600 text-white"
        wordmark-class="text-sm font-semibold text-slate-900"
    />
</div>
                                </div>

                                <div class="mt-10 space-y-1">
                                    <div
                                        class="flex items-center gap-2 rounded-lg bg-blue-50 px-3 py-2 text-xs font-semibold text-blue-700"
                                    >
                                        <span class="h-1.5 w-1.5 rounded-full bg-blue-600" />
                                        Focus
                                    </div>

                                    <div
                                        class="px-3 py-2 text-xs font-medium text-slate-400"
                                    >
                                        Sessions
                                    </div>

                                    <div
                                        class="px-3 py-2 text-xs font-medium text-slate-400"
                                    >
                                        Insights
                                    </div>
                                </div>

                                <div
                                    class="mt-20 rounded-xl border border-slate-200 bg-white p-3"
                                >
                                    <p
                                        class="text-[10px] font-medium text-slate-400"
                                    >
                                        TODAY
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-900"
                                    >
                                        2h 18m focused
                                    </p>

                                    <div
                                        class="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-100"
                                    >
                                        <div
                                            class="h-full w-[74%] rounded-full bg-blue-600"
                                        />
                                    </div>
                                </div>
                            </aside>

                            <!-- Main preview -->

                            <div class="p-5 sm:p-8">
                                <div
                                    class="flex items-center justify-between"
                                >
                                    <div>
                                        <p
                                            class="text-xs font-medium text-slate-400"
                                        >
                                            FOCUS SESSION
                                        </p>

                                        <h3
                                            class="mt-1 text-base font-semibold text-slate-950 sm:text-lg"
                                        >
                                            Deep work
                                        </h3>
                                    </div>

                                    <span
                                        class="rounded-full bg-emerald-50 px-2.5 py-1 text-[10px] font-semibold text-emerald-700"
                                    >
                                        Focusing
                                    </span>
                                </div>

                                <div
                                    class="mx-auto mt-7 max-w-md rounded-2xl border border-slate-100 bg-slate-50/70 p-5 sm:p-7"
                                >
                                    <div
                                        class="relative mx-auto flex h-44 w-44 items-center justify-center rounded-full sm:h-52 sm:w-52"
                                    >
                                        <svg
                                            viewBox="0 0 220 220"
                                            class="absolute inset-0 h-full w-full -rotate-90"
                                            aria-hidden="true"
                                        >
                                            <circle
                                                cx="110"
                                                cy="110"
                                                r="94"
                                                fill="none"
                                                stroke="#e2e8f0"
                                                stroke-width="7"
                                            />

                                            <circle
                                                cx="110"
                                                cy="110"
                                                r="94"
                                                fill="none"
                                                stroke="#2563eb"
                                                stroke-width="7"
                                                stroke-linecap="round"
                                                :stroke-dasharray="590"
                                                :stroke-dashoffset="
                                                    590 -
                                                    (590 * demoProgress) /
                                                        100
                                                "
                                                class="transition-all duration-1000"
                                            />
                                        </svg>

                                        <div class="text-center">
                                            <p
                                                class="text-3xl font-semibold tracking-tight text-slate-950 sm:text-4xl"
                                            >
                                                {{ demoMinutes }}:{{
                                                    demoRemainingSeconds
                                                }}
                                            </p>

                                            <p
                                                class="mt-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-slate-400"
                                            >
                                                Remaining
                                            </p>
                                        </div>
                                    </div>

                                    <div class="mt-6 text-center">
                                        <p
                                            class="text-xs font-medium text-slate-400"
                                        >
                                            Stay with the work.
                                        </p>
                                    </div>
                                </div>

                                <div
                                    class="mt-5 grid grid-cols-3 gap-2 sm:gap-3"
                                >
                                    <div
                                        class="rounded-xl border border-slate-100 bg-white p-3 text-center"
                                    >
                                        <p
                                            class="text-[10px] font-medium text-slate-400"
                                        >
                                            Planned
                                        </p>

                                        <p
                                            class="mt-1 text-sm font-semibold text-slate-900"
                                        >
                                            25 min
                                        </p>
                                    </div>

                                    <div
                                        class="rounded-xl border border-slate-100 bg-white p-3 text-center"
                                    >
                                        <p
                                            class="text-[10px] font-medium text-slate-400"
                                        >
                                            Interruptions
                                        </p>

                                        <p
                                            class="mt-1 text-sm font-semibold text-slate-900"
                                        >
                                            1
                                        </p>
                                    </div>

                                    <div
                                        class="rounded-xl border border-slate-100 bg-white p-3 text-center"
                                    >
                                        <p
                                            class="text-[10px] font-medium text-slate-400"
                                        >
                                            Integrity
                                        </p>

                                        <p
                                            class="mt-1 text-sm font-semibold text-blue-600"
                                        >
                                            92%
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div
                    class="mx-auto mt-8 flex max-w-xl flex-wrap items-center justify-center gap-x-8 gap-y-3 text-xs font-medium text-slate-400"
                >
                    <span>Intentional</span>
                    <span class="h-1 w-1 rounded-full bg-slate-300" />
                    <span>Private</span>
                    <span class="h-1 w-1 rounded-full bg-slate-300" />
                    <span>Simple</span>
                    <span class="h-1 w-1 rounded-full bg-slate-300" />
                    <span>No distractions</span>
                </div>
            </div>
        </section>

        <!-- =========================================================
             PROBLEM / ABOUT
        ========================================================== -->

        <section
            id="about"
            class="border-y border-slate-100 bg-slate-50/60"
        >
            <div
                class="mx-auto grid max-w-7xl gap-12 px-5 py-24 sm:px-8 lg:grid-cols-2 lg:items-center lg:px-10 lg:py-32"
            >
                <div
                    id="about-copy"
                    data-reveal
                    class="transition-all duration-700"
                    :class="
                        isSectionVisible('about-copy')
                            ? 'translate-y-0 opacity-100'
                            : 'translate-y-8 opacity-0'
                    "
                >
                    <span
                        class="text-xs font-bold uppercase tracking-[0.18em] text-blue-600"
                    >
                        Why Focura
                    </span>

                    <h2
                        class="mt-5 max-w-xl text-3xl font-semibold tracking-tight text-slate-950 sm:text-4xl lg:text-5xl"
                    >
                        Focus is not just about time.
                    </h2>

                    <p
                        class="mt-6 max-w-xl text-base leading-7 text-slate-500 sm:text-lg sm:leading-8"
                    >
                        A timer can tell you how long you worked.
                        Focura helps you understand what happened
                        during that time.
                    </p>
                </div>

                <div
                    id="about-card"
                    data-reveal
                    class="grid gap-4 transition-all delay-100 duration-700 sm:grid-cols-2"
                    :class="
                        isSectionVisible('about-card')
                            ? 'translate-y-0 opacity-100'
                            : 'translate-y-8 opacity-0'
                    "
                >
                    <div
                        class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg"
                    >
                        <div
                            class="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600"
                        >
                            <svg
                                viewBox="0 0 24 24"
                                fill="none"
                                class="h-5 w-5"
                                aria-hidden="true"
                            >
                                <circle
                                    cx="12"
                                    cy="12"
                                    r="8.5"
                                    stroke="currentColor"
                                    stroke-width="1.7"
                                />
                                <path
                                    d="M12 7V12L15.5 14"
                                    stroke="currentColor"
                                    stroke-width="1.7"
                                    stroke-linecap="round"
                                />
                            </svg>
                        </div>

                        <h3
                            class="mt-5 font-semibold text-slate-950"
                        >
                            Time with intention
                        </h3>

                        <p
                            class="mt-2 text-sm leading-6 text-slate-500"
                        >
                            Start each session knowing exactly what
                            you want to focus on.
                        </p>
                    </div>

                    <div
                        class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg"
                    >
                        <div
                            class="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600"
                        >
                            <svg
                                viewBox="0 0 24 24"
                                fill="none"
                                class="h-5 w-5"
                                aria-hidden="true"
                            >
                                <path
                                    d="M5 12.5L9.2 17L19 7"
                                    stroke="currentColor"
                                    stroke-width="1.8"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                />
                            </svg>
                        </div>

                        <h3
                            class="mt-5 font-semibold text-slate-950"
                        >
                            Honest feedback
                        </h3>

                        <p
                            class="mt-2 text-sm leading-6 text-slate-500"
                        >
                            See interruptions without turning focus
                            into a competition.
                        </p>
                    </div>

                    <div
                        class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg sm:col-span-2"
                    >
                        <div class="flex items-start gap-4">
                            <div
                                class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-700"
                            >
                                <svg
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    class="h-5 w-5"
                                    aria-hidden="true"
                                >
                                    <path
                                        d="M5 19V11M12 19V5M19 19V8"
                                        stroke="currentColor"
                                        stroke-width="1.8"
                                        stroke-linecap="round"
                                    />
                                </svg>
                            </div>

                            <div>
                                <h3
                                    class="font-semibold text-slate-950"
                                >
                                    Understand your patterns
                                </h3>

                                <p
                                    class="mt-2 max-w-xl text-sm leading-6 text-slate-500"
                                >
                                    Over time, your history becomes a
                                    useful picture of when and how you
                                    do your best work.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- =========================================================
             FEATURES
        ========================================================== -->

        <section id="features">
            <div
                class="mx-auto max-w-7xl px-5 py-24 sm:px-8 lg:px-10 lg:py-32"
            >
                <div
                    id="features-heading"
                    data-reveal
                    class="mx-auto max-w-2xl text-center transition-all duration-700"
                    :class="
                        isSectionVisible('features-heading')
                            ? 'translate-y-0 opacity-100'
                            : 'translate-y-8 opacity-0'
                    "
                >
                    <span
                        class="text-xs font-bold uppercase tracking-[0.18em] text-blue-600"
                    >
                        Built around focus
                    </span>

                    <h2
                        class="mt-5 text-3xl font-semibold tracking-tight text-slate-950 sm:text-4xl lg:text-5xl"
                    >
                        Everything you need.
                        Nothing you don't.
                    </h2>

                    <p
                        class="mt-5 text-base leading-7 text-slate-500 sm:text-lg"
                    >
                        Focura keeps the workspace quiet so your
                        attention can stay where it belongs.
                    </p>
                </div>

                <div
                    class="mt-16 grid gap-5 lg:grid-cols-2"
                >
                    <!-- Feature 1 -->

                    <article
                        id="feature-focus"
                        data-reveal
                        class="group overflow-hidden rounded-3xl border border-slate-200 bg-slate-50 transition-all duration-700 hover:-translate-y-1 hover:shadow-xl"
                        :class="
                            isSectionVisible('feature-focus')
                                ? 'translate-y-0 opacity-100'
                                : 'translate-y-8 opacity-0'
                        "
                    >
                        <div class="p-7 sm:p-9">
                            <span
                                class="inline-flex rounded-full bg-blue-100 px-3 py-1 text-xs font-semibold text-blue-700"
                            >
                                01
                            </span>

                            <h3
                                class="mt-5 text-2xl font-semibold tracking-tight text-slate-950"
                            >
                                Intentional Focus
                            </h3>

                            <p
                                class="mt-3 max-w-md text-sm leading-6 text-slate-500"
                            >
                                Define what matters before the timer
                                starts. Give every session a clear
                                purpose.
                            </p>
                        </div>

                        <div
                            class="relative mx-5 overflow-hidden rounded-t-2xl border border-slate-200 bg-white p-5 shadow-sm transition-transform duration-500 group-hover:scale-[1.01] sm:mx-7 sm:p-7"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <p
                                        class="text-[10px] font-semibold uppercase tracking-wider text-slate-400"
                                    >
                                        SESSION INTENTION
                                    </p>

                                    <p
                                        class="mt-2 text-sm font-semibold text-slate-900"
                                    >
                                        Finish the project proposal
                                    </p>
                                </div>

                                <span
                                    class="rounded-lg bg-blue-50 p-2 text-blue-600"
                                >
                                    <svg
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        class="h-4 w-4"
                                        aria-hidden="true"
                                    >
                                        <path
                                            d="M12 3L14.6 8.4L20.5 9.3L16.2 13.5L17.2 19.4L12 16.6L6.8 19.4L7.8 13.5L3.5 9.3L9.4 8.4L12 3Z"
                                            stroke="currentColor"
                                            stroke-width="1.5"
                                            stroke-linejoin="round"
                                        />
                                    </svg>
                                </span>
                            </div>

                            <div
                                class="mt-6 rounded-xl bg-slate-50 p-4"
                            >
                                <div
                                    class="h-2 overflow-hidden rounded-full bg-slate-200"
                                >
                                    <div
                                        class="h-full w-[68%] rounded-full bg-blue-600 transition-all duration-1000 group-hover:w-[82%]"
                                    />
                                </div>

                                <div
                                    class="mt-3 flex justify-between text-[10px] font-medium text-slate-400"
                                >
                                    <span>Focus started</span>
                                    <span>17 min remaining</span>
                                </div>
                            </div>
                        </div>
                    </article>

                    <!-- Feature 2 -->

                    <article
                        id="feature-integrity"
                        data-reveal
                        class="group overflow-hidden rounded-3xl border border-slate-200 bg-slate-50 transition-all duration-700 hover:-translate-y-1 hover:shadow-xl"
                        :class="
                            isSectionVisible('feature-integrity')
                                ? 'translate-y-0 opacity-100'
                                : 'translate-y-8 opacity-0'
                        "
                    >
                        <div class="p-7 sm:p-9">
                            <span
                                class="inline-flex rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700"
                            >
                                02
                            </span>

                            <h3
                                class="mt-5 text-2xl font-semibold tracking-tight text-slate-950"
                            >
                                Focus Integrity
                            </h3>

                            <p
                                class="mt-3 max-w-md text-sm leading-6 text-slate-500"
                            >
                                See how consistently your actual focus
                                matched the time you planned.
                            </p>
                        </div>

                        <div
                            class="relative mx-5 overflow-hidden rounded-t-2xl border border-slate-200 bg-white p-6 shadow-sm sm:mx-7 sm:p-8"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <p
                                        class="text-[10px] font-semibold uppercase tracking-wider text-slate-400"
                                    >
                                        FOCUS INTEGRITY
                                    </p>

                                    <p
                                        class="mt-2 text-4xl font-semibold tracking-tight text-slate-950"
                                    >
                                        92<span class="text-blue-600">%</span>
                                    </p>
                                </div>

                                <div
                                    class="flex h-16 w-16 items-center justify-center rounded-full border-4 border-emerald-100 bg-emerald-50 text-sm font-semibold text-emerald-700"
                                >
                                    92
                                </div>
                            </div>

                            <div
                                class="mt-6 grid grid-cols-2 gap-3"
                            >
                                <div
                                    class="rounded-xl bg-slate-50 p-3"
                                >
                                    <p
                                        class="text-[10px] font-medium text-slate-400"
                                    >
                                        Planned
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-900"
                                    >
                                        25 min
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-3"
                                >
                                    <p
                                        class="text-[10px] font-medium text-slate-400"
                                    >
                                        Focused
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-900"
                                    >
                                        23 min
                                    </p>
                                </div>
                            </div>
                        </div>
                    </article>

                    <!-- Feature 3 -->

                    <article
                        id="feature-interruptions"
                        data-reveal
                        class="group overflow-hidden rounded-3xl border border-slate-200 bg-white transition-all duration-700 hover:-translate-y-1 hover:shadow-xl"
                        :class="
                            isSectionVisible('feature-interruptions')
                                ? 'translate-y-0 opacity-100'
                                : 'translate-y-8 opacity-0'
                        "
                    >
                        <div class="grid lg:grid-cols-2 lg:items-center">
                            <div class="p-7 sm:p-9">
                                <span
                                    class="inline-flex rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-700"
                                >
                                    03
                                </span>

                                <h3
                                    class="mt-5 text-2xl font-semibold tracking-tight text-slate-950"
                                >
                                    Interruption Awareness
                                </h3>

                                <p
                                    class="mt-3 text-sm leading-6 text-slate-500"
                                >
                                    Notice when your attention leaves
                                    the work. No judgment. Just useful
                                    information.
                                </p>
                            </div>

                            <div class="p-5 sm:p-7">
                                <div
                                    class="rounded-2xl border border-slate-200 bg-slate-50 p-5"
                                >
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <span
                                            class="text-xs font-semibold text-slate-900"
                                        >
                                            Interruptions
                                        </span>

                                        <span
                                            class="text-xs font-medium text-slate-400"
                                        >
                                            Today
                                        </span>
                                    </div>

                                    <div
                                        class="mt-6 flex items-end gap-2"
                                    >
                                        <div
                                            v-for="height in [
                                                32,
                                                48,
                                                38,
                                                68,
                                                45,
                                                84,
                                                55,
                                            ]"
                                            :key="height"
                                            class="flex-1 rounded-t-md bg-blue-100 transition-all duration-500 group-hover:bg-blue-200"
                                            :style="{
                                                height: `${height}px`,
                                            }"
                                        />
                                    </div>

                                    <div
                                        class="mt-3 flex justify-between text-[10px] text-slate-400"
                                    >
                                        <span>Mon</span>
                                        <span>Tue</span>
                                        <span>Wed</span>
                                        <span>Thu</span>
                                        <span>Fri</span>
                                        <span>Sat</span>
                                        <span>Sun</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </article>

                    <!-- Feature 4 -->

                    <article
                        id="feature-insights"
                        data-reveal
                        class="group overflow-hidden rounded-3xl border border-slate-200 bg-slate-950 text-white transition-all duration-700 hover:-translate-y-1 hover:shadow-xl"
                        :class="
                            isSectionVisible('feature-insights')
                                ? 'translate-y-0 opacity-100'
                                : 'translate-y-8 opacity-0'
                        "
                    >
                        <div class="grid lg:grid-cols-2 lg:items-center">
                            <div class="p-7 sm:p-9">
                                <span
                                    class="inline-flex rounded-full bg-white/10 px-3 py-1 text-xs font-semibold text-blue-300"
                                >
                                    04
                                </span>

                                <h3
                                    class="mt-5 text-2xl font-semibold tracking-tight"
                                >
                                    Focus Insights
                                </h3>

                                <p
                                    class="mt-3 text-sm leading-6 text-slate-400"
                                >
                                    Turn your sessions into a clearer
                                    understanding of your focus patterns.
                                </p>
                            </div>

                            <div class="p-5 sm:p-7">
                                <div
                                    class="rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur-sm"
                                >
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <span
                                            class="text-xs font-semibold"
                                        >
                                            Focus trend
                                        </span>

                                        <span
                                            class="rounded-md bg-emerald-400/10 px-2 py-1 text-[10px] font-semibold text-emerald-300"
                                        >
                                            +18%
                                        </span>
                                    </div>

                                    <svg
                                        viewBox="0 0 320 110"
                                        fill="none"
                                        class="mt-6 w-full"
                                        aria-hidden="true"
                                    >
                                        <path
                                            d="M5 92C25 87 34 75 55 78C77 81 80 59 101 64C122 69 129 43 150 48C172 53 177 34 198 39C218 44 224 25 246 30C266 35 279 16 315 7"
                                            stroke="#60a5fa"
                                            stroke-width="3"
                                            stroke-linecap="round"
                                            class="animate-draw-line"
                                        />
                                    </svg>

                                    <div
                                        class="mt-3 flex justify-between text-[10px] text-slate-500"
                                    >
                                        <span>7 days ago</span>
                                        <span>Today</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </article>
                </div>
            </div>
        </section>

        <!-- =========================================================
             HOW IT WORKS
        ========================================================== -->

        <section
            id="how-it-works"
            class="border-y border-slate-100 bg-slate-50/70"
        >
            <div
                class="mx-auto max-w-7xl px-5 py-24 sm:px-8 lg:px-10 lg:py-32"
            >
                <div
                    id="how-heading"
                    data-reveal
                    class="max-w-2xl transition-all duration-700"
                    :class="
                        isSectionVisible('how-heading')
                            ? 'translate-y-0 opacity-100'
                            : 'translate-y-8 opacity-0'
                    "
                >
                    <span
                        class="text-xs font-bold uppercase tracking-[0.18em] text-blue-600"
                    >
                        How it works
                    </span>

                    <h2
                        class="mt-5 text-3xl font-semibold tracking-tight text-slate-950 sm:text-4xl lg:text-5xl"
                    >
                        A simpler way to work deeply.
                    </h2>
                </div>

                <div
                    class="mt-16 grid gap-0 md:grid-cols-3"
                >
                    <article
                        v-for="(step, index) in [
                            {
                                number: '01',
                                title: 'Set your intention',
                                description:
                                    'Choose what you want to accomplish and how long you want to focus.',
                            },
                            {
                                number: '02',
                                title: 'Stay with the work',
                                description:
                                    'Focura quietly tracks your session while you focus on the task in front of you.',
                            },
                            {
                                number: '03',
                                title: 'Understand your focus',
                                description:
                                    'Review interruptions, integrity, and patterns so you can work with more awareness.',
                            },
                        ]"
                        :key="step.number"
                        :id="`step-${index}`"
                        data-reveal
                        class="relative border-slate-200 py-8 transition-all duration-700 first:pt-0 last:pb-0 md:border-l md:px-8 md:first:pt-8 md:last:pb-8"
                        :class="
                            isSectionVisible(`step-${index}`)
                                ? 'translate-y-0 opacity-100'
                                : 'translate-y-8 opacity-0'
                        "
                        :style="{
                            transitionDelay: `${index * 100}ms`,
                        }"
                    >
                        <div
                            class="text-sm font-bold text-blue-600"
                        >
                            {{ step.number }}
                        </div>

                        <h3
                            class="mt-5 text-xl font-semibold tracking-tight text-slate-950"
                        >
                            {{ step.title }}
                        </h3>

                        <p
                            class="mt-3 text-sm leading-6 text-slate-500"
                        >
                            {{ step.description }}
                        </p>

                        <div
                            v-if="index < 2"
                            class="absolute bottom-0 left-8 right-8 h-px bg-slate-200 md:left-auto md:right-0 md:top-8 md:h-px md:w-8"
                        />
                    </article>
                </div>
            </div>
        </section>

        <!-- =========================================================
             INTEGRITY SHOWCASE
        ========================================================== -->

        <section id="integrity">
            <div
                class="mx-auto grid max-w-7xl gap-16 px-5 py-24 sm:px-8 lg:grid-cols-2 lg:items-center lg:px-10 lg:py-32"
            >
                <div
                    id="integrity-copy"
                    data-reveal
                    class="transition-all duration-700"
                    :class="
                        isSectionVisible('integrity-copy')
                            ? 'translate-x-0 opacity-100'
                            : '-translate-x-8 opacity-0'
                    "
                >
                    <span
                        class="text-xs font-bold uppercase tracking-[0.18em] text-blue-600"
                    >
                        Focus Integrity
                    </span>

                    <h2
                        class="mt-5 text-3xl font-semibold tracking-tight text-slate-950 sm:text-4xl lg:text-5xl"
                    >
                        Measure consistency,
                        <span class="text-blue-600">
                            not perfection.
                        </span>
                    </h2>

                    <p
                        class="mt-6 max-w-xl text-base leading-7 text-slate-500 sm:text-lg sm:leading-8"
                    >
                        Focus Integrity compares the time you
                        actually focused with the time you planned.
                        It is a behavioral signal designed to help you
                        understand your work, not judge it.
                    </p>

                    <div
                        class="mt-8 flex flex-wrap gap-3"
                    >
                        <div
                            class="rounded-xl border border-slate-200 bg-white px-4 py-3"
                        >
                            <p
                                class="text-xs font-medium text-slate-400"
                            >
                                Planned
                            </p>

                            <p
                                class="mt-1 text-sm font-semibold text-slate-900"
                            >
                                60 minutes
                            </p>
                        </div>

                        <div
                            class="rounded-xl border border-slate-200 bg-white px-4 py-3"
                        >
                            <p
                                class="text-xs font-medium text-slate-400"
                            >
                                Focused
                            </p>

                            <p
                                class="mt-1 text-sm font-semibold text-slate-900"
                            >
                                54 minutes
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    id="integrity-visual"
                    data-reveal
                    class="transition-all delay-100 duration-700"
                    :class="
                        isSectionVisible('integrity-visual')
                            ? 'translate-x-0 opacity-100'
                            : 'translate-x-8 opacity-0'
                    "
                >
                    <div
                        class="relative mx-auto max-w-md"
                    >
                        <div
                            class="absolute -inset-8 rounded-full bg-blue-100/70 blur-3xl"
                        />

                        <div
                            class="relative rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl shadow-slate-900/10 sm:p-8"
                        >
                            <div
                                class="flex items-center justify-between"
                            >
                                <div>
                                    <p
                                        class="text-xs font-semibold uppercase tracking-wider text-slate-400"
                                    >
                                        Today's focus
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-950"
                                    >
                                        Wednesday
                                    </p>
                                </div>

                                <span
                                    class="rounded-lg bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700"
                                >
                                    4 sessions
                                </span>
                            </div>

                            <div
                                class="relative mx-auto mt-10 flex h-56 w-56 items-center justify-center rounded-full"
                            >
                                <div
                                    class="absolute inset-0 rounded-full border-[18px] border-slate-100"
                                />

                                <div
                                    class="absolute inset-0 rounded-full border-[18px] border-transparent border-r-blue-600 border-t-blue-600 -rotate-12"
                                />

                                <div class="text-center">
                                    <p
                                        class="text-5xl font-semibold tracking-tight text-slate-950"
                                    >
                                        90%
                                    </p>

                                    <p
                                        class="mt-2 text-xs font-medium text-slate-400"
                                    >
                                        Focus Integrity
                                    </p>
                                </div>
                            </div>

                            <div
                                class="mt-8 grid grid-cols-3 gap-2"
                            >
                                <div
                                    class="rounded-xl bg-slate-50 p-3 text-center"
                                >
                                    <p
                                        class="text-lg font-semibold text-slate-950"
                                    >
                                        3h
                                    </p>

                                    <p
                                        class="mt-1 text-[10px] text-slate-400"
                                    >
                                        Focused
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-3 text-center"
                                >
                                    <p
                                        class="text-lg font-semibold text-slate-950"
                                    >
                                        2
                                    </p>

                                    <p
                                        class="mt-1 text-[10px] text-slate-400"
                                    >
                                        Interruptions
                                    </p>
                                </div>

                                <div
                                    class="rounded-xl bg-slate-50 p-3 text-center"
                                >
                                    <p
                                        class="text-lg font-semibold text-blue-600"
                                    >
                                        +12%
                                    </p>

                                    <p
                                        class="mt-1 text-[10px] text-slate-400"
                                    >
                                        vs. last week
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- =========================================================
             INSIGHTS
        ========================================================== -->

        <section
            id="insights"
            class="bg-slate-950 text-white"
        >
            <div
                class="mx-auto max-w-7xl px-5 py-24 sm:px-8 lg:px-10 lg:py-32"
            >
                <div
                    class="grid gap-14 lg:grid-cols-[0.8fr_1.2fr] lg:items-center"
                >
                    <div
                        id="insights-copy"
                        data-reveal
                        class="transition-all duration-700"
                        :class="
                            isSectionVisible('insights-copy')
                                ? 'translate-y-0 opacity-100'
                                : 'translate-y-8 opacity-0'
                        "
                    >
                        <span
                            class="text-xs font-bold uppercase tracking-[0.18em] text-blue-400"
                        >
                            Focus Insights
                        </span>

                        <h2
                            class="mt-5 text-3xl font-semibold tracking-tight sm:text-4xl lg:text-5xl"
                        >
                            Turn sessions into
                            <span class="text-blue-400">
                                understanding.
                            </span>
                        </h2>

                        <p
                            class="mt-6 max-w-xl text-base leading-7 text-slate-400 sm:text-lg sm:leading-8"
                        >
                            Your focus history gives you more than
                            numbers. It helps reveal when your attention
                            is strongest and where interruptions tend
                            to happen.
                        </p>

                        <RouterLink
                            to="/insights"
                            class="mt-8 inline-flex items-center gap-2 rounded-xl bg-white px-5 py-3 text-sm font-semibold text-slate-950 transition hover:-translate-y-0.5 hover:bg-slate-100"
                        >
                            Explore insights

                            <svg
                                viewBox="0 0 20 20"
                                fill="none"
                                class="h-4 w-4"
                                aria-hidden="true"
                            >
                                <path
                                    d="M4 10H16M11 5L16 10L11 15"
                                    stroke="currentColor"
                                    stroke-width="1.7"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                />
                            </svg>
                        </RouterLink>
                    </div>

                    <div
                        id="insights-chart"
                        data-reveal
                        class="transition-all delay-100 duration-700"
                        :class="
                            isSectionVisible('insights-chart')
                                ? 'translate-y-0 opacity-100'
                                : 'translate-y-8 opacity-0'
                        "
                    >
                        <div
                            class="rounded-3xl border border-white/10 bg-white/[0.04] p-5 shadow-2xl backdrop-blur sm:p-7"
                        >
                            <div
                                class="flex items-center justify-between"
                            >
                                <div>
                                    <p
                                        class="text-xs font-semibold text-white"
                                    >
                                        Focus performance
                                    </p>

                                    <p
                                        class="mt-1 text-[11px] text-slate-500"
                                    >
                                        Last 30 days
                                    </p>
                                </div>

                                <button
                                    type="button"
                                    class="rounded-lg border border-white/10 px-3 py-1.5 text-[10px] font-medium text-slate-400"
                                >
                                    30 days
                                </button>
                            </div>

                            <div
                                class="mt-8 flex h-56 items-end gap-2 sm:gap-3"
                            >
                                <div
                                    v-for="height in [
                                        35,
                                        48,
                                        43,
                                        62,
                                        56,
                                        70,
                                        66,
                                        78,
                                        73,
                                        86,
                                        81,
                                        92,
                                    ]"
                                    :key="height"
                                    class="group/bar relative flex-1 rounded-t-lg bg-blue-500/20 transition-all duration-500 hover:bg-blue-400"
                                    :style="{
                                        height: `${height}%`,
                                    }"
                                >
                                    <div
                                        class="absolute inset-x-0 bottom-0 rounded-t-lg bg-blue-500 transition-all duration-500 group-hover/bar:bg-blue-400"
                                        :style="{
                                            height: `${Math.max(
                                                18,
                                                height - 8,
                                            )}%`,
                                        }"
                                    />
                                </div>
                            </div>

                            <div
                                class="mt-5 flex items-center justify-between border-t border-white/10 pt-4"
                            >
                                <div>
                                    <p
                                        class="text-2xl font-semibold"
                                    >
                                        84%
                                    </p>

                                    <p
                                        class="mt-1 text-[10px] text-slate-500"
                                    >
                                        Average focus integrity
                                    </p>
                                </div>

                                <div
                                    class="text-right"
                                >
                                    <p
                                        class="text-sm font-semibold text-emerald-400"
                                    >
                                        +14.8%
                                    </p>

                                    <p
                                        class="mt-1 text-[10px] text-slate-500"
                                    >
                                        compared to previous period
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- =========================================================
             PHILOSOPHY
        ========================================================== -->

        <section>
            <div
                class="mx-auto max-w-4xl px-5 py-24 text-center sm:px-8 lg:py-36"
            >
                <div
                    id="philosophy"
                    data-reveal
                    class="transition-all duration-700"
                    :class="
                        isSectionVisible('philosophy')
                            ? 'translate-y-0 opacity-100'
                            : 'translate-y-8 opacity-0'
                    "
                >
                    <span
                        class="text-xs font-bold uppercase tracking-[0.18em] text-blue-600"
                    >
                        Our philosophy
                    </span>

                    <blockquote
                        class="mt-7 text-3xl font-semibold leading-tight tracking-tight text-slate-950 sm:text-4xl lg:text-5xl"
                    >
                        “Focura does not try to control your attention.
                        It helps you become aware of it.”
                    </blockquote>

                    <p
                        class="mx-auto mt-7 max-w-xl text-sm leading-6 text-slate-500 sm:text-base"
                    >
                        No streaks. No points. No leaderboards.
                        Just a quieter way to understand how you work.
                    </p>
                </div>
            </div>
        </section>

        <!-- =========================================================
             FINAL CTA
        ========================================================== -->

        <section
            class="px-5 pb-8 sm:px-8 lg:px-10"
        >
            <div
                class="relative mx-auto max-w-7xl overflow-hidden rounded-[2rem] bg-blue-600 px-6 py-16 text-center shadow-2xl shadow-blue-600/20 sm:px-10 sm:py-20"
            >
                <div
                    class="pointer-events-none absolute -left-24 -top-24 h-64 w-64 rounded-full bg-white/10 blur-3xl"
                />

                <div
                    class="pointer-events-none absolute -bottom-32 -right-24 h-72 w-72 rounded-full bg-blue-400/30 blur-3xl"
                />

                <div class="relative mx-auto max-w-2xl">
                    <h2
                        class="text-3xl font-semibold tracking-tight text-white sm:text-4xl lg:text-5xl"
                    >
                        Give your next session
                        your full attention.
                    </h2>

                    <p
                        class="mx-auto mt-5 max-w-xl text-sm leading-6 text-blue-100 sm:text-base"
                    >
                        Start with a simple focus session. No account
                        required.
                    </p>

                    <RouterLink
                        to="/focus"
                        class="mt-8 inline-flex items-center gap-2 rounded-xl bg-white px-6 py-3.5 text-sm font-semibold text-blue-700 shadow-lg transition duration-300 hover:-translate-y-1 hover:bg-blue-50"
                    >
                        Start focusing

                        <svg
                            viewBox="0 0 20 20"
                            fill="none"
                            class="h-4 w-4"
                            aria-hidden="true"
                        >
                            <path
                                d="M4 10H16M11 5L16 10L11 15"
                                stroke="currentColor"
                                stroke-width="1.7"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                            />
                        </svg>
                    </RouterLink>
                </div>
            </div>
        </section>

        <!-- =========================================================
             FOOTER
        ========================================================== -->

        <footer
            class="mx-auto max-w-7xl px-5 pb-8 pt-14 sm:px-8 lg:px-10"
        >
            <div
                class="grid gap-10 border-b border-slate-200 pb-10 sm:grid-cols-2 lg:grid-cols-4"
            >
                <div class="sm:col-span-2">
<RouterLink
    to="/"
    class="inline-flex items-center"
>
    <FocuraLogo
        :size="32"
        :show-wordmark="true"
        logo-class="bg-blue-600 text-white"
        wordmark-class="text-lg font-semibold tracking-tight text-slate-950"
    />
</RouterLink>

                    <p
                        class="mt-4 max-w-sm text-sm leading-6 text-slate-500"
                    >
                        A minimal focus workspace for students and
                        professionals.
                    </p>
                </div>

                <div>
                    <p
                        class="text-xs font-bold uppercase tracking-wider text-slate-400"
                    >
                        Product
                    </p>

                    <div
                        class="mt-4 space-y-3"
                    >
                        <button
                            type="button"
                            class="block text-sm text-slate-500 transition hover:text-slate-950"
                            @click="scrollToSection('features')"
                        >
                            Features
                        </button>

                        <button
                            type="button"
                            class="block text-sm text-slate-500 transition hover:text-slate-950"
                            @click="scrollToSection('how-it-works')"
                        >
                            How it works
                        </button>

                        <RouterLink
                            to="/insights"
                            class="block text-sm text-slate-500 transition hover:text-slate-950"
                        >
                            Insights
                        </RouterLink>
                    </div>
                </div>

                <div>
                    <p
                        class="text-xs font-bold uppercase tracking-wider text-slate-400"
                    >
                        Account
                    </p>

                    <div
                        class="mt-4 space-y-3"
                    >
                        <RouterLink
                            to="/login"
                            class="block text-sm text-slate-500 transition hover:text-slate-950"
                        >
                            Log in
                        </RouterLink>

                        <RouterLink
                            to="/register"
                            class="block text-sm text-slate-500 transition hover:text-slate-950"
                        >
                            Create account
                        </RouterLink>

                        <RouterLink
                            to="/focus"
                            class="block text-sm text-slate-500 transition hover:text-slate-950"
                        >
                            Start focusing
                        </RouterLink>
                    </div>
                </div>
            </div>

            <div
                class="flex flex-col gap-3 pt-6 text-xs text-slate-400 sm:flex-row sm:items-center sm:justify-between"
            >
                <p>
                    © {{ new Date().getFullYear() }} Focura. Focus with intention.
                </p>

                <p>
                    Built for better attention.
                </p>
            </div>
        </footer>
    </main>
</template>

<style scoped>
@keyframes fade-up {
    from {
        opacity: 0;
        transform: translateY(18px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

@keyframes draw-line {
    from {
        stroke-dasharray: 500;
        stroke-dashoffset: 500;
    }

    to {
        stroke-dasharray: 500;
        stroke-dashoffset: 0;
    }
}

.animate-fade-up {
    animation: fade-up 0.7s cubic-bezier(0.22, 1, 0.36, 1)
        both;
}

.animation-delay-100 {
    animation-delay: 100ms;
}

.animation-delay-200 {
    animation-delay: 200ms;
}

.animation-delay-300 {
    animation-delay: 300ms;
}

.animation-delay-400 {
    animation-delay: 400ms;
}

.animate-draw-line {
    stroke-dasharray: 500;
    stroke-dashoffset: 0;
    animation: draw-line 1.4s cubic-bezier(0.22, 1, 0.36, 1)
        both;
}

@media (prefers-reduced-motion: reduce) {
    .animate-fade-up,
    .animate-draw-line {
        animation: none;
    }

    * {
        scroll-behavior: auto !important;
    }
}
</style>