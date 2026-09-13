<script setup lang="ts">
import {
    computed,
    onBeforeUnmount,
    onMounted,
    ref,
} from 'vue';
import {
    RouterLink,
    useRoute,
    useRouter,
} from 'vue-router';

import { useAuth } from '@/composables/useAuth';

interface NavigationItem {
    name: 'focus' | 'sessions' | 'insights' | 'settings';
    label: string;
    description: string;
}

const route = useRoute();
const router = useRouter();

const { user, logout, isLoading } = useAuth();

const isAccountMenuOpen = ref(false);
const isLoggingOut = ref(false);

const navigationItems: NavigationItem[] = [
    {
        name: 'focus',
        label: 'Focus',
        description: 'Start a focus session',
    },
    {
        name: 'sessions',
        label: 'Sessions',
        description: 'Review your session history',
    },
    {
        name: 'insights',
        label: 'Insights',
        description: 'Understand your focus consistency',
    },
    {
        name: 'settings',
        label: 'Settings',
        description: 'Manage your preferences',
    },
];

const activeRouteName = computed(() => {
    if (route.name === 'session-detail') {
        return 'sessions';
    }

    return route.name;
});

const userInitials = computed(() => {
    const name = user.value?.name?.trim() ?? '';

    if (!name) {
        return 'U';
    }

    const parts = name
        .split(/\s+/)
        .filter(Boolean);

    if (parts.length === 1) {
        return parts[0].slice(0, 2).toUpperCase();
    }

    return (
        `${parts[0][0]}${parts[parts.length - 1][0]}`
    ).toUpperCase();
});

function toggleAccountMenu(): void {
    isAccountMenuOpen.value =
        !isAccountMenuOpen.value;
}

function closeAccountMenu(): void {
    isAccountMenuOpen.value = false;
}

function handleDocumentClick(event: MouseEvent): void {
    const target = event.target;

    if (!(target instanceof Node)) {
        return;
    }

    const accountMenu = document.getElementById(
        'focura-account-menu',
    );

    if (
        accountMenu &&
        !accountMenu.contains(target)
    ) {
        closeAccountMenu();
    }
}

function handleKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
        closeAccountMenu();
    }
}

async function handleLogout(): Promise<void> {
    if (isLoggingOut.value || isLoading.value) {
        return;
    }

    isLoggingOut.value = true;
    closeAccountMenu();

    try {
        await logout();
        await router.push({ name: 'landing' });
    } finally {
        isLoggingOut.value = false;
    }
}

onMounted(() => {
    document.addEventListener(
        'click',
        handleDocumentClick,
    );

    document.addEventListener(
        'keydown',
        handleKeydown,
    );
});

onBeforeUnmount(() => {
    document.removeEventListener(
        'click',
        handleDocumentClick,
    );

    document.removeEventListener(
        'keydown',
        handleKeydown,
    );
});
</script>

<template>
    <div class="min-h-screen bg-white dark:bg-slate-950">
        <nav
            class="border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950"
            aria-label="Main navigation"
        >
            <div
                class="mx-auto flex max-w-6xl items-center justify-between gap-3 px-4 py-3 sm:px-6 lg:px-8"
            >
                <RouterLink
                    to="/"
                    class="hidden shrink-0 text-xl font-semibold tracking-tight text-slate-900 dark:text-slate-100 sm:block"
                    aria-label="Focura home"
                >
                    Focura
                </RouterLink>

                <div
                    class="flex min-w-0 flex-1 items-center justify-center"
                >
                    <div
                        class="flex w-full items-center justify-center gap-1 overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 p-1 sm:w-auto"
                    >
                        <RouterLink
                            v-for="item in navigationItems"
                            :key="item.name"
                            :to="{ name: item.name }"
                            :aria-current="
                                activeRouteName === item.name
                                    ? 'page'
                                    : undefined
                            "
                            :title="item.description"
                            class="flex min-h-9 shrink-0 items-center justify-center rounded-lg px-3 py-2 text-sm font-medium transition-colors sm:px-4"
                            :class="
                                activeRouteName === item.name
                                    ? 'bg-white dark:bg-slate-950 text-blue-600 shadow-sm ring-1 ring-slate-200'
                                    : 'text-slate-500 dark:text-slate-400 hover:bg-white dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-slate-100'
                            "
                        >
                            <svg
                                v-if="item.name === 'focus'"
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="mr-1.5 h-4 w-4"
                                aria-hidden="true"
                            >
                                <circle
                                    cx="12"
                                    cy="12"
                                    r="8"
                                />
                                <circle
                                    cx="12"
                                    cy="12"
                                    r="3"
                                />
                            </svg>

                            <svg
                                v-else-if="item.name === 'sessions'"
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="mr-1.5 h-4 w-4"
                                aria-hidden="true"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M8 6h11M8 12h11M8 18h11"
                                />
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M4.5 6h.01M4.5 12h.01M4.5 18h.01"
                                />
                            </svg>

                            <svg
                                v-else-if="item.name === 'insights'"
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="mr-1.5 h-4 w-4"
                                aria-hidden="true"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M4 19V5"
                                />
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M4 19h16"
                                />
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="m7 15 3-4 3 2 5-6"
                                />
                            </svg>

                            <svg
                                v-else
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="mr-1.5 h-4 w-4"
                                aria-hidden="true"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"
                                />
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.41 1.41-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.04 1.56V20h-2v-.09a1.7 1.7 0 0 0-1.04-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.41-1.41.06-.06A1.7 1.7 0 0 0 8.4 15.4a1.7 1.7 0 0 0-1.56-1.04H6v-2h.84A1.7 1.7 0 0 0 8.4 11.3a1.7 1.7 0 0 0-.34-1.88L8 9.36l1.41-1.41.06.06a1.7 1.7 0 0 0 1.88.34A1.7 1.7 0 0 0 12.4 6.8V6h2v.8a1.7 1.7 0 0 0 1.04 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.41 1.41-.06.06a1.7 1.7 0 0 0-.34 1.88 1.7 1.7 0 0 0 1.56 1.04H20v2h-.6a1.7 1.7 0 0 0-1.56 1.04Z"
                                />
                            </svg>

                            {{ item.label }}
                        </RouterLink>
                    </div>
                </div>

                <div
                    id="focura-account-menu"
                    class="relative shrink-0"
                >
                    <button
                        type="button"
                        class="flex min-h-10 items-center gap-2 rounded-xl px-2 py-1.5 text-left transition-colors hover:bg-slate-50 dark:hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1"
                        :aria-expanded="
                            isAccountMenuOpen
                        "
                        aria-haspopup="menu"
                        aria-label="Open account menu"
                        @click.stop="toggleAccountMenu"
                    >
                        <span
                            class="flex h-8 w-8 items-center justify-center rounded-full bg-blue-50 text-xs font-semibold text-blue-700 ring-1 ring-blue-100"
                            aria-hidden="true"
                        >
                            {{ userInitials }}
                        </span>

                        <span
                            class="hidden max-w-32 truncate text-sm font-medium text-slate-700 dark:text-slate-300 md:block"
                        >
                            {{ user?.name ?? 'Account' }}
                        </span>

                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            class="hidden h-4 w-4 text-slate-400 dark:text-slate-500 md:block"
                            aria-hidden="true"
                        >
                            <path
                                fill-rule="evenodd"
                                d="M5.23 7.21a.75.75 0 0 1 1.06.02L10 11.168l3.71-3.938a.75.75 0 1 1 1.08 1.04l-4.25 4.51a.75.75 0 0 1-1.08 0l-4.25-4.51a.75.75 0 0 1 .02-1.06Z"
                                clip-rule="evenodd"
                            />
                        </svg>
                    </button>

                    <Transition
                        enter-active-class="transition duration-100 ease-out"
                        enter-from-class="scale-95 opacity-0"
                        enter-to-class="scale-100 opacity-100"
                        leave-active-class="transition duration-75 ease-in"
                        leave-from-class="scale-100 opacity-100"
                        leave-to-class="scale-95 opacity-0"
                    >
                        <div
                            v-if="isAccountMenuOpen"
                            class="absolute right-0 z-50 mt-2 w-64 origin-top-right rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 p-1.5 shadow-lg ring-1 ring-black/5"
                            role="menu"
                            aria-label="Account menu"
                        >
                            <div
                                class="border-b border-slate-100 dark:border-slate-800 px-3 py-2.5"
                            >
                                <p
                                    class="truncate text-sm font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    {{ user?.name }}
                                </p>

                                <p
                                    class="mt-0.5 truncate text-xs text-slate-500 dark:text-slate-400"
                                >
                                    {{ user?.email }}
                                </p>
                            </div>

                            <RouterLink
                                :to="{ name: 'settings' }"
                                class="mt-1 flex items-center gap-2.5 rounded-lg px-3 py-2.5 text-sm font-medium text-slate-600 dark:text-slate-400 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-slate-100"
                                role="menuitem"
                                @click="closeAccountMenu"
                            >
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="1.8"
                                    class="h-4 w-4 text-slate-400 dark:text-slate-500"
                                    aria-hidden="true"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"
                                    />
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.41 1.41-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.04 1.56V20h-2v-.09a1.7 1.7 0 0 0-1.04-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.41-1.41.06-.06A1.7 1.7 0 0 0 8.4 15.4a1.7 1.7 0 0 0-1.56-1.04H6v-2h.84A1.7 1.7 0 0 0 8.4 11.3a1.7 1.7 0 0 0-.34-1.88L8 9.36l1.41-1.41.06.06a1.7 1.7 0 0 0 1.88.34A1.7 1.7 0 0 0 12.4 6.8V6h2v.8a1.7 1.7 0 0 0 1.04 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.41 1.41-.06.06a1.7 1.7 0 0 0-.34 1.88 1.7 1.7 0 0 0 1.56 1.04H20v2h-.6a1.7 1.7 0 0 0-1.56 1.04Z"
                                    />
                                </svg>

                                Settings
                            </RouterLink>

                            <button
                                type="button"
                                class="flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
                                role="menuitem"
                                :disabled="isLoggingOut || isLoading"
                                @click="handleLogout"
                            >
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="1.8"
                                    class="h-4 w-4"
                                    aria-hidden="true"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M15 8V6.5A2.5 2.5 0 0 0 12.5 4h-6A2.5 2.5 0 0 0 4 6.5v11A2.5 2.5 0 0 0 6.5 20h6a2.5 2.5 0 0 0 2.5-2.5V16"
                                    />
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M10 12h10"
                                    />
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="m17 9 3 3-3 3"
                                    />
                                </svg>

                                <span>
                                    {{
                                        isLoggingOut
                                            ? 'Logging out...'
                                            : 'Log out'
                                    }}
                                </span>
                            </button>
                        </div>
                    </Transition>
                </div>
            </div>
        </nav>

        <main>
            <slot />
        </main>
    </div>
</template>
