<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CancelFocusSessionRequest;
use App\Http\Requests\CompleteFocusSessionRequest;
use App\Http\Requests\ListFocusSessionsRequest;
use App\Http\Requests\PauseFocusSessionRequest;
use App\Http\Requests\ResumeFocusSessionRequest;
use App\Http\Requests\ShowFocusSessionRequest;
use App\Http\Requests\StoreFocusSessionRequest;
use App\Http\Requests\StoreSessionInterruptionRequest;
use App\Http\Resources\FocusSessionResource;
use App\Models\FocusSession;
use App\Services\ApiIdentityService;
use App\Services\FocusSessionService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;

class FocusSessionController extends Controller
{
    public function __construct(
        private readonly FocusSessionService $focusSessionService,
        private readonly ApiIdentityService $apiIdentityService,
    ) {}

    /**
     * List sessions belonging to the current authenticated user
     * or guest visitor.
     */
    public function index(
        ListFocusSessionsRequest $request,
    ): JsonResponse {
        $identity = $this->apiIdentityService->resolve($request);

        $perPage = (int) (
            $request->validated('per_page') ?? 10
        );

        if ($identity['type'] === 'user') {
            $sessions = $this->focusSessionService->listForUser(
                userId: $identity['user_id'],
                mode: $request->validated('mode'),
                status: $request->validated('status'),
                perPage: $perPage,
            );
        } else {
            $sessions = $this->focusSessionService->listForVisitor(
                visitorId: $identity['visitor_id'],
                mode: $request->validated('mode'),
                status: $request->validated('status'),
                perPage: $perPage,
            );
        }

        return FocusSessionResource::collection($sessions)
            ->additional([
                'message' => 'Sessions retrieved successfully.',
            ])
            ->response();
    }

    /**
     * Show a session belonging to the current authenticated user
     * or guest visitor.
     */
    public function show(
        ShowFocusSessionRequest $request,
        FocusSession $focusSession,
    ): FocusSessionResource {
        $identity = $this->apiIdentityService->resolve($request);

        if ($identity['type'] === 'user') {
            $session = $this->focusSessionService->findForUser(
                sessionId: $focusSession->id,
                userId: $identity['user_id'],
            );
        } else {
            $session = $this->focusSessionService->findForVisitor(
                sessionId: $focusSession->id,
                visitorId: $identity['visitor_id'],
            );
        }

        return (new FocusSessionResource($session))
            ->additional([
                'message' => 'Session retrieved successfully.',
            ]);
    }

    /**
     * Claim guest sessions for the authenticated user.
     */
    public function claimVisitorSessions(
        Request $request,
    ): JsonResponse {
        $userId = $this->apiIdentityService->userId();

        if ($userId === null) {
            abort(401, 'Authentication required.');
        }

        $visitorId = $request->header('X-Visitor-Id');

        if (
            $visitorId === null
            || $visitorId === ''
        ) {
            throw ValidationException::withMessages([
                'visitor_id' => [
                    'The X-Visitor-Id header is required.',
                ],
            ]);
        }

        if (! preg_match(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i',
            $visitorId,
        )) {
            throw ValidationException::withMessages([
                'visitor_id' => [
                    'The X-Visitor-Id header must be a valid UUID.',
                ],
            ]);
        }

        $claimedCount =
            $this->focusSessionService->claimVisitorSessions(
                visitorId: $visitorId,
                userId: $userId,
            );

        return response()->json([
            'data' => [
                'claimed_count' => $claimedCount,
            ],
            'message' => 'Guest sessions claimed successfully.',
        ]);
    }

    /**
     * Create a new focus or relax session.
     */
    public function store(
        StoreFocusSessionRequest $request,
    ): FocusSessionResource {
        $data = $request->validated();
        $identity = $this->apiIdentityService->resolve($request);

        $payload = [
            'mode' => $data['mode'],
            'title' => $data['title'] ?? null,
            'planned_duration_seconds' => (int) $data['planned_duration_seconds'],
            'started_at' => $data['started_at'],
            'user_id' => null,
            'visitor_id' => null,
        ];

        if ($identity['type'] === 'user') {
            $payload['user_id'] = $identity['user_id'];
        } else {
            $payload['visitor_id'] = $identity['visitor_id'];
        }

        $session = $this->focusSessionService->create($payload);

        $session->load([
            'interruptions',
            'pauses',
        ]);

        return (new FocusSessionResource($session))
            ->additional([
                'message' => 'Session created successfully.',
            ]);
    }

    /**
     * Complete an active focus session.
     */
    public function complete(
        CompleteFocusSessionRequest $request,
        FocusSession $focusSession,
    ): FocusSessionResource {
        $session = $this->resolveOwnedSession(
            $request,
            $focusSession,
        );

        $validated = $request->validated();

        $session = $this->focusSessionService->complete(
            $session,
            $validated['ended_at'],
        );

        $session->load([
            'interruptions',
            'pauses',
        ]);

        return (new FocusSessionResource($session))
            ->additional([
                'message' => 'Session completed successfully.',
            ]);
    }

    /**
     * Record an interruption for a focus session.
     */
    public function storeInterruption(
        StoreSessionInterruptionRequest $request,
        FocusSession $focusSession,
    ): JsonResponse {
        $session = $this->resolveOwnedSession(
            $request,
            $focusSession,
        );

        $validated = $request->validated();

        try {
            $interruption =
                $this->focusSessionService->recordInterruption(
                    $session,
                    $validated['started_at'],
                    $validated['ended_at'],
                );
        } catch (InvalidArgumentException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], 422);
        }

        return response()->json([
            'data' => $interruption,
            'message' => 'Interruption recorded successfully.',
        ], 201);
    }

    /**
     * Pause an active focus session.
     */
    public function pause(
        PauseFocusSessionRequest $request,
        FocusSession $focusSession,
    ): JsonResponse {
        $session = $this->resolveOwnedSession(
            $request,
            $focusSession,
        );

        $validated = $request->validated();

        $pause = $this->focusSessionService->pause(
            $session,
            $validated['started_at'],
        );

        return response()->json([
            'data' => $pause,
            'message' => 'Session paused successfully.',
        ]);
    }

    /**
     * Resume a paused focus session.
     */
    public function resume(
        ResumeFocusSessionRequest $request,
        FocusSession $focusSession,
    ): JsonResponse {
        $session = $this->resolveOwnedSession(
            $request,
            $focusSession,
        );

        $validated = $request->validated();

        $pause = $this->focusSessionService->resume(
            $session,
            $validated['ended_at'],
        );

        return response()->json([
            'data' => $pause,
            'message' => 'Session resumed successfully.',
        ]);
    }

    /**
     * Cancel an active or paused focus session.
     */
    public function cancel(
        CancelFocusSessionRequest $request,
        FocusSession $focusSession,
    ): FocusSessionResource {
        $session = $this->resolveOwnedSession(
            $request,
            $focusSession,
        );

        $validated = $request->validated();

        $session = $this->focusSessionService->cancel(
            $session,
            $validated['cancelled_at'],
        );

        $session->load([
            'interruptions',
            'pauses',
        ]);

        return (new FocusSessionResource($session))
            ->additional([
                'message' => 'Session cancelled successfully.',
            ]);
    }

    /**
     * Resolve and authorize a session for the current identity.
     *
     * @throws ModelNotFoundException
     */
    private function resolveOwnedSession(
        Request $request,
        FocusSession $focusSession,
    ): FocusSession {
        $identity = $this->apiIdentityService->resolve($request);

        if ($identity['type'] === 'user') {
            return $this->focusSessionService->findForUser(
                sessionId: $focusSession->id,
                userId: $identity['user_id'],
            );
        }

        return $this->focusSessionService->findForVisitor(
            sessionId: $focusSession->id,
            visitorId: $identity['visitor_id'],
        );
    }
}
