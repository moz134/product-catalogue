import Foundation

/// Mirrors packages/shared/src/errors.ts.
struct APIErrorResponse: Codable, Sendable {
    struct Body: Codable, Sendable {
        let code: String
        let message: String
        let fields: [String: [String]]?
    }

    let error: Body
}

enum APIError: Error, Equatable, Sendable {
    /// No connection, timeout, or the server could not be reached.
    case network
    case notFound
    /// The server rejected the input. `fields` maps field name to messages.
    case validation(message: String, fields: [String: [String]])
    /// Any other error response the API described (rate limited, upstream down, email failed...).
    case server(status: Int, code: String, message: String)
    case invalidResponse

    /// Safe, human-readable text. Never includes raw server or system errors.
    var userMessage: String {
        switch self {
        case .network:
            "We couldn't reach the server. Check your connection and try again."
        case .notFound:
            "We couldn't find that. It may have moved or no longer exists."
        case .validation(let message, _):
            message
        case .server(_, _, let message):
            message
        case .invalidResponse:
            "The server sent an unexpected response. Please try again."
        }
    }
}
