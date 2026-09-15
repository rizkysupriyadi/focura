const NORMAL_FAVICON = '/favicon.svg';

const LOADING_FRAMES = [
    'data:image/svg+xml;charset=utf-8,' +
        encodeURIComponent(`
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
                <rect width="32" height="32" rx="8" fill="#2563eb"/>
                <circle cx="16" cy="16" r="7" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-dasharray="22 22"/>
            </svg>
        `),
    'data:image/svg+xml;charset=utf-8,' +
        encodeURIComponent(`
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
                <rect width="32" height="32" rx="8" fill="#2563eb"/>
                <circle cx="16" cy="16" r="7" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-dasharray="22 22" stroke-dashoffset="7"/>
            </svg>
        `),
    'data:image/svg+xml;charset=utf-8,' +
        encodeURIComponent(`
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
                <rect width="32" height="32" rx="8" fill="#2563eb"/>
                <circle cx="16" cy="16" r="7" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-dasharray="22 22" stroke-dashoffset="14"/>
            </svg>
        `),
    'data:image/svg+xml;charset=utf-8,' +
        encodeURIComponent(`
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
                <rect width="32" height="32" rx="8" fill="#2563eb"/>
                <circle cx="16" cy="16" r="7" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-dasharray="22 22" stroke-dashoffset="21"/>
            </svg>
        `),
];

let faviconLink: HTMLLinkElement | null = null;
let animationId: number | null = null;
let frameIndex = 0;
let loadingDepth = 0;
let startTimer: number | null = null;

function getFaviconLink(): HTMLLinkElement {
    if (faviconLink) {
        return faviconLink;
    }

    const existing =
        document.querySelector<HTMLLinkElement>('link[rel="icon"]');

    if (existing) {
        faviconLink = existing;

        return existing;
    }

    const link = document.createElement('link');

    link.rel = 'icon';
    link.type = 'image/svg+xml';
    link.href = NORMAL_FAVICON;

    document.head.appendChild(link);

    faviconLink = link;

    return link;
}

function setFavicon(href: string): void {
    getFaviconLink().href = href;
}

function animate(): void {
    if (loadingDepth <= 0) {
        animationId = null;

        return;
    }

    frameIndex = (frameIndex + 1) % LOADING_FRAMES.length;

    setFavicon(LOADING_FRAMES[frameIndex]);

    animationId = window.setTimeout(animate, 180);
}

function beginAnimation(): void {
    if (animationId !== null) {
        return;
    }

    frameIndex = 0;

    setFavicon(LOADING_FRAMES[frameIndex]);

    animationId = window.setTimeout(animate, 180);
}

function endAnimation(): void {
    if (animationId !== null) {
        window.clearTimeout(animationId);
        animationId = null;
    }

    frameIndex = 0;

    setFavicon(NORMAL_FAVICON);
}

export function startTabLoading(): void {
    if (typeof document === 'undefined') {
        return;
    }

    loadingDepth += 1;

    /*
     * Avoid flashing the loading favicon for very fast
     * navigations. Only show it when loading lasts longer
     * than 120ms.
     */
    if (loadingDepth === 1) {
        if (startTimer !== null) {
            window.clearTimeout(startTimer);
        }

        startTimer = window.setTimeout(() => {
            startTimer = null;

            if (loadingDepth > 0) {
                beginAnimation();
            }
        }, 120);
    }
}

export function stopTabLoading(): void {
    if (typeof document === 'undefined') {
        return;
    }

    loadingDepth = Math.max(0, loadingDepth - 1);

    if (loadingDepth > 0) {
        return;
    }

    if (startTimer !== null) {
        window.clearTimeout(startTimer);
        startTimer = null;
    }

    endAnimation();
}

export function resetTabLoading(): void {
    if (typeof document === 'undefined') {
        return;
    }

    loadingDepth = 0;

    if (startTimer !== null) {
        window.clearTimeout(startTimer);
        startTimer = null;
    }

    endAnimation();
}
