import Foundation
import Testing
@testable import Dark

private actor FetchCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }

    func count() -> Int {
        value
    }
}

private struct MockImageDataFetcher: ImageDataFetching {
    let counter: FetchCounter
    let returnedData: Data
    let delay: Duration

    func data(from url: URL) async throws -> Data {
        await counter.increment()
        try await Task.sleep(for: delay)
        return returnedData
    }
}

@Suite("ImageDataCache")
struct ImageDataCacheTests {

    @Test("Repeated reads of the same URL reuse cached bytes")
    func repeatedReadsReuseCache() async throws {
        let counter = FetchCounter()
        let cache = ImageDataCache(fetcher: MockImageDataFetcher(
            counter: counter,
            returnedData: Data("cached-image".utf8),
            delay: .zero
        ))
        let url = try #require(URL(string: "https://example.com/avatar.png"))

        let first = try await cache.data(for: url)
        let second = try await cache.data(for: url)

        #expect(first == second)
        #expect(await counter.count() == 1)
    }

    @Test("Concurrent reads of the same URL share one in-flight request")
    func concurrentReadsShareInFlightRequest() async throws {
        let counter = FetchCounter()
        let cache = ImageDataCache(fetcher: MockImageDataFetcher(
            counter: counter,
            returnedData: Data("shared-request".utf8),
            delay: .milliseconds(50)
        ))
        let url = try #require(URL(string: "https://example.com/another-avatar.png"))

        async let first = cache.data(for: url)
        async let second = cache.data(for: url)
        let (firstData, secondData) = try await (first, second)

        #expect(firstData == secondData)
        #expect(await counter.count() == 1)
    }
}
