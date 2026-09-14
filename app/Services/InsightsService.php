<?php

namespace App\Services;

use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

class InsightsService
{
    /**
     * Get aggregated insights belonging to the current identity.
     *
     * @param array{
     *     type: 'user'|'visitor',
     *     user_id: int|null,
     *     visitor_id: string|null
     * } $identity
     *
     * @return array{
     *     summary: array{
     *         sessions_completed: int,
     *         total_focus_time_seconds: int,
     *         total_interruption_time_seconds: int,
     *         average_session_duration_seconds: int,
     *         average_focus_integrity: float|null,
     *         focus_consistency: float|null,
     *         focus_sessions: int,
     *         relax_sessions: int
     *     },
     *     trend: array<int, array{
     *         date: string,
     *         sessions_completed: int,
     *         focus_sessions: int,
     *         relax_sessions: int,
     *         focus_time_seconds: int,
     *         interruption_time_seconds: int,
     *         actual_time_seconds: int,
     *         focus_integrity: float|null
     *     }>,
     *     interruptions: array{
     *         total_count: int,
     *         total_duration_seconds: int,
     *         average_duration_seconds: int,
     *         sessions_interrupted: int
     *     }
     * }
     */
    public function getForIdentity(
        array $identity,
        string $range = '30d',
    ): array {
        $query = DB::table('focus_sessions')
            ->where('status', 'completed');

        $this->applyIdentity(
            $query,
            $identity,
        );

        $this->applyRange(
            $query,
            $range,
        );

        $summaryRow = (array) $query
            ->selectRaw(
                'COUNT(*) AS sessions_completed',
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'focus'
                        THEN focused_duration_seconds
                        ELSE 0
                    END
                ), 0) AS total_focus_time_seconds",
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'focus'
                        THEN interrupted_duration_seconds
                        ELSE 0
                    END
                ), 0) AS total_interruption_time_seconds",
            )
            ->selectRaw(
                'COALESCE(AVG(actual_duration_seconds), 0) AS average_session_duration_seconds',
            )
            ->selectRaw(
                "AVG(
                    CASE
                        WHEN mode = 'focus'
                        THEN focus_integrity
                        ELSE NULL
                    END
                ) AS average_focus_integrity",
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'focus'
                        THEN actual_duration_seconds
                        ELSE 0
                    END
                ), 0) AS focus_actual_time_seconds",
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'focus'
                        THEN 1
                        ELSE 0
                    END
                ), 0) AS focus_sessions",
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'relax'
                        THEN 1
                        ELSE 0
                    END
                ), 0) AS relax_sessions",
            )
            ->first();

        $focusedDuration = (int) (
            $summaryRow[
                'total_focus_time_seconds'
            ] ?? 0
        );

        $focusActualTime = (int) (
            $summaryRow[
                'focus_actual_time_seconds'
            ] ?? 0
        );

        $focusConsistency = null;

        if ($focusActualTime > 0) {
            $focusConsistency = round(
                min(
                    100,
                    max(
                        0,
                        (
                            $focusedDuration /
                            $focusActualTime
                        ) * 100,
                    ),
                ),
                2,
            );
        }

        $averageFocusIntegrity =
            $summaryRow['average_focus_integrity']
            ?? null;

        $summary = [
            'sessions_completed' => (int) (
                $summaryRow['sessions_completed'] ?? 0
            ),
            'total_focus_time_seconds' => $focusedDuration,
            'total_interruption_time_seconds' => (int) (
                $summaryRow[
                    'total_interruption_time_seconds'
                ] ?? 0
            ),
            'average_session_duration_seconds' => (int) round(
                (float) (
                    $summaryRow[
                        'average_session_duration_seconds'
                    ] ?? 0
                ),
            ),
            'average_focus_integrity' => $averageFocusIntegrity === null
                    ? null
                    : round(
                        (float) $averageFocusIntegrity,
                        2,
                    ),
            'focus_consistency' => $focusConsistency,
            'focus_sessions' => (int) (
                $summaryRow['focus_sessions'] ?? 0
            ),
            'relax_sessions' => (int) (
                $summaryRow['relax_sessions'] ?? 0
            ),
        ];

        return [
            'summary' => $summary,
            'trend' => $this->getTrend(
                identity: $identity,
                range: $range,
            ),
            'interruptions' => $this->getInterruptionSummary(
                identity: $identity,
                range: $range,
            ),
        ];
    }

    /**
     * @param array{
     *     type: 'user'|'visitor',
     *     user_id: int|null,
     *     visitor_id: string|null
     * } $identity
     *
     * @return array<int, array{
     *     date: string,
     *     sessions_completed: int,
     *     focus_sessions: int,
     *     relax_sessions: int,
     *     focus_time_seconds: int,
     *     interruption_time_seconds: int,
     *     actual_time_seconds: int,
     *     focus_integrity: float|null
     * }>
     */
    private function getTrend(
        array $identity,
        string $range,
    ): array {
        $query = DB::table('focus_sessions')
            ->where('status', 'completed');

        $this->applyIdentity(
            $query,
            $identity,
        );

        $this->applyRange(
            $query,
            $range,
        );

        $rows = $query
            ->selectRaw(
                'DATE(started_at) AS trend_date',
            )
            ->selectRaw(
                'COUNT(*) AS sessions_completed',
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'focus'
                        THEN 1
                        ELSE 0
                    END
                ), 0) AS focus_sessions",
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'relax'
                        THEN 1
                        ELSE 0
                    END
                ), 0) AS relax_sessions",
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'focus'
                        THEN focused_duration_seconds
                        ELSE 0
                    END
                ), 0) AS focus_time_seconds",
            )
            ->selectRaw(
                "COALESCE(SUM(
                    CASE
                        WHEN mode = 'focus'
                        THEN interrupted_duration_seconds
                        ELSE 0
                    END
                ), 0) AS interruption_time_seconds",
            )
            ->selectRaw(
                'COALESCE(SUM(actual_duration_seconds), 0) AS actual_time_seconds',
            )
            ->selectRaw(
                "AVG(
                    CASE
                        WHEN mode = 'focus'
                        THEN focus_integrity
                        ELSE NULL
                    END
                ) AS focus_integrity",
            )
            ->groupByRaw(
                'DATE(started_at)',
            )
            ->orderBy('trend_date')
            ->get();

        $trend = [];

        foreach ($rows as $row) {
            $data = (array) $row;

            $trend[] = [
                'date' => (string) (
                    $data['trend_date'] ?? ''
                ),
                'sessions_completed' => (int) (
                    $data['sessions_completed'] ?? 0
                ),
                'focus_sessions' => (int) (
                    $data['focus_sessions'] ?? 0
                ),
                'relax_sessions' => (int) (
                    $data['relax_sessions'] ?? 0
                ),
                'focus_time_seconds' => (int) (
                    $data['focus_time_seconds'] ?? 0
                ),
                'interruption_time_seconds' => (int) (
                    $data[
                        'interruption_time_seconds'
                    ] ?? 0
                ),
                'actual_time_seconds' => (int) (
                    $data['actual_time_seconds'] ?? 0
                ),
                'focus_integrity' => $data['focus_integrity'] === null
                        ? null
                        : round(
                            (float) $data[
                                'focus_integrity'
                            ],
                            2,
                        ),
            ];
        }

        return $trend;
    }

    /**
     * @param array{
     *     type: 'user'|'visitor',
     *     user_id: int|null,
     *     visitor_id: string|null
     * } $identity
     *
     * @return array{
     *     total_count: int,
     *     total_duration_seconds: int,
     *     average_duration_seconds: int,
     *     sessions_interrupted: int
     * }
     */
    private function getInterruptionSummary(
        array $identity,
        string $range,
    ): array {
        $query = DB::table('session_interruptions')
            ->join(
                'focus_sessions',
                'focus_sessions.id',
                '=',
                'session_interruptions.focus_session_id',
            )
            ->where(
                'focus_sessions.status',
                'completed',
            );

        $this->applyIdentity(
            $query,
            $identity,
            'focus_sessions',
        );

        $this->applyRange(
            $query,
            $range,
            'focus_sessions.started_at',
        );

        $row = (array) $query
            ->selectRaw(
                'COUNT(session_interruptions.id) AS total_count',
            )
            ->selectRaw(
                'COALESCE(SUM(session_interruptions.duration_seconds), 0) AS total_duration_seconds',
            )
            ->selectRaw(
                'COUNT(DISTINCT session_interruptions.focus_session_id) AS sessions_interrupted',
            )
            ->first();

        $totalCount = (int) (
            $row['total_count'] ?? 0
        );

        $totalDuration = (int) (
            $row['total_duration_seconds'] ?? 0
        );

        return [
            'total_count' => $totalCount,
            'total_duration_seconds' => $totalDuration,
            'average_duration_seconds' => $totalCount > 0
                    ? (int) round(
                        $totalDuration / $totalCount,
                    )
                    : 0,
            'sessions_interrupted' => (int) (
                $row['sessions_interrupted'] ?? 0
            ),
        ];
    }

    /**
     * Apply the current identity to a focus-session query.
     *
     * @param array{
     *     type: 'user'|'visitor',
     *     user_id: int|null,
     *     visitor_id: string|null
     * } $identity
     */
    private function applyIdentity(
        Builder $query,
        array $identity,
        string $table = 'focus_sessions',
    ): void {
        if ($identity['type'] === 'user') {
            $query->where(
                "{$table}.user_id",
                $identity['user_id'],
            );

            return;
        }

        $query->where(
            "{$table}.visitor_id",
            $identity['visitor_id'],
        );
    }

    private function applyRange(
        Builder $query,
        string $range,
        string $column = 'started_at',
    ): void {
        match ($range) {
            'today' => $query->where(
                $column,
                '>=',
                now()->startOfDay(),
            ),
            '7d' => $query->where(
                $column,
                '>=',
                now()->subDays(6)->startOfDay(),
            ),
            '30d' => $query->where(
                $column,
                '>=',
                now()->subDays(29)->startOfDay(),
            ),
            '90d' => $query->where(
                $column,
                '>=',
                now()->subDays(89)->startOfDay(),
            ),
            'all' => null,
            default => $query->where(
                $column,
                '>=',
                now()->subDays(29)->startOfDay(),
            ),
        };
    }
}
