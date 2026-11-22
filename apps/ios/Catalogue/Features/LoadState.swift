import Foundation

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(APIError)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var error: APIError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}

extension LoadState {
    /// Returns `nil` if the task was cancelled (the user navigated away), so a cancelled request
    /// never shows up as an error.
    @MainActor
    static func run(_ operation: () async throws -> Value) async -> LoadState<Value>? {
        do {
            return .loaded(try await operation())
        } catch {
            if Task.isCancelled { return nil }
            // CatalogueAPI only throws APIError; anything else is treated as a connection problem.
            return .failed(error as? APIError ?? .network)
        }
    }
}
