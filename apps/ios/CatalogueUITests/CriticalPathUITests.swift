import XCTest

/// Uses the offline stub API (`-UITestStubAPI`), so it needs no backend or network.
@MainActor
final class CriticalPathUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestStubAPI"]
        app.launch()
    }

    private func tile(_ id: String) -> XCUIElement {
        app.buttons["product-tile-\(id)"].firstMatch
    }

    func testHomeShowsTheFiveTopRatedProducts() {
        XCTAssertTrue(tile("1").waitForExistence(timeout: 5))
        let tiles = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'product-tile-'"))
        XCTAssertEqual(tiles.count, 5)
    }

    func testCategoryLinkShowsTopRatedThenMoreProducts() {
        app.buttons["category-link-electronics"].tap()

        XCTAssertTrue(app.navigationBars["Electronics"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Top rated"].exists)
        XCTAssertTrue(app.staticTexts["More in Electronics"].exists)
    }

    func testSearchButtonShowsOnlyMatchingProducts() {
        let field = app.textFields["search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("ssd")
        app.buttons["search-button"].tap()

        XCTAssertTrue(app.staticTexts["search-result-count"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["search-result-count"].label, "1 product found")
        XCTAssertTrue(tile("2").exists)
        XCTAssertFalse(tile("1").exists)
    }

    func testTileOpensDetailsAndEnquiryEndsWithThankYou() {
        XCTAssertTrue(tile("2").waitForExistence(timeout: 5))
        tile("2").tap()

        XCTAssertTrue(app.staticTexts["product-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["product-title"].label, "SSD drive 1TB")
        app.buttons["enquire-button"].tap()

        // Submitting empty shows validation and does not send.
        let send = app.buttons["enquiry-send"]
        XCTAssertTrue(send.waitForExistence(timeout: 5))
        send.tap()
        XCTAssertTrue(app.staticTexts["enquiry-name-error"].waitForExistence(timeout: 2))

        let name = app.textFields["enquiry-name"]
        name.tap()
        name.typeText("Ada Lovelace")
        let email = app.textFields["enquiry-email"]
        email.tap()
        email.typeText("ada@example.com")
        send.tap()

        XCTAssertTrue(app.staticTexts["thank-you-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["thank-you-reference"].label, "Reference: STUB-REF-0001")
    }
}
