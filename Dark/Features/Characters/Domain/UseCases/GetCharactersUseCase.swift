// Characters/Domain/UseCases/GetCharactersUseCase.swift

/// Encapsulates the business rule for fetching a page of characters.
/// A struct + Sendable ensures safe transfer across actor boundaries.
struct GetCharactersUseCase: Sendable {
    private let repository: any CharacterRepository

    init(repository: any CharacterRepository) {
        self.repository = repository
    }

    func execute(page: Int) async throws -> CharacterPage {
        try await repository.getCharacters(page: page)
    }
}
