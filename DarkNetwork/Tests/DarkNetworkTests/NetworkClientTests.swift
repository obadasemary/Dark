// Tests/DarkNetworkTests/NetworkClientTests.swift
import Testing
import Foundation
@testable import DarkNetwork

// Shared test model
private struct User: Codable, Equatable {
    let id: Int
    let name: String
}

// Shared test endpoint
private struct UsersEndpoint: Endpoint {
    var path: String = "/users/1"
    var method: HTTPMethod = .get
    var parameters: [String: Any]? = nil
}

@Suite("URLSessionNetworkClient")
struct NetworkClientTests {

    @Test("Decodes valid JSON response into expected model")
    func successfulDecode() async throws {
        let expected = User(id: 1, name: "Obada")
        let transport = try MockHTTPTransport.success(expected)
        let client = URLSessionNetworkClient(transport: transport)

        let user = try await client.request(endpoint: UsersEndpoint(), response: User.self)

        #expect(user == expected)
    }

    @Test("Throws requestFailed for 404 status code")
    func http404Error() async throws {
        let transport = MockHTTPTransport.failure(statusCode: 404)
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.requestFailed(statusCode: 404)) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    @Test("Throws requestFailed for 500 status code")
    func http500Error() async throws {
        let transport = MockHTTPTransport.failure(statusCode: 500)
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.requestFailed(statusCode: 500)) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    @Test("Throws decodingFailed when response body shape does not match model")
    func decodingFailure() async throws {
        struct WrongShape: Codable { let x: Int }
        let transport = try MockHTTPTransport.success(WrongShape(x: 99))
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.decodingFailed(
            NSError(domain: "", code: 0) // actual error is ignored by coarse Equatable
        )) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    @Test("Throws noData when 200 response has empty body")
    func emptyResponseBody() async throws {
        let url = URL(string: "https://api.example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 200,
            httpVersion: nil, headerFields: nil
        )!
        let transport = MockHTTPTransport { _ in (Data(), response) }
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.noData) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    @Test("Transport errors propagate unwrapped (e.g. URLError)")
    func transportErrorPropagates() async throws {
        let transportError = URLError(.notConnectedToInternet)
        let transport = MockHTTPTransport { _ in throw transportError }
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: URLError.self) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    @Test("Custom JSONDecoder with snake_case strategy is used")
    func customDecoderSnakeCase() async throws {
        struct SnakeUser: Codable, Equatable {
            let userId: Int
        }
        let json = #"{"user_id": 42}"#.data(using: .utf8)!
        let url = URL(string: "https://api.example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 200,
            httpVersion: nil, headerFields: nil
        )!
        let transport = MockHTTPTransport { _ in (json, response) }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let client = URLSessionNetworkClient(transport: transport, decoder: decoder)

        let user = try await client.request(endpoint: UsersEndpoint(), response: SnakeUser.self)
        #expect(user.userId == 42)
    }

    // MARK: - Non-HTTPURLResponse

    @Test("Throws unknown when response is not HTTPURLResponse")
    func nonHTTPURLResponseThrowsUnknown() async throws {
        let url = URL(string: "https://api.example.com")!
        // URLResponse (not HTTPURLResponse) triggers the guard
        let plainResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let data = #"{"id":1,"name":"X"}"#.data(using: .utf8)!
        let transport = MockHTTPTransport { _ in (data, plainResponse) }
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.unknown(NSError(domain: "", code: 0))) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    // MARK: - Status code boundary tests

    @Test("Status 199 throws requestFailed (below 2xx range)")
    func status199ThrowsRequestFailed() async throws {
        let transport = MockHTTPTransport.failure(statusCode: 199)
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.requestFailed(statusCode: 199)) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    @Test("Status 200 succeeds (lower boundary of 2xx range)")
    func status200Succeeds() async throws {
        let expected = User(id: 2, name: "Boundary")
        let transport = try MockHTTPTransport.success(expected, statusCode: 200)
        let client = URLSessionNetworkClient(transport: transport)

        let user = try await client.request(endpoint: UsersEndpoint(), response: User.self)
        #expect(user == expected)
    }

    @Test("Status 299 succeeds (upper boundary of 2xx range)")
    func status299Succeeds() async throws {
        let expected = User(id: 3, name: "UpperBound")
        let transport = try MockHTTPTransport.success(expected, statusCode: 299)
        let client = URLSessionNetworkClient(transport: transport)

        let user = try await client.request(endpoint: UsersEndpoint(), response: User.self)
        #expect(user == expected)
    }

    @Test("Status 300 throws requestFailed (above 2xx range)")
    func status300ThrowsRequestFailed() async throws {
        let transport = MockHTTPTransport.failure(statusCode: 300)
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.requestFailed(statusCode: 300)) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    @Test("Status 401 throws requestFailed (unauthorized)")
    func status401ThrowsRequestFailed() async throws {
        let transport = MockHTTPTransport.failure(statusCode: 401)
        let client = URLSessionNetworkClient(transport: transport)

        await #expect(throws: NetworkError.requestFailed(statusCode: 401)) {
            try await client.request(endpoint: UsersEndpoint(), response: User.self)
        }
    }

    // MARK: - Request forwarding

    @Test("URLRequest forwarded to transport includes endpoint headers")
    func requestHeadersForwardedToTransport() async throws {
        struct HeaderEndpoint: Endpoint {
            var path = "/secure"
            var method: HTTPMethod = .get
            var parameters: [String: Any]? = nil
            var headers: [String: String] { ["Authorization": "Bearer abc"] }
        }
        // Use a reference-type box so the @Sendable closure can mutate it safely.
        final class RequestCapture: @unchecked Sendable { var value: URLRequest? }
        let capture = RequestCapture()
        let expected = User(id: 5, name: "Secure")
        let encoded = try JSONEncoder().encode(expected)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200, httpVersion: nil, headerFields: nil
        )!
        let transport = MockHTTPTransport { req in
            capture.value = req
            return (encoded, response)
        }
        let client = URLSessionNetworkClient(transport: transport)

        _ = try await client.request(endpoint: HeaderEndpoint(), response: User.self)

        #expect(capture.value?.value(forHTTPHeaderField: "Authorization") == "Bearer abc")
    }

    @Test("POST endpoint body is forwarded to transport")
    func postBodyForwardedToTransport() async throws {
        struct CreateEndpoint: Endpoint {
            var path = "/users"
            var method: HTTPMethod = .post
            var parameters: [String: Any]? = ["name": "NewUser"]
        }
        // Use a reference-type box so the @Sendable closure can mutate it safely.
        final class RequestCapture: @unchecked Sendable { var value: URLRequest? }
        let capture = RequestCapture()
        let expected = User(id: 10, name: "NewUser")
        let encoded = try JSONEncoder().encode(expected)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200, httpVersion: nil, headerFields: nil
        )!
        let transport = MockHTTPTransport { req in
            capture.value = req
            return (encoded, response)
        }
        let client = URLSessionNetworkClient(transport: transport)

        _ = try await client.request(endpoint: CreateEndpoint(), response: User.self)

        let body = try #require(capture.value?.httpBody)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(decoded?["name"] == "NewUser")
    }

    // MARK: - Array decoding

    @Test("Decodes array of models from JSON response")
    func decodeArrayResponse() async throws {
        let users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
        let transport = try MockHTTPTransport.success(users)
        let client = URLSessionNetworkClient(transport: transport)

        let result = try await client.request(endpoint: UsersEndpoint(), response: [User].self)
        #expect(result == users)
    }
}
