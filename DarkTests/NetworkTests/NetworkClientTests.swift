// DarkTests/NetworkTests/NetworkClientTests.swift
import Testing
import Foundation
@testable import Dark

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
}
