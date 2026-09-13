<?php

namespace App\Http\Resources;

use App\Models\SessionInterruption;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin SessionInterruption
 */
class SessionInterruptionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'started_at' => $this->started_at->toISOString(),
            'ended_at' => $this->ended_at?->toISOString(),
            'duration_seconds' => $this->duration_seconds,
        ];
    }
}
