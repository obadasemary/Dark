// DarkTests/NetworkTests/HTTPMethodTests.swift
import Testing
import DarkNetwork

@Suite("HTTPMethod")
struct HTTPMethodTests {

    @Test("get has correct raw value")
    func getRawValue() {
        #expect(HTTPMethod.get.rawValue == "GET")
    }

    @Test("post has correct raw value")
    func postRawValue() {
        #expect(HTTPMethod.post.rawValue == "POST")
    }

    @Test("put has correct raw value")
    func putRawValue() {
        #expect(HTTPMethod.put.rawValue == "PUT")
    }

    @Test("delete has correct raw value")
    func deleteRawValue() {
        #expect(HTTPMethod.delete.rawValue == "DELETE")
    }

    @Test("raw values are distinct")
    func distinctRawValues() {
        let values = [HTTPMethod.get.rawValue, HTTPMethod.post.rawValue,
                      HTTPMethod.put.rawValue, HTTPMethod.delete.rawValue]
        let unique = Set(values)
        #expect(unique.count == values.count)
    }

    @Test("initialise from raw value succeeds for all known values")
    func initFromRawValue() {
        #expect(HTTPMethod(rawValue: "GET") == .get)
        #expect(HTTPMethod(rawValue: "POST") == .post)
        #expect(HTTPMethod(rawValue: "PUT") == .put)
        #expect(HTTPMethod(rawValue: "DELETE") == .delete)
    }

    @Test("initialise from lowercase raw value returns nil (case-sensitive)")
    func initFromLowercaseRawValue() {
        #expect(HTTPMethod(rawValue: "get") == nil)
        #expect(HTTPMethod(rawValue: "post") == nil)
    }

    @Test("initialise from unknown raw value returns nil")
    func initFromUnknownRawValue() {
        #expect(HTTPMethod(rawValue: "PATCH") == nil)
        #expect(HTTPMethod(rawValue: "OPTIONS") == nil)
    }
}