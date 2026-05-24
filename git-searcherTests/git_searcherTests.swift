import XCTest
@testable import git_searcher

final class git_searcherTests: XCTestCase {
    func testRecentSearchListPolicyKeepsTenItemsSortedByRecentDate() {
        let recents = (0..<12).reduce(into: [RecentSearch]()) { items, index in
            items = RecentSearchListPolicy.upsert(
                keyword: "keyword-\(index)",
                in: items,
                searchedAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        XCTAssertEqual(recents.count, 10)
        XCTAssertEqual(recents.first?.keyword, "keyword-11")
        XCTAssertEqual(recents.last?.keyword, "keyword-2")
        XCTAssertEqual(recents, recents.sorted { $0.searchedAt > $1.searchedAt })
    }

    func testSearchViewStateFiltersSuggestionsFromRecentSearches() {
        var state = SearchViewState()
        state.query = "swi"
        state.contentMode = .suggestions
        state.recents = [
            RecentSearch(keyword: "swift", searchedAt: Date(timeIntervalSince1970: 3)),
            RecentSearch(keyword: "rxswift", searchedAt: Date(timeIntervalSince1970: 2)),
            RecentSearch(keyword: "kotlin", searchedAt: Date(timeIntervalSince1970: 1))
        ]

        XCTAssertEqual(state.visibleRecents.map(\.keyword), ["swift", "rxswift"])
    }

    func testRepositorySearchResponseDecodesGitHubSearchPayload() throws {
        let json = """
        {
          "total_count": 1,
          "items": [
            {
              "id": 1,
              "name": "swift",
              "html_url": "https://github.com/apple/swift",
              "description": "The Swift Programming Language",
              "owner": {
                "login": "apple",
                "avatar_url": "https://avatars.githubusercontent.com/u/10639145?v=4"
              }
            }
          ]
        }
        """

        let response = try JSONDecoder().decode(RepositorySearchResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.totalCount, 1)
        XCTAssertEqual(response.items.first?.name, "swift")
        XCTAssertEqual(response.items.first?.owner.login, "apple")
        XCTAssertEqual(response.items.first?.htmlURL.absoluteString, "https://github.com/apple/swift")
        XCTAssertEqual(response.items.first?.owner.avatarURL?.host(), "avatars.githubusercontent.com")
    }
}
