import Foundation
import WebKit

final class CookieVault: ObservableObject {
    @Published var cookies: [CookieModel] = []
    private let keychain: KeychainStoring
    private let storageKey = "cookie-vault"
    private var cookieStore: WKHTTPCookieStore?

    init(keychain: KeychainStoring = KeychainHelper()) {
        self.keychain = keychain
        loadFromStorage()
    }

    func observe(cookieStore: WKHTTPCookieStore) {
        self.cookieStore = cookieStore
    }

    func snapshotCookies() {
        guard let store = cookieStore else { return }
        store.getAllCookies { [weak self] cookies in
            guard let self else { return }
            let models = cookies.compactMap { cookie -> CookieModel? in
                guard !cookie.isExpired else { return nil }
                return CookieModel(cookie: cookie)
            }
            self.cookies = models
            self.persist(models: models)
        }
    }

    func restoreCookies(completion: @escaping (Bool) -> Void) {
        guard let store = cookieStore ?? WKWebsiteDataStore.default().httpCookieStore else {
            completion(false)
            return
        }
        let models = cookies.filter { !$0.isExpired }
        guard !models.isEmpty else {
            completion(true)
            return
        }
        let group = DispatchGroup()
        for model in models {
            guard let cookie = model.toHTTPCookie() else { continue }
            group.enter()
            store.setCookie(cookie) { _ in group.leave() }
        }
        group.notify(queue: .main) {
            completion(true)
        }
    }

    private func persist(models: [CookieModel]) {
        do {
            let data = try JSONEncoder().encode(models)
            _ = keychain.write(key: storageKey, data: data)
        } catch {
            print("CookieVault persist failed: \(error)")
        }
    }

    private func loadFromStorage() {
        guard let data = keychain.read(key: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([CookieModel].self, from: data) {
            cookies = decoded
        }
    }
}

private extension HTTPCookie {
    var isExpired: Bool {
        if let expiresDate, expiresDate < Date() { return true }
        return false
    }
}

private extension CookieModel {
    var isExpired: Bool {
        if let expiresDate, expiresDate < Date() { return true }
        return false
    }
}
