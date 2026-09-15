import type {
    FocusInsights,
    FocusInsightsRange,
} from '@/types/focusSession';

export type InsightShareFormat =
    | 'classic'
    | 'minimal'
    | 'metrics'
    | 'profile';

export type InsightShareBackground =
    | 'solid'
    | 'transparent';

interface InsightShareOptions {
    insights: FocusInsights;
    range: FocusInsightsRange;
    format: InsightShareFormat;
    background: InsightShareBackground;
    accountName: string;
}

const SHARE_SIZE = {
    width: 1080,
    height: 1350,
};

const WHITE = '#ffffff';
const DARK = '#0f172a';

function formatDuration(seconds: number): string {
    const safeSeconds = Math.max(
        0,
        Math.round(seconds),
    );

    const hours = Math.floor(
        safeSeconds / 3600,
    );

    const minutes = Math.floor(
        (safeSeconds % 3600) / 60,
    );

    if (hours > 0) {
        return `${hours}h ${minutes}m`;
    }

    if (minutes > 0) {
        return `${minutes}m`;
    }

    return `${safeSeconds}s`;
}

function formatNumber(value: number): string {
    return new Intl.NumberFormat('en-US', {
        maximumFractionDigits: 2,
    }).format(value);
}

function rangeLabel(
    range: FocusInsightsRange,
): string {
    switch (range) {
        case 'today':
            return 'TODAY';

        case '7d':
            return 'THIS WEEK';

        case '30d':
            return 'THIS MONTH';

        case '90d':
            return 'LAST 90 DAYS';

        case 'all':
            return 'ALL TIME';
    }
}

function drawText(
    context: CanvasRenderingContext2D,
    text: string,
    x: number,
    y: number,
    font: string,
    align: CanvasTextAlign = 'left',
): void {
    context.font = font;
    context.fillStyle = WHITE;
    context.textAlign = align;
    context.textBaseline = 'alphabetic';
    context.fillText(text, x, y);
}

function drawBackground(
    context: CanvasRenderingContext2D,
    background: InsightShareBackground,
    width: number,
    height: number,
): void {
    if (background !== 'solid') {
        return;
    }

    context.fillStyle = DARK;
    context.fillRect(
        0,
        0,
        width,
        height,
    );
}

function drawClassic(
    context: CanvasRenderingContext2D,
    options: InsightShareOptions,
): void {
    const centerX = SHARE_SIZE.width / 2;
    const padding = 90;

    drawText(
        context,
        'FOCURA',
        padding,
        118,
        '800 68px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
    );

    drawText(
        context,
        'Focus with intention.',
        padding,
        170,
        '500 34px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
    );

    drawText(
        context,
        rangeLabel(options.range),
        centerX,
        310,
        '800 38px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'TOTAL FOCUS',
        centerX,
        405,
        '800 34px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        formatDuration(
            options.insights.summary
                .total_focus_time_seconds,
        ),
        centerX,
        540,
        '800 132px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'focused time',
        centerX,
        590,
        '600 34px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'FOCUS INTEGRITY',
        centerX,
        735,
        '800 34px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .average_focus_integrity === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .average_focus_integrity,
              )}%`,
        centerX,
        825,
        '800 86px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'CONSISTENCY',
        centerX,
        940,
        '800 34px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .focus_consistency === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .focus_consistency,
              )}%`,
        centerX,
        1030,
        '800 86px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.accountName,
        centerX,
        1190,
        '700 38px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );
}

function drawMinimal(
    context: CanvasRenderingContext2D,
    options: InsightShareOptions,
): void {
    const centerX = SHARE_SIZE.width / 2;

    drawText(
        context,
        'FOCURA',
        centerX,
        150,
        '800 72px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        rangeLabel(options.range),
        centerX,
        285,
        '800 40px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        formatDuration(
            options.insights.summary
                .total_focus_time_seconds,
        ),
        centerX,
        545,
        '800 154px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'TOTAL FOCUS',
        centerX,
        615,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'FOCUS INTEGRITY',
        centerX,
        790,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .average_focus_integrity === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .average_focus_integrity,
              )}%`,
        centerX,
        890,
        '800 92px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'CONSISTENCY',
        centerX,
        1040,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .focus_consistency === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .focus_consistency,
              )}%`,
        centerX,
        1140,
        '800 92px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.accountName,
        centerX,
        1270,
        '700 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );
}

function drawMetrics(
    context: CanvasRenderingContext2D,
    options: InsightShareOptions,
): void {
    const centerX = SHARE_SIZE.width / 2;

    drawText(
        context,
        'FOCURA',
        centerX,
        125,
        '800 70px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        rangeLabel(options.range),
        centerX,
        250,
        '800 40px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'TOTAL FOCUS',
        centerX,
        385,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        formatDuration(
            options.insights.summary
                .total_focus_time_seconds,
        ),
        centerX,
        515,
        '800 128px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'FOCUS INTEGRITY',
        centerX,
        700,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .average_focus_integrity === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .average_focus_integrity,
              )}%`,
        centerX,
        800,
        '800 88px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'CONSISTENCY',
        centerX,
        970,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .focus_consistency === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .focus_consistency,
              )}%`,
        centerX,
        1070,
        '800 88px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.accountName,
        centerX,
        1220,
        '700 38px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );
}

function drawProfile(
    context: CanvasRenderingContext2D,
    options: InsightShareOptions,
): void {
    const centerX = SHARE_SIZE.width / 2;

    drawText(
        context,
        'FOCURA',
        centerX,
        125,
        '800 70px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.accountName,
        centerX,
        300,
        '800 62px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        rangeLabel(options.range),
        centerX,
        400,
        '800 38px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        formatDuration(
            options.insights.summary
                .total_focus_time_seconds,
        ),
        centerX,
        630,
        '800 150px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'TOTAL FOCUS',
        centerX,
        700,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'FOCUS INTEGRITY',
        centerX,
        870,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .average_focus_integrity === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .average_focus_integrity,
              )}%`,
        centerX,
        970,
        '800 88px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        'CONSISTENCY',
        centerX,
        1110,
        '800 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );

    drawText(
        context,
        options.insights.summary
            .focus_consistency === null
            ? '—'
            : `${formatNumber(
                  options.insights.summary
                      .focus_consistency,
              )}%`,
        centerX,
        1210,
        '800 88px Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        'center',
    );
}

export async function generateInsightSharePng(
    options: InsightShareOptions,
): Promise<Blob> {
    const canvas =
        document.createElement('canvas');

    canvas.width = SHARE_SIZE.width;
    canvas.height = SHARE_SIZE.height;

    const context = canvas.getContext('2d');

    if (!context) {
        throw new Error(
            'Unable to create the insight image.',
        );
    }

    context.imageSmoothingEnabled = true;

    drawBackground(
        context,
        options.background,
        SHARE_SIZE.width,
        SHARE_SIZE.height,
    );

    switch (options.format) {
        case 'minimal':
            drawMinimal(context, options);
            break;

        case 'metrics':
            drawMetrics(context, options);
            break;

        case 'profile':
            drawProfile(context, options);
            break;

        case 'classic':
        default:
            drawClassic(context, options);
            break;
    }

    return new Promise((resolve, reject) => {
        canvas.toBlob(
            (blob) => {
                if (!blob) {
                    reject(
                        new Error(
                            'Unable to create the insight image.',
                        ),
                    );

                    return;
                }

                resolve(blob);
            },
            'image/png',
        );
    });
}

export async function shareInsightPng(
    blob: Blob,
    range: FocusInsightsRange,
): Promise<boolean> {
    if (
        typeof navigator.share !== 'function' ||
        typeof navigator.canShare !== 'function'
    ) {
        return false;
    }

    const file = new File(
        [blob],
        `focura-${range}-insights.png`,
        {
            type: 'image/png',
        },
    );

    if (!navigator.canShare({ files: [file] })) {
        return false;
    }

    await navigator.share({
        title: 'Focura Focus Insights',
        text: 'My focus insights from Focura.',
        files: [file],
    });

    return true;
}

export function downloadInsightPng(
    blob: Blob,
    range: FocusInsightsRange,
): void {
    const url = URL.createObjectURL(blob);

    const anchor =
        document.createElement('a');

    anchor.href = url;
    anchor.download =
        `focura-${range}-insights.png`;

    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();

    window.setTimeout(() => {
        URL.revokeObjectURL(url);
    }, 1000);
}
