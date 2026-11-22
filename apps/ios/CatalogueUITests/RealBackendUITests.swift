import XCTest

/// End-to-end against the real backend (no stub): home → product → enquiry → thank you.
/// Opt-in, because it needs the API running on this Mac (`npm run dev` or `docker compose up`):
///
///     TEST_RUNNER_CATALOGUE_E2E=1 ./scripts/test-ios.sh -only-testing:CatalogueUITests/RealBackendUITests
///
/// Afterwards the enquiry email is in Mailpit (http://localhost:8025) or the API's console log.
@MainActor
final class RealBackendUITests: XCTestCase {
    func testEnquiryReachesTheRealBackend() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["CATALOGUE_E2E"] == "1",
            "Set TEST_RUNNER_CATALOGUE_E2E=1 with the API running to enable"
        )
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let tiles = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'product-tile-'"))
        XCTAssertTrue(tiles.firstMatch.waitForExistence(timeout: 15), "No products: is the API running on localhost:3000?")
        XCTAssertEqual(tiles.count, 5, "Home should show the 5 top-rated products")

        tiles.firstMatch.tap()
        XCTAssertTrue(app.buttons["enquire-button"].waitForExistence(timeout: 10))
        app.buttons["enquire-button"].tap()

        let name = app.textFields["enquiry-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("iOS E2E Test")
        let email = app.textFields["enquiry-email"]
        email.tap()
        email.typeText("ios.e2e@example.com")
        app.buttons["enquiry-send"].tap()

        XCTAssertTrue(app.staticTexts["thank-you-title"].waitForExistence(timeout: 15))
        let reference = app.staticTexts["thank-you-reference"].label
        XCTAssertTrue(reference.hasPrefix("Reference: "), reference)
        print("E2E enquiry reference: \(reference)")
    }
}
