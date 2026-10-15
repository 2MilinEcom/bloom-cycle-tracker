import XCTest

final class BloomUITests: XCTestCase {
    @MainActor func testOnboardingLoggingAndRelaunch() throws {
        let app = XCUIApplication(); app.launch()
        // This test expects a clean installation. It does not bypass production authentication.
        let begin = app.buttons["onboarding.begin"]
        XCTAssertTrue(begin.waitForExistence(timeout: 30))
        app.swipeUp()
        let lock = app.switches["onboarding.lock"]
        if lock.value as? String == "1" { lock.tap() }
        app.switches["I understand these are estimates"].tap()
        begin.tap()
        let checkIn = app.buttons["today.log"]
        XCTAssertTrue(checkIn.waitForExistence(timeout: 5)); checkIn.tap()
        app.buttons["log.save"].tap()
        XCTAssertTrue(app.staticTexts["Today, in your words"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["Today, in your words"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Calendar"].tap()
        XCTAssertTrue(app.staticTexts["A wider view."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Patterns"].tap()
        XCTAssertTrue(app.staticTexts["Know your rhythm."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Journal"].tap()
        XCTAssertTrue(app.buttons["Write today"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Privacy"].tap()
        XCTAssertTrue(app.staticTexts["Your body. Your data."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Today"].tap()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Bloom Today"; screenshot.lifetime = .keepAlways; add(screenshot)
    }
}
