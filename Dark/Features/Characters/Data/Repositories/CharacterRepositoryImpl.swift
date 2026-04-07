// Characters/Data/Repositories/CharacterRepositoryImpl.swift
import DarkNetwork

/// Production implementation. Depends on `NetworkClient` from DarkNetwork.
/// Struct + `Sendable` deps → automatically `Sendable`, safe across actors.
struct CharacterRepositoryImpl: CharacterRepository {
    private let client: any NetworkClient

    init(client: any NetworkClient = URLSessionNetworkClient()) {
        self.client = client
    }

    func getCharacters(page: Int) async throws -> CharacterPage {
        let dto = try await client.request(
            endpoint: CharactersEndpoint.getAll(page: page),
            response: CharacterPageDTO.self
        )
        return dto.toDomain(page: page)
    }
}
