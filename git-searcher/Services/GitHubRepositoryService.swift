import Foundation
import RxSwift

protocol GitHubRepositoryServicing {
    func search(keyword: String, page: Int) -> Single<RepositorySearchResponse>
}

enum GitHubRepositoryServiceError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case missingData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "검색 요청 URL을 만들 수 없습니다."
        case let .invalidResponse(statusCode):
            return "GitHub API 요청에 실패했습니다. 상태 코드: \(statusCode)"
        case .missingData:
            return "응답 데이터가 비어 있습니다."
        }
    }
}

final class GitHubRepositoryService: GitHubRepositoryServicing {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func search(keyword: String, page: Int) -> Single<RepositorySearchResponse> {
        guard var components = URLComponents(string: "https://api.github.com/search/repositories") else {
            return .error(GitHubRepositoryServiceError.invalidURL)
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: keyword),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = components.url else {
            return .error(GitHubRepositoryServiceError.invalidURL)
        }

        return Single.create { [session, decoder] single in
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    single(.failure(error))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse,
                   !(200..<300).contains(httpResponse.statusCode) {
                    single(.failure(GitHubRepositoryServiceError.invalidResponse(statusCode: httpResponse.statusCode)))
                    return
                }

                guard let data else {
                    single(.failure(GitHubRepositoryServiceError.missingData))
                    return
                }

                do {
                    let response = try decoder.decode(RepositorySearchResponse.self, from: data)
                    single(.success(response))
                } catch {
                    single(.failure(error))
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}

