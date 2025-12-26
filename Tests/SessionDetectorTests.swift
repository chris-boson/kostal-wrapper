import XCTest
@testable import SolarPortalWrapper

final class SessionDetectorTests: XCTestCase {
    func testLoginURLDetection() {
        let detector = SessionDetector()
        XCTAssertTrue(detector.isLoginURL(URL(string: "https://example.com/login")!))
        XCTAssertFalse(detector.isLoginURL(URL(string: "https://example.com/dashboard")!))
    }

    func testHTMLDetection() {
        let detector = SessionDetector()
        let html = "<form><input type=\"password\"/></form>"
        XCTAssertTrue(detector.containsLoginMarkup(html))
        XCTAssertFalse(detector.containsLoginMarkup("<div>No password here</div>"))
    }
}
