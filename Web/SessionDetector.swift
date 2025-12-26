import Foundation
import WebKit

final class SessionDetector: ObservableObject {
    @Published var sessionLost: Bool = false
    @Published var isEnabled: Bool = true
    @Published var lastLoginURL: String?

    var loginPathIndicators: [String] = ["/login", "/signin"]
    var htmlIndicators: [String] = ["type=\"password\"", "name=\"password\""]

    func evaluate(webView: WKWebView) {
        guard isEnabled else { return }
        if let url = webView.url, isLoginURL(url) {
            triggerLost(url: url)
            return
        }

        webView.evaluateJavaScript("document.documentElement.innerHTML") { [weak self] result, _ in
            guard let self, let html = result as? String else { return }
            if self.containsLoginMarkup(html) {
                triggerLost(url: webView.url)
            }
        }
    }

    func isLoginURL(_ url: URL) -> Bool {
        loginPathIndicators.contains { url.path.lowercased().contains($0) }
    }

    func containsLoginMarkup(_ html: String) -> Bool {
        let lowercased = html.lowercased()
        return htmlIndicators.contains { lowercased.contains($0.lowercased()) }
    }

    private func triggerLost(url: URL?) {
        DispatchQueue.main.async {
            self.sessionLost = true
            self.lastLoginURL = url?.absoluteString
        }
    }
}
