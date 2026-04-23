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
            Character(
                id: 1,
                name: "Rick Sanchez",
                status: .alive,
                species: "Human",
                gender: "Male",
                origin: "Earth (C-137)",
                location: "Citadel of Ricks",
                imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")
            )
        ]
        let viewModel = CharactersViewModel(
            useCase: GetCharactersUseCase(
                repository: StubCharacterRepository(page: CharacterPage(
                    characters: expectedCharacters,
                    currentPage: 1,
                    totalPages: 1,
                    hasNextPage: false
                ))
            )
        )

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.characters == expectedCharacters)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @MainActor
    @Test("load exposes a user-facing failure state when the service throws")
    func loadFailure() async {
        let viewModel = CharactersViewModel(
            useCase: GetCharactersUseCase(
                repository: StubCharacterRepository(error: StubCharacterRepository.Failure.offline)
            )
        )

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.characters.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
}

private struct StubCharacterRepository: CharacterRepository {
    enum Failure: Error, Sendable {
        case offline
    }

    var page: CharacterPage?
    var error: Failure?

    func getCharacters(page: Int) async throws -> CharacterPage {
        if let error {
            throw error
        }
        return self.page!
    }
}
