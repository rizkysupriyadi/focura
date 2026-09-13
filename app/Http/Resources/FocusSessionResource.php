<?php

namespace App\Http\Resources;

use App\Models\FocusSession;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FocusSession
 */
class FocusSessionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'user_id' => $this->user_id,
            'visitor_id' => $this->visitor_id,

            'mode' => $this->mode,
            'title' => $this->title,

            'planned_duration_seconds' =>
                $this->planned_duration_seconds,

            'actual_duration_seconds' =>
                $this->actual_duration_seconds,

            'focused_duration_seconds' =>
                $this->focused_duration_seconds,

            'interrupted_duration_seconds' =>
                $this->interrupted_duration_seconds,

            'interruption_count' =>
                $this->interruption_count,

            'focus_integrity' => $this->focus_integrity,

            'status' => $this->status,

            'started_at' =>
                $this->started_at->toISOString(),

            'ended_at' =>
                $this->ended_at?->toISOString(),

            'interruptions' =>
                SessionInterruptionResource::collection(
                    $this->whenLoaded('interruptions'),
                ),

            'created_at' =>
                $this->created_at?->toISOString(),

            'updated_at' =>
                $this->updated_at?->toISOString(),
        ];
    }
}