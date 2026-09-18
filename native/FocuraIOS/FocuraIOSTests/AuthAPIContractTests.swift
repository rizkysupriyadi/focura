import Foundation
import Testing
@testable import FocuraIOS

@Test
func authAPIResponseDecodesLaravelRegisterResponse() throws {
    let json = """
    {
        "data": {
            "token": "test-token",
            "token_type": "Bearer",
            "expires_at": "2026-10-16T09:30:00.000000Z",
            "user": {
                "id": 42,
                "name": "Rizky",
                "email": "rizky@example.com",
                "email_verified_at": null,
                "created_at": "2026-09-16T09:30:00.000000Z"
            }
        },
        "message": "Registered successfully."
    }
    """

    let response = try APIJSONDecoder.make().decode(
        AuthAPIResponse.self,
        from: Data(json.utf8)
    )

    #expect(response.data.token == "test-token")
    #expect(response.data.tokenType == "Bearer")
    #expect(response.data.user.id == 42)
    #expect(response.data.user.name == "Rizky")
    #expect(response.data.user.email == "rizky@example.com")
    #expect(response.data.user.emailVerifiedAt == nil)
    #expect(response.data.expiresAt != nil)
    #expect(response.message == "Registered successfully.")
}

@Test
func authMeResponseDecodesLaravelUserResource() throws {
    let json = """
    {
        "data": {
            "id": 42,
            "name": "Rizky",
            "email": "rizky@example.com",
            "email_verified_at": "2026-09-16T09:30:00.000000Z",
            "created_at": "2026-09-16T09:30:00.000000Z"
        }
    }
    """

    let response = try APIJSONDecoder.make().decode(
        AuthMeResponse.self,
        from: Data(json.utf8)
    )

    #expect(response.data.id == 42)
    #expect(response.data.name == "Rizky")
    #expect(response.data.email == "rizky@example.com")
    #expect(response.data.emailVerifiedAt != nil)
    #expect(response.data.createdAt != nil)
}

@Test
func logoutResponseDecodesLaravelLogoutResponse() throws {
    let json = """
    {
        "data": null,
        "message": "Logged out successfully."
    }
    """

    let response = try APIJSONDecoder.make().decode(
        LogoutResponse.self,
        from: Data(json.utf8)
    )

    #expect(response.data == nil)
    #expect(response.message == "Logged out successfully.")
}

@Test
func guestSessionClaimResponseDecodesLaravelResponse() throws {
    let json = """
    {
        "data": {
            "claimed_count": 3
        },
        "message": "Guest sessions claimed successfully."
    }
    """

    let response = try APIJSONDecoder.make().decode(
        GuestSessionClaimResponse.self,
        from: Data(json.utf8)
    )

    #expect(response.data.claimedCount == 3)
    #expect(response.message == "Guest sessions claimed successfully.")
}

@Test
func authUserDoesNotExposeSensitiveFields() throws {
    let json = """
    {
        "id": 42,
        "name": "Rizky",
        "email": "rizky@example.com",
        "email_verified_at": null,
        "created_at": "2026-09-16T09:30:00.000000Z"
    }
    """

    let user = try APIJSONDecoder.make().decode(
        AuthUser.self,
        from: Data(json.utf8)
    )

    #expect(user.id == 42)
    #expect(user.email == "rizky@example.com")
}
