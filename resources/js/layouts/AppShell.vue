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

const {
    user,
    logout,
    isLoading,
} = useAuth();

const isAccountMenuOpen = ref(false);
const isMobileMenuOpen = ref(false);
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

const isGuest = computed(() => {
    return user.value === null;
});

const accountLabel = computed(() => {
    return user.value?.name?.trim() || 'Guest';
});

const userInitials = computed(() => {
    const name = user.value?.name?.trim() ?? '';

    if (!name) {
        return 'G';
    }

    const parts = name
        .split(/\s+/)
        .filter(Boolean);

    if (parts.length === 1) {
        return parts[0]
            .slice(0, 2)
            .toUpperCase();
    }

    return (
        `${parts[0][0]}${parts[parts.length - 1][0]}`
    ).toUpperCase();
});

function toggleAccountMenu(): void {
    isAccountMenuOpen.value =
        !isAccountMenuOpen.value;

    if (isAccountMenuOpen.value) {
        closeMobileMenu();
    }
}

function closeAccountMenu(): void {
    isAccountMenuOpen.value = false;
}

function toggleMobileMenu(): void {
    isMobileMenuOpen.value =
        !isMobileMenuOpen.value;

    if (isMobileMenuOpen.value) {
        closeAccountMenu();
    }
}

function closeMobileMenu(): void {
    isMobileMenuOpen.value = false;
}

function closeAllMenus(): void {
    closeAccountMenu();
    closeMobileMenu();
}

function handleDocumentClick(
    event: MouseEvent,
): void {
    const target = event.target;

    if (!(target instanceof Node)) {
        return;
    }

    const accountMenu =
        document.getElementById(
            'focura-account-menu',
        );

    const mobileMenu =
        document.getElementById(
            'focura-mobile-menu',
        );

    const mobileMenuButton =
        document.getElementById(
            'focura-mobile-menu-button',
        );

    if (
        accountMenu &&
        !accountMenu.contains(target) &&
        mobileMenu &&
        !mobileMenu.contains(target) &&
        mobileMenuButton &&
        !mobileMenuButton.contains(target)
    ) {
        closeAllMenus();
        return;
    }

    if (
        accountMenu &&
        !accountMenu.contains(target)
    ) {
        closeAccountMenu();
    }

    if (
        mobileMenu &&
        !mobileMenu.contains(target) &&
        mobileMenuButton &&
        !mobileMenuButton.contains(target)
    ) {
        closeMobileMenu();
    }
}

function handleKeydown(
    event: KeyboardEvent,
): void {
    if (event.key === 'Escape') {
        closeAllMenus();
    }
}

function handleNavigation(): void {
    closeAllMenus();
}

async function handleLogout(): Promise<void> {
    if (
        isGuest.value ||
        isLoggingOut.value ||
        isLoading.value
    ) {
        return;
    }

    isLoggingOut.value = true;

    closeAllMenus();

    try {
        await logout();

        await router.push({
            name: 'landing',
        });
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
    <div
        class="min-h-screen bg-white dark:bg-slate-950"
    >
        <nav
            class="border-b border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-950"
            aria-label="Main navigation"
        >
            <div
                class="mx-auto flex max-w-6xl items-center justify-between gap-3 px-4 py-3 sm:px-6 lg:px-8"
            >
                <!-- Logo -->
                <RouterLink
                    to="/"
                    class="shrink-0 text-xl font-semibold tracking-tight text-slate-900 dark:text-slate-100"
                    aria-label="Focura home"
                    @click="handleNavigation"
                >
                    Focura
                </RouterLink>

                <!-- Desktop Navigation -->
                <div
                    class="hidden flex-1 items-center justify-center sm:flex"
                >
                    <div
                        class="flex items-center justify-center gap-1 rounded-xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-900"
                    >
                        <RouterLink
                            v-for="item in navigationItems"
                            :key="item.name"
                            :to="{ name: item.name }"
                            :aria-current="
                                activeRouteName ===
                                item.name
                                    ? 'page'
                                    : undefined
                            "
                            :title="item.description"
                            class="flex min-h-10 shrink-0 items-center justify-center rounded-lg px-3 py-2 text-sm font-medium transition-colors sm:px-4"
                            :class="
                                activeRouteName ===
                                item.name
                                    ? 'bg-white text-blue-600 shadow-sm ring-1 ring-slate-200 dark:bg-slate-950 dark:ring-slate-700'
                                    : 'text-slate-500 hover:bg-white hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100'
                            "
                        >
                            <!-- Focus -->
                            <svg
                                v-if="
                                    item.name === 'focus'
                                "
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

                            <!-- Sessions -->
                            <svg
                                v-else-if="
                                    item.name ===
                                    'sessions'
                                "
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

                            <!-- Insights -->
                            <svg
                                v-else-if="
                                    item.name ===
                                    'insights'
                                "
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

                            <!-- Settings -->
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
                                    d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.41 1.41-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.04 1.56V20h-2v-.09a1.7 1.7 0 0 0-1.04-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.41-1.41.06-.06A1.7 1.7 0 0 0 8.4 15.4a1.7 1.7 0 0 0-1.56-1.04H6v-2h.84A1.7 1.7 0 0 0 8.4 11.3a1.7 1.7 0 0 0-.34-1.88L8 9.36l1.41-1.41.06.06a1.7 1.7 0 0 0 1.88.34A1.7 1.7 0 0 0 12.4 6.8V6h2v.8a1.7 1.7 0 0 0 1.04 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.41 1.41-.06.06a1.7 1.7 0 0 0 .34 1.88 1.7 1.7 0 0 0 1.56 1.04H20v2h-.6a1.7 1.7 0 0 0-1.56 1.04Z"
                                />
                            </svg>

                            {{ item.label }}
                        </RouterLink>
                    </div>
                </div>

                <!-- Desktop Account / Guest -->
                <div
                    id="focura-account-menu"
                    class="relative hidden shrink-0 sm:block"
                >
                    <button
                        type="button"
                        class="flex min-h-10 items-center gap-2 rounded-xl px-2 py-1.5 text-left transition-colors hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 dark:hover:bg-slate-800"
                        :aria-expanded="
                            isAccountMenuOpen
                        "
                        aria-haspopup="menu"
                        aria-label="Open account menu"
                        @click.stop="
                            toggleAccountMenu
                        "
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
                            {{ accountLabel }}
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
                            v-if="
                                isAccountMenuOpen
                            "
                            class="absolute right-0 z-50 mt-2 w-64 origin-top-right rounded-xl border border-slate-200 bg-white p-1.5 shadow-lg ring-1 ring-black/5 dark:border-slate-700 dark:bg-slate-950"
                            role="menu"
                            aria-label="User menu"
                        >
                            <!-- User / Guest Information -->
                            <div
                                class="border-b border-slate-100 px-3 py-2.5 dark:border-slate-800"
                            >
                                <p
                                    class="truncate text-sm font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    {{ accountLabel }}
                                </p>

                                <p
                                    v-if="user?.email"
                                    class="mt-0.5 truncate text-xs text-slate-500 dark:text-slate-400"
                                >
                                    {{ user.email }}
                                </p>

                                <p
                                    v-else
                                    class="mt-0.5 text-xs text-slate-500 dark:text-slate-400"
                                >
                                    Guest session
                                </p>
                            </div>

                            <!-- Settings -->
                            <RouterLink
                                :to="{
                                    name: 'settings',
                                }"
                                class="mt-1 flex items-center gap-2.5 rounded-lg px-3 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100"
                                role="menuitem"
                                @click="
                                    closeAccountMenu
                                "
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
                                        d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.41 1.41-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.04 1.56V20h-2v-.09a1.7 1.7 0 0 0-1.04-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.41-1.41.06-.06A1.7 1.7 0 0 0 8.4 15.4a1.7 1.7 0 0 0-1.56-1.04H6v-2h.84A1.7 1.7 0 0 0 8.4 11.3a1.7 1.7 0 0 0-.34-1.88L8 9.36l1.41-1.41.06.06a1.7 1.7 0 0 0 1.88.34A1.7 1.7 0 0 0 12.4 6.8V6h2v.8a1.7 1.7 0 0 0 1.04 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.41 1.41-.06.06a1.7 1.7 0 0 0 1.56 1.04H20v2h-.6a1.7 1.7 0 0 0-1.56 1.04Z"
                                    />
                                </svg>

                                Settings
                            </RouterLink>

                            <!-- Log out: Authenticated only -->
                            <button
                                v-if="!isGuest"
                                type="button"
                                class="flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60 dark:hover:bg-red-950/30"
                                role="menuitem"
                                :disabled="
                                    isLoggingOut ||
                                    isLoading
                                "
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

                <!-- Mobile Menu Button -->
                <button
                    id="focura-mobile-menu-button"
                    type="button"
                    class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-slate-600 transition-colors hover:bg-slate-50 hover:text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-white sm:hidden"
                    :aria-expanded="
                        isMobileMenuOpen
                    "
                    aria-controls="focura-mobile-menu"
                    aria-label="Toggle navigation menu"
                    @click.stop="toggleMobileMenu"
                >
                    <!-- Hamburger -->
                    <svg
                        v-if="
                            !isMobileMenuOpen
                        "
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="1.8"
                        class="h-5 w-5"
                        aria-hidden="true"
                    >
                        <path
                            stroke-linecap="round"
                            d="M4 7h16"
                        />
                        <path
                            stroke-linecap="round"
                            d="M4 12h16"
                        />
                        <path
                            stroke-linecap="round"
                            d="M4 17h16"
                        />
                    </svg>

                    <!-- Close -->
                    <svg
                        v-else
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="1.8"
                        class="h-5 w-5"
                        aria-hidden="true"
                    >
                        <path
                            stroke-linecap="round"
                            d="m6 6 12 12"
                        />
                        <path
                            stroke-linecap="round"
                            d="m18 6-12 12"
                        />
                    </svg>
                </button>
            </div>

            <!-- Mobile Menu -->
            <Transition
                enter-active-class="transition duration-150 ease-out"
                enter-from-class="-translate-y-2 opacity-0"
                enter-to-class="translate-y-0 opacity-100"
                leave-active-class="transition duration-100 ease-in"
                leave-from-class="translate-y-0 opacity-100"
                leave-to-class="-translate-y-2 opacity-0"
            >
                <div
                    v-if="isMobileMenuOpen"
                    id="focura-mobile-menu"
                    class="border-t border-slate-100 bg-white px-4 pb-4 pt-3 dark:border-slate-800 dark:bg-slate-950 sm:hidden"
                >
                    <!-- Navigation -->
                    <div
                        class="rounded-xl border border-slate-200 bg-slate-50 p-1.5 dark:border-slate-700 dark:bg-slate-900"
                    >
                        <RouterLink
                            v-for="item in navigationItems"
                            :key="item.name"
                            :to="{ name: item.name }"
                            :aria-current="
                                activeRouteName ===
                                item.name
                                    ? 'page'
                                    : undefined
                            "
                            class="flex min-h-11 items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors"
                            :class="
                                activeRouteName ===
                                item.name
                                    ? 'bg-white text-blue-600 shadow-sm ring-1 ring-slate-200 dark:bg-slate-950 dark:ring-slate-700'
                                    : 'text-slate-600 hover:bg-white hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100'
                            "
                            @click="
                                handleNavigation
                            "
                        >
                            <!-- Focus -->
                            <svg
                                v-if="
                                    item.name === 'focus'
                                "
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="h-5 w-5 shrink-0"
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

                            <!-- Sessions -->
                            <svg
                                v-else-if="
                                    item.name ===
                                    'sessions'
                                "
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="h-5 w-5 shrink-0"
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

                            <!-- Insights -->
                            <svg
                                v-else-if="
                                    item.name ===
                                    'insights'
                                "
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="h-5 w-5 shrink-0"
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

                            <!-- Settings -->
                            <svg
                                v-else
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                class="h-5 w-5 shrink-0"
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
                                    d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.41 1.41-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.04 1.56V20h-2v-.09a1.7 1.7 0 0 0-1.04-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.41-1.41.06-.06A1.7 1.7 0 0 0 8.4 15.4a1.7 1.7 0 0 0-1.56-1.04H6v-2h.84A1.7 1.7 0 0 0 8.4 11.3a1.7 1.7 0 0 0-.34-1.88L8 9.36l1.41-1.41.06.06a1.7 1.7 0 0 0 1.88.34A1.7 1.7 0 0 0 12.4 6.8V6h2v.8a1.7 1.7 0 0 0 1.04 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.41 1.41-.06.06a1.7 1.7 0 0 0 1.56.34A1.7 1.7 0 0 0 20v2h-.6a1.7 1.7 0 0 0-1.56 1.04Z"
                                />
                            </svg>

                            <span
                                class="min-w-0 flex-1"
                            >
                                {{ item.label }}
                            </span>

                            <span
                                class="hidden text-xs text-slate-400 dark:text-slate-500 sm:block"
                            >
                                {{
                                    item.description
                                }}
                            </span>
                        </RouterLink>
                    </div>

                    <!-- Mobile Guest / User -->
                    <div
                        class="mt-3 rounded-xl border border-slate-200 bg-white p-3 dark:border-slate-700 dark:bg-slate-900"
                    >
                        <div
                            class="flex items-center gap-3"
                        >
                            <span
                                class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-blue-50 text-sm font-semibold text-blue-700 ring-1 ring-blue-100"
                                aria-hidden="true"
                            >
                                {{ userInitials }}
                            </span>

                            <div
                                class="min-w-0 flex-1"
                            >
                                <p
                                    class="truncate text-sm font-semibold text-slate-900 dark:text-slate-100"
                                >
                                    {{ accountLabel }}
                                </p>

                                <p
                                    v-if="user?.email"
                                    class="truncate text-xs text-slate-500 dark:text-slate-400"
                                >
                                    {{ user.email }}
                                </p>

                                <p
                                    v-else
                                    class="text-xs text-slate-500 dark:text-slate-400"
                                >
                                    Guest session
                                </p>
                            </div>
                        </div>

                        <!-- Guest: Settings only -->
                        <div
                            v-if="isGuest"
                            class="mt-3"
                        >
                            <RouterLink
                                :to="{
                                    name: 'settings',
                                }"
                                class="flex min-h-10 w-full items-center justify-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 hover:text-slate-900 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                                @click="
                                    handleNavigation
                                "
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
                                        d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"
                                    />
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.41 1.41-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.04 1.56V20h-2v-.09a1.7 1.7 0 0 0-1.04-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.41-1.41.06-.06A1.7 1.7 0 0 0 8.4 15.4a1.7 1.7 0 0 0-1.56-1.04H6v-2h.84A1.7 1.7 0 0 0 8.4 11.3a1.7 1.7 0 0 0-.34-1.88L8 9.36l1.41-1.41.06.06a1.7 1.7 0 0 0 1.88.34A1.7 1.7 0 0 0 12.4 6.8V6h2v.8a1.7 1.7 0 0 0 1.04 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.41 1.41-.06.06a1.7 1.7 0 0 0 1.56.34 1.7 1.7 0 0 0 1.56 1.04H20v2h-.6a1.7 1.7 0 0 0-1.56 1.04Z"
                                    />
                                </svg>

                                Settings
                            </RouterLink>
                        </div>

                        <!-- Authenticated: Settings + Log out -->
                        <div
                            v-else
                            class="mt-3 grid grid-cols-2 gap-2"
                        >
                            <RouterLink
                                :to="{
                                    name: 'settings',
                                }"
                                class="flex min-h-10 items-center justify-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 hover:text-slate-900 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                                @click="
                                    handleNavigation
                                "
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
                                        d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"
                                    />
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.41 1.41-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.04 1.56V20h-2v-.09a1.7 1.7 0 0 0-1.04-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.41-1.41.06-.06A1.7 1.7 0 0 0 8.4 15.4a1.7 1.7 0 0 0-1.56-1.04H6v-2h.84A1.7 1.7 0 0 0 8.4 11.3a1.7 1.7 0 0 0-.34-1.88L8 9.36l1.41-1.41.06.06a1.7 1.7 0 0 0 1.88.34A1.7 1.7 0 0 0 12.4 6.8V6h2v.8a1.7 1.7 0 0 0 1.04 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.41 1.41-.06.06a1.7 1.7 0 0 0 1.56 1.04H20v2h-.6a1.7 1.7 0 0 0-1.56 1.04Z"
                                    />
                                </svg>

                                Settings
                            </RouterLink>

                            <button
                                type="button"
                                class="flex min-h-10 items-center justify-center gap-2 rounded-lg border border-red-100 px-3 py-2 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-red-900/50 dark:hover:bg-red-950/30"
                                :disabled="
                                    isLoggingOut ||
                                    isLoading
                                "
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

                                {{
                                    isLoggingOut
                                        ? 'Logging out...'
                                        : 'Log out'
                                }}
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </nav>

        <main>
            <slot />
        </main>
    </div>
</template>