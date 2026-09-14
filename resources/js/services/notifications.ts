export type NotificationPermissionState =
    | 'default'
    | 'granted'
    | 'denied'
    | 'unsupported';

export function getNotificationPermission():
    NotificationPermissionState {
    if (
        typeof window === 'undefined' ||
        !('Notification' in window)
    ) {
        return 'unsupported';
    }

    return Notification.permission;
}

export function isNotificationSupported(): boolean {
    return (
        typeof window !== 'undefined' &&
        'Notification' in window
    );
}

export async function requestNotificationPermission():
    Promise<NotificationPermissionState> {
    if (!isNotificationSupported()) {
        return 'unsupported';
    }

    if (Notification.permission !== 'default') {
        return Notification.permission;
    }

    try {
        return await Notification.requestPermission();
    } catch {
        return 'default';
    }
}

export interface FocuraNotificationOptions {
    title: string;
    body: string;
    tag?: string;
}

export function showNotification(
    options: FocuraNotificationOptions,
): boolean {
    if (
        !isNotificationSupported() ||
        Notification.permission !== 'granted'
    ) {
        return false;
    }

    try {
        new Notification(options.title, {
            body: options.body,
            icon: '/favicon.svg',
            tag: options.tag,
        });

        return true;
    } catch {
        return false;
    }
}