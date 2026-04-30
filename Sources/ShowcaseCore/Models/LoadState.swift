import Foundation

/// Represents the loading state of async data operations
public enum LoadState: Sendable {
    case idle
    case loading
    case loaded
    case failed(Error)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
