// Characters/Data/DTOs/CharacterPageDTO.swift
import Foundation

// MARK: - Page envelope

struct CharacterPageDTO: Decodable, Sendable {
    let info: PageInfoDTO
    let results: [CharacterDTO]
}

struct PageInfoDTO: Decodable, Sendable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}

// MARK: - Character

struct CharacterDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let type: String
    let gender: String
    let origin: LocationDTO
    let location: LocationDTO
    let image: String
    let episode: [String]
    let url: String
    let created: String
}

struct LocationDTO: Decodable, Sendable {
    let name: String
    let url: String
}

// MARK: - Domain mapping

extension CharacterPageDTO {
    func toDomain(page: Int) -> CharacterPage {
        CharacterPage(
            characters: results.map { $0.toDomain() },
            currentPage: page,
            totalPages: info.pages,
            hasNextPage: info.next != nil
        )
    }
}

extension CharacterDTO {
    func toDomain() -> Character {
        Character(
            id: id,
            name: name,
            status: CharacterStatus(rawValue: status) ?? .unknown,
            species: species,
            gender: gender,
            origin: origin.name,
            location: location.name,
            imageURL: URL(string: image)
        )
    }
}
