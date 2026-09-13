<?php

use App\Services\FocusSessionService;
use Carbon\Carbon;
use InvalidArgumentException;

it('pauses an active session', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'title' => 'Study',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $pause = $service->pause(
        $session,
        '2026-09-10 10:10:00',
    );

    expect($pause->focus_session_id)
        ->toBe($session->id)
        ->and($pause->started_at->toDateTimeString())
        ->toBe('2026-09-10 10:10:00')
        ->and($pause->ended_at)
        ->toBeNull()
        ->and($pause->duration_seconds)
        ->toBe(0);

    expect($session->fresh()->status)
        ->toBe('paused');
});

it('resumes a paused session and records pause duration', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $service->pause(
        $session,
        '2026-09-10 10:10:00',
    );

    $pause = $service->resume(
        $session,
        '2026-09-10 10:15:00',
    );

    expect($pause->ended_at->toDateTimeString())
        ->toBe('2026-09-10 10:15:00')
        ->and($pause->duration_seconds)
        ->toBe(300);

    expect($session->fresh()->status)
        ->toBe('active');
});

it('rejects pausing an already paused session', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $service->pause(
        $session,
        '2026-09-10 10:10:00',
    );

    expect(fn () => $service->pause(
        $session,
        '2026-09-10 10:12:00',
    ))->toThrow(InvalidArgumentException::class);
});

it('rejects resuming an active session', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    expect(fn () => $service->resume(
        $session,
        '2026-09-10 10:10:00',
    ))->toThrow(InvalidArgumentException::class);
});

it('supports multiple pause and resume cycles', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 3600,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $firstPause = $service->pause(
        $session,
        '2026-09-10 10:10:00',
    );

    $service->resume(
        $session,
        '2026-09-10 10:15:00',
    );

    $secondPause = $service->pause(
        $session,
        '2026-09-10 10:30:00',
    );

    $service->resume(
        $session,
        '2026-09-10 10:40:00',
    );

    expect($firstPause->fresh()->duration_seconds)
        ->toBe(300)
        ->and($secondPause->fresh()->duration_seconds)
        ->toBe(600);

    expect($session->fresh()->pauses()->count())
        ->toBe(2);
});

it('excludes manual pause duration from actual session duration', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 3600,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $service->pause(
        $session,
        '2026-09-10 10:10:00',
    );

    $service->resume(
        $session,
        '2026-09-10 10:20:00',
    );

    $completed = $service->complete(
        $session,
        '2026-09-10 10:30:00',
    );

    expect($completed->actual_duration_seconds)
        ->toBe(1200)
        ->and($completed->focused_duration_seconds)
        ->toBe(1200)
        ->and($completed->interrupted_duration_seconds)
        ->toBe(0);
});

it('cancels an active session', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $cancelled = $service->cancel(
        $session,
        '2026-09-10 10:10:00',
    );

    expect($cancelled->status)
        ->toBe('cancelled')
        ->and($cancelled->ended_at->toDateTimeString())
        ->toBe('2026-09-10 10:10:00');
});

it('cancels a paused session and closes the active pause', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $service->pause(
        $session,
        '2026-09-10 10:10:00',
    );

    $cancelled = $service->cancel(
        $session,
        '2026-09-10 10:15:00',
    );

    $pause = $session->fresh()->pauses()->first();

    expect($cancelled->status)
        ->toBe('cancelled')
        ->and($pause)
        ->not->toBeNull()
        ->and($pause?->ended_at?->toDateTimeString())
        ->toBe('2026-09-10 10:15:00')
        ->and($pause?->duration_seconds)
        ->toBe(300);
});

it('rejects completing a paused session', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $service->pause(
        $session,
        '2026-09-10 10:10:00',
    );

    expect(fn () => $service->complete(
        $session,
        Carbon::parse('2026-09-10 10:20:00'),
    ))->toThrow(InvalidArgumentException::class);
});

it('rejects cancelling a completed session', function (): void {
    $service = app(FocusSessionService::class);

    $session = $service->create([
        'mode' => 'focus',
        'planned_duration_seconds' => 1500,
        'started_at' => '2026-09-10 10:00:00',
    ]);

    $service->complete(
        $session,
        '2026-09-10 10:25:00',
    );

    expect(fn () => $service->cancel(
        $session,
        '2026-09-10 10:30:00',
    ))->toThrow(InvalidArgumentException::class);
});
