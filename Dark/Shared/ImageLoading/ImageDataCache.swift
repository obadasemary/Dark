import Foundation

protocol ImageDataFetching: Sendable {
    func data(from url: URL) async throws -> Data
}

struct URLSessionImageDataFetcher: ImageDataFetching {
    func data(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard !data.isEmpty else {
            throw URLError(.zeroByteResource)
        }

        return data
    }
}

actor ImageDataCache {
    static let shared = ImageDataCache()

    private let fetcher: any ImageDataFetching
    private let storage = NSCache<NSURL, NSData>()
    private var inFlightRequests: [URL: Task<Data, Error>] = [:]

    init(fetcher: any ImageDataFetching = URLSessionImageDataFetcher()) {
        self.fetcher = fetcher
        storage.countLimit = 300
        storage.totalCostLimit = 50 * 1024 * 1024
    }

    func data(for url: URL) async throws -> Data {
        if let cachedData = storage.object(forKey: url as NSURL) {
            return Data(referencing: cachedData)
        }

        if let existingTask = inFlightRequests[url] {
            return try await existingTask.value
        }

        let task = Task {
            try await fetcher.data(from: url)
        }

        inFlightRequests[url] = task
        defer { inFlightRequests[url] = nil }

        let data = try await task.value
        storage.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        return data
    }

    func removeAll() {
        storage.removeAllObjects()
        inFlightRequests.values.forEach { $0.cancel() }
        inFlightRequests.removeAll()
    }
}
