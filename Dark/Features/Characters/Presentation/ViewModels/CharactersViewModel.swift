// Characters/Presentation/ViewModels/CharactersViewModel.swift
import Foundation
import Observation

/// Drives the characters list UI.
///
/// @MainActor isolates all state mutations to the main actor — the correct
/// boundary for UI-owned state. The use case and repository are Sendable
/// structs, so they can be called from this actor without data-race risk.
@MainActor
@Observable
final class CharactersViewModel {
    private(set) var characters: [Character] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var currentPage = 0
    private(set) var hasNextPage = true

    private let useCase: GetCharactersUseCase

    init(useCase: GetCharactersUseCase = GetCharactersUseCase(
        repository: CharacterRepositoryImpl()
    )) {
        self.useCase = useCase
    }

    /// How many items before the end of the list to trigger the next page load.
    /// Keeps the feed feeling seamless — new content is ready before the user hits the bottom.
    private let prefetchThreshold = 5

    // MARK: - Intent

    func loadInitialPageIfNeeded() async {
        guard characters.isEmpty, !isLoading else { return }
        await fetchNextPage()
    }

    /// Called each time a row becomes visible.
    /// Starts the next fetch when the visible item is within `prefetchThreshold` of the end.
    /// Fire-and-forget so the fetch outlives the row's `.onAppear` scope and isn't
    /// cancelled when the user scrolls past the trigger row.
    func onItemAppear(_ character: Character) {
        guard hasNextPage, !isLoading else { return }
        guard let index = characters.firstIndex(where: { $0.id == character.id }) else { return }
        let triggerIndex = max(0, characters.count - prefetchThreshold)
        guard index >= triggerIndex else { return }
        Task { await fetchNextPage() }
    }

    func retry() async {
        await fetchNextPage()
    }

    // MARK: - Private

    private func fetchNextPage() async {
        guard !isLoading, hasNextPage else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let nextPage = currentPage + 1
        do {
            let page = try await useCase.execute(page: nextPage)
            characters += page.characters
            currentPage = page.currentPage
            hasNextPage = page.hasNextPage
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
