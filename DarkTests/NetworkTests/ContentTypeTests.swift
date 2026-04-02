// DarkTests/NetworkTests/ContentTypeTests.swift
import Testing
@testable import Dark

@Suite("ContentType")
struct ContentTypeTests {

    @Test("json has correct raw value")
    func jsonRawValue() {
        #expect(ContentType.json.rawValue == "application/json")
    }

    @Test("formURLEncoded has correct raw value")
    func formURLEncodedRawValue() {
        #expect(ContentType.formURLEncoded.rawValue == "application/x-www-form-urlencoded")
    }

    @Test("multipart has correct raw value")
    func multipartRawValue() {
        #expect(ContentType.multipart.rawValue == "multipart/form-data")
    }

    @Test("raw values are distinct")
    func distinctRawValues() {
        let values = [ContentType.json.rawValue, ContentType.formURLEncoded.rawValue, ContentType.multipart.rawValue]
        let unique = Set(values)
        #expect(unique.count == values.count)
    }

    @Test("initialise from raw value succeeds for all known values")
    func initFromRawValue() {
        #expect(ContentType(rawValue: "application/json") == .json)
        #expect(ContentType(rawValue: "application/x-www-form-urlencoded") == .formURLEncoded)
        #expect(ContentType(rawValue: "multipart/form-data") == .multipart)
    }

    @Test("initialise from unknown raw value returns nil")
    func initFromUnknownRawValue() {
        #expect(ContentType(rawValue: "text/plain") == nil)
    }
}