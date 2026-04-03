// DarkTests/NetworkTests/EndpointTests.swift
import Testing
import Foundation
@testable import DarkNetwork

// Minimal concrete Endpoint used only in this test file.
private struct TestEndpoint: Endpoint {
    var path: String
    var method: HTTPMethod
    var parameters: [String: Any]?
    // baseURL, headers, contentType use protocol extension defaults
}

@Suite("Endpoint")
struct EndpointTests {

    @Test("GET builds URL with query items and no body")
    func getEndpointQueryItems() throws {
        let endpoint = TestEndpoint(
            path: "/search",
            method: .get,
            parameters: ["q": "swift", "page": 1]
        )
        let request = try endpoint.asURLRequest()
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems.contains(URLQueryItem(name: "q", value: "swift")))
        #expect(queryItems.contains(URLQueryItem(name: "page", value: "1")))
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
    }

    @Test("POST serialises parameters into JSON body")
    func postEndpointBodyEncoding() throws {
        let endpoint = TestEndpoint(
            path: "/users",
            method: .post,
            parameters: ["name": "Obada"]
        )
        let request = try endpoint.asURLRequest()
        let body = try #require(request.httpBody)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: String]

        #expect(request.httpMethod == "POST")
        #expect(decoded?["name"] == "Obada")
        #expect(request.url?.query == nil)
    }

    @Test("Default headers contain Content-Type: application/json")
    func defaultHeaders() throws {
        let endpoint = TestEndpoint(path: "/ping", method: .get, parameters: nil)
        let request = try endpoint.asURLRequest()
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("Default baseURL resolves path correctly")
    func defaultBaseURL() throws {
        let endpoint = TestEndpoint(path: "/v1/items", method: .get, parameters: nil)
        let request = try endpoint.asURLRequest()
        #expect(request.url?.host == "api.example.com")
        #expect(request.url?.path == "/v1/items")
    }

    @Test("POST with formURLEncoded content type percent-encodes body")
    func postFormURLEncoded() throws {
        struct FormEndpoint: Endpoint {
            var path = "/login"
            var method: HTTPMethod = .post
            var parameters: [String: Any]? = ["user": "alice", "pass": "p@ss=1&2"]
            var contentType: ContentType { .formURLEncoded }
        }
        let request = try FormEndpoint().asURLRequest()
        let body = try #require(request.httpBody)
        let bodyString = try #require(String(data: body, encoding: .utf8))
        let pairs = Dictionary(
            uniqueKeysWithValues: bodyString
                .split(separator: "&")
                .map { pair -> (String, String) in
                    let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                    return (parts[0], parts[1])
                }
        )

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
        #expect(pairs["user"] == "alice")
        // Special characters must be percent-encoded, not left bare.
        #expect(pairs["pass"] != "p@ss=1&2")
        #expect(request.url?.query == nil)
    }

    @Test("POST with multipart content type builds valid multipart body")
    func postMultipart() throws {
        let fileBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
        struct UploadEndpoint: Endpoint {
            var fileBytes: Data
            var path = "/upload"
            var method: HTTPMethod = .post
            var parameters: [String: Any]? { ["note": "hello", "attachment": fileBytes] }
            var contentType: ContentType { .multipart }
        }
        let request = try UploadEndpoint(fileBytes: fileBytes).asURLRequest()
        let body = try #require(request.httpBody)
        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))

        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        let boundary = String(contentType.dropFirst("multipart/form-data; boundary=".count))
        #expect(!boundary.isEmpty)

        // Body must contain the text part and the closing delimiter.
        // Use Data range-search because the body contains non-UTF-8 binary bytes.
        #expect(body.range(of: Data("name=\"note\"".utf8)) != nil)
        #expect(body.range(of: Data("hello".utf8)) != nil)
        #expect(body.range(of: Data("--\(boundary)--".utf8)) != nil)

        // Body must contain the raw bytes of the Data part.
        #expect(body.range(of: fileBytes) != nil)
    }

    @Test("Custom baseURL override is respected")
    func customBaseURL() throws {
        struct StagingEndpoint: Endpoint {
            var baseURL: URL { URL(string: "https://staging.example.com")! }
            var path = "/health"
            var method: HTTPMethod = .get
            var parameters: [String: Any]? = nil
        }
        let request = try StagingEndpoint().asURLRequest()
        #expect(request.url?.host == "staging.example.com")
        #expect(request.url?.path == "/health")
    }

    // MARK: - PUT method

    @Test("PUT serialises parameters into JSON body and sets correct HTTP method")
    func putEndpointBodyEncoding() throws {
        let endpoint = TestEndpoint(
            path: "/users/42",
            method: .put,
            parameters: ["name": "Updated Name"]
        )
        let request = try endpoint.asURLRequest()
        let body = try #require(request.httpBody)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: String]

        #expect(request.httpMethod == "PUT")
        #expect(decoded?["name"] == "Updated Name")
        #expect(request.url?.query == nil)
    }

    @Test("PUT with nil parameters produces no body")
    func putEndpointNilParameters() throws {
        let endpoint = TestEndpoint(path: "/users/42", method: .put, parameters: nil)
        let request = try endpoint.asURLRequest()
        #expect(request.httpMethod == "PUT")
        #expect(request.httpBody == nil)
    }

    // MARK: - DELETE method

    @Test("DELETE with parameters serialises body and sets correct HTTP method")
    func deleteEndpointBodyEncoding() throws {
        let endpoint = TestEndpoint(
            path: "/items/99",
            method: .delete,
            parameters: ["confirm": true]
        )
        let request = try endpoint.asURLRequest()
        let body = try #require(request.httpBody)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Bool]

        #expect(request.httpMethod == "DELETE")
        #expect(decoded?["confirm"] == true)
        #expect(request.url?.query == nil)
    }

    @Test("DELETE with nil parameters produces no body and no query")
    func deleteEndpointNilParameters() throws {
        let endpoint = TestEndpoint(path: "/items/99", method: .delete, parameters: nil)
        let request = try endpoint.asURLRequest()
        #expect(request.httpMethod == "DELETE")
        #expect(request.httpBody == nil)
        #expect(request.url?.query == nil)
    }

    // MARK: - GET with nil parameters

    @Test("GET with nil parameters produces no query items")
    func getEndpointNilParametersNoQuery() throws {
        let endpoint = TestEndpoint(path: "/users", method: .get, parameters: nil)
        let request = try endpoint.asURLRequest()
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == nil)
        #expect(request.httpBody == nil)
    }

    // MARK: - Custom content type

    @Test("formURLEncoded contentType is reflected in Content-Type header")
    func formURLEncodedContentTypeHeader() throws {
        struct FormEndpoint: Endpoint {
            var path = "/login"
            var method: HTTPMethod = .post
            var parameters: [String: Any]? = nil
            var contentType: ContentType { .formURLEncoded }
        }
        let request = try FormEndpoint().asURLRequest()
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test("multipart contentType is reflected in Content-Type header")
    func multipartContentTypeHeader() throws {
        struct UploadEndpoint: Endpoint {
            var path = "/upload"
            var method: HTTPMethod = .post
            var parameters: [String: Any]? = nil
            var contentType: ContentType { .multipart }
        }
        let request = try UploadEndpoint().asURLRequest()
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "multipart/form-data")
    }

    // MARK: - Custom headers

    @Test("Custom headers override defaults and are present in URLRequest")
    func customHeadersAreApplied() throws {
        struct AuthEndpoint: Endpoint {
            var path = "/protected"
            var method: HTTPMethod = .get
            var parameters: [String: Any]? = nil
            var headers: [String: String] {
                ["Authorization": "Bearer token123", "X-Custom-Header": "value"]
            }
        }
        let request = try AuthEndpoint().asURLRequest()
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
        #expect(request.value(forHTTPHeaderField: "X-Custom-Header") == "value")
    }

    // MARK: - URL construction

    @Test("Path with no leading slash is still appended correctly")
    func pathWithoutLeadingSlash() throws {
        let endpoint = TestEndpoint(path: "noSlash", method: .get, parameters: nil)
        let request = try endpoint.asURLRequest()
        let path = try #require(request.url?.path)
        #expect(path.hasSuffix("noSlash"))
    }

    @Test("POST with multiple parameters all serialised into body")
    func postMultipleParameters() throws {
        let endpoint = TestEndpoint(
            path: "/register",
            method: .post,
            parameters: ["username": "alice", "age": 30, "active": true]
        )
        let request = try endpoint.asURLRequest()
        let body = try #require(request.httpBody)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]

        #expect(decoded?["username"] as? String == "alice")
        #expect(decoded?["age"] as? Int == 30)
        #expect(decoded?["active"] as? Bool == true)
    }
}
