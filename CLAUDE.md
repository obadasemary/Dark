# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build
xcodebuild -scheme Dark -configuration Debug build

# Run all tests
xcodebuild -scheme Dark -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run unit tests only
xcodebuild -scheme DarkTests -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run UI tests only
xcodebuild -scheme DarkUITests -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run a specific test suite
xcodebuild -scheme DarkTests -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:DarkTests/NetworkClientTests

# Run a single test by name
xcodebuild -scheme DarkTests -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:DarkTests/NetworkClientTests/successfulDecode

# Clean
xcodebuild clean -scheme Dark
```

## Project Overview

Native SwiftUI app targeting iOS 26.4 / macOS 26.4 / xrOS 26.4, built with Xcode. Bundle ID: `com.SamuraiStudios.Dark`.

**Three targets:**
- `Dark` — main application
- `DarkTests` — unit tests using the Swift Testing framework (`import Testing`, `#expect`, `#require`)
- `DarkUITests` — UI automation tests using XCTest (`XCUIApplication`)

## Architecture

The UI layer ([Dark/DarkApp.swift](Dark/DarkApp.swift), [Dark/ContentView.swift](Dark/ContentView.swift)) is in an early template state. The network layer is production-ready and establishes the patterns to follow for new code.

### Network Layer ([Dark/Network/](Dark/Network/))

Built around two protocols that separate concerns and enable testing without URLProtocol subclassing:

**`HTTPTransport`** — low-level seam over URLSession. `URLSession` conforms to it automatically. Only override this in tests via `MockHTTPTransport`.

**`NetworkClient`** — the interface features/ViewModels depend on. Single generic method:

```swift
func request<T: Decodable>(endpoint: some Endpoint, response: T.Type) async throws -> T
```

**`URLSessionNetworkClient`** — production implementation. Takes `transport: any HTTPTransport` and `decoder: JSONDecoder` as injected dependencies. Validates HTTP status (2xx), checks for non-empty data, then decodes.

**`Endpoint` protocol** — each API endpoint is a struct conforming to `Endpoint`. GET requests encode `parameters` as query items; POST/PUT/DELETE serialize them as a JSON body. Default `baseURL` is `https://api.example.com` — override per-endpoint as needed.

**`NetworkError`** — `invalidURL`, `requestFailed(statusCode:)`, `noData`, `decodingFailed(Error)`, `unknown(Error)`. Has custom `Equatable` because `Error` doesn't conform to it.

### Testing Patterns

Unit tests use **Swift Testing** (`import Testing`). Use `@Test`, `@Suite`, `#expect()`, `#require()` — never `XCTAssert*`.

For network tests, inject `MockHTTPTransport` using its factory methods:

```swift
let transport = try MockHTTPTransport.success(MyModel(field: "value"))
let transport = MockHTTPTransport.failure(statusCode: 404)
let client = URLSessionNetworkClient(transport: transport)
```

UI tests in `DarkUITests/` still use XCTest/XCUITest.
