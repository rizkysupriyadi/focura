<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

uses(RefreshDatabase::class);

describe('POST /api/v1/auth/register', function () {
    it('registers a new user', function () {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Rizky',
            'email' => 'rizky@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.name', 'Rizky')
            ->assertJsonPath('data.email', 'rizky@example.com')
            ->assertJsonMissingPath('data.password');

        $this->assertDatabaseHas('users', [
            'email' => 'rizky@example.com',
        ]);

        expect(auth()->check())->toBeTrue();
    });

    it('validates registration data', function () {
        $response = $this->postJson('/api/v1/auth/register', []);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'name',
                'email',
                'password',
            ]);
    });

    it('rejects duplicate email addresses', function () {
        User::factory()->create([
            'email' => 'existing@example.com',
        ]);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Another User',
            'email' => 'existing@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    });
});

describe('POST /api/v1/auth/login', function () {
    it('logs in a user with valid credentials', function () {
        $user = User::factory()->create([
            'email' => 'rizky@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'rizky@example.com',
            'password' => 'password123',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.email', 'rizky@example.com');

        $this->assertAuthenticatedAs($user);
    });

    it('rejects invalid credentials', function () {
        User::factory()->create([
            'email' => 'rizky@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'rizky@example.com',
            'password' => 'wrong-password',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);

        $this->assertGuest();
    });

    it('validates login data', function () {
        $response = $this->postJson('/api/v1/auth/login', []);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'email',
                'password',
            ]);
    });
});

describe('GET /api/v1/auth/me', function () {
    it('returns the authenticated user', function () {
        $user = User::factory()->create([
            'name' => 'Rizky',
            'email' => 'rizky@example.com',
        ]);

        $response = $this
            ->actingAs($user)
            ->getJson('/api/v1/auth/me');

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.name', 'Rizky')
            ->assertJsonPath('data.email', 'rizky@example.com')
            ->assertJsonMissingPath('data.password');
    });

    it('requires authentication', function () {
        $response = $this->getJson('/api/v1/auth/me');

        $response->assertUnauthorized();
    });
});

describe('POST /api/v1/auth/logout', function () {
    it('logs out the authenticated user', function () {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->postJson('/api/v1/auth/logout');

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'Logged out successfully.'
            );

        $this->assertGuest();
    });

    it('requires authentication', function () {
        $response = $this->postJson('/api/v1/auth/logout');

        $response->assertUnauthorized();
    });
});