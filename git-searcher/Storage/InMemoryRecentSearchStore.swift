import Foundation
import RxSwift

final class InMemoryRecentSearchStore: RecentSearchStoring {
    private let subject: BehaviorSubject<[RecentSearch]>

    var recents: Observable<[RecentSearch]> {
        subject.asObservable()
    }

    init(items: [RecentSearch] = []) {
        subject = BehaviorSubject(value: RecentSearchListPolicy.sortedLimited(items))
    }

    func currentRecents() -> [RecentSearch] {
        (try? subject.value()) ?? []
    }

    func upsert(keyword: String) {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else { return }

        subject.onNext(RecentSearchListPolicy.upsert(keyword: trimmedKeyword, in: currentRecents(), searchedAt: Date()))
    }

    func delete(_ recent: RecentSearch) {
        subject.onNext(currentRecents().filter { $0.keyword != recent.keyword })
    }

    func deleteAll() {
        subject.onNext([])
    }

}

