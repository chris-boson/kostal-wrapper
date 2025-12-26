import XCTest
import WebKit
@testable import SolarPortalWrapper

final class CookieVaultTests: XCTestCase {
    func testSerializationRoundTrip() throws {
        let keychain = KeychainMock()
        let vault = CookieVault(keychain: keychain)
        let expires = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: "session",
            .value: "abc",
            .domain: "example.com",
            .path: "/",
            .expires: expires as Any
        ]
        let cookie = HTTPCookie(properties: cookieProperties)!
        vault.observe(cookieStore: WKWebsiteDataStore.default().httpCookieStore)
        vault.cookies = [CookieModel(cookie: cookie)]

        vault.snapshotCookies()
        XCTAssertNotNil(keychain.storage["cookie-vault"])

        let restored = CookieVault(keychain: keychain)
        XCTAssertEqual(restored.cookies.first?.name, "session")
        XCTAssertEqual(restored.cookies.first?.domain, "example.com")
    }

    func testExpiredCookieIgnored() throws {
        let keychain = KeychainMock()
        let vault = CookieVault(keychain: keychain)
        let expired = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let properties: [HTTPCookiePropertyKey: Any] = [
            .name: "old",
            .value: "1",
            .domain: "example.com",
            .path: "/",
            .expires: expired as Any
        ]
        let cookie = HTTPCookie(properties: properties)!
        vault.cookies = [CookieModel(cookie: cookie)]

        let expectation = expectation(description: "restore")
        vault.restoreCookies { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
