// Characters/Data/Endpoints/CharactersEndpoint.swift
import Foundation
import DarkNetwork

enum CharactersEndpoint: Endpoint {
    case getAll(page: Int)

    var baseURL: URL {
        // Force-unwrap intentional: malformed base URL is a programmer error.
        URL(string: "https://rickandmortyapi.com/api")!
    }

    var path: String { "/character" }

    var method: HTTPMethod { .get }

    var parameters: [String: Any]? {
        switch self {
        case .getAll(let page): ["page": page]
        }
    }
}
