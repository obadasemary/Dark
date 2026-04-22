//
//  DarkTests.swift
//  DarkTests
//
//  Created by Abdelrahman Mohamed on 02.04.2026.
//

import Foundation
import Testing
@testable import Dark

struct DarkTests {
    @MainActor
    @Test("load stores characters after a successful response")
    func loadSuccess() async {
        let expectedCharacters = [
            RickAndMortyCharacter(
                id: 1,
                name: "Rick Sanchez",
                status: "Alive",
                species: "Human",
                image: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")!
            )
        ]
        let viewModel = CharacterFeedViewModel(
            service: StubCharacterFeedService(characters: expectedCharacters)
        )

        await viewModel.load()

        #expect(viewModel.characters == expectedCharacters)
        #expect(viewModel.state == .loaded)
    }

    @MainActor
    @Test("load exposes a user-facing failure state when the service throws")
    func loadFailure() async {
        let viewModel = CharacterFeedViewModel(
            service: StubCharacterFeedService(error: StubCharacterFeedService.Failure.offline)
        )

        await viewModel.load()

        #expect(viewModel.characters.isEmpty)

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected the view model to enter a failed state.")
            return
        }

        #expect(message == "Something went wrong while loading the feed.")
    }
}

private struct StubCharacterFeedService: CharacterFeedServing {
    enum Failure: Error, Sendable {
        case offline
    }

    var characters: [RickAndMortyCharacter] = []
    var error: Failure?

    func fetchCharacters(page: Int) async throws -> [RickAndMortyCharacter] {
        if let error {
            throw error
        }

        return characters
    }
}
