import Foundation
import WebKit

final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    private weak var webView: WKWebView?
    private let sessionDetector: SessionDetector
    private let cookieVault: CookieVault
    var allowAnyURL: Bool

    init(sessionDetector: SessionDetector, cookieVault: CookieVault, allowAnyURL: Bool) {
        self.sessionDetector = sessionDetector
        self.cookieVault = cookieVault
        self.allowAnyURL = allowAnyURL
    }

    func attach(webView: WKWebView) {
        self.webView = webView
        webView.configuration.websiteDataStore.httpCookieStore.add(self)
        cookieVault.observe(cookieStore: webView.configuration.websiteDataStore.httpCookieStore)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if !allowAnyURL, let host = navigationAction.request.url?.host, let baseHost = webView.url?.host, host != baseHost {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        sessionDetector.evaluate(webView: webView)
    }
}

extension WebViewCoordinator: WKHTTPCookieStoreObserver {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieVault.snapshotCookies()
    }
}
