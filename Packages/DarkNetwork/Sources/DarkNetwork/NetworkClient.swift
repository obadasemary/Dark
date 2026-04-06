// DarkNetwork/NetworkClient.swift
import Foundation

// MARK: - HTTPTransport

/// Low-level seam over URLSession.
/// Conform a mock struct to this protocol in tests — no URLProtocol subclassing needed.
public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// URLSession satisfies HTTPTransport for free.
extension URLSession: HTTPTransport {}

// MARK: - NetworkClient

/// The abstraction that features and ViewModels depend on.
/// Use `any NetworkClient` at injection sites for full DI flexibility.
public protocol NetworkClient: Sendable {
    func request<T: Decodable>(
        endpoint: some Endpoint,
        response: T.Type
    ) async throws -> T
}

// MARK: - URLSessionNetworkClient

/// Production implementation of `NetworkClient`.
///
/// Usage:
/// ```swift
/// let client: any NetworkClient = URLSessionNetworkClient()
/// let user = try await client.request(endpoint: UsersEndpoint.fetchUser(id: 1), response: User.self)
/// ```
public struct URLSessionNetworkClient: NetworkClient, @unchecked Sendable {

    private let transport: any HTTPTransport
    private let decoder: JSONDecoder

    /// - Parameters:
    ///   - transport: Defaults to `URLSession.shared`. Inject a `MockHTTPTransport` in tests.
    ///   - decoder: Defaults to a plain `JSONDecoder`. Inject a custom one to set
    ///              `keyDecodingStrategy`, `dateDecodingStrategy`, etc.
    public init(
        transport: any HTTPTransport = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.transport = transport
        self.decoder = decoder
    }

    public func request<T: Decodable>(
        endpoint: some Endpoint,
        response: T.Type
    ) async throws -> T {
        let urlRequest = try endpoint.asURLRequest()

        let (data, urlResponse) = try await transport.data(for: urlRequest)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkError.unknown(
                NSError(domain: "NetworkClient", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Response is not HTTPURLResponse"])
            )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw NetworkError.noData
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
