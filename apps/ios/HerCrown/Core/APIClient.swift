import Foundation

/// An error from the API, with the message the server wrote for people (docs/api.md conventions).
struct APIError: LocalizedError, Equatable {
    let status: Int
    let code: String
    let message: String
    var errorDescription: String? { message }

    static let offline = APIError(status: 0, code: "offline", message: "You're offline. We'll try again when you're connected.")
    var isPremiumRequired: Bool { code == "premium_required" }
}

/// Talks to the Her Crown API with the session's bearer token and the app headers on every request.
final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let base: URL
    private let decoder = JSONDecoder()
    private let tokenAccount = "token"
    private let lock = NSLock()
    private var cachedToken: String?

    init(base: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.base = base
        self.session = session
    }

    var token: String? {
        get { lock.withLock { cachedToken ?? Keychain.read(tokenAccount) } }
        set {
            lock.withLock { cachedToken = newValue }
            if let newValue { Keychain.write(newValue, for: tokenAccount) } else { Keychain.delete(tokenAccount) }
        }
    }

    private func makeRequest(_ method: String, _ path: String, body: Data?, accept: String = "application/json") -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: base)!)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue(accept, forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.setValue(AppConfig.installID, forHTTPHeaderField: "X-Install-Id")
        request.setValue(AppConfig.appVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue("ios", forHTTPHeaderField: "X-Platform")
        request.setValue(AppConfig.buildChannel, forHTTPHeaderField: "X-Build")
        return request
    }

    /// Sends a request and returns the raw response. Throws `APIError` for non-2xx answers and `.offline` for network failures.
    @discardableResult
    func send(_ method: String, _ path: String, json: Any? = nil) async throws -> (Data, HTTPURLResponse) {
        let body = try json.map { try JSONSerialization.data(withJSONObject: $0) }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: makeRequest(method, path, body: body))
        } catch {
            throw APIError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.offline }
        guard (200..<300).contains(http.statusCode) else {
            let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            throw APIError(status: http.statusCode, code: object?["error"] as? String ?? "http_\(http.statusCode)",
                           message: object?["message"] as? String ?? "Something went wrong. Please try again.")
        }
        return (data, http)
    }

    func get<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        try decoder.decode(T.self, from: try await send("GET", path).0)
    }

    func call<T: Decodable>(_ method: String, _ path: String, json: Any? = nil, as type: T.Type = T.self) async throws -> T {
        try decoder.decode(T.self, from: try await send(method, path, json: json).0)
    }

    /// Server-Sent Events (study tools): yields (event, data) pairs as they arrive.
    func events(_ path: String) -> AsyncThrowingStream<(String, Data), Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: makeRequest("GET", path, body: nil, accept: "text/event-stream"))
                    guard let http = response as? HTTPURLResponse else { throw APIError.offline }
                    if !(200..<300).contains(http.statusCode) {
                        var data = Data()
                        for try await byte in bytes { data.append(byte) }
                        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                        throw APIError(status: http.statusCode, code: object?["error"] as? String ?? "http_\(http.statusCode)",
                                       message: object?["message"] as? String ?? "Something went wrong. Please try again.")
                    }
                    if !(http.value(forHTTPHeaderField: "Content-Type") ?? "").contains("event-stream") {
                        var data = Data()
                        for try await byte in bytes { data.append(byte) }
                        continuation.yield(("done", data)) // already stored: plain JSON
                    } else {
                        var event = "message"
                        for try await line in bytes.lines {
                            if line.hasPrefix("event: ") { event = String(line.dropFirst(7)) }
                            else if line.hasPrefix("data: ") { continuation.yield((event, Data(line.dropFirst(6).utf8))) }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error is APIError ? error : APIError.offline)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
