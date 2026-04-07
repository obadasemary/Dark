// Characters/Domain/Repositories/CharacterRepository.swift

/// Contract between domain and data layers.
/// Sendable required because implementations are called from async contexts.
protocol CharacterRepository: Sendable {
    func getCharacters(page: Int) async throws -> CharacterPage
}
