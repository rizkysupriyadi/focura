<script setup lang="ts">
withDefaults(
    defineProps<{
        size?: number;
        strokeWidth?: number;
        showWordmark?: boolean;
        logoClass?: string;
        wordmarkClass?: string;
    }>(),
    {
        size: 36,
        strokeWidth: 1.8,
        showWordmark: false,
        logoClass:
            'bg-blue-600 text-white',
        wordmarkClass:
            'text-slate-950',
    },
);
</script>

<template>
    <div class="flex items-center gap-2.5">
        <!-- Logo mark -->
        <span
            class="flex shrink-0 items-center justify-center rounded-xl"
            :class="logoClass"
            :style="{
                width: `${size}px`,
                height: `${size}px`,
            }"
        >
            <svg
                :width="size * 0.68"
                :height="size * 0.68"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
            >
                <path
                    d="M7 17.5C8.8 19.1 11.2 20 14 20C18.4 20 21 17.8 21 14.2C21 11.2 19.1 9.2 16.1 8.8C14.2 8.5 12.7 7.5 12.7 5.8C12.7 4.2 14 3 15.8 3C17.3 3 18.5 3.6 19.4 4.6"
                    stroke="currentColor"
                    :stroke-width="strokeWidth"
                    stroke-linecap="round"
                />

                <path
                    d="M17 6.5C15.2 4.9 12.8 4 10 4C5.6 4 3 6.2 3 9.8C3 12.8 4.9 14.8 7.9 15.2C9.8 15.5 11.3 16.5 11.3 18.2C11.3 19.8 10 21 8.2 21C6.7 21 5.5 20.4 4.6 19.4"
                    stroke="currentColor"
                    :stroke-width="strokeWidth"
                    stroke-linecap="round"
                />
            </svg>
        </span>

        <!-- Wordmark -->
        <span
            v-if="showWordmark"
            :class="[
                'text-xl font-semibold tracking-[-0.025em]',
                wordmarkClass,
            ]"
        >
            Focura
        </span>
    </div>
</template>