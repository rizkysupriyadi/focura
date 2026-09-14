const CACHE_NAME = 'focura-shell-v2';

const APP_SHELL = [
    '/',
    '/focus',
    '/manifest.webmanifest',
    '/focura-icon.svg',
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            return cache.addAll(APP_SHELL);
        }),
    );

    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) => {
            return Promise.all(
                keys
                    .filter((key) => key !== CACHE_NAME)
                    .map((key) => caches.delete(key)),
            );
        }),
    );

    self.clients.claim();
});

self.addEventListener('fetch', (event) => {
    const request = event.request;

    if (request.method !== 'GET') {
        return;
    }

    const url = new URL(request.url);

    if (url.origin !== self.location.origin) {
        return;
    }

    if (url.pathname.startsWith('/api/')) {
        return;
    }

    if (
        url.pathname.startsWith('/build/') ||
        url.pathname === '/focura-icon.svg' ||
        url.pathname === '/manifest.webmanifest'
    ) {
        event.respondWith(
            caches.match(request).then((cached) => {
                if (cached) {
                    return cached;
                }

                return fetch(request).then((response) => {
                    if (
                        response.ok &&
                        response.type === 'basic'
                    ) {
                        const responseClone =
                            response.clone();

                        void caches.open(
                            CACHE_NAME,
                        ).then((cache) => {
                            void cache.put(
                                request,
                                responseClone,
                            );
                        });
                    }

                    return response;
                });
            }),
        );

        return;
    }

    event.respondWith(
        fetch(request).catch(() => {
            return caches.match(request);
        }),
    );
});
