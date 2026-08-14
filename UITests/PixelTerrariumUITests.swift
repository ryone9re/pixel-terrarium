import XCTest

final class PixelTerrariumUITests: XCTestCase {
    @MainActor
    func testOnboardingWateringHistoryAndDeletion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        let startButton = app.buttons["start-terrarium-button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 8))
        startButton.tap()

        let waterButton = app.buttons["water-button"]
        XCTAssertTrue(waterButton.waitForExistence(timeout: 8))
        XCTAssertTrue(waterButton.isEnabled)
        waterButton.tap()

        XCTAssertTrue(app.staticTexts["watering-status"].waitForExistence(timeout: 4))
        XCTAssertEqual(waterButton.label, "今日は水やり済み")
        XCTAssertFalse(waterButton.isEnabled)

        app.buttons["history-button"].tap()
        XCTAssertTrue(app.staticTexts["水をあげました"].waitForExistence(timeout: 4))
        app.buttons["閉じる"].tap()

        app.buttons["settings-button"].tap()
        let deleteButton = app.buttons["delete-data-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 4))
        deleteButton.tap()
        app.buttons["すべて削除"].tap()

        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededHomeLaunches() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--seed-sample"]
        app.launch()

        XCTAssertTrue(app.staticTexts["星あかりの森"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["water-button"].exists)
    }
}
