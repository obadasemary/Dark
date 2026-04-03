// DarkNetworkTests/NetworkErrorTests.swift
import Testing
import Foundation
import DarkNetwork

@Suite("NetworkError")
struct NetworkErrorTests {

    // MARK: - Same-case equality

    @Test("invalidURL equals itself")
    func invalidURLEquality() {
        #expect(NetworkError.invalidURL == NetworkError.invalidURL)
    }

    @Test("noData equals itself")
    func noDataEquality() {
        #expect(NetworkError.noData == NetworkError.noData)
    }

    @Test("requestFailed equals when status codes match")
    func requestFailedSameCode() {
        #expect(NetworkError.requestFailed(statusCode: 404) == NetworkError.requestFailed(statusCode: 404))
    }

    @Test("requestFailed not equal when status codes differ")
    func requestFailedDifferentCodes() {
        #expect(NetworkError.requestFailed(statusCode: 404) != NetworkError.requestFailed(statusCode: 500))
    }

    @Test("decodingFailed equals another decodingFailed regardless of wrapped error")
    func decodingFailedTypeLevelEquality() {
        let err1 = NSError(domain: "A", code: 1)
        let err2 = NSError(domain: "B", code: 999)
        #expect(NetworkError.decodingFailed(err1) == NetworkError.decodingFailed(err2))
    }

    @Test("unknown equals another unknown regardless of wrapped error")
    func unknownTypeLevelEquality() {
        let err1 = NSError(domain: "X", code: 0)
        let err2 = URLError(.cancelled)
        #expect(NetworkError.unknown(err1) == NetworkError.unknown(err2))
    }

    // MARK: - Cross-case inequality

    @Test("invalidURL does not equal noData")
    func invalidURLNotEqualNoData() {
        #expect(NetworkError.invalidURL != NetworkError.noData)
    }

    @Test("invalidURL does not equal requestFailed")
    func invalidURLNotEqualRequestFailed() {
        #expect(NetworkError.invalidURL != NetworkError.requestFailed(statusCode: 404))
    }

    @Test("noData does not equal decodingFailed")
    func noDataNotEqualDecodingFailed() {
        let err = NSError(domain: "D", code: 0)
        #expect(NetworkError.noData != NetworkError.decodingFailed(err))
    }

    @Test("requestFailed does not equal unknown")
    func requestFailedNotEqualUnknown() {
        let err = NSError(domain: "E", code: 0)
        #expect(NetworkError.requestFailed(statusCode: 200) != NetworkError.unknown(err))
    }

    @Test("decodingFailed does not equal unknown")
    func decodingFailedNotEqualUnknown() {
        let err = NSError(domain: "F", code: 0)
        #expect(NetworkError.decodingFailed(err) != NetworkError.unknown(err))
    }

    @Test("unknown does not equal invalidURL")
    func unknownNotEqualInvalidURL() {
        let err = NSError(domain: "G", code: 0)
        #expect(NetworkError.unknown(err) != NetworkError.invalidURL)
    }

    // MARK: - requestFailed boundary values

    @Test("requestFailed equality holds at status code 0")
    func requestFailedZeroStatusCode() {
        #expect(NetworkError.requestFailed(statusCode: 0) == NetworkError.requestFailed(statusCode: 0))
    }

    @Test("requestFailed equality holds at Int.max")
    func requestFailedMaxStatusCode() {
        #expect(NetworkError.requestFailed(statusCode: Int.max) == NetworkError.requestFailed(statusCode: Int.max))
    }

    @Test("requestFailed equality holds at negative status code")
    func requestFailedNegativeStatusCode() {
        #expect(NetworkError.requestFailed(statusCode: -1) == NetworkError.requestFailed(statusCode: -1))
    }

    // MARK: - Conforms to Error

    @Test("NetworkError conforms to Error protocol")
    func conformsToError() {
        let error: Error = NetworkError.invalidURL
        #expect(error is NetworkError)
    }
}
