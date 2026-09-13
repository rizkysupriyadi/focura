<?php

namespace Tests\Feature;

use App\Models\FocusSession;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InsightsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_requires_a_visitor_id(): void
    {
        $response = $this->getJson(
            '/api/v1/insights',
        );

        $response
            ->assertStatus(422)
            ->assertJsonValidationErrors([
                'visitor_id',
            ]);
    }

    public function test_it_rejects_an_invalid_visitor_id(): void
    {
        $response = $this->withHeaders([
            'X-Visitor-Id' => 'not-a-uuid',
        ])->getJson(
            '/api/v1/insights',
        );

        $response
            ->assertStatus(422)
            ->assertJsonValidationErrors([
                'visitor_id',
            ]);
    }

    public function test_it_rejects_an_invalid_range(): void
    {
        $response = $this->withHeaders([
            'X-Visitor-Id' => '550e8400-e29b-41d4-a716-446655440000',
        ])->getJson(
            '/api/v1/insights?range=365d',
        );

        $response
            ->assertStatus(422)
            ->assertJsonValidationErrors([
                'range',
            ]);
    }

    public function test_it_returns_empty_insights_for_a_new_visitor(): void
    {
        $visitorId =
            '550e8400-e29b-41d4-a716-446655440000';

        $response = $this->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])->getJson(
            '/api/v1/insights?range=30d',
        );

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.summary.sessions_completed',
                0,
            )
            ->assertJsonPath(
                'data.summary.focus_sessions',
                0,
            )
            ->assertJsonPath(
                'data.summary.relax_sessions',
                0,
            )
            ->assertJsonPath(
                'data.summary.total_focus_time_seconds',
                0,
            )
            ->assertJsonPath(
                'data.summary.total_interruption_time_seconds',
                0,
            )
            ->assertJsonPath(
                'data.interruptions.total_count',
                0,
            )
            ->assertJsonPath(
                'data.interruptions.sessions_interrupted',
                0,
            )
            ->assertJsonPath(
                'data.trend',
                [],
            );
    }

    public function test_it_separates_focus_and_relax_analytics(): void
    {
        $visitorId =
            '550e8400-e29b-41d4-a716-446655440000';

        FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'focus',
            'title' => 'Focus session',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1500,
            'focused_duration_seconds' => 1200,
            'interrupted_duration_seconds' => 300,
            'interruption_count' => 1,
            'focus_integrity' => 80,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(35),
        ]);

        FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'relax',
            'title' => 'Relax session',
            'planned_duration_seconds' => 300,
            'actual_duration_seconds' => 300,
            'focused_duration_seconds' => 300,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => null,
            'status' => 'completed',
            'started_at' => now()->subMinutes(30),
            'ended_at' => now()->subMinutes(25),
        ]);

        $response = $this->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])->getJson(
            '/api/v1/insights?range=30d',
        );

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.summary.sessions_completed',
                2,
            )
            ->assertJsonPath(
                'data.summary.focus_sessions',
                1,
            )
            ->assertJsonPath(
                'data.summary.relax_sessions',
                1,
            )
            ->assertJsonPath(
                'data.summary.total_focus_time_seconds',
                1200,
            )
            ->assertJsonPath(
                'data.summary.total_interruption_time_seconds',
                300,
            )
            ->assertJsonPath(
                'data.summary.average_session_duration_seconds',
                900,
            )
            ->assertJsonPath(
                'data.summary.average_focus_integrity',
                80,
            )
            ->assertJsonPath(
                'data.summary.focus_consistency',
                80,
            );
    }

    public function test_it_does_not_include_another_visitors_sessions(): void
    {
        $visitorId =
            '550e8400-e29b-41d4-a716-446655440000';

        $otherVisitorId =
            '6ba7b810-9dad-41d1-80b4-00c04fd430c8';

        FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1200,
            'focused_duration_seconds' => 1200,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(40),
        ]);

        FocusSession::create([
            'visitor_id' => $otherVisitorId,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1800,
            'focused_duration_seconds' => 1800,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(30),
        ]);

        $response = $this->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])->getJson(
            '/api/v1/insights?range=30d',
        );

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.summary.sessions_completed',
                1,
            )
            ->assertJsonPath(
                'data.summary.total_focus_time_seconds',
                1200,
            );
    }

    public function test_it_applies_the_requested_range(): void
    {
        $visitorId =
            '550e8400-e29b-41d4-a716-446655440000';

        FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1500,
            'focused_duration_seconds' => 1500,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subDays(2),
            'ended_at' => now()->subDays(2)->addMinutes(25),
        ]);

        FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1800,
            'focused_duration_seconds' => 1800,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subDays(40),
            'ended_at' => now()->subDays(40)->addMinutes(30),
        ]);

        $response = $this->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])->getJson(
            '/api/v1/insights?range=7d',
        );

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.summary.sessions_completed',
                1,
            )
            ->assertJsonPath(
                'data.summary.total_focus_time_seconds',
                1500,
            );
    }

    public function test_it_returns_daily_trend_data(): void
    {
        $visitorId =
            '550e8400-e29b-41d4-a716-446655440000';

        $date = now()
            ->subDays(2)
            ->startOfDay()
            ->addHours(9);

        FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1500,
            'focused_duration_seconds' => 1200,
            'interrupted_duration_seconds' => 300,
            'interruption_count' => 1,
            'focus_integrity' => 80,
            'status' => 'completed',
            'started_at' => $date,
            'ended_at' => $date->copy()->addMinutes(25),
        ]);

        FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'relax',
            'planned_duration_seconds' => 300,
            'actual_duration_seconds' => 300,
            'focused_duration_seconds' => 300,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => null,
            'status' => 'completed',
            'started_at' => $date->copy()->addHours(2),
            'ended_at' => $date->copy()->addHours(2)->addMinutes(5),
        ]);

        $response = $this->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])->getJson(
            '/api/v1/insights?range=7d',
        );

        $response
            ->assertSuccessful()
            ->assertJsonCount(
                1,
                'data.trend',
            )
            ->assertJsonPath(
                'data.trend.0.date',
                $date->toDateString(),
            )
            ->assertJsonPath(
                'data.trend.0.sessions_completed',
                2,
            )
            ->assertJsonPath(
                'data.trend.0.focus_sessions',
                1,
            )
            ->assertJsonPath(
                'data.trend.0.relax_sessions',
                1,
            )
            ->assertJsonPath(
                'data.trend.0.focus_time_seconds',
                1200,
            )
            ->assertJsonPath(
                'data.trend.0.interruption_time_seconds',
                300,
            )
            ->assertJsonPath(
                'data.trend.0.actual_time_seconds',
                1800,
            )
            ->assertJsonPath(
                'data.trend.0.focus_integrity',
                80,
            );
    }

    public function test_it_aggregates_interruption_metrics(): void
    {
        $visitorId =
            '550e8400-e29b-41d4-a716-446655440000';

        $session = FocusSession::create([
            'visitor_id' => $visitorId,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1800,
            'focused_duration_seconds' => 1500,
            'interrupted_duration_seconds' => 300,
            'interruption_count' => 2,
            'focus_integrity' => 83.33,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(30),
        ]);

        $session->interruptions()->create([
            'started_at' => now()->subMinutes(55),
            'ended_at' => now()->subMinutes(52),
            'duration_seconds' => 180,
        ]);

        $session->interruptions()->create([
            'started_at' => now()->subMinutes(48),
            'ended_at' => now()->subMinutes(46),
            'duration_seconds' => 120,
        ]);

        $response = $this->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])->getJson(
            '/api/v1/insights?range=30d',
        );

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.interruptions.total_count',
                2,
            )
            ->assertJsonPath(
                'data.interruptions.total_duration_seconds',
                300,
            )
            ->assertJsonPath(
                'data.interruptions.average_duration_seconds',
                150,
            )
            ->assertJsonPath(
                'data.interruptions.sessions_interrupted',
                1,
            );
    }

    public function test_it_returns_insights_for_an_authenticated_user(): void
    {
        $user = \App\Models\User::factory()->create();

        FocusSession::create([
            'user_id' => $user->id,
            'visitor_id' => null,
            'mode' => 'focus',
            'title' => 'Authenticated focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1500,
            'focused_duration_seconds' => 1500,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(35),
        ]);

        $response = $this
            ->actingAs($user)
            ->getJson('/api/v1/insights?range=30d');

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.summary.sessions_completed',
                1,
            )
            ->assertJsonPath(
                'data.summary.focus_sessions',
                1,
            )
            ->assertJsonPath(
                'data.summary.total_focus_time_seconds',
                1500,
            );
    }

    public function test_authenticated_user_only_sees_own_insights(): void
    {
        $user = \App\Models\User::factory()->create();
        $otherUser = \App\Models\User::factory()->create();

        FocusSession::create([
            'user_id' => $user->id,
            'visitor_id' => null,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1200,
            'focused_duration_seconds' => 1200,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(40),
        ]);

        FocusSession::create([
            'user_id' => $otherUser->id,
            'visitor_id' => null,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1800,
            'focused_duration_seconds' => 1800,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(30),
        ]);

        $response = $this
            ->actingAs($user)
            ->getJson('/api/v1/insights?range=30d');

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.summary.sessions_completed',
                1,
            )
            ->assertJsonPath(
                'data.summary.total_focus_time_seconds',
                1200,
            );
    }

    public function test_authenticated_user_ignores_visitor_header_for_insights(): void
    {
        $user = \App\Models\User::factory()->create();

        $visitorId =
            '550e8400-e29b-41d4-a716-446655440000';

        FocusSession::create([
            'user_id' => $user->id,
            'visitor_id' => null,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1200,
            'focused_duration_seconds' => 1200,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(40),
        ]);

        FocusSession::create([
            'user_id' => null,
            'visitor_id' => $visitorId,
            'mode' => 'focus',
            'planned_duration_seconds' => 1800,
            'actual_duration_seconds' => 1800,
            'focused_duration_seconds' => 1800,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => 100,
            'status' => 'completed',
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(30),
        ]);

        $response = $this
            ->actingAs($user)
            ->withHeaders([
                'X-Visitor-Id' => $visitorId,
            ])
            ->getJson('/api/v1/insights?range=30d');

        $response
            ->assertSuccessful()
            ->assertJsonPath(
                'data.summary.sessions_completed',
                1,
            )
            ->assertJsonPath(
                'data.summary.total_focus_time_seconds',
                1200,
            );
    }

}
