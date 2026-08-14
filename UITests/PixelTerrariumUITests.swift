import XCTest

final class PixelTerrariumUITests: XCTestCase {
    @MainActor
    func testLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Pixel Terrarium"].waitForExistence(timeout: 5))
    }
}
