<?php

namespace App\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class ApiIdentityService
{
    /**
     * Resolve the current API identity.
     *
     * Authenticated users are always identified by the
     * server-side Laravel session. Guests are identified
     * by the X-Visitor-Id header.
     *
     * @return array{
     *     type: 'user'|'visitor',
     *     user_id: int|null,
     *     visitor_id: string|null
     * }
     */
    public function resolve(Request $request): array
    {
        if (Auth::guard('web')->check()) {
            return [
                'type' => 'user',
                'user_id' => (int) Auth::guard('web')->id(),
                'visitor_id' => null,
            ];
        }

        $visitorId = $this->visitorId($request);

        if ($visitorId === null) {
            $header = $request->header('X-Visitor-Id');

            if ($header === null || $header === '') {
                throw ValidationException::withMessages([
                    'visitor_id' => [
                        'The X-Visitor-Id header is required.',
                    ],
                ]);
            }

            throw ValidationException::withMessages([
                'visitor_id' => [
                    'The X-Visitor-Id header must be a valid UUID.',
                ],
            ]);
        }

        return [
            'type' => 'visitor',
            'user_id' => null,
            'visitor_id' => $visitorId,
        ];
    }

    public function isAuthenticated(): bool
    {
        return Auth::guard('web')->check();
    }

    public function userId(): ?int
    {
        $userId = Auth::guard('web')->id();

        return $userId === null
            ? null
            : (int) $userId;
    }

    public function visitorId(Request $request): ?string
    {
        $visitorId = $request->header('X-Visitor-Id');

        if ($visitorId === null || $visitorId === '') {
            return null;
        }

        if (! preg_match(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i',
            $visitorId,
        )) {
            return null;
        }

        return $visitorId;
    }
}
