import {
    onBeforeUnmount,
} from 'vue';

type AudioContextWithWebkit =
    typeof window & {
        webkitAudioContext?: typeof AudioContext;
    };

function getAudioContextConstructor():
    | typeof AudioContext
    | null {
    if (typeof window === 'undefined') {
        return null;
    }

    const audioWindow =
        window as AudioContextWithWebkit;

    return (
        window.AudioContext ??
        audioWindow.webkitAudioContext ??
        null
    );
}

function createContext(): AudioContext | null {
    const AudioContextConstructor =
        getAudioContextConstructor();

    if (!AudioContextConstructor) {
        return null;
    }

    try {
        return new AudioContextConstructor();
    } catch {
        return null;
    }
}

function playTone(
    context: AudioContext,
    frequency: number,
    startTime: number,
    duration: number,
    volume: number,
): void {
    const oscillator =
        context.createOscillator();

    const gain =
        context.createGain();

    oscillator.type = 'sine';

    oscillator.frequency.setValueAtTime(
        frequency,
        startTime,
    );

    gain.gain.setValueAtTime(
        0.0001,
        startTime,
    );

    gain.gain.exponentialRampToValueAtTime(
        volume,
        startTime + 0.02,
    );

    gain.gain.exponentialRampToValueAtTime(
        0.0001,
        startTime + duration,
    );

    oscillator.connect(gain);
    gain.connect(context.destination);

    oscillator.start(startTime);
    oscillator.stop(startTime + duration);
}

export function useAudio() {
    let activeContext: AudioContext | null = null;

    function playCompletionSound(): void {
        const context = createContext();

        if (!context) {
            return;
        }

        activeContext = context;

        const now = context.currentTime;

        try {
            playTone(
                context,
                660,
                now,
                0.35,
                0.12,
            );

            playTone(
                context,
                880,
                now + 0.12,
                0.35,
                0.12,
            );

            void context.resume().catch(() => {
                // Audio is optional.
            });

            window.setTimeout(() => {
                void context.close().catch(() => {
                    // Audio cleanup is optional.
                });

                if (activeContext === context) {
                    activeContext = null;
                }
            }, 500);
        } catch {
            void context.close().catch(() => {
                // Audio cleanup is optional.
            });

            if (activeContext === context) {
                activeContext = null;
            }
        }
    }

    function playInterruptionWarningSound(): void {
        const context = createContext();

        if (!context) {
            return;
        }

        activeContext = context;

        const now = context.currentTime;

        try {
            playTone(
                context,
                520,
                now,
                0.16,
                0.08,
            );

            playTone(
                context,
                420,
                now + 0.18,
                0.16,
                0.08,
            );

            void context.resume().catch(() => {
                // Audio is optional.
            });

            window.setTimeout(() => {
                void context.close().catch(() => {
                    // Audio cleanup is optional.
                });

                if (activeContext === context) {
                    activeContext = null;
                }
            }, 400);
        } catch {
            void context.close().catch(() => {
                // Audio cleanup is optional.
            });

            if (activeContext === context) {
                activeContext = null;
            }
        }
    }

    onBeforeUnmount(() => {
        if (!activeContext) {
            return;
        }

        void activeContext.close().catch(() => {
            // Audio cleanup is optional.
        });

        activeContext = null;
    });

    return {
        playCompletionSound,
        playInterruptionWarningSound,
    };
}
