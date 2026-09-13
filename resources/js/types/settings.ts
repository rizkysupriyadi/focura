export type FocuraAppearance =
    | 'light'
    | 'dark';

export interface FocuraSettings {
    appearance: FocuraAppearance;
    focusDurationMinutes: number;
    shortBreakDurationMinutes: number;
    longBreakDurationMinutes: number;
    interruptionTrackingEnabled: boolean;
    interruptionWarningEnabled: boolean;
    interruptionWarningSoundEnabled: boolean;
    completionNotificationEnabled: boolean;
    completionSoundEnabled: boolean;
}

export const DEFAULT_FOCURA_SETTINGS: FocuraSettings = {
    appearance: 'light',
    focusDurationMinutes: 25,
    shortBreakDurationMinutes: 5,
    longBreakDurationMinutes: 15,
    interruptionTrackingEnabled: true,
    interruptionWarningEnabled: true,
    interruptionWarningSoundEnabled: true,
    completionNotificationEnabled: false,
    completionSoundEnabled: true,
};
