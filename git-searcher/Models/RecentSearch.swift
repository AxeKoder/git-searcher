import Foundation

nonisolated struct RecentSearch: Codable, Hashable {
    let keyword: String
    let searchedAt: Date
}

