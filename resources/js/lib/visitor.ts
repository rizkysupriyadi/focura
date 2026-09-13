const VISITOR_STORAGE_KEY = 'focura.visitor_id';

function createVisitorId(): string {
    if (
        typeof crypto !== 'undefined' &&
        typeof crypto.randomUUID === 'function'
    ) {
        return crypto.randomUUID();
    }

    const timestamp = Date.now().toString(16);

    const randomPart =
        Math.random().toString(16).slice(2) +
        Math.random().toString(16).slice(2);

    return `${timestamp}-${randomPart}`;
}

function isValidVisitorId(value: string): boolean {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        value,
    );
}

export function getVisitorId(): string {
    if (typeof window === 'undefined') {
        return '';
    }

    const existing = localStorage.getItem(
        VISITOR_STORAGE_KEY,
    );

    if (
        existing !== null &&
        isValidVisitorId(existing)
    ) {
        return existing;
    }

    const visitorId = createVisitorId();

    localStorage.setItem(
        VISITOR_STORAGE_KEY,
        visitorId,
    );

    return visitorId;
}