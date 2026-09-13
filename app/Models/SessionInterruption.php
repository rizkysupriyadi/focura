<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $focus_session_id
 * @property Carbon $started_at
 * @property Carbon|null $ended_at
 * @property int $duration_seconds
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable([
    'focus_session_id',
    'started_at',
    'ended_at',
    'duration_seconds',
])]
class SessionInterruption extends Model
{
    /**
     * Get the focus session that owns the interruption.
     *
     * @return BelongsTo<FocusSession, $this>
     */
    public function focusSession(): BelongsTo
    {
        return $this->belongsTo(FocusSession::class);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'duration_seconds' => 'integer',
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
        ];
    }
}
