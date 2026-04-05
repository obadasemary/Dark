// Sources/DarkNetwork/NetworkError.swift
import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case noData
    case decodingFailed(Error)
    case unknown(Error)

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
