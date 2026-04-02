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
