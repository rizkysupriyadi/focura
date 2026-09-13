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
        Schema::table('focus_sessions', function (Blueprint $table) {
            $table->uuid('visitor_id')
                ->nullable()
                ->after('user_id');

            $table->index([
                'visitor_id',
                'created_at',
            ]);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('focus_sessions', function (Blueprint $table) {
            $table->dropIndex([
                'focus_sessions_visitor_id_created_at_index',
            ]);

            $table->dropColumn('visitor_id');
        });
    }
};
