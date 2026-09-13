<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int|null $user_id
 * @property string $mode
 * @property string|null $title
 * @property int $planned_duration_seconds
 * @property int $actual_duration_seconds
 * @property int $focused_duration_seconds
 * @property int $interrupted_duration_seconds
 * @property int $interruption_count
 * @property float|null $focus_integrity
 * @property string $status
 * @property Carbon $started_at
 * @property Carbon|null $ended_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 * @property int $id
 * @property int|null $user_id
 * @property string|null $visitor_id
 * @property string $mode
 */
#[Fillable([
    'user_id',
    'visitor_id',
    'mode',
    'title',
    'planned_duration_seconds',
    'actual_duration_seconds',
    'focused_duration_seconds',
    'interrupted_duration_seconds',
    'interruption_count',
    'focus_integrity',
    'status',
    'started_at',
    'ended_at',
])]
class FocusSession extends Model
{
    /**
     * Get the user who owns the session.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the interruptions recorded during the session.
     *
     * @return HasMany<SessionInterruption, $this>
     */
    public function interruptions(): HasMany
    {
        return $this->hasMany(SessionInterruption::class);
    }

    /**
     * Get the manual pauses recorded during the session.
     *
     * @return HasMany<SessionPause, $this>
     */
    public function pauses(): HasMany
    {
        return $this->hasMany(SessionPause::class);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'planned_duration_seconds' => 'integer',
            'actual_duration_seconds' => 'integer',
            'focused_duration_seconds' => 'integer',
            'interrupted_duration_seconds' => 'integer',
            'interruption_count' => 'integer',
            'focus_integrity' => 'float',
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
        ];
    }
}
