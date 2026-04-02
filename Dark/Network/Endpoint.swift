// Dark/Network/Endpoint.swift
import Foundation

protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var parameters: [String: Any]? { get }
    var contentType: ContentType { get }
}

extension Endpoint {

    /// Default base URL — override per endpoint or per API group.
    var baseURL: URL {
        // Force-unwrap is intentional: a nil base URL is a programmer
        // error that must fail at design time, not silently at runtime.
        URL(string: "https://api.example.com")!
    }

    /// Default headers always include Content-Type derived from `contentType`.
    var headers: [String: String] {
        ["Content-Type": contentType.rawValue]
    }

    /// Default content type is JSON.
    var contentType: ContentType { .json }

    // MARK: - Internal builder

    /// Builds a `URLRequest` from this endpoint.
    /// Called exclusively by `URLSessionNetworkClient` — not part of the public API.
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // GET: encode parameters as URL query items.
        if method == .get, let params = parameters {
            components?.queryItems = params.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }

        guard let resolvedURL = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: resolvedURL)
        request.httpMethod = method.rawValue
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // non-GET: serialize parameters as a JSON body.
        if method != .get, let params = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }

        return request
    }
}
