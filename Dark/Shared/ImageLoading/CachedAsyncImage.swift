import Observation
import SwiftUI

#if canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#endif

@MainActor
@Observable
final class CachedImageLoader {
    enum Phase {
        case idle
        case loading
        case success(Image)
        case failure
    }

    private(set) var phase: Phase = .idle

    private let cache: ImageDataCache

    init(cache: ImageDataCache = .shared) {
        self.cache = cache
    }

    func load(from url: URL?) async {
        guard let url else {
            phase = .failure
            return
        }

        phase = .loading

        do {
            let data = try await cache.data(for: url)

            let platformImage = await Task.detached(priority: .userInitiated) {
                PlatformImage(data: data)
            }.value

            guard !Task.isCancelled else { return }
            guard let platformImage else {
                phase = .failure
                return
            }

            phase = .success(Image(platformImage: platformImage))
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failure
        }
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let failure: () -> Failure

    @State private var loader = CachedImageLoader()

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }

    var body: some View {
        Group {
            switch loader.phase {
            case .success(let image):
                content(image)
            case .failure:
                failure()
            case .idle, .loading:
                placeholder()
            }
        }
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}

private extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
