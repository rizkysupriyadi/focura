<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\InsightsRequest;
use App\Http\Resources\InsightsResource;
use App\Services\ApiIdentityService;
use App\Services\InsightsService;

class InsightsController extends Controller
{
    public function __construct(
        private readonly InsightsService $insightsService,
        private readonly ApiIdentityService $apiIdentityService,
    ) {}

    public function __invoke(
        InsightsRequest $request,
    ): InsightsResource {
        $identity = $this->apiIdentityService->resolve(
            $request,
        );

        $insights = $this->insightsService->getForIdentity(
            identity: $identity,
            range: $request->validated('range') ?? '30d',
        );

        return (new InsightsResource($insights))
            ->additional([
                'message' => 'Insights retrieved successfully.',
            ]);
    }
}
