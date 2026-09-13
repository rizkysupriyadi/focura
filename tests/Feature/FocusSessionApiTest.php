<?php

use App\Models\FocusSession;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

uses(RefreshDatabase::class);

const TEST_VISITOR_ID = '550e8400-e29b-41d4-a716-446655440000';
const OTHER_VISITOR_ID = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

function createApiSession(
    string $visitorId = TEST_VISITOR_ID,
    string $mode = 'focus',
    string $status = 'active',
): FocusSession {
    return FocusSession::create([
        'visitor_id' => $visitorId,
        'mode' => $mode,
        'title' => 'Test session',
        'planned_duration_seconds' => 1500,
        'actual_duration_seconds' => 0,
        'focused_duration_seconds' => 0,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => null,
        'status' => $status,
        'started_at' => '2026-09-10 09:00:00',
        'ended_at' => null,
    ]);
}

it('creates a focus session through the api', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson('/api/v1/focus-sessions', [
        'mode' => 'focus',
        'title' => 'Deep work',
        'planned_duration_seconds' => 3000,
        'started_at' => '2026-09-10T09:00:00Z',
        'visitor_id' => TEST_VISITOR_ID,
    ]);

    $response
        ->assertCreated()
        ->assertJsonPath(
            'message',
            'Session created successfully.',
        )
        ->assertJsonPath(
            'data.mode',
            'focus',
        )
        ->assertJsonPath(
            'data.title',
            'Deep work',
        )
        ->assertJsonPath(
            'data.planned_duration_seconds',
            3000,
        )
        ->assertJsonPath(
            'data.status',
            'active',
        )
        ->assertJsonPath(
            'data.visitor_id',
            TEST_VISITOR_ID,
        );

    expect(FocusSession::query()->count())
        ->toBe(1)
        ->and(
            FocusSession::query()->first()?->visitor_id,
        )->toBe(TEST_VISITOR_ID);
});

it('uses the visitor header instead of the client supplied visitor id', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson('/api/v1/focus-sessions', [
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10T09:00:00Z',
        'visitor_id' => OTHER_VISITOR_ID,
    ]);

    $response
        ->assertCreated()
        ->assertJsonPath(
            'data.visitor_id',
            TEST_VISITOR_ID,
        );

    expect(
        FocusSession::query()->first()?->visitor_id,
    )->toBe(TEST_VISITOR_ID);
});

it('rejects session creation without a visitor header', function () {
    $response = $this->postJson(
        '/api/v1/focus-sessions',
        [
            'mode' => 'focus',
            'planned_duration_seconds' => 1500,
            'started_at' => '2026-09-10T09:00:00Z',
            'visitor_id' => TEST_VISITOR_ID,
        ],
    );

    $response
        ->assertUnprocessable()
        ->assertJsonValidationErrors([
            'visitor_id',
        ]);
});

it('creates a relax session through the api', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson('/api/v1/focus-sessions', [
        'mode' => 'relax',
        'planned_duration_seconds' => 600,
        'started_at' => '2026-09-10T10:00:00Z',
        'visitor_id' => TEST_VISITOR_ID,
    ]);

    $response
        ->assertCreated()
        ->assertJsonPath(
            'data.mode',
            'relax',
        )
        ->assertJsonPath(
            'data.planned_duration_seconds',
            600,
        )
        ->assertJsonPath(
            'data.visitor_id',
            TEST_VISITOR_ID,
        );
});

it('validates required session fields', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson(
        '/api/v1/focus-sessions',
        [],
    );

    $response
        ->assertUnprocessable()
        ->assertJsonValidationErrors([
            'mode',
            'planned_duration_seconds',
            'started_at',
        ]);
});

it('rejects an invalid session mode', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson('/api/v1/focus-sessions', [
        'mode' => 'invalid',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10T09:00:00Z',
    ]);

    $response
        ->assertUnprocessable()
        ->assertJsonValidationErrors([
            'mode',
        ]);
});

it('rejects a non-positive planned duration', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson('/api/v1/focus-sessions', [
        'mode' => 'focus',
        'planned_duration_seconds' => 0,
        'started_at' => '2026-09-10T09:00:00Z',
    ]);

    $response
        ->assertUnprocessable()
        ->assertJsonValidationErrors([
            'planned_duration_seconds',
        ]);
});

it('rejects an invalid visitor id header', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        'not-a-uuid',
    )->postJson('/api/v1/focus-sessions', [
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10T09:00:00Z',
    ]);

    $response
        ->assertUnprocessable()
        ->assertJsonValidationErrors([
            'visitor_id',
        ]);
});

it('completes a focus session through the api', function () {
    $createResponse = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson(
        '/api/v1/focus-sessions',
        [
            'mode' => 'focus',
            'title' => 'Laravel study',
            'planned_duration_seconds' => 3000,
            'started_at' => '2026-09-10T09:00:00Z',
            'visitor_id' => TEST_VISITOR_ID,
        ],
    );

    $createResponse->assertCreated();

    $sessionId = $createResponse->json('data.id');

    expect($sessionId)->toBeInt();

    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$sessionId}/complete",
        [
            'ended_at' => '2026-09-10T09:50:00Z',
        ],
    );

    $response
        ->assertOk()
        ->assertJsonPath(
            'message',
            'Session completed successfully.',
        )
        ->assertJsonPath(
            'data.status',
            'completed',
        )
        ->assertJsonPath(
            'data.actual_duration_seconds',
            3000,
        )
        ->assertJsonPath(
            'data.focused_duration_seconds',
            3000,
        )
        ->assertJsonPath(
            'data.focus_integrity',
            100,
        );
});

it('records an interruption through the api', function () {
    $session = createApiSession();

    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/interruptions",
        [
            'started_at' => '2026-09-10T09:20:00Z',
            'ended_at' => '2026-09-10T09:23:00Z',
        ],
    );

    $response
        ->assertCreated()
        ->assertJsonPath(
            'message',
            'Interruption recorded successfully.',
        )
        ->assertJsonPath(
            'data.focus_session_id',
            $session->id,
        )
        ->assertJsonPath(
            'data.duration_seconds',
            180,
        );
});

it('rejects an interruption for a relax session', function () {
    $session = createApiSession(
        mode: 'relax',
    );

    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/interruptions",
        [
            'started_at' => '2026-09-10T09:02:00Z',
            'ended_at' => '2026-09-10T09:03:00Z',
        ],
    );

    $response->assertStatus(422);
});

it('returns not found for an unknown session', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson(
        '/api/v1/focus-sessions/999999/complete',
        [
            'ended_at' => '2026-09-10T09:25:00Z',
        ],
    );

    $response->assertNotFound();
});

it('does not trust client supplied metrics', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson('/api/v1/focus-sessions', [
        'mode' => 'focus',
        'planned_duration_seconds' => 3000,
        'started_at' => '2026-09-10T09:00:00Z',
        'visitor_id' => TEST_VISITOR_ID,
        'actual_duration_seconds' => 999999,
        'focused_duration_seconds' => 999999,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => 100,
        'status' => 'completed',
    ]);

    $response
        ->assertCreated()
        ->assertJsonPath(
            'data.actual_duration_seconds',
            0,
        )
        ->assertJsonPath(
            'data.focused_duration_seconds',
            0,
        )
        ->assertJsonPath(
            'data.focus_integrity',
            null,
        )
        ->assertJsonPath(
            'data.status',
            'active',
        )
        ->assertJsonPath(
            'data.visitor_id',
            TEST_VISITOR_ID,
        );
});

it('lists only sessions belonging to the visitor', function () {
    $visitorId = (string) Str::uuid();
    $otherVisitorId = (string) Str::uuid();

    createApiSession(
        visitorId: $visitorId,
        status: 'completed',
    );

    createApiSession(
        visitorId: $otherVisitorId,
        status: 'completed',
    );

    $response = $this->withHeader(
        'X-Visitor-Id',
        $visitorId,
    )->getJson('/api/v1/focus-sessions');

    $response
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath(
            'data.0.visitor_id',
            $visitorId,
        );
});

it('requires a visitor id for session history', function () {
    $response = $this->getJson(
        '/api/v1/focus-sessions',
    );

    $response
        ->assertStatus(422)
        ->assertJsonPath(
            'message',
            'The X-Visitor-Id header is required.',
        );
});

it('rejects an invalid visitor id for session history', function () {
    $response = $this->withHeader(
        'X-Visitor-Id',
        'invalid',
    )->getJson('/api/v1/focus-sessions');

    $response
        ->assertStatus(422)
        ->assertJsonPath(
            'message',
            'The X-Visitor-Id header must be a valid UUID.',
        );
});

it('filters session history by mode and status', function () {
    $visitorId = (string) Str::uuid();

    createApiSession(
        visitorId: $visitorId,
        mode: 'focus',
        status: 'completed',
    );

    createApiSession(
        visitorId: $visitorId,
        mode: 'relax',
        status: 'completed',
    );

    createApiSession(
        visitorId: $visitorId,
        mode: 'focus',
        status: 'cancelled',
    );

    $response = $this->withHeader(
        'X-Visitor-Id',
        $visitorId,
    )->getJson(
        '/api/v1/focus-sessions?mode=focus&status=completed',
    );

    $response
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath(
            'data.0.mode',
            'focus',
        )
        ->assertJsonPath(
            'data.0.status',
            'completed',
        )
        ->assertJsonPath(
            'data.0.visitor_id',
            $visitorId,
        );
});

it('returns a session detail for its visitor', function () {
    $visitorId = (string) Str::uuid();

    $session = FocusSession::create([
        'visitor_id' => $visitorId,
        'mode' => 'focus',
        'title' => 'Deep work',
        'planned_duration_seconds' => 1500,
        'actual_duration_seconds' => 1500,
        'focused_duration_seconds' => 1400,
        'interrupted_duration_seconds' => 100,
        'interruption_count' => 1,
        'focus_integrity' => 93.33,
        'status' => 'completed',
        'started_at' => now()->subMinutes(25),
        'ended_at' => now(),
    ]);

    $response = $this->withHeader(
        'X-Visitor-Id',
        $visitorId,
    )->getJson(
        "/api/v1/focus-sessions/{$session->id}",
    );

    $response
        ->assertOk()
        ->assertJsonPath(
            'data.id',
            $session->id,
        )
        ->assertJsonPath(
            'data.visitor_id',
            $visitorId,
        )
        ->assertJsonPath(
            'data.mode',
            'focus',
        )
        ->assertJsonPath(
            'data.title',
            'Deep work',
        )
        ->assertJsonPath(
            'data.focus_integrity',
            93.33,
        )
        ->assertJsonPath(
            'data.interruption_count',
            1,
        );
});

it('does not expose a session detail to another visitor', function () {
    $ownerVisitorId = (string) Str::uuid();
    $otherVisitorId = (string) Str::uuid();

    $session = createApiSession(
        visitorId: $ownerVisitorId,
        status: 'completed',
    );

    $response = $this->withHeader(
        'X-Visitor-Id',
        $otherVisitorId,
    )->getJson(
        "/api/v1/focus-sessions/{$session->id}",
    );

    $response->assertNotFound();
});

it('requires a visitor id for session detail', function () {
    $session = createApiSession(
        status: 'completed',
    );

    $response = $this->getJson(
        "/api/v1/focus-sessions/{$session->id}",
    );

    $response
        ->assertStatus(422)
        ->assertJsonValidationErrors([
            'visitor_id',
        ]);
});

it('prevents another visitor from completing a session', function () {
    $session = createApiSession();

    $response = $this->withHeader(
        'X-Visitor-Id',
        OTHER_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/complete",
        [
            'ended_at' => '2026-09-10T09:25:00Z',
        ],
    );

    $response->assertNotFound();

    expect($session->fresh()->status)
        ->toBe('active');
});

it('prevents another visitor from pausing a session', function () {
    $session = createApiSession();

    $response = $this->withHeader(
        'X-Visitor-Id',
        OTHER_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/pause",
        [
            'started_at' => '2026-09-10T09:10:00Z',
        ],
    );

    $response->assertNotFound();

    expect($session->fresh()->status)
        ->toBe('active');
});

it('prevents another visitor from resuming a session', function () {
    $session = createApiSession();

    $this->withHeader(
        'X-Visitor-Id',
        TEST_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/pause",
        [
            'started_at' => '2026-09-10T09:10:00Z',
        ],
    )->assertOk();

    $response = $this->withHeader(
        'X-Visitor-Id',
        OTHER_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/resume",
        [
            'ended_at' => '2026-09-10T09:15:00Z',
        ],
    );

    $response->assertNotFound();

    expect($session->fresh()->status)
        ->toBe('paused');
});

it('prevents another visitor from cancelling a session', function () {
    $session = createApiSession();

    $response = $this->withHeader(
        'X-Visitor-Id',
        OTHER_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/cancel",
        [
            'cancelled_at' => '2026-09-10T09:10:00Z',
        ],
    );

    $response->assertNotFound();

    expect($session->fresh()->status)
        ->toBe('active');
});

it('prevents another visitor from recording an interruption', function () {
    $session = createApiSession();

    $response = $this->withHeader(
        'X-Visitor-Id',
        OTHER_VISITOR_ID,
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/interruptions",
        [
            'started_at' => '2026-09-10T09:10:00Z',
            'ended_at' => '2026-09-10T09:11:00Z',
        ],
    );

    $response->assertNotFound();

    expect($session->fresh()->interruptions()->count())
        ->toBe(0);
});

it('rejects lifecycle mutation without a visitor header', function () {
    $session = createApiSession();

    $response = $this->postJson(
        "/api/v1/focus-sessions/{$session->id}/pause",
        [
            'started_at' => '2026-09-10T09:10:00Z',
        ],
    );

    $response->assertStatus(422);

    expect($session->fresh()->status)
        ->toBe('active');
});

it('rejects lifecycle mutation with an invalid visitor header', function () {
    $session = createApiSession();

    $response = $this->withHeader(
        'X-Visitor-Id',
        'invalid',
    )->postJson(
        "/api/v1/focus-sessions/{$session->id}/cancel",
        [
            'cancelled_at' => '2026-09-10T09:10:00Z',
        ],
    );

    $response->assertStatus(422);

    expect($session->fresh()->status)
        ->toBe('active');
});

it('creates a session for the authenticated user', function () {
    $user = User::factory()->create();

    $response = $this
        ->actingAs($user)
        ->postJson('/api/v1/focus-sessions', [
            'mode' => 'focus',
            'title' => 'Authenticated focus',
            'planned_duration_seconds' => 1500,
            'started_at' => '2026-09-10T09:00:00Z',
        ]);

    $response
        ->assertCreated()
        ->assertJsonPath(
            'data.user_id',
            $user->id,
        )
        ->assertJsonPath(
            'data.visitor_id',
            null,
        );

    expect(
        FocusSession::query()->first()?->user_id,
    )->toBe($user->id);
});

it('does not require a visitor header for authenticated session creation', function () {
    $user = User::factory()->create();

    $response = $this
        ->actingAs($user)
        ->postJson('/api/v1/focus-sessions', [
            'mode' => 'focus',
            'planned_duration_seconds' => 1500,
            'started_at' => '2026-09-10T09:00:00Z',
        ]);

    $response->assertCreated();
});

it('lists only sessions belonging to the authenticated user', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();

    FocusSession::create([
        'user_id' => $user->id,
        'mode' => 'focus',
        'title' => 'My session',
        'planned_duration_seconds' => 1500,
        'actual_duration_seconds' => 1500,
        'focused_duration_seconds' => 1500,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => 100,
        'status' => 'completed',
        'started_at' => now()->subHour(),
        'ended_at' => now()->subMinutes(35),
    ]);

    FocusSession::create([
        'user_id' => $otherUser->id,
        'mode' => 'focus',
        'title' => 'Other session',
        'planned_duration_seconds' => 1500,
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
        ->getJson('/api/v1/focus-sessions');

    $response
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath(
            'data.0.user_id',
            $user->id,
        );
});

it('does not allow an authenticated user to access another users session', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();

    $session = FocusSession::create([
        'user_id' => $otherUser->id,
        'mode' => 'focus',
        'title' => 'Private session',
        'planned_duration_seconds' => 1500,
        'actual_duration_seconds' => 0,
        'focused_duration_seconds' => 0,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => null,
        'status' => 'active',
        'started_at' => now(),
    ]);

    $response = $this
        ->actingAs($user)
        ->getJson(
            "/api/v1/focus-sessions/{$session->id}",
        );

    $response->assertNotFound();
});

it('guest cannot claim guest sessions', function () {
    $visitorId =
        '550e8400-e29b-41d4-a716-446655440000';

    $response = $this
        ->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])
        ->postJson('/api/v1/focus-sessions/claim');

    $response->assertUnauthorized();
});

it('claim requires a visitor id', function () {
    $user = \App\Models\User::factory()->create();

    $response = $this
        ->actingAs($user)
        ->postJson('/api/v1/focus-sessions/claim');

    $response
        ->assertStatus(422)
        ->assertJsonValidationErrors([
            'visitor_id',
        ]);
});

it('claim rejects an invalid visitor id', function () {
    $user = \App\Models\User::factory()->create();

    $response = $this
        ->actingAs($user)
        ->withHeaders([
            'X-Visitor-Id' => 'not-a-uuid',
        ])
        ->postJson('/api/v1/focus-sessions/claim');

    $response
        ->assertStatus(422)
        ->assertJsonValidationErrors([
            'visitor_id',
        ]);
});

it('authenticated user can claim guest sessions', function () {
    $user = \App\Models\User::factory()->create();

    $visitorId =
        '550e8400-e29b-41d4-a716-446655440000';

    $session = FocusSession::create([
        'user_id' => null,
        'visitor_id' => $visitorId,
        'mode' => 'focus',
        'planned_duration_seconds' => 1800,
        'actual_duration_seconds' => 0,
        'focused_duration_seconds' => 0,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => null,
        'status' => 'active',
        'started_at' => now(),
        'ended_at' => null,
    ]);

    $response = $this
        ->actingAs($user)
        ->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])
        ->postJson('/api/v1/focus-sessions/claim');

    $response
        ->assertSuccessful()
        ->assertJsonPath(
            'data.claimed_count',
            1,
        );

    $session->refresh();

    $this->assertSame(
        $user->id,
        $session->user_id,
    );

    $this->assertNull(
        $session->visitor_id,
    );
});

it('claim moves multiple guest sessions to authenticated user', function () {
    $user = \App\Models\User::factory()->create();

    $visitorId =
        '550e8400-e29b-41d4-a716-446655440000';

    $first = FocusSession::create([
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

    $second = FocusSession::create([
        'user_id' => null,
        'visitor_id' => $visitorId,
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'actual_duration_seconds' => 1500,
        'focused_duration_seconds' => 1500,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => 100,
        'status' => 'completed',
        'started_at' => now()->subHours(2),
        'ended_at' => now()->subMinutes(90),
    ]);

    $response = $this
        ->actingAs($user)
        ->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])
        ->postJson('/api/v1/focus-sessions/claim');

    $response
        ->assertSuccessful()
        ->assertJsonPath(
            'data.claimed_count',
            2,
        );

    $first->refresh();
    $second->refresh();

    $this->assertSame($user->id, $first->user_id);
    $this->assertSame($user->id, $second->user_id);
    $this->assertNull($first->visitor_id);
    $this->assertNull($second->visitor_id);
});

it('claim does not take sessions owned by another user', function () {
    $user = \App\Models\User::factory()->create();
    $otherUser = \App\Models\User::factory()->create();

    $visitorId =
        '550e8400-e29b-41d4-a716-446655440000';

    $session = FocusSession::create([
        'user_id' => $otherUser->id,
        'visitor_id' => $visitorId,
        'mode' => 'focus',
        'planned_duration_seconds' => 1800,
        'actual_duration_seconds' => 0,
        'focused_duration_seconds' => 0,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => null,
        'status' => 'active',
        'started_at' => now(),
        'ended_at' => null,
    ]);

    $response = $this
        ->actingAs($user)
        ->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])
        ->postJson('/api/v1/focus-sessions/claim');

    $response
        ->assertSuccessful()
        ->assertJsonPath(
            'data.claimed_count',
            0,
        );

    $session->refresh();

    $this->assertSame(
        $otherUser->id,
        $session->user_id,
    );

    $this->assertSame(
        $visitorId,
        $session->visitor_id,
    );
});

it('claim is idempotent', function () {
    $user = \App\Models\User::factory()->create();

    $visitorId =
        '550e8400-e29b-41d4-a716-446655440000';

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

    $firstResponse = $this
        ->actingAs($user)
        ->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])
        ->postJson('/api/v1/focus-sessions/claim');

    $firstResponse
        ->assertSuccessful()
        ->assertJsonPath(
            'data.claimed_count',
            1,
        );

    $secondResponse = $this
        ->actingAs($user)
        ->withHeaders([
            'X-Visitor-Id' => $visitorId,
        ])
        ->postJson('/api/v1/focus-sessions/claim');

    $secondResponse
        ->assertSuccessful()
        ->assertJsonPath(
            'data.claimed_count',
            0,
        );
});
