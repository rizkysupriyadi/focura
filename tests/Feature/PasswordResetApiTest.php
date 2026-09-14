<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\URL;

uses(RefreshDatabase::class);

describe('POST /api/v1/auth/forgot-password', function () {
    it('validates the email address', function () {
        $response = $this->postJson(
            '/api/v1/auth/forgot-password',
            []
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    });

    it('returns the same response for an existing account', function () {
        Notification::fake();

        User::factory()->create([
            'email' => 'rizky@example.com',
        ]);

        $response = $this->postJson(
            '/api/v1/auth/forgot-password',
            [
                'email' => 'rizky@example.com',
            ]
        );

        $response
            ->assertOk()
            ->assertJson([
                'message' => 'If an account exists for that email address, a password reset link has been sent.',
            ]);

        Notification::assertSentTo(
            User::where('email', 'rizky@example.com')->first(),
            \Illuminate\Auth\Notifications\ResetPassword::class,
        );
    });

    it('does not reveal whether an account exists', function () {
        Notification::fake();

        $response = $this->postJson(
            '/api/v1/auth/forgot-password',
            [
                'email' => 'does-not-exist@example.com',
            ]
        );

        $response
            ->assertOk()
            ->assertJson([
                'message' => 'If an account exists for that email address, a password reset link has been sent.',
            ]);

        Notification::assertNothingSent();
    });
});

describe('POST /api/v1/auth/reset-password', function () {
    it('validates reset password input', function () {
        $response = $this->postJson(
            '/api/v1/auth/reset-password',
            []
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'token',
                'email',
                'password',
            ]);
    });

    it('resets the password with a valid token', function () {
        $user = User::factory()->create([
            'email' => 'rizky@example.com',
            'password' => Hash::make('old-password'),
        ]);

        $token = Password::createToken($user);

        $response = $this->postJson(
            '/api/v1/auth/reset-password',
            [
                'token' => $token,
                'email' => 'rizky@example.com',
                'password' => 'new-password',
                'password_confirmation' => 'new-password',
            ]
        );

        $response
            ->assertOk()
            ->assertJson([
                'message' => 'Your password has been reset successfully.',
            ]);

        $user->refresh();

        expect(
            Hash::check('new-password', $user->password)
        )->toBeTrue();

        expect(
            Hash::check('old-password', $user->password)
        )->toBeFalse();

        $this->postJson(
            '/api/v1/auth/login',
            [
                'email' => 'rizky@example.com',
                'password' => 'new-password',
            ]
        )->assertOk();
    });

    it('rejects an invalid reset token', function () {
        User::factory()->create([
            'email' => 'rizky@example.com',
            'password' => Hash::make('old-password'),
        ]);

        $response = $this->postJson(
            '/api/v1/auth/reset-password',
            [
                'token' => 'invalid-reset-token',
                'email' => 'rizky@example.com',
                'password' => 'new-password',
                'password_confirmation' => 'new-password',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    });

    it('rejects a token for a different email address', function () {
        $user = User::factory()->create([
            'email' => 'rizky@example.com',
            'password' => Hash::make('old-password'),
        ]);

        User::factory()->create([
            'email' => 'other@example.com',
        ]);

        $token = Password::createToken($user);

        $response = $this->postJson(
            '/api/v1/auth/reset-password',
            [
                'token' => $token,
                'email' => 'other@example.com',
                'password' => 'new-password',
                'password_confirmation' => 'new-password',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    });

    it('rejects a mismatched password confirmation', function () {
        $user = User::factory()->create([
            'email' => 'rizky@example.com',
        ]);

        $token = Password::createToken($user);

        $response = $this->postJson(
            '/api/v1/auth/reset-password',
            [
                'token' => $token,
                'email' => 'rizky@example.com',
                'password' => 'new-password',
                'password_confirmation' => 'different-password',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'password',
            ]);
    });

    it('invalidates the reset token after successful use', function () {
        $user = User::factory()->create([
            'email' => 'rizky@example.com',
        ]);

        $token = Password::createToken($user);

        $payload = [
            'token' => $token,
            'email' => 'rizky@example.com',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ];

        $this->postJson(
            '/api/v1/auth/reset-password',
            $payload
        )->assertOk();

        $this->postJson(
            '/api/v1/auth/reset-password',
            $payload
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    });
});

describe('password reset notification', function () {
    it('generates a reset URL using the Focura reset password route', function () {
        Notification::fake();

        $user = User::factory()->create([
            'email' => 'rizky@example.com',
        ]);

        $this->postJson(
            '/api/v1/auth/forgot-password',
            [
                'email' => 'rizky@example.com',
            ]
        )->assertOk();

        Notification::assertSentTo(
            $user,
            \Illuminate\Auth\Notifications\ResetPassword::class,
            function ($notification) use ($user): bool {
                $url = URL::route(
                    'password.reset',
                    [
                        'token' => $notification->token,
                        'email' => $user->email,
                    ]
                );

                return str_contains(
                    $url,
                    '/reset-password?'
                );
            }
        );
    });
});
