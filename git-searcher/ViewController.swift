import UIKit
import RxCocoa
import RxSwift

nonisolated private enum SearchSection: Int, CaseIterable {
    case recents
    case repositories
    case loading
}

nonisolated private enum SearchItem: Hashable {
    case recent(RecentSearch)
    case repository(GitHubRepository)
    case loading
}

final class ViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<SearchSection, SearchItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>

    private lazy var viewModel = Self.makeViewModel()
    private let disposeBag = DisposeBag()
    private let selectedRecentSubject = PublishSubject<String>()
    private let deleteRecentSubject = PublishSubject<RecentSearch>()
    private let selectedRepositorySubject = PublishSubject<GitHubRepository>()

    private let titleLabel = UILabel()
    private let searchBar = UISearchBar()
    private let sectionTitleLabel = UILabel()
    private let clearAllButton = UIButton(type: .system)
    private let emptyLabel = UILabel()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
    private var dataSource: DataSource?
    private var lastPresentedErrorMessage: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureDataSource()
        bindViewModel()
    }

    private func configureViews() {
        view.backgroundColor = .systemGroupedBackground

        titleLabel.text = "Search"
        titleLabel.accessibilityIdentifier = "searchTitleLabel"
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        searchBar.placeholder = "GitHub 저장소 검색"
        searchBar.accessibilityIdentifier = "repositorySearchBar"
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.returnKeyType = .search
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        sectionTitleLabel.font = .preferredFont(forTextStyle: .headline)
        sectionTitleLabel.accessibilityIdentifier = "sectionTitleLabel"
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        clearAllButton.setTitle("전체 삭제", for: .normal)
        clearAllButton.accessibilityIdentifier = "clearAllButton"
        clearAllButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        clearAllButton.translatesAutoresizingMaskIntoConstraints = false

        let summaryStackView = UIStackView(arrangedSubviews: [sectionTitleLabel, clearAllButton])
        summaryStackView.axis = .horizontal
        summaryStackView.alignment = .center
        summaryStackView.distribution = .equalSpacing
        summaryStackView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = "searchCollectionView"
        collectionView.keyboardDismissMode = .onDrag
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.accessibilityIdentifier = "emptyLabel"
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0

        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(summaryStackView)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            summaryStackView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            summaryStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            summaryStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            collectionView.topAnchor.constraint(equalTo: summaryStackView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        let recentRegistration = UICollectionView.CellRegistration<RecentSearchCollectionViewCell, RecentSearch> { [weak self] cell, _, recent in
            cell.configure(with: recent)
            cell.onDelete = { [weak self] in
                self?.deleteRecentSubject.onNext(recent)
            }
        }

        let repositoryRegistration = UICollectionView.CellRegistration<RepositoryCollectionViewCell, GitHubRepository> { cell, _, repository in
            cell.configure(with: repository)
        }

        let loadingRegistration = UICollectionView.CellRegistration<LoadingCollectionViewCell, Void> { cell, _, _ in
            cell.startAnimating()
        }

        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case let .recent(recent):
                return collectionView.dequeueConfiguredReusableCell(
                    using: recentRegistration,
                    for: indexPath,
                    item: recent
                )
            case let .repository(repository):
                return collectionView.dequeueConfiguredReusableCell(
                    using: repositoryRegistration,
                    for: indexPath,
                    item: repository
                )
            case .loading:
                return collectionView.dequeueConfiguredReusableCell(
                    using: loadingRegistration,
                    for: indexPath,
                    item: ()
                )
            }
        }
    }

    private func bindViewModel() {
        let searchButtonTrigger = searchBar.rx.searchButtonClicked
            .withLatestFrom(searchBar.rx.text.orEmpty)

        let loadNextPageTrigger = collectionView.rx.contentOffset
            .compactMap { [weak self] _ -> Void? in
                guard let self else { return nil }

                let visibleHeight = collectionView.bounds.height
                let contentHeight = collectionView.contentSize.height
                guard contentHeight > visibleHeight else { return nil }

                let threshold = contentHeight - visibleHeight * 1.5
                return collectionView.contentOffset.y > threshold ? () : nil
            }
            .throttle(.milliseconds(600), scheduler: MainScheduler.instance)

        let input = SearchViewModel.Input(
            queryText: searchBar.rx.text.orEmpty.asObservable(),
            searchTrigger: Observable.merge(searchButtonTrigger, selectedRecentSubject.asObservable()),
            deleteRecent: deleteRecentSubject.asObservable(),
            deleteAllRecents: clearAllButton.rx.tap.asObservable(),
            loadNextPage: loadNextPageTrigger.asObservable(),
            selectedRepository: selectedRepositorySubject.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.state
            .drive(onNext: { [weak self] state in
                self?.render(state)
            })
            .disposed(by: disposeBag)

        output.openURL
            .emit(onNext: { [weak self] url in
                self?.presentWebView(url: url)
            })
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.handleSelection(at: indexPath)
            })
            .disposed(by: disposeBag)
    }

    private func render(_ state: SearchViewState) {
        if searchBar.text != state.query {
            searchBar.text = state.query
        }

        sectionTitleLabel.text = sectionTitle(for: state)
        clearAllButton.isHidden = state.contentMode == .results || state.recents.isEmpty
        applySnapshot(for: state)
        updateEmptyMessage(for: state)
        presentErrorIfNeeded(state.errorMessage)
    }

    private func applySnapshot(for state: SearchViewState) {
        var snapshot = Snapshot()

        switch state.contentMode {
        case .recents, .suggestions:
            let recents = state.visibleRecents
            if !recents.isEmpty {
                snapshot.appendSections([.recents])
                snapshot.appendItems(recents.map(SearchItem.recent), toSection: .recents)
            }
        case .results:
            if state.isLoadingFirstPage {
                snapshot.appendSections([.loading])
                snapshot.appendItems([.loading], toSection: .loading)
            } else {
                if !state.repositories.isEmpty {
                    snapshot.appendSections([.repositories])
                    snapshot.appendItems(state.repositories.map(SearchItem.repository), toSection: .repositories)
                }

                if state.isLoadingNextPage {
                    snapshot.appendSections([.loading])
                    snapshot.appendItems([.loading], toSection: .loading)
                }
            }
        }

        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func updateEmptyMessage(for state: SearchViewState) {
        let message: String?

        switch state.contentMode {
        case .recents:
            message = state.visibleRecents.isEmpty ? "최근 검색어가 없습니다." : nil
        case .suggestions:
            message = state.visibleRecents.isEmpty ? "최근 검색어에서 일치하는 자동완성이 없습니다." : nil
        case .results:
            message = !state.isLoadingFirstPage && state.repositories.isEmpty ? "검색 결과가 없습니다." : nil
        }

        emptyLabel.text = message
        collectionView.backgroundView = message == nil ? nil : emptyLabel
    }

    private func sectionTitle(for state: SearchViewState) -> String {
        switch state.contentMode {
        case .recents:
            return "최근 검색어"
        case .suggestions:
            return "자동완성"
        case .results:
            return state.isLoadingFirstPage ? "검색 중..." : "총 \(formattedCount(state.totalCount))개"
        }
    }

    private func handleSelection(at indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }

        switch item {
        case let .recent(recent):
            searchBar.text = recent.keyword
            searchBar.resignFirstResponder()
            selectedRecentSubject.onNext(recent.keyword)
        case let .repository(repository):
            selectedRepositorySubject.onNext(repository)
        case .loading:
            break
        }
    }

    private func presentWebView(url: URL) {
        let webViewController = WebViewController(url: url)
        let navigationController = UINavigationController(rootViewController: webViewController)
        present(navigationController, animated: true)
    }

    private func presentErrorIfNeeded(_ message: String?) {
        guard let message, lastPresentedErrorMessage != message else {
            if message == nil {
                lastPresentedErrorMessage = nil
            }
            return
        }

        lastPresentedErrorMessage = message
        let alertController = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default))
        present(alertController, animated: true)
    }

    private func formattedCount(_ count: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
    }

    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(84)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(84)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 16, trailing: 20)
            return section
        }
    }

    private static func makeViewModel() -> SearchViewModel {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("UITestsUseMockData") else {
            return SearchViewModel()
        }

        let store: RecentSearchStoring
        if arguments.contains("UITestsSeedRecents") {
            store = InMemoryRecentSearchStore(items: [
                RecentSearch(keyword: "swift", searchedAt: makeDate(year: 2026, month: 5, day: 24, hour: 14, minute: 30)),
                RecentSearch(keyword: "rxswift", searchedAt: makeDate(year: 2026, month: 5, day: 23, hour: 9, minute: 0))
            ])
        } else {
            store = InMemoryRecentSearchStore()
        }

        return SearchViewModel(
            service: GitHubRepositoryStubService.uiTestService(),
            store: store
        )
    }

    private static func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: Calendar.current,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date ?? Date()
    }
}

