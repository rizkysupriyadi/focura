export function getCsrfToken(): string | null {
    if (
        typeof document === 'undefined'
    ) {
        return null;
    }

    const meta = document.querySelector(
        'meta[name="csrf-token"]',
    );

    if (!(meta instanceof HTMLMetaElement)) {
        return null;
    }

    return meta.content || null;
}

export function getCsrfHeaders(): HeadersInit {
    const token = getCsrfToken();

    if (!token) {
        throw new Error(
            'Unable to obtain the CSRF token.',
        );
    }

    return {
        'X-CSRF-TOKEN': token,
    };
}
