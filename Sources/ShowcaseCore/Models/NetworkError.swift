import Foundation

/// Network error types with user-friendly messages
public enum NetworkError: LocalizedError, Sendable, Equatable {
    case offline
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection. Please check your network."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid server response. Please contact support."
        }
    }
}
