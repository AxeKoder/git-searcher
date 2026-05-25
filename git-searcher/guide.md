요구사항 1. 검색 화면
1. 검색어 입력 후, 검색 결과를 보여줍니다.
2. 검색어가 비어있을 시, 최근 검색어를 최대 10개까지 보여줍니다.
3. 최근 검색어는 날짜 기준으로 내림차순 정렬합니다.
4. 최근 검색어 ‘삭제’ 또는 ‘전체 삭제’가 가능합니다.
5. 최근 검색 내역은 앱 재시작 시에도 유지됩니다.
6. 최근 검색어 선택 시, 검색 결과를 보여줍니다.

[추가 구현]
1. 검색어 입력 시, 자동완성을 보여줍니다.
2. 자동완성 노출 시, 검색 날짜를 같이 보여줍니다.
3. 자동완성은 최근 검색어에서 추출하여 사용합니다.

요구사항 2. 검색 결과 화면
1. 검색 결과를 List 형태로 보여줍니다.
2. 총 검색 결과 수를 보여줍니다.
3. 저장소 정보를 보여줍니다.
- Thumbnail : owner.avatar_url
- Title : name
- Description : owner.login
4. 검색 결과 선택 시, WebView 를 통해 해당 저장소로 이동합니다.

[추가 구현]
1. Scroll 중간에 Next Page 를 미리 호출합니다.
2. Next Page 를 로딩할 때, 로딩 상태를 보여줍니다.

[Endpoint]
[GET] https://api.github.com/search/repositories?q={keyword}&page={page}
(Ex. https://api.github.com/search/repositories?q=swift&page=1)



[화면 구조]
- Title: search label
- Search Bar
- Search filtered list(vertical)


[Test code]
- unit test
  1. RecentSearchListPolicy가 최근 검색어 목록을 최대 10개로 유지하고 날짜 내림차순으로 정렬하는지 검증합니다.
  2. SearchViewState가 입력 검색어를 기준으로 최근 검색어 기반 자동완성 후보를 필터링하는지 검증합니다.
  3. RepositorySearchResponse가 GitHub 검색 API 응답의 총 개수, 저장소명, 소유자, URL 정보를 올바르게 디코딩하는지 검증합니다.
  4. HTTP 실패 상태 코드가 GitHubRepositoryServiceError.invalidResponse로 감지되는지 검증합니다.

- ui test
  1. 최근 검색어가 없을 때 검색 화면의 빈 상태가 노출되는지 검증합니다.
  2. Mock 최근 검색어가 있을 때 최근 검색어와 전체 삭제 버튼이 노출되는지 검증합니다.
  3. 검색어 입력 후 Search 키로 검색을 수행하고, Mock API 응답 결과 리스트와 총 검색 결과 수가 노출되며 결과 선택 시 WebView로 이동하는지 검증합니다.
