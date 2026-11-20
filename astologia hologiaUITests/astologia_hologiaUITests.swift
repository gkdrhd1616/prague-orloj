//
//  astologia_hologiaUITests.swift
//  astologia hologiaUITests
//
//  Created by Shubeu on 5/6/26.
//

import XCTest

final class astologia_hologiaUITests: XCTestCase {
    /// The app follows the system language; these tests read English labels.
    static let englishArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]


    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchIsResponsive() throws {
        let app = XCUIApplication()
        app.launchArguments = Self.englishArguments + ["-uiTesting"]
        app.launch()

        XCTAssertTrue(app.buttons["Open controls"].waitForExistence(timeout: 8))
    }

    #if os(iOS)
    @MainActor
    func testIPadRotationKeepsDialAndControlsVisible() throws {
        let app = XCUIApplication()
        app.launchArguments = Self.englishArguments + ["-uiTestingDate", "2026-09-26T01:55:00Z"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        let dial = app.descendants(matching: .any)["orlojDial"]
        XCTAssertTrue(dial.waitForExistence(timeout: 8))

        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let layout = NSPredicate { _, _ in
                let frame = app.frame
                let isLandscape = frame.width > frame.height
                return isLandscape == (orientation == .landscapeLeft)
                    && frame.insetBy(dx: -1, dy: -1).contains(dial.frame)
                    && app.buttons["Open controls"].isHittable
            }
            expectation(for: layout, evaluatedWith: app)
            waitForExpectations(timeout: 10)
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = orientation == .portrait ? "iPad Portrait" : "iPad Landscape"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        XCUIDevice.shared.orientation = .portrait
    }

    #endif

    @MainActor
    func testMissingLocationWaitsForConfirmedCoordinates() throws {
        let app = XCUIApplication()
        app.launchArguments = Self.englishArguments + ["-uiTestingMissingLocation"]
        app.launch()
        let dial = app.descendants(matching: .any)["orlojDial"]
        let settings = app.buttons["Location settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        XCTAssertFalse(dial.exists)
        settings.tap()
        app.buttons["settingsChoice-Manual sky"].tap()
        let confirm = app.buttons["Use these coordinates"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 4))
        confirm.tap()
        XCTAssertTrue(dial.waitForExistence(timeout: 4))
    }

    @MainActor
    func testSettingsKeepsManualCoordinatesHiddenUntilManualSky() throws {
        let app = launchWithDrawer(tab: "Settings")

        XCTAssertTrue(app.staticTexts["section-Time"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["section-Location mode"].exists)
        XCTAssertTrue(app.staticTexts["section-Current basis"].exists)
        XCTAssertFalse(app.textFields["Latitude"].exists)
        XCTAssertFalse(app.textFields["Longitude"].exists)

        app.buttons["settingsChoice-Manual sky"].tap()

        XCTAssertTrue(app.textFields["Latitude"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.textFields["Longitude"].exists)
    }

    @MainActor
    func testGuideFocusCanReturnToDisplay() throws {
        let app = launchWithDrawer(tab: "Guide")

        XCTAssertTrue(app.staticTexts["section-Reading guide"].waitForExistence(timeout: 4))

        app.buttons["guideTopic-sun"].tap()

        XCTAssertTrue(app.buttons["focusResetButton"].waitForExistence(timeout: 4))

        app.buttons["focusResetButton"].tap()

        XCTAssertFalse(app.buttons["focusResetButton"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testAstronomyReadoutHighlightsDialAndLinksToGuide() throws {
        let app = launchWithDrawer(tab: "Astronomy")

        XCTAssertTrue(app.staticTexts["section-Current readout"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["section-Astronomy"].exists)
        let readoutCapture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        readoutCapture.name = "iPad Astronomy"
        readoutCapture.lifetime = .keepAlways
        add(readoutCapture)

        app.descendants(matching: .any)["readout-Moon"].tap()
        XCTAssertTrue(app.buttons["focusResetButton"].waitForExistence(timeout: 4))

        app.buttons["learn-Moon"].tap()
        XCTAssertTrue(app.staticTexts["section-Reading guide"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["guideTopic-moon"].waitForExistence(timeout: 4))
    }

    @MainActor
    private func launchWithDrawer(tab: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = Self.englishArguments + ["-uiTestingOpenDrawer", "-uiTestingDrawerTab", tab]
        app.launch()
        XCTAssertTrue(app.staticTexts["Astologia Hologia"].waitForExistence(timeout: 8))
        return app
    }
}
