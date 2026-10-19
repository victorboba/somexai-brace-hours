import XCTest

/// Captures App Store screenshots. Run with scripts/screenshots.sh BraceHours.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testAppScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["-unlock", "-resetData", "-sampleData", "-skipOnboarding", "-uiTesting"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Brace off"].waitForExistence(timeout: 10) || app.buttons["Brace on"].waitForExistence(timeout: 5))
        snap("01-today", app)

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        snap("02-history", app)

        app.tabBars.buttons["Report"].tap()
        XCTAssertTrue(app.navigationBars["Report"].waitForExistence(timeout: 5))
        snap("03-report", app)

        app.tabBars.buttons["Today"].tap()
        app.buttons["More"].tap()
        app.buttons["Skin check"].tap()
        XCTAssertTrue(app.navigationBars["Skin Check"].waitForExistence(timeout: 5))
        snap("04-skin-check", app)
        app.buttons["Cancel"].tap()

        app.buttons["Add missed time"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Add Missed Time"].waitForExistence(timeout: 5))
        snap("05-missed-time", app)
        app.buttons["Cancel"].tap()

        app.buttons["How do I use this app"].tap()
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
        snap("06-how-to", app)
    }

    func testPaywall() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-uiTesting", "-mockPrices"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lifetime"].waitForExistence(timeout: 10))
        snap("paywall", app)
    }

    private func snap(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
