//
//  astologia_hologiaUITestsLaunchTests.swift
//  astologia hologiaUITests
//
//  Created by Shubeu on 5/6/26.
//

import XCTest

final class astologia_hologiaUITestsLaunchTests: XCTestCase {
    /// The app follows the system language; these tests read English labels.
    static let englishArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]


    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += Self.englishArguments + ["-uiTestingDate", "2026-09-26T01:55:00Z"]
        app.launch()

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
