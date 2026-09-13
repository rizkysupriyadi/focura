<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InsightsResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $data = is_array($this->resource)
            ? $this->resource
            : [];

        $summary = is_array($data['summary'] ?? null)
            ? $data['summary']
            : [];

        $interruptions =
            is_array($data['interruptions'] ?? null)
                ? $data['interruptions']
                : [];

        $trend = is_array($data['trend'] ?? null)
            ? $data['trend']
            : [];

        return [
            'summary' => [
                'sessions_completed' => (int) (
                    $summary['sessions_completed'] ?? 0
                ),
                'total_focus_time_seconds' => (int) (
                    $summary[
                        'total_focus_time_seconds'
                    ] ?? 0
                ),
                'total_interruption_time_seconds' => (int) (
                    $summary[
                        'total_interruption_time_seconds'
                    ] ?? 0
                ),
                'average_session_duration_seconds' => (int) (
                    $summary[
                        'average_session_duration_seconds'
                    ] ?? 0
                ),
                'average_focus_integrity' => $summary['average_focus_integrity']
                    ?? null,
                'focus_consistency' => $summary['focus_consistency']
                    ?? null,
                'focus_sessions' => (int) (
                    $summary['focus_sessions'] ?? 0
                ),
                'relax_sessions' => (int) (
                    $summary['relax_sessions'] ?? 0
                ),
            ],

            'trend' => array_values(
                array_map(
                    static function (mixed $item): array {
                        $item = is_array($item)
                            ? $item
                            : [];

                        return [
                            'date' => (string) (
                                $item['date'] ?? ''
                            ),
                            'sessions_completed' => (int) (
                                $item[
                                    'sessions_completed'
                                ] ?? 0
                            ),
                            'focus_sessions' => (int) (
                                $item[
                                    'focus_sessions'
                                ] ?? 0
                            ),
                            'relax_sessions' => (int) (
                                $item[
                                    'relax_sessions'
                                ] ?? 0
                            ),
                            'focus_time_seconds' => (int) (
                                $item[
                                    'focus_time_seconds'
                                ] ?? 0
                            ),
                            'interruption_time_seconds' => (int) (
                                $item[
                                    'interruption_time_seconds'
                                ] ?? 0
                            ),
                            'actual_time_seconds' => (int) (
                                $item[
                                    'actual_time_seconds'
                                ] ?? 0
                            ),
                            'focus_integrity' => $item[
                                    'focus_integrity'
                                ] ?? null,
                        ];
                    },
                    $trend,
                ),
            ),

            'interruptions' => [
                'total_count' => (int) (
                    $interruptions['total_count'] ?? 0
                ),
                'total_duration_seconds' => (int) (
                    $interruptions[
                        'total_duration_seconds'
                    ] ?? 0
                ),
                'average_duration_seconds' => (int) (
                    $interruptions[
                        'average_duration_seconds'
                    ] ?? 0
                ),
                'sessions_interrupted' => (int) (
                    $interruptions[
                        'sessions_interrupted'
                    ] ?? 0
                ),
            ],
        ];
    }
}
