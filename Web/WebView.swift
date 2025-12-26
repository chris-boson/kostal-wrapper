import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String
    let allowAnyURL: Bool
    let cookieVault: CookieVault
    @ObservedObject var sessionDetector: SessionDetector

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(sessionDetector: sessionDetector, cookieVault: cookieVault, allowAnyURL: allowAnyURL)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.attach(webView: webView)
        loadInitialURL(webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let current = uiView.url?.absoluteString, current != urlString {
            loadInitialURL(uiView)
        }
        context.coordinator.allowAnyURL = allowAnyURL
    }

    private func loadInitialURL(_ webView: WKWebView) {
        guard let url = URL(string: urlString) else { return }
        cookieVault.restoreCookies { _ in
            webView.load(URLRequest(url: url))
        }
    }
}
