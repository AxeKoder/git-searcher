import Foundation

enum RecentSearchListPolicy {
    static let maxCount = 10

    static func upsert(keyword: String, in items: [RecentSearch], searchedAt: Date) -> [RecentSearch] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            return sortedLimited(items)
        }

        let loweredKeyword = trimmedKeyword.lowercased()
        let filteredItems = items.filter { $0.keyword.lowercased() != loweredKeyword }
        return sortedLimited(filteredItems + [RecentSearch(keyword: trimmedKeyword, searchedAt: searchedAt)])
    }

    static func sortedLimited(_ items: [RecentSearch]) -> [RecentSearch] {
        Array(items.sorted { $0.searchedAt > $1.searchedAt }.prefix(maxCount))
    }
}

