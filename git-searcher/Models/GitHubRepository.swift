import Foundation

nonisolated struct RepositorySearchResponse: Decodable {
    let totalCount: Int
    let items: [GitHubRepository]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

nonisolated struct GitHubRepository: Decodable, Hashable {
    let id: Int
    let name: String
    let htmlURL: URL
    let owner: RepositoryOwner
    let descriptionText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case htmlURL = "html_url"
        case owner
        case descriptionText = "description"
    }
}

nonisolated struct RepositoryOwner: Decodable, Hashable {
    let login: String
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}

