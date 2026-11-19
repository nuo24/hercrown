import XCTest
@testable import HerCrown

final class AccountDeletionTests: XCTestCase {
    @MainActor
    func testOldGuestUsesGuestDeletionAndPreservesAccountOnFailure() async throws {
        try await checkDeletion(guest: true, path: "/api/auth/delete-anonymous-user", code: "temporary_failure")
    }

    @MainActor
    func testAppleDeletionExposesFreshSessionErrorWithoutClearingAccount() async throws {
        try await checkDeletion(guest: false, path: "/api/auth/delete-user", code: "SESSION_EXPIRED")
    }

    @MainActor
    private func checkDeletion(guest: Bool, path: String, code: String) async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [DeletionProtocol.self]
        let session = URLSession(configuration: config)
        let api = APIClient(base: URL(string: "https://deletion-test.invalid")!, session: session)
        let previousToken = api.token
        api.token = "deletion-test-session"
        defer { api.token = previousToken; session.invalidateAndCancel(); DeletionProtocol.handler = nil }
        let app = AppModel(api: api)
        let me = account(guest: guest)
        app.me = try JSONDecoder().decode(Me.self, from: me)
        var requests: [String] = []
        DeletionProtocol.handler = { request in
            requests.append(request.url!.path)
            if request.url?.path == "/me" { return (200, [:], me) }
            XCTAssertEqual(request.url?.path, path)
            XCTAssertEqual(request.httpMethod, "POST")
            return (400, [:], Data("{\"code\":\"\(code)\",\"message\":\"Please try again\"}".utf8))
        }
        do { try await app.deleteAccount(); XCTFail("Deletion should fail") }
        catch let error as APIError { XCTAssertEqual(error.code, code) }
        XCTAssertEqual(requests, ["/me", path])
        XCTAssertEqual(app.me?.user.id, "delete-test")
        XCTAssertEqual(api.token, "deletion-test-session")
    }

    @MainActor
    func testReauthenticationWithDifferentAppleAccountCannotDeleteOrReplaceSession() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [DeletionProtocol.self]
        let session = URLSession(configuration: config)
        let api = APIClient(base: URL(string: "https://deletion-test.invalid")!, session: session)
        let previousToken = api.token
        api.token = "original-session"
        defer { api.token = previousToken; session.invalidateAndCancel(); DeletionProtocol.handler = nil }
        let app = AppModel(api: api)
        app.me = try JSONDecoder().decode(Me.self, from: account(guest: false))
        let other = account(guest: false, id: "different-account")
        DeletionProtocol.handler = { request in
            if request.url?.path == "/api/auth/sign-in/social" {
                XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
                return (200, ["set-auth-token": "other-session"], Data("{}".utf8))
            }
            XCTAssertEqual(request.url?.path, "/me")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer other-session")
            return (200, [:], other)
        }
        do {
            try await app.reauthenticateForDeletion(identityToken: "apple-test-token", expectedUserID: "delete-test")
            XCTFail("A different account must be rejected")
        } catch let error as APIError { XCTAssertEqual(error.code, "account_mismatch") }
        XCTAssertEqual(api.token, "original-session")
        XCTAssertEqual(app.me?.user.id, "delete-test")
    }

    private func account(guest: Bool, id: String = "delete-test") -> Data {
        Data("""
        {"user":{"id":"\(id)","isAnonymous":\(guest)},"profile":{},
        "preferences":{"topics":[],"remindersEnabled":false,"reminderTime":"09:00","appearance":"light","fontSize":"default","wordsOfJesusInRed":false,"translation":"kjv"},
        "onboarding":{"completed":true},"membership":{"premium":false}}
        """.utf8)
    }
}

private final class DeletionProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, [String: String], Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, headers, data) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
