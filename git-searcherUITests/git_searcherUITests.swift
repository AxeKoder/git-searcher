import XCTest

final class git_searcherUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyRecentSearchStateIsVisible() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["최근 검색어"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["최근 검색어가 없습니다."].exists)
    }
    
    @MainActor
    func testSearchShowsResultsAndOpensRepositoryWebView() throws {
        let app = makeApp()
        app.launch()

        let searchField = app.searchFields["GitHub 저장소 검색"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("swift")

        submitSearch(in: app)

        XCTAssertTrue(app.staticTexts["총 3개"].waitForExistence(timeout: 3))

        let repositoryTitle = app.collectionViews["searchCollectionView"].staticTexts["swift"]
        XCTAssertTrue(repositoryTitle.waitForExistence(timeout: 2))
        repositoryTitle.tap()

        XCTAssertTrue(app.navigationBars["github.com"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSeededRecentSearchesShowKeywordDateAndClearButton() throws {
        let app = makeApp(seedRecents: true)
        app.launch()

        XCTAssertTrue(app.staticTexts["최근 검색어"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["swift"].exists)
        XCTAssertTrue(app.buttons["전체 삭제"].exists)
    }

    

    private func makeApp(seedRecents: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITestsUseMockData"]

        if seedRecents {
            app.launchArguments.append("UITestsSeedRecents")
        }

        return app
    }

    private func submitSearch(in app: XCUIApplication) {
        let searchButton = app.keyboards.buttons["Search"]
        if searchButton.waitForExistence(timeout: 1) {
            searchButton.tap()
            return
        }

        let localizedSearchButton = app.keyboards.buttons["검색"]
        if localizedSearchButton.waitForExistence(timeout: 1) {
            localizedSearchButton.tap()
            return
        }

        app.typeText("\n")
    }
}
