import Foundation

/// Product analytics → POST /events (docs/analytics.md). Events wait in a small file and are sent in batches, so
/// they survive being offline. Never put names, emails, notes or which verses someone reads in props.
actor Analytics {
    static let shared = Analytics()

    private struct Event: Codable { let id: String; let name: String; let at: Double; let props: [String: JSONValue] }
    private var queue: [Event] = []
    private var sending = false
    private let file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("hc-events.json")

    init() {
        if let data = try? Data(contentsOf: file), let saved = try? JSONDecoder().decode([Event].self, from: data) { queue = saved }
    }

    func track(_ name: String, _ props: [String: JSONValue] = [:]) {
        queue.append(Event(id: UUID().uuidString.lowercased(), name: name, at: Date().timeIntervalSince1970 * 1000, props: props))
        if queue.count > 500 { queue.removeFirst(queue.count - 500) }
        save()
        if queue.count >= 10 { Task { await flush() } }
    }

    /// Sends up to 50 at a time. Kept on network failure; dropped when the server says it rejected them.
    func flush() async {
        guard !sending, !queue.isEmpty else { return }
        sending = true
        defer { sending = false }
        while !queue.isEmpty {
            let batch = Array(queue.prefix(50))
            let body: [String: Any] = ["events": batch.map { ["id": $0.id, "name": $0.name, "at": $0.at, "props": $0.props.mapValues(\.any)] }]
            do {
                try await APIClient.shared.send("POST", "/events", json: body)
            } catch let error as APIError where error.status == 400 {
                // Malformed batch: drop it rather than retry forever.
            } catch {
                return
            }
            queue.removeFirst(batch.count)
            save()
        }
    }

    private func save() {
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(queue).write(to: file, options: .atomic)
    }
}

/// A small JSON value for event props.
enum JSONValue: Codable, Sendable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    case string(String), number(Double), bool(Bool)
    init(stringLiteral value: String) { self = .string(value) }
    init(integerLiteral value: Int) { self = .number(Double(value)) }
    init(booleanLiteral value: Bool) { self = .bool(value) }
    var any: Any {
        switch self { case .string(let s): return s; case .number(let n): return n; case .bool(let b): return b }
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { self = .bool(b) } else if let n = try? c.decode(Double.self) { self = .number(n) } else { self = .string(try c.decode(String.self)) }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self { case .string(let s): try c.encode(s); case .number(let n): try c.encode(n); case .bool(let b): try c.encode(b) }
    }
}
