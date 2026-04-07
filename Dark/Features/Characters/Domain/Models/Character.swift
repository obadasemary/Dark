// Characters/Domain/Models/Character.swift
import Foundation

// MARK: - Character status

enum CharacterStatus: String, Sendable, CaseIterable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .alive: "Alive"
        case .dead: "Dead"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - Domain models

struct Character: Identifiable, Sendable {
    let id: Int
    let name: String
    let status: CharacterStatus
    let species: String
    let gender: String
    let origin: String
    let location: String
    let imageURL: URL?
}

struct CharacterPage: Sendable {
    let characters: [Character]
    let currentPage: Int
    let totalPages: Int
    let hasNextPage: Bool
}
