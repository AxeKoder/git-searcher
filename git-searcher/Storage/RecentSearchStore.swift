import Foundation
import RxSwift

protocol RecentSearchStoring {
    var recents: Observable<[RecentSearch]> { get }

    func currentRecents() -> [RecentSearch]
    func upsert(keyword: String)
    func delete(_ recent: RecentSearch)
    func deleteAll()
}

final class RecentSearchStore: RecentSearchStoring {
    private static let storageKey = "recent_searches"
    private let userDefaults: UserDefaults
    private let now: () -> Date
    private let subject: BehaviorSubject<[RecentSearch]>

    var recents: Observable<[RecentSearch]> {
        subject.asObservable()
    }

    init(userDefaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        self.now = now
        self.subject = BehaviorSubject(value: Self.loadItems(from: userDefaults))
    }

    func currentRecents() -> [RecentSearch] {
        (try? subject.value()) ?? []
    }

    func upsert(keyword: String) {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else { return }

        save(RecentSearchListPolicy.upsert(keyword: trimmedKeyword, in: currentRecents(), searchedAt: now()))
    }

    func delete(_ recent: RecentSearch) {
        let items = currentRecents().filter { $0.keyword != recent.keyword }
        save(items)
    }

    func deleteAll() {
        save([])
    }

    private func save(_ items: [RecentSearch]) {
        let sortedItems = RecentSearchListPolicy.sortedLimited(items)

        if let data = try? JSONEncoder().encode(sortedItems) {
            userDefaults.set(data, forKey: Self.storageKey)
        }

        subject.onNext(sortedItems)
    }

    private static func loadItems(from userDefaults: UserDefaults) -> [RecentSearch] {
        guard let data = userDefaults.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([RecentSearch].self, from: data) else {
            return []
        }

        return RecentSearchListPolicy.sortedLimited(items)
    }
}

