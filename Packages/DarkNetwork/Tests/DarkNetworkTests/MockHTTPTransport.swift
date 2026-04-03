// DarkNetworkTests/MockHTTPTransport.swift
import Foundation
import DarkNetwork

/// A configurable stub conforming to `HTTPTransport`.
/// Inject into `URLSessionNetworkClient(transport:)` in tests.
struct MockHTTPTransport: HTTPTransport {

    /// Closure executed when `data(for:)` is called.
    /// Set this to control what the mock returns or throws.
    var result: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await result(request)
    }
}

// MARK: - Factories

extension MockHTTPTransport {

    /// Returns a 200 (or custom status) response whose body is `value` JSON-encoded.
    static func success<T: Encodable>(
        _ value: T,
        statusCode: Int = 200,
        url: URL = URL(string: "https://api.example.com")!
    ) throws -> MockHTTPTransport {
        let data = try JSONEncoder().encode(value)
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return MockHTTPTransport { _ in (data, response) }
    }

    /// Returns a response with the given HTTP status code and an empty body.
    static func failure(
        statusCode: Int,
        url: URL = URL(string: "https://api.example.com")!
    ) -> MockHTTPTransport {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return MockHTTPTransport { _ in (Data(), response) }
    }
}
