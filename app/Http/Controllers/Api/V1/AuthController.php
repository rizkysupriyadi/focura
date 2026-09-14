<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ForgotPasswordRequest;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Requests\Api\V1\ResetPasswordRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = DB::transaction(function () use ($request): User {
            return User::create([
                'name' => $request->string('name')->trim()->toString(),
                'email' => strtolower(
                    $request->string('email')->trim()->toString()
                ),
                'password' => Hash::make(
                    $request->string('password')->toString()
                ),
            ]);
        });

        Auth::login($user);

        $request->session()->regenerate();

        return response()->json([
            'data' => new UserResource($user),
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $credentials = [
            'email' => strtolower(
                $request->string('email')->trim()->toString()
            ),
            'password' => $request->string('password')->toString(),
        ];

        $remember = $request->boolean('remember');

        if (! Auth::attempt($credentials, $remember)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $request->session()->regenerate();

        /** @var User $user */
        $user = Auth::user();

        return response()->json([
            'data' => new UserResource($user),
        ]);
    }

    public function forgotPassword(
        ForgotPasswordRequest $request,
    ): JsonResponse {
        Password::sendResetLink([
            'email' => strtolower(
                $request->string('email')->trim()->toString()
            ),
        ]);

        /*
         * Always return the same response.
         *
         * This prevents the endpoint from revealing whether
         * an email address belongs to an existing Focura account.
         */
        return response()->json([
            'message' => 'If an account exists for that email address, a password reset link has been sent.',
        ]);
    }

    public function resetPassword(
        ResetPasswordRequest $request,
    ): JsonResponse {
        $status = Password::reset(
            [
                'email' => strtolower(
                    $request->string('email')->trim()->toString()
                ),
                'password' => $request->string('password')->toString(),
                'password_confirmation' => $request
                    ->string('password_confirmation')
                    ->toString(),
                'token' => $request->string('token')->toString(),
            ],
            function (User $user, string $password): void {
                $user->forceFill([
                    'password' => Hash::make($password),
                ])->save();

            },
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages([
                'email' => [
                    'This password reset link is invalid or has expired.',
                ],
            ]);
        }

        return response()->json([
            'message' => 'Your password has been reset successfully.',
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return response()->json([
            'data' => null,
            'message' => 'Logged out successfully.',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'data' => new UserResource($user),
        ]);
    }
}