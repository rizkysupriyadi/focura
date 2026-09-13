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
        Schema::create('session_interruptions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('focus_session_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->timestampTz('started_at');

            $table->timestampTz('ended_at')->nullable();

            $table->unsignedInteger('duration_seconds')
                ->default(0);

            $table->timestampsTz();

            $table->index('focus_session_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('session_interruptions');
    }
};
