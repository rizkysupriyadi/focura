<?php

use App\Models\FocusSession;
use App\Models\SessionInterruption;
use App\Services\FocusSessionService;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use InvalidArgumentException;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->service = new FocusSessionService;
});

it('creates a focus session with the expected initial values', function () {
    $startedAt = Carbon::parse('2026-09-10 09:00:00');

    $session = $this->service->create([
        'mode' => 'focus',
        'title' => 'Deep work',
        'planned_duration_seconds' => 50 * 60,
        'started_at' => $startedAt,
    ]);

    expect($session)
        ->toBeInstanceOf(FocusSession::class)
        ->and($session->mode)->toBe('focus')
        ->and($session->title)->toBe('Deep work')
        ->and($session->planned_duration_seconds)->toBe(3000)
        ->and($session->actual_duration_seconds)->toBe(0)
        ->and($session->focused_duration_seconds)->toBe(0)
        ->and($session->interrupted_duration_seconds)->toBe(0)
        ->and($session->interruption_count)->toBe(0)
        ->and($session->focus_integrity)->toBeNull()
        ->and($session->status)->toBe('active');

    expect(
        FocusSession::query()->count()
    )->toBe(1);
});

it('creates a relax session', function () {
    $session = $this->service->create([
        'mode' => 'relax',
        'planned_duration_seconds' => 10 * 60,
        'started_at' => Carbon::parse('2026-09-10 10:00:00'),
    ]);

    expect($session->mode)->toBe('relax')
        ->and($session->planned_duration_seconds)->toBe(600)
        ->and($session->status)->toBe('active');
});

it('rejects an invalid session mode', function () {
    $this->service->create([
        'mode' => 'invalid',
        'planned_duration_seconds' => 1500,
        'started_at' => Carbon::parse('2026-09-10 09:00:00'),
    ]);
})->throws(InvalidArgumentException::class);

it('rejects a non-positive planned duration', function () {
    $this->service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 0,
        'started_at' => Carbon::parse('2026-09-10 09:00:00'),
    ]);
})->throws(InvalidArgumentException::class);

it('records an interruption for a focus session', function () {
    $startedAt = Carbon::parse('2026-09-10 09:00:00');

    $session = $this->service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 50 * 60,
        'started_at' => $startedAt,
    ]);

    $interruption = $this->service->recordInterruption(
        $session,
        '2026-09-10 09:10:00',
        '2026-09-10 09:13:00',
    );

    expect($interruption)
        ->toBeInstanceOf(SessionInterruption::class)
        ->and($interruption->focus_session_id)->toBe($session->id)
        ->and($interruption->duration_seconds)->toBe(180);

    expect(
        $session->interruptions()->count()
    )->toBe(1);
});

it('calculates focus integrity from focused and actual duration', function () {
    $session = $this->service->create([
        'mode' => 'focus',
        'title' => 'Deep work',
        'planned_duration_seconds' => 50 * 60,
        'started_at' => Carbon::parse('2026-09-10 09:00:00'),
    ]);

    $this->service->recordInterruption(
        $session,
        '2026-09-10 09:20:00',
        '2026-09-10 09:23:00',
    );

    $completed = $this->service->complete(
        $session,
        '2026-09-10 09:50:00',
    );

    expect($completed->status)->toBe('completed')
        ->and($completed->actual_duration_seconds)->toBe(3000)
        ->and($completed->interrupted_duration_seconds)->toBe(180)
        ->and($completed->focused_duration_seconds)->toBe(2820)
        ->and($completed->interruption_count)->toBe(1)
        ->and($completed->focus_integrity)->toBe(94.0);
});

it('does not calculate focus integrity for relax sessions', function () {
    $session = $this->service->create([
        'mode' => 'relax',
        'planned_duration_seconds' => 10 * 60,
        'started_at' => Carbon::parse('2026-09-10 10:00:00'),
    ]);

    $completed = $this->service->complete(
        $session,
        '2026-09-10 10:10:00',
    );

    expect($completed->status)->toBe('completed')
        ->and($completed->actual_duration_seconds)->toBe(600)
        ->and($completed->focused_duration_seconds)->toBe(600)
        ->and($completed->interrupted_duration_seconds)->toBe(0)
        ->and($completed->interruption_count)->toBe(0)
        ->and($completed->focus_integrity)->toBeNull();
});

it('rejects interruptions for relax sessions', function () {
    $session = $this->service->create([
        'mode' => 'relax',
        'planned_duration_seconds' => 10 * 60,
        'started_at' => Carbon::parse('2026-09-10 10:00:00'),
    ]);

    $this->service->recordInterruption(
        $session,
        '2026-09-10 10:02:00',
        '2026-09-10 10:03:00',
    );
})->throws(InvalidArgumentException::class);

it('rejects an interruption that starts before the session', function () {
    $session = $this->service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 25 * 60,
        'started_at' => Carbon::parse('2026-09-10 09:00:00'),
    ]);

    $this->service->recordInterruption(
        $session,
        '2026-09-10 08:59:00',
        '2026-09-10 09:01:00',
    );
})->throws(InvalidArgumentException::class);

it('rejects an interruption whose end is before its start', function () {
    $session = $this->service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 25 * 60,
        'started_at' => Carbon::parse('2026-09-10 09:00:00'),
    ]);

    $this->service->recordInterruption(
        $session,
        '2026-09-10 09:05:00',
        '2026-09-10 09:04:00',
    );
})->throws(InvalidArgumentException::class);

it('does not exceed the planned duration when completing a session', function () {
    $session = $this->service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 25 * 60,
        'started_at' => Carbon::parse('2026-09-10 09:00:00'),
    ]);

    $completed = $this->service->complete(
        $session,
        '2026-09-10 10:00:00',
    );

    expect($completed->actual_duration_seconds)->toBe(1500)
        ->and($completed->focused_duration_seconds)->toBe(1500)
        ->and($completed->interrupted_duration_seconds)->toBe(0)
        ->and($completed->focus_integrity)->toBe(100.0);
});

it('rejects completing a cancelled session', function () {
    $session = $this->service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 25 * 60,
        'started_at' => Carbon::parse('2026-09-10 09:00:00'),
    ]);

    $session->update([
        'status' => 'cancelled',
    ]);

    $this->service->complete(
        $session,
        '2026-09-10 09:25:00',
    );
})->throws(InvalidArgumentException::class);

it('returns a session detail only for the requested visitor', function () {
    $visitorId = (string) Str::uuid();
    $otherVisitorId = (string) Str::uuid();

    $session = FocusSession::create([
        'visitor_id' => $visitorId,
        'mode' => 'focus',
        'title' => 'Deep work',
        'planned_duration_seconds' => 1500,
        'actual_duration_seconds' => 1500,
        'focused_duration_seconds' => 1500,
        'interrupted_duration_seconds' => 0,
        'interruption_count' => 0,
        'focus_integrity' => 100,
        'status' => 'completed',
        'started_at' => now()->subMinutes(25),
        'ended_at' => now(),
    ]);

    $result = app(FocusSessionService::class)
        ->findForVisitor(
            $session->id,
            $visitorId,
        );

    expect($result->id)
        ->toBe($session->id)
        ->and($result->visitor_id)
        ->toBe($visitorId);

    expect(
        fn () => app(FocusSessionService::class)
            ->findForVisitor(
                $session->id,
                $otherVisitorId,
            ),
    )->toThrow(
        ModelNotFoundException::class,
    );
});
