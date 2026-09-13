<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('focus_sessions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();

            $table->string('mode', 20);

            $table->string('title', 255)->nullable();

            $table->unsignedInteger('planned_duration_seconds');

            $table->unsignedInteger('actual_duration_seconds')
                ->default(0);

            $table->unsignedInteger('focused_duration_seconds')
                ->default(0);

            $table->unsignedInteger('interrupted_duration_seconds')
                ->default(0);

            $table->unsignedInteger('interruption_count')
                ->default(0);

            $table->decimal('focus_integrity', 5, 2)->nullable();

            $table->string('status', 20);

            $table->timestampTz('started_at');

            $table->timestampTz('ended_at')->nullable();

            $table->timestampsTz();

            $table->index(['user_id', 'created_at']);
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'started_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('focus_sessions');
    }
};
