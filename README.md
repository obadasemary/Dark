# Dark

A native SwiftUI app targeting iOS 26.4, macOS 26.4, and xrOS 26.4.

**Bundle ID:** `com.SamuraiStudios.Dark`

## Requirements

- Xcode 26+
- iOS 26.4 / macOS 26.4 / xrOS 26.4 SDK

## Build & Test

```bash
# Build
xcodebuild -scheme Dark -configuration Debug build

# Run all tests
xcodebuild -scheme Dark -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run unit tests only
xcodebuild -scheme DarkTests -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run UI tests only
xcodebuild -scheme DarkUITests -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a specific test suite
xcodebuild -scheme DarkTests -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:DarkTests/NetworkClientTests

# Run a single test
xcodebuild -scheme DarkTests -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:DarkTests/NetworkClientTests/successfulDecode

# Clean
xcodebuild clean -scheme Dark
```

## Project Structure

```
Dark/
├── Dark/
│   ├── DarkApp.swift          # App entry point
│   ├── ContentView.swift      # Root view
│   └── Network/               # Network layer
│       ├── Endpoint.swift     # Endpoint protocol + URLRequest builder
│       ├── NetworkClient.swift # HTTPTransport + NetworkClient protocols + URLSessionNetworkClient
│       ├── NetworkError.swift  # Error types
│       ├── HTTPMethod.swift    # HTTP method enum
│       └── ContentType.swift   # Content type enum
├── DarkTests/
│   └── NetworkTests/          # Unit tests (Swift Testing)
└── DarkUITests/               # UI tests (XCTest)
```

## Architecture

### Network Layer

The network layer is built around two protocols that separate concerns and enable testing without `URLProtocol` subclassing.

**`HTTPTransport`** — low-level seam over `URLSession`. `URLSession` conforms automatically. Swap in `MockHTTPTransport` in tests.

**`NetworkClient`** — the interface that features and ViewModels depend on:

```swift
func request<T: Decodable>(endpoint: some Endpoint, response: T.Type) async throws -> T
```

**`URLSessionNetworkClient`** — production implementation with injected `transport` and `decoder`:

```swift
let client: any NetworkClient = URLSessionNetworkClient()
let user = try await client.request(endpoint: UsersEndpoint.fetchUser(id: 1), response: User.self)
```

**`Endpoint` protocol** — define each API endpoint as a struct:

```swift
struct FetchUserEndpoint: Endpoint {
    let path = "/users/1"
    let method: HTTPMethod = .get
    let parameters: [String: Any]? = nil
}
```

GET requests encode `parameters` as URL query items. POST/PUT/DELETE serialize them as a JSON body. The default `baseURL` is `https://api.example.com` — override per endpoint as needed.

**`NetworkError`** — `invalidURL`, `requestFailed(statusCode:)`, `noData`, `decodingFailed(Error)`, `unknown(Error)`.

### Testing

Unit tests use Swift Testing (`import Testing`). Use `@Test`, `@Suite`, `#expect()`, `#require()` — never `XCTAssert*`.

Inject `MockHTTPTransport` via factory methods:

```swift
let transport = try MockHTTPTransport.success(MyModel(field: "value"))
let transport = MockHTTPTransport.failure(statusCode: 404)
let client = URLSessionNetworkClient(transport: transport)
```

UI tests in `DarkUITests/` use XCTest/XCUITest.
