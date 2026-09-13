export interface AuthUser {
    id: number;
    name: string;
    email: string;
    email_verified_at: string | null;
    created_at: string | null;
}

export interface AuthResponse {
    data: AuthUser;
    message?: string;
}

export interface LogoutResponse {
    data: null;
    message?: string;
}

export interface ClaimGuestSessionsResponse {
    data: {
        claimed_count: number;
    };
    message?: string;
}

export interface LoginPayload {
    email: string;
    password: string;
    remember?: boolean;
}

export interface RegisterPayload {
    name: string;
    email: string;
    password: string;
    password_confirmation: string;
}
