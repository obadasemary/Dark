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

        // non-GET: serialize parameters according to the declared contentType.
        if method != .get, let params = parameters {
            switch contentType {
            case .json:
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])

            case .formURLEncoded:
                // Percent-encode keys and values, excluding characters that carry
                // structural meaning in an application/x-www-form-urlencoded body.
                var allowed = CharacterSet.urlQueryAllowed
                allowed.remove(charactersIn: "+&=")
                let bodyString = params
                    .map { key, value -> String in
                        let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                        let v = "\(value)".addingPercentEncoding(withAllowedCharacters: allowed) ?? "\(value)"
                        return "\(k)=\(v)"
                    }
                    .joined(separator: "&")
                request.httpBody = bodyString.data(using: .utf8)

            case .multipart:
                let boundary = "Boundary-\(UUID().uuidString)"
                var body = Data()
                for (key, value) in params {
                    body.append(contentsOf: "--\(boundary)\r\n".utf8)
                    if let data = value as? Data {
                        // Binary / file part.
                        body.append(contentsOf: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key)\"\r\n".utf8)
                        body.append(contentsOf: "Content-Type: application/octet-stream\r\n\r\n".utf8)
                        body.append(data)
                        body.append(contentsOf: "\r\n".utf8)
                    } else {
                        // Plain text part.
                        body.append(contentsOf: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8)
                        body.append(contentsOf: "\(value)\r\n".utf8)
                    }
                }
                body.append(contentsOf: "--\(boundary)--\r\n".utf8)
                request.httpBody = body
                // The boundary must be included in the Content-Type header value.
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            }
        }

        return request
    }
}
