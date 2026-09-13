import {
    computed,
    onMounted,
    ref,
    watch,
} from 'vue';

export type FocusMusicSource =
    | 'off'
    | 'youtube'
    | 'spotify';

const STORAGE_KEY = 'focura.focus_music';

interface StoredFocusMusic {
    source: FocusMusicSource;
    url: string;
}

interface FocusMusicState {
    source: FocusMusicSource;
    url: string;
}

function isValidSource(
    value: unknown,
): value is FocusMusicSource {
    return (
        value === 'off' ||
        value === 'youtube' ||
        value === 'spotify'
    );
}

function loadState(): FocusMusicState {
    if (typeof window === 'undefined') {
        return {
            source: 'off',
            url: '',
        };
    }

    try {
        const stored =
            localStorage.getItem(STORAGE_KEY);

        if (!stored) {
            return {
                source: 'off',
                url: '',
            };
        }

        const parsed =
            JSON.parse(stored) as Partial<StoredFocusMusic>;

        return {
            source: isValidSource(parsed.source)
                ? parsed.source
                : 'off',
            url:
                typeof parsed.url === 'string'
                    ? parsed.url
                    : '',
        };
    } catch {
        return {
            source: 'off',
            url: '',
        };
    }
}

function getYouTubeVideoId(
    url: URL,
): string | null {
    if (
        url.hostname === 'youtu.be' ||
        url.hostname === 'www.youtu.be'
    ) {
        const id = url.pathname
            .split('/')
            .filter(Boolean)[0];

        return id ?? null;
    }

    if (
        url.hostname === 'youtube.com' ||
        url.hostname === 'www.youtube.com' ||
        url.hostname === 'm.youtube.com'
    ) {
        const pathname =
            url.pathname;

        if (
            pathname === '/watch' ||
            pathname === '/watch/'
        ) {
            return url.searchParams.get('v');
        }

        const segments = pathname
            .split('/')
            .filter(Boolean);

        if (
            segments[0] === 'embed' ||
            segments[0] === 'shorts'
        ) {
            return segments[1] ?? null;
        }
    }

    return null;
}

function getYouTubePlaylistId(
    url: URL,
): string | null {
    const list =
        url.searchParams.get('list');

    if (!list) {
        return null;
    }

    return list;
}

function buildYouTubeEmbedUrl(
    input: string,
): string | null {
    try {
        const url = new URL(input.trim());

        const hostname =
            url.hostname.toLowerCase();

        const isYouTube =
            hostname === 'youtube.com' ||
            hostname === 'www.youtube.com' ||
            hostname === 'm.youtube.com' ||
            hostname === 'youtu.be' ||
            hostname === 'www.youtu.be';

        if (!isYouTube) {
            return null;
        }

        const playlistId =
            getYouTubePlaylistId(url);

        const videoId =
            getYouTubeVideoId(url);

        if (videoId && playlistId) {
            return `https://www.youtube.com/embed/${encodeURIComponent(videoId)}?list=${encodeURIComponent(playlistId)}`;
        }

        if (videoId) {
            return `https://www.youtube.com/embed/${encodeURIComponent(videoId)}`;
        }

        if (playlistId) {
            return `https://www.youtube.com/embed/videoseries?list=${encodeURIComponent(playlistId)}`;
        }

        return null;
    } catch {
        return null;
    }
}

function buildSpotifyEmbedUrl(
    input: string,
): string | null {
    try {
        const url = new URL(input.trim());

        const hostname =
            url.hostname.toLowerCase();

        if (
            hostname !== 'open.spotify.com' &&
            hostname !== 'spotify.link'
        ) {
            return null;
        }

        const segments = url.pathname
            .split('/')
            .filter(Boolean);

        if (
            segments.length < 2 ||
            segments[0] === 'intl-id'
        ) {
            return null;
        }

        let type = segments[0];
        let id = segments[1];

        if (
            type.startsWith('intl-') &&
            segments.length >= 4
        ) {
            type = segments[2];
            id = segments[3];
        }

        const supportedTypes = [
            'track',
            'playlist',
            'album',
            'artist',
            'show',
            'episode',
        ];

        if (
            !supportedTypes.includes(type) ||
            !id
        ) {
            return null;
        }

        return `https://open.spotify.com/embed/${encodeURIComponent(type)}/${encodeURIComponent(id)}`;
    } catch {
        return null;
    }
}

export function useFocusMusic() {
    const source = ref<FocusMusicSource>('off');
    const url = ref('');
    const draftUrl = ref('');
    const error = ref<string | null>(null);
    const isLoaded = ref(false);

    const embedUrl = computed(() => {
        if (
            source.value === 'youtube'
        ) {
            return buildYouTubeEmbedUrl(
                url.value,
            );
        }

        if (
            source.value === 'spotify'
        ) {
            return buildSpotifyEmbedUrl(
                url.value,
            );
        }

        return null;
    });

    const hasPlayer = computed(() => {
        return (
            source.value !== 'off' &&
            embedUrl.value !== null
        );
    });

    const sourceLabel = computed(() => {
        switch (source.value) {
            case 'youtube':
                return 'YouTube';

            case 'spotify':
                return 'Spotify';

            default:
                return 'Off';
        }
    });

    function persist(): void {
        if (typeof window === 'undefined') {
            return;
        }

        const state: StoredFocusMusic = {
            source: source.value,
            url: url.value,
        };

        localStorage.setItem(
            STORAGE_KEY,
            JSON.stringify(state),
        );
    }

    function selectSource(
        nextSource: FocusMusicSource,
    ): void {
        source.value = nextSource;
        error.value = null;

        if (nextSource === 'off') {
            url.value = '';
            draftUrl.value = '';
            persist();
        }
    }

    function loadMusic(): boolean {
        const normalized =
            draftUrl.value.trim();

        if (source.value === 'off') {
            url.value = '';
            error.value = null;
            persist();

            return true;
        }

        if (!normalized) {
            error.value =
                `Paste a ${sourceLabel.value} URL first.`;

            return false;
        }

        const nextEmbedUrl =
            source.value === 'youtube'
                ? buildYouTubeEmbedUrl(
                      normalized,
                  )
                : buildSpotifyEmbedUrl(
                      normalized,
                  );

        if (!nextEmbedUrl) {
            error.value =
                source.value === 'youtube'
                    ? 'Enter a valid YouTube video or playlist URL.'
                    : 'Enter a valid Spotify track, playlist, album, artist, show, or episode URL.';

            return false;
        }

        url.value = normalized;
        error.value = null;
        persist();

        return true;
    }

    function clearMusic(): void {
        source.value = 'off';
        url.value = '';
        draftUrl.value = '';
        error.value = null;
        persist();
    }

    onMounted(() => {
        const state = loadState();

        source.value = state.source;
        url.value = state.url;
        draftUrl.value = state.url;
        isLoaded.value = true;
    });

    watch(
        [source, url],
        () => {
            if (!isLoaded.value) {
                return;
            }

            persist();
        },
    );

    return {
        source,
        url,
        draftUrl,
        error,
        embedUrl,
        hasPlayer,
        sourceLabel,
        selectSource,
        loadMusic,
        clearMusic,
    };
}
