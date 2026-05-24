import Foundation
import RxCocoa
import RxSwift

enum SearchContentMode {
    case recents
    case suggestions
    case results
}

struct SearchViewState {
    var query = ""
    var recents: [RecentSearch] = []
    var repositories: [GitHubRepository] = []
    var totalCount = 0
    var contentMode: SearchContentMode = .recents
    var isLoadingFirstPage = false
    var isLoadingNextPage = false
    var errorMessage: String?

    var visibleRecents: [RecentSearch] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return recents }

        return recents.filter {
            $0.keyword.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}

final class SearchViewModel {
    struct Input {
        let queryText: Observable<String>
        let searchTrigger: Observable<String>
        let deleteRecent: Observable<RecentSearch>
        let deleteAllRecents: Observable<Void>
        let loadNextPage: Observable<Void>
        let selectedRepository: Observable<GitHubRepository>
    }

    struct Output {
        let state: Driver<SearchViewState>
        let openURL: Signal<URL>
    }

    private let service: GitHubRepositoryServicing
    private let store: RecentSearchStoring
    private let disposeBag = DisposeBag()
    private let stateSubject: BehaviorSubject<SearchViewState>
    private let openURLSubject = PublishSubject<URL>()

    private var state: SearchViewState
    private var currentPage = 0
    private var canLoadNextPage = false
    private var isRequesting = false

    init(
        service: GitHubRepositoryServicing = GitHubRepositoryService(),
        store: RecentSearchStoring = RecentSearchStore()
    ) {
        self.service = service
        self.store = store

        var initialState = SearchViewState()
        initialState.recents = store.currentRecents()
        self.state = initialState
        self.stateSubject = BehaviorSubject(value: initialState)
    }

    func transform(input: Input) -> Output {
        bindRecents()

        input.queryText
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] query in
                self?.handleQueryChange(query)
            })
            .disposed(by: disposeBag)

        input.searchTrigger
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] keyword in
                self?.search(keyword: keyword)
            })
            .disposed(by: disposeBag)

        input.deleteRecent
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] recent in
                self?.store.delete(recent)
            })
            .disposed(by: disposeBag)

        input.deleteAllRecents
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.store.deleteAll()
            })
            .disposed(by: disposeBag)

        input.loadNextPage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.loadNextPage()
            })
            .disposed(by: disposeBag)

        input.selectedRepository
            .map(\.htmlURL)
            .bind(to: openURLSubject)
            .disposed(by: disposeBag)

        return Output(
            state: stateSubject.asDriver(onErrorJustReturn: SearchViewState()),
            openURL: openURLSubject.asSignal(onErrorSignalWith: .empty())
        )
    }

    private func bindRecents() {
        store.recents
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] recents in
                guard let self else { return }

                state.recents = recents
                if state.contentMode != .results {
                    state.contentMode = state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .recents : .suggestions
                }
                emit()
            })
            .disposed(by: disposeBag)
    }

    private func handleQueryChange(_ query: String) {
        state.query = query
        state.repositories = []
        state.totalCount = 0
        state.isLoadingFirstPage = false
        state.isLoadingNextPage = false
        state.errorMessage = nil
        state.contentMode = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .recents : .suggestions

        currentPage = 0
        canLoadNextPage = false
        isRequesting = false
        emit()
    }

    private func search(keyword: String) {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty, !isRequesting else { return }

        store.upsert(keyword: trimmedKeyword)

        state.query = trimmedKeyword
        state.repositories = []
        state.totalCount = 0
        state.contentMode = .results
        state.isLoadingFirstPage = true
        state.isLoadingNextPage = false
        state.errorMessage = nil
        currentPage = 1
        canLoadNextPage = false
        isRequesting = true
        emit()

        service.search(keyword: trimmedKeyword, page: 1)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] response in
                    self?.handleFirstPage(response)
                },
                onFailure: { [weak self] error in
                    self?.handleSearchError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func loadNextPage() {
        let keyword = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard state.contentMode == .results,
              !keyword.isEmpty,
              canLoadNextPage,
              !isRequesting else {
            return
        }

        let nextPage = currentPage + 1
        state.isLoadingNextPage = true
        state.errorMessage = nil
        isRequesting = true
        emit()

        service.search(keyword: keyword, page: nextPage)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] response in
                    self?.handleNextPage(response, page: nextPage)
                },
                onFailure: { [weak self] error in
                    self?.handleSearchError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func handleFirstPage(_ response: RepositorySearchResponse) {
        state.repositories = response.items
        state.totalCount = response.totalCount
        state.isLoadingFirstPage = false
        state.isLoadingNextPage = false
        state.errorMessage = nil
        currentPage = 1
        canLoadNextPage = state.repositories.count < response.totalCount
        isRequesting = false
        emit()
    }

    private func handleNextPage(_ response: RepositorySearchResponse, page: Int) {
        state.repositories = appendUniqueRepositories(response.items, to: state.repositories)
        state.totalCount = response.totalCount
        state.isLoadingFirstPage = false
        state.isLoadingNextPage = false
        state.errorMessage = nil
        currentPage = page
        canLoadNextPage = state.repositories.count < response.totalCount && !response.items.isEmpty
        isRequesting = false
        emit()
    }

    private func handleSearchError(_ error: Error) {
        state.isLoadingFirstPage = false
        state.isLoadingNextPage = false
        state.errorMessage = error.localizedDescription
        canLoadNextPage = false
        isRequesting = false
        emit()
    }

    private func appendUniqueRepositories(_ newRepositories: [GitHubRepository], to repositories: [GitHubRepository]) -> [GitHubRepository] {
        let existingIDs = Set(repositories.map(\.id))
        return repositories + newRepositories.filter { !existingIDs.contains($0.id) }
    }

    private func emit() {
        stateSubject.onNext(state)
    }
}

