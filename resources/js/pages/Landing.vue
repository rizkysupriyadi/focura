<script setup lang="ts">
import { RouterLink } from 'vue-router';
</script>

<template>
    <main class="min-h-screen bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100">
        <section
            class="mx-auto flex min-h-screen max-w-6xl flex-col px-6 py-8 sm:px-8 lg:px-12"
        >
            <header class="flex items-center justify-between">
                <RouterLink
                    to="/"
                    class="text-xl font-semibold tracking-tight"
                >
                    Focura
                </RouterLink>

                <div class="flex items-center gap-2">
                    <RouterLink
                        to="/login"
                        class="rounded-lg px-3 py-2 text-sm font-medium text-slate-600 dark:text-slate-400 transition hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-slate-100"
                    >
                        Log in
                    </RouterLink>

                    <RouterLink
                        to="/register"
                        class="rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-blue-700"
                    >
                        Create account
                    </RouterLink>
                </div>
            </header>

            <div
                class="flex flex-1 flex-col justify-center py-20 lg:max-w-4xl"
            >
                <p
                    class="mb-5 text-sm font-medium uppercase tracking-[0.18em] text-blue-600"
                >
                    Focus with intention.
                </p>

                <h1
                    class="max-w-4xl text-5xl font-semibold tracking-tight text-slate-950 dark:text-slate-50 sm:text-6xl lg:text-7xl"
                >
                    Protect your attention.
                </h1>

                <p
                    class="mt-7 max-w-2xl text-lg leading-8 text-slate-600 dark:text-slate-400 sm:text-xl"
                >
                    A simple workspace to protect your attention, track
                    interruptions, and understand your focus.
                </p>

                <div class="mt-9 flex flex-wrap items-center gap-4">
                    <RouterLink
                        to="/focus"
                        class="rounded-xl bg-blue-600 px-6 py-3.5 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700"
                    >
                        Start Focusing
                    </RouterLink>

                    <span class="text-sm text-slate-500 dark:text-slate-400">
                        No account required
                    </span>
                </div>
            </div>

            <div
                class="grid gap-4 border-t border-slate-200 dark:border-slate-700 py-8 sm:grid-cols-3"
            >
                <div class="sm:pr-8">
                    <h2 class="font-semibold text-slate-900 dark:text-slate-100">Focus</h2>

                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">
                        Create a focused workspace for the work that matters.
                    </p>
                </div>

                <div class="border-slate-200 dark:border-slate-700 sm:border-l sm:px-8">
                    <h2 class="font-semibold text-slate-900 dark:text-slate-100">Integrity</h2>

                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">
                        Understand how consistently you stayed with your work.
                    </p>
                </div>

                <div class="border-slate-200 dark:border-slate-700 sm:border-l sm:pl-8">
                    <h2 class="font-semibold text-slate-900 dark:text-slate-100">Insights</h2>

                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">
                        See your focus patterns without unnecessary noise.
                    </p>
                </div>
            </div>
        </section>
    </main>
</template>