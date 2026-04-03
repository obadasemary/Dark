// DarkNetwork/ContentType.swift

public enum ContentType: String, Sendable {
    case json           = "application/json"
    case formURLEncoded = "application/x-www-form-urlencoded"
    case multipart      = "multipart/form-data"
}
