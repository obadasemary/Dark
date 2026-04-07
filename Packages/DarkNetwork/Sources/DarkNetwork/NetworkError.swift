// DarkNetwork/NetworkError.swift
import Foundation

public enum NetworkError: LocalizedError, Equatable, @unchecked Sendable {
    
    case invalidURL
    case requestFailed(statusCode: Int)
    case noData
    case decodingFailed(Error)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .requestFailed(let statusCode):
            return "Request failed with status code \(statusCode)."
        case .noData:
            return "The server returned an empty response."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    // Manual Equatable: `Error` does not conform to `Equatable`,
    // so decodingFailed and unknown use type-level equality.
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.noData, .noData):
            return true
        case let (.requestFailed(a), .requestFailed(b)):
            return a == b
        case (.decodingFailed, .decodingFailed):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
