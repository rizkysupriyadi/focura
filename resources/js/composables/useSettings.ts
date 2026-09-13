import {
    computed,
    ref,
    watch,
} from 'vue';

import {
    DEFAULT_FOCURA_SETTINGS,
    type FocuraAppearance,
    type FocuraSettings,
} from '@/types/settings';

const STORAGE_KEY = 'focura.settings';

const settings = ref<FocuraSettings>({
    ...DEFAULT_FOCURA_SETTINGS,
});

let initialized = false;

function normalizeAppearance(
    value: unknown,
): FocuraAppearance {
    return value === 'dark'
        ? 'dark'
        : 'light';
}

function clampInteger(
    value: unknown,
    fallback: number,
    minimum: number,
    maximum: number,
): number {
    const numericValue =
        typeof value === 'number'
            ? value
            : Number(value);

    if (!Number.isFinite(numericValue)) {
        return fallback;
    }

    return Math.min(
        maximum,
        Math.max(
            minimum,
            Math.floor(numericValue),
        ),
    );
}

function normalizeBoolean(
    value: unknown,
    fallback: boolean,
): boolean {
    if (typeof value === 'boolean') {
        return value;
    }

    return fallback;
}

function normalizeSettings(
    value: Partial<FocuraSettings>,
): FocuraSettings {
    return {
        appearance: normalizeAppearance(
            value.appearance,
        ),

        focusDurationMinutes: clampInteger(
            value.focusDurationMinutes,
            DEFAULT_FOCURA_SETTINGS
                .focusDurationMinutes,
            1,
            180,
        ),

        shortBreakDurationMinutes: clampInteger(
            value.shortBreakDurationMinutes,
            DEFAULT_FOCURA_SETTINGS
                .shortBreakDurationMinutes,
            1,
            60,
        ),

        longBreakDurationMinutes: clampInteger(
            value.longBreakDurationMinutes,
            DEFAULT_FOCURA_SETTINGS
                .longBreakDurationMinutes,
            1,
            120,
        ),

        interruptionTrackingEnabled:
            normalizeBoolean(
                value.interruptionTrackingEnabled,
                DEFAULT_FOCURA_SETTINGS
                    .interruptionTrackingEnabled,
            ),

        interruptionWarningEnabled:
            normalizeBoolean(
                value.interruptionWarningEnabled,
                DEFAULT_FOCURA_SETTINGS
                    .interruptionWarningEnabled,
            ),

        interruptionWarningSoundEnabled:
            normalizeBoolean(
                value.interruptionWarningSoundEnabled,
                DEFAULT_FOCURA_SETTINGS
                    .interruptionWarningSoundEnabled,
            ),

        completionNotificationEnabled:
            normalizeBoolean(
                value.completionNotificationEnabled,
                DEFAULT_FOCURA_SETTINGS
                    .completionNotificationEnabled,
            ),

        completionSoundEnabled:
            normalizeBoolean(
                value.completionSoundEnabled,
                DEFAULT_FOCURA_SETTINGS
                    .completionSoundEnabled,
            ),
    };
}

function persist(): void {
    if (typeof window === 'undefined') {
        return;
    }

    localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify(settings.value),
    );
}

function applyAppearance(
    appearance: FocuraAppearance,
): void {
    if (typeof document === 'undefined') {
        return;
    }

    document.documentElement.classList.toggle(
        'dark',
        appearance === 'dark',
    );

    document.documentElement.style.colorScheme =
        appearance;
}

function initialize(): void {
    if (
        initialized ||
        typeof window === 'undefined'
    ) {
        return;
    }

    initialized = true;

    const raw = localStorage.getItem(
        STORAGE_KEY,
    );

    if (!raw) {
        settings.value = {
            ...DEFAULT_FOCURA_SETTINGS,
        };

        applyAppearance(
            settings.value.appearance,
        );

        return;
    }

    try {
        const parsed: unknown = JSON.parse(raw);

        if (
            typeof parsed !== 'object' ||
            parsed === null ||
            Array.isArray(parsed)
        ) {
            throw new Error(
                'Invalid settings format.',
            );
        }

        settings.value = normalizeSettings(
            parsed as Partial<FocuraSettings>,
        );

        persist();

        applyAppearance(
            settings.value.appearance,
        );
    } catch {
        settings.value = {
            ...DEFAULT_FOCURA_SETTINGS,
        };

        localStorage.removeItem(
            STORAGE_KEY,
        );

        applyAppearance('light');
    }
}

function update(
    changes: Partial<FocuraSettings>,
): void {
    initialize();

    settings.value = normalizeSettings({
        ...settings.value,
        ...changes,
    });

    persist();

    applyAppearance(
        settings.value.appearance,
    );
}

function reset(): void {
    initialize();

    settings.value = {
        ...DEFAULT_FOCURA_SETTINGS,
    };

    persist();

    applyAppearance('light');
}

watch(
    () => settings.value.appearance,
    (appearance) => {
        applyAppearance(appearance);
    },
);

const focusDurationSeconds = computed(
    () =>
        settings.value.focusDurationMinutes *
        60,
);

const shortBreakDurationSeconds = computed(
    () =>
        settings.value.shortBreakDurationMinutes *
        60,
);

const longBreakDurationSeconds = computed(
    () =>
        settings.value.longBreakDurationMinutes *
        60,
);

export function useSettings() {
    initialize();

    return {
        settings,

        focusDurationSeconds,
        shortBreakDurationSeconds,
        longBreakDurationSeconds,

        update,
        reset,
    };
}
