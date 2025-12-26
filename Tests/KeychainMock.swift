import Foundation
@testable import SolarPortalWrapper

final class KeychainMock: KeychainStoring {
    var storage: [String: Data] = [:]

    func read(key: String) -> Data? {
        storage[key]
    }

    @discardableResult
    func write(key: String, data: Data) -> Bool {
        storage[key] = data
        return true
    }

    func delete(key: String) {
        storage.removeValue(forKey: key)
    }
}
