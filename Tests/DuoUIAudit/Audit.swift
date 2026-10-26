import XCTest

final class Audit: XCTestCase {
    @MainActor
    func capture(_ app: XCUIApplication, _ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = name + "-tree"
        tree.lifetime = .keepAlways
        add(tree)
        print("DUO_SCREEN " + name + "\n" + app.debugDescription)
        print("DUO_READY " + name)
        fflush(stdout)
        // The primary display can be inactive on Duo. The host captures the
        // active display via CoreDevice while this screen remains stationary.
        Thread.sleep(forTimeInterval: 4)

    }

    @MainActor
    func testNavigate() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.ratedcounsel.swiftfin.duo")
        app.activate()
        let actions = ProcessInfo.processInfo.environment["DUO_ACTIONS"] ?? "capture:initial"
        for (index, action) in actions.components(separatedBy: "|").enumerated() {
            let parts = action.split(separator: ":", maxSplits: 1).map(String.init)
            let value = parts.count > 1 ? parts[1] : ""
            // Duo can expose a zero-sized inactive window before its active one.
            // Coordinate gestures must target the actual visible window.
            let surface: XCUIElement = app.windows.allElementsBoundByIndex.max {
                $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
            } ?? app
            switch parts[0] {
            case "tap":
                let element = app.buttons.matching(NSPredicate(format: "label == %@ OR identifier == %@", value, value)).firstMatch
                XCTAssertTrue(element.waitForExistence(timeout: 10), "Missing button " + value)
                let candidates = app.buttons.matching(NSPredicate(format: "label == %@ OR identifier == %@", value, value)).allElementsBoundByIndex
                (candidates.first(where: { $0.isHittable }) ?? element).tap()
            case "prefix":
                let element = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", value)).firstMatch
                XCTAssertTrue(element.waitForExistence(timeout: 10), "Missing button prefix " + value)
                element.tap()
            case "back":
                let back = app.buttons["BackButton"].firstMatch
                if back.exists { back.tap() }
                else { app.navigationBars.buttons.element(boundBy: 0).tap() }
            case "point":
                let xy = value.split(separator: ",").compactMap { Double($0) }
                XCTAssertEqual(xy.count, 2)
                surface.coordinate(withNormalizedOffset: CGVector(dx: xy[0], dy: xy[1])).tap()
            case "system":
                print("DUO_SYSTEM\n" + XCUIApplication(bundleIdentifier: "com.apple.springboard").debugDescription)
            case "up": surface.swipeUp()
            case "down": surface.swipeDown()
            case "search":
                let field = app.searchFields.firstMatch
                XCTAssertTrue(field.waitForExistence(timeout: 10))
                field.tap()
                field.typeText(value + "\n")
            case "launch": app.terminate(); app.launch()
            default: break
            }
            if parts[0] == "back" || (parts[0] == "tap" && value == "Close") { continue }
            capture(app, String(format: "%02d", index) + "-" + parts[0] + "-" + value)
        }
    }
}
