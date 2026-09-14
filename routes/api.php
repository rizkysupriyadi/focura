<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\FocusSessionController;
use App\Http\Controllers\Api\V1\InsightsController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    /*
    |--------------------------------------------------------------------------
    | Authentication
    |--------------------------------------------------------------------------
    */

    Route::middleware([
        'web',
        'guest',
        'throttle:10,1',
    ])->group(function () {
        Route::post('/auth/register', [
            AuthController::class,
            'register',
        ]);

        Route::post('/auth/login', [
            AuthController::class,
            'login',
        ]);

    });

    Route::middleware([
        'web',
        'throttle:5,1',
    ])->group(function () {
        Route::post('/auth/forgot-password', [
            AuthController::class,
            'forgotPassword',
        ]);

        Route::post('/auth/reset-password', [
            AuthController::class,
            'resetPassword',
        ]);
    });

    Route::middleware(['web'])->group(function () {
        Route::post('/auth/logout', [
            AuthController::class,
            'logout',
        ])->middleware('auth');

        Route::get('/auth/me', [
            AuthController::class,
            'me',
        ])->middleware('auth');
    });

    /*
    |--------------------------------------------------------------------------
    | Focus Sessions
    |--------------------------------------------------------------------------
    */

    Route::get('/focus-sessions', [
        FocusSessionController::class,
        'index',
    ]);

    Route::post('/focus-sessions/claim', [
        FocusSessionController::class,
        'claimVisitorSessions',
    ])->middleware([
        'web',
        'auth',
        'throttle:30,1',
    ]);

    Route::get('/focus-sessions/{focusSession}', [
        FocusSessionController::class,
        'show',
    ]);

    Route::post('/focus-sessions', [
        FocusSessionController::class,
        'store',
    ])->middleware('throttle:120,1');

    Route::post('/focus-sessions/{focusSession}/complete', [
        FocusSessionController::class,
        'complete',
    ])->middleware('throttle:120,1');

    Route::post('/focus-sessions/{focusSession}/interruptions', [
        FocusSessionController::class,
        'storeInterruption',
    ])->middleware('throttle:120,1');

    Route::post('/focus-sessions/{focusSession}/pause', [
        FocusSessionController::class,
        'pause',
    ])->middleware('throttle:120,1');

    Route::post('/focus-sessions/{focusSession}/resume', [
        FocusSessionController::class,
        'resume',
    ])->middleware('throttle:120,1');

    Route::post('/focus-sessions/{focusSession}/cancel', [
        FocusSessionController::class,
        'cancel',
    ])->middleware('throttle:120,1');

    /*
    |--------------------------------------------------------------------------
    | Insights
    |--------------------------------------------------------------------------
    */

    Route::get('/insights', InsightsController::class)
        ->middleware('throttle:60,1');
});