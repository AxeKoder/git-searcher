import Foundation
import RxSwift

final class GitHubRepositoryStubService: GitHubRepositoryServicing {
    private let responses: [Int: RepositorySearchResponse]

    init(responses: [Int: RepositorySearchResponse]) {
        self.responses = responses
    }

    func search(keyword: String, page: Int) -> Single<RepositorySearchResponse> {
        .just(responses[page] ?? RepositorySearchResponse(totalCount: 0, items: []))
    }
}

extension GitHubRepositoryStubService {
    static func uiTestService() -> GitHubRepositoryStubService {
        GitHubRepositoryStubService(
            responses: [
                1: RepositorySearchResponse(
                    totalCount: 3,
                    items: [
                        GitHubRepository(
                            id: 1,
                            name: "swift",
                            htmlURL: URL(string: "https://github.com/apple/swift")!,
                            owner: RepositoryOwner(login: "apple", avatarURL: nil),
                            descriptionText: "The Swift Programming Language"
                        ),
                        GitHubRepository(
                            id: 2,
                            name: "swift-algorithms",
                            htmlURL: URL(string: "https://github.com/apple/swift-algorithms")!,
                            owner: RepositoryOwner(login: "apple", avatarURL: nil),
                            descriptionText: "Commonly used sequence and collection algorithms"
                        )
                    ]
                ),
                2: RepositorySearchResponse(
                    totalCount: 3,
                    items: [
                        GitHubRepository(
                            id: 3,
                            name: "RxSwift",
                            htmlURL: URL(string: "https://github.com/ReactiveX/RxSwift")!,
                            owner: RepositoryOwner(login: "ReactiveX", avatarURL: nil),
                            descriptionText: "Reactive Programming in Swift"
                        )
                    ]
                )
            ]
        )
    }
}

