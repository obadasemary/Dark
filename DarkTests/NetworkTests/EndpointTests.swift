// DarkTests/NetworkTests/EndpointTests.swift
import Testing
import Foundation
@testable import Dark

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
}
