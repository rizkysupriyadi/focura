<?php

namespace App\Services;

use App\Models\FocusSession;
use App\Models\SessionInterruption;
use App\Models\SessionPause;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class FocusSessionService
{
    /**
     * Create a new focus or relax session.
     *
     * @param array{
     *     user_id?: int|null,
     *     visitor_id?: string|null,
     *     mode: string,
     *     title?: string|null,
     *     planned_duration_seconds: int,
     *     started_at: CarbonInterface|string
     * } $data
     */
    /**
     * Claim all unassigned guest sessions for an authenticated user.
     *
     * Only sessions belonging to the supplied visitor identity and
     * without an existing user owner can be claimed.
     */
    public function claimVisitorSessions(
        string $visitorId,
        int $userId,
    ): int {
        return DB::transaction(function () use (
            $visitorId,
            $userId,
        ): int {
            $sessions = FocusSession::query()
                ->where('visitor_id', $visitorId)
                ->whereNull('user_id')
                ->lockForUpdate()
                ->get();

            if ($sessions->isEmpty()) {
                return 0;
            }

            return FocusSession::query()
                ->whereKey($sessions->modelKeys())
                ->where('visitor_id', $visitorId)
                ->whereNull('user_id')
                ->update([
                    'user_id' => $userId,
                    'visitor_id' => null,
                    'updated_at' => now(),
                ]);
        });
    }

    public function create(array $data): FocusSession
    {
        $mode = $data['mode'] ?? null;
        $plannedDuration = (int) (
            $data['planned_duration_seconds'] ?? 0
        );

        if (! in_array($mode, ['focus', 'relax'], true)) {
            throw new InvalidArgumentException(
                'The session mode must be focus or relax.',
            );
        }

        if ($plannedDuration <= 0) {
            throw new InvalidArgumentException(
                'The planned duration must be greater than zero.',
            );
        }

        return FocusSession::create([
            'user_id' => $data['user_id'] ?? null,
            'visitor_id' => $data['visitor_id'] ?? null,
            'mode' => $mode,
            'title' => $data['title'] ?? null,
            'planned_duration_seconds' => $plannedDuration,
            'actual_duration_seconds' => 0,
            'focused_duration_seconds' => 0,
            'interrupted_duration_seconds' => 0,
            'interruption_count' => 0,
            'focus_integrity' => null,
            'status' => 'active',
            'started_at' => $data['started_at'],
            'ended_at' => null,
        ]);
    }

    /**
     * List sessions belonging to a guest visitor.
     *
     * @return LengthAwarePaginator<int, FocusSession>
     */
    public function listForVisitor(
        string $visitorId,
        ?string $mode = null,
        ?string $status = null,
        int $perPage = 10,
    ): LengthAwarePaginator {
        return FocusSession::query()
            ->where('visitor_id', $visitorId)
            ->when(
                $mode !== null,
                fn ($query) => $query->where('mode', $mode),
            )
            ->when(
                $status !== null,
                fn ($query) => $query->where('status', $status),
            )
            ->with(['interruptions'])
            ->latest('started_at')
            ->paginate($perPage);
    }

    /**
     * List sessions belonging to an authenticated user.
     *
     * @return LengthAwarePaginator<int, FocusSession>
     */
    public function listForUser(
        int $userId,
        ?string $mode = null,
        ?string $status = null,
        int $perPage = 10,
    ): LengthAwarePaginator {
        return FocusSession::query()
            ->where('user_id', $userId)
            ->when(
                $mode !== null,
                fn ($query) => $query->where('mode', $mode),
            )
            ->when(
                $status !== null,
                fn ($query) => $query->where('status', $status),
            )
            ->with(['interruptions'])
            ->latest('started_at')
            ->paginate($perPage);
    }

    /**
     * Find a session belonging to a guest visitor.
     *
     * @throws ModelNotFoundException
     */
    public function findForVisitor(
        int $sessionId,
        string $visitorId,
    ): FocusSession {
        return FocusSession::query()
            ->whereKey($sessionId)
            ->where('visitor_id', $visitorId)
            ->with(['interruptions'])
            ->firstOrFail();
    }

    /**
     * Find a session belonging to an authenticated user.
     *
     * @throws ModelNotFoundException
     */
    public function findForUser(
        int $sessionId,
        int $userId,
    ): FocusSession {
        return FocusSession::query()
            ->whereKey($sessionId)
            ->where('user_id', $userId)
            ->with(['interruptions'])
            ->firstOrFail();
    }

    /**
     * Record an interruption for a focus session.
     */
    public function recordInterruption(
        FocusSession $session,
        CarbonInterface|string $startedAt,
        CarbonInterface|string $endedAt,
    ): SessionInterruption {
        return DB::transaction(function () use (
            $session,
            $startedAt,
            $endedAt,
        ): SessionInterruption {
            $lockedSession = FocusSession::query()
                ->whereKey($session->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedSession->mode !== 'focus') {
                throw new InvalidArgumentException(
                    'Interruptions can only be recorded for focus sessions.',
                );
            }

            if ($lockedSession->status !== 'active') {
                throw new InvalidArgumentException(
                    'Interruptions can only be recorded for active sessions.',
                );
            }

            $started = Carbon::parse($startedAt);
            $ended = Carbon::parse($endedAt);

            if ($started->lt($lockedSession->started_at)) {
                throw new InvalidArgumentException(
                    'The interruption cannot start before the session.',
                );
            }

            if ($ended->lt($started)) {
                throw new InvalidArgumentException(
                    'The interruption cannot end before it starts.',
                );
            }

            $duration = $started->diffInSeconds($ended);

            if ($duration <= 0) {
                throw new InvalidArgumentException(
                    'The interruption duration must be greater than zero.',
                );
            }

            $sessionEnd = $lockedSession->started_at->copy()->addSeconds(
                $lockedSession->planned_duration_seconds,
            );

            if ($started->gte($sessionEnd)) {
                throw new InvalidArgumentException(
                    'The interruption must occur within the planned session duration.',
                );
            }

            if ($ended->gt($sessionEnd)) {
                $ended = $sessionEnd;
                $duration = $started->diffInSeconds($ended);
            }

            if ($duration <= 0) {
                throw new InvalidArgumentException(
                    'The interruption duration must be greater than zero.',
                );
            }

            return SessionInterruption::create([
                'focus_session_id' => $lockedSession->id,
                'started_at' => $started,
                'ended_at' => $ended,
                'duration_seconds' => $duration,
            ]);
        });
    }

    /**
     * Pause an active session.
     */
    public function pause(
        FocusSession $session,
        CarbonInterface|string $startedAt,
    ): SessionPause {
        return DB::transaction(function () use (
            $session,
            $startedAt,
        ): SessionPause {
            $lockedSession = FocusSession::query()
                ->whereKey($session->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedSession->status !== 'active') {
                throw new InvalidArgumentException(
                    'Only active sessions can be paused.',
                );
            }

            $started = Carbon::parse($startedAt);

            if ($started->lt($lockedSession->started_at)) {
                throw new InvalidArgumentException(
                    'The pause cannot start before the session.',
                );
            }

            $plannedEnd = $lockedSession->started_at->copy()->addSeconds(
                $lockedSession->planned_duration_seconds,
            );

            if ($started->gt($plannedEnd)) {
                throw new InvalidArgumentException(
                    'The pause cannot start after the planned session duration.',
                );
            }

            $pause = SessionPause::create([
                'focus_session_id' => $lockedSession->id,
                'started_at' => $started,
                'ended_at' => null,
                'duration_seconds' => 0,
            ]);

            $lockedSession->update([
                'status' => 'paused',
            ]);

            return $pause;
        });
    }

    /**
     * Resume a paused session.
     */
    public function resume(
        FocusSession $session,
        CarbonInterface|string $endedAt,
    ): SessionPause {
        return DB::transaction(function () use (
            $session,
            $endedAt,
        ): SessionPause {
            $lockedSession = FocusSession::query()
                ->whereKey($session->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedSession->status !== 'paused') {
                throw new InvalidArgumentException(
                    'Only paused sessions can be resumed.',
                );
            }

            $pause = SessionPause::query()
                ->where('focus_session_id', $lockedSession->id)
                ->whereNull('ended_at')
                ->latest('started_at')
                ->lockForUpdate()
                ->first();

            if ($pause === null) {
                throw new InvalidArgumentException(
                    'The session does not have an active pause.',
                );
            }

            $ended = Carbon::parse($endedAt);

            if ($ended->lt($pause->started_at)) {
                throw new InvalidArgumentException(
                    'The pause cannot end before it starts.',
                );
            }

            $duration = $pause->started_at->diffInSeconds($ended);

            $pause->update([
                'ended_at' => $ended,
                'duration_seconds' => $duration,
            ]);

            $lockedSession->update([
                'status' => 'active',
            ]);

            return $pause->fresh();
        });
    }

    /**
     * Cancel an active or paused session.
     */
    public function cancel(
        FocusSession $session,
        CarbonInterface|string $cancelledAt,
    ): FocusSession {
        return DB::transaction(function () use (
            $session,
            $cancelledAt,
        ): FocusSession {
            $lockedSession = FocusSession::query()
                ->whereKey($session->id)
                ->lockForUpdate()
                ->firstOrFail();

            if (! in_array(
                $lockedSession->status,
                ['active', 'paused'],
                true,
            )) {
                throw new InvalidArgumentException(
                    'Only active or paused sessions can be cancelled.',
                );
            }

            $cancelled = Carbon::parse($cancelledAt);

            if ($cancelled->lt($lockedSession->started_at)) {
                throw new InvalidArgumentException(
                    'The cancellation time cannot be before the session start.',
                );
            }

            if ($lockedSession->status === 'paused') {
                $pause = SessionPause::query()
                    ->where('focus_session_id', $lockedSession->id)
                    ->whereNull('ended_at')
                    ->latest('started_at')
                    ->lockForUpdate()
                    ->first();

                if ($pause !== null) {
                    if ($cancelled->lt($pause->started_at)) {
                        throw new InvalidArgumentException(
                            'The cancellation time cannot be before the active pause started.',
                        );
                    }

                    $pauseDuration =
                        $pause->started_at->diffInSeconds($cancelled);

                    $pause->update([
                        'ended_at' => $cancelled,
                        'duration_seconds' => $pauseDuration,
                    ]);
                }
            }

            $lockedSession->update([
                'status' => 'cancelled',
                'ended_at' => $cancelled,
            ]);

            return $lockedSession->fresh([
                'interruptions',
                'pauses',
            ]);
        });
    }

    /**
     * Complete an active session and calculate its metrics.
     */
    public function complete(
        FocusSession $session,
        CarbonInterface|string $endedAt,
    ): FocusSession {
        return DB::transaction(function () use (
            $session,
            $endedAt,
        ): FocusSession {
            $lockedSession = FocusSession::query()
                ->whereKey($session->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedSession->status !== 'active') {
                throw new InvalidArgumentException(
                    'Only active sessions can be completed.',
                );
            }

            $ended = Carbon::parse($endedAt);

            if ($ended->lt($lockedSession->started_at)) {
                throw new InvalidArgumentException(
                    'The end time cannot be before the session start.',
                );
            }

            $actualDuration = $this->calculateActualDuration(
                $lockedSession,
                $ended,
            );

            $interruptions = SessionInterruption::query()
                ->where('focus_session_id', $lockedSession->id)
                ->get();

            $interruptedDuration = $this->calculateInterruptedDuration(
                $interruptions,
                $lockedSession->started_at,
                $ended,
            );

            $interruptedDuration = min(
                $interruptedDuration,
                $actualDuration,
            );

            $focusedDuration = max(
                0,
                $actualDuration - $interruptedDuration,
            );

            $focusIntegrity = null;

            if ($lockedSession->mode === 'focus') {
                $focusIntegrity = round(
                    (
                        $focusedDuration /
                        $lockedSession->planned_duration_seconds
                    ) * 100,
                    2,
                );

                $focusIntegrity = min(
                    100,
                    max(0, $focusIntegrity),
                );
            }

            $lockedSession->update([
                'actual_duration_seconds' => $actualDuration,
                'focused_duration_seconds' => $focusedDuration,
                'interrupted_duration_seconds' =>
                    $interruptedDuration,
                'interruption_count' => $interruptions->count(),
                'focus_integrity' => $focusIntegrity,
                'status' => 'completed',
                'ended_at' => $ended,
            ]);

            return $lockedSession->fresh([
                'interruptions',
                'pauses',
            ]);
        });
    }

    /**
     * Calculate actual active duration excluding manual pauses.
     */
    private function calculateActualDuration(
        FocusSession $session,
        CarbonInterface $endedAt,
    ): int {
        $sessionEnd = $session->started_at->copy()->addSeconds(
            $session->planned_duration_seconds,
        );

        $effectiveEnd = $endedAt->copy();

        if ($effectiveEnd->gt($sessionEnd)) {
            $effectiveEnd = $sessionEnd;
        }

        if ($effectiveEnd->lte($session->started_at)) {
            return 0;
        }

        $totalElapsed = $session->started_at->diffInSeconds(
            $effectiveEnd,
        );

        $pauseDuration = SessionPause::query()
            ->where('focus_session_id', $session->id)
            ->whereNotNull('ended_at')
            ->get()
            ->sum(function (SessionPause $pause): int {
                return $pause->duration_seconds;
            });

        return max(
            0,
            min(
                $session->planned_duration_seconds,
                $totalElapsed - $pauseDuration,
            ),
        );
    }

    /**
     * Calculate interruption duration up to the effective session end.
     *
     * @param \Illuminate\Database\Eloquent\Collection<int, SessionInterruption> $interruptions
     */
    private function calculateInterruptedDuration(
        $interruptions,
        CarbonInterface $sessionStartedAt,
        CarbonInterface $endedAt,
    ): int {
        $total = 0;

        foreach ($interruptions as $interruption) {
            if ($interruption->ended_at === null) {
                continue;
            }

            $start = $interruption->started_at->copy();
            $end = $interruption->ended_at->copy();

            if ($end->lte($sessionStartedAt)) {
                continue;
            }

            if ($start->lt($sessionStartedAt)) {
                $start = $sessionStartedAt->copy();
            }

            if ($end->gt($endedAt)) {
                $end = $endedAt->copy();
            }

            if ($end->lte($start)) {
                continue;
            }

            $total += $start->diffInSeconds($end);
        }

        return $total;
    }
}
