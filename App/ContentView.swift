import SwiftUI
import WebKit

struct ContentView: View {
    @State private var showSettings = false
    @State private var showDebug = false
    @AppStorage("portalURL") private var portalURL: String = "https://kostal-solar-portal.com"
    @AppStorage("allowAnyURL") private var allowAnyURL: Bool = false
    @StateObject private var sessionDetector = SessionDetector()

    let cookieVault: CookieVault
    @Binding var lastRestore: Date?

    var body: some View {
        NavigationStack {
            WebView(urlString: portalURL, allowAnyURL: allowAnyURL, cookieVault: cookieVault, sessionDetector: sessionDetector)
                .overlay(alignment: .top) {
                    if sessionDetector.sessionLost {
                        sessionLostBanner
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showDebug.toggle() }) {
                            Label("Debug", systemImage: "ladybug")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showSettings.toggle() }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(portalURL: $portalURL, allowAnyURL: $allowAnyURL)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showDebug) {
                    DebugPanel(cookieVault: cookieVault, lastRestore: $lastRestore, sessionDetector: sessionDetector)
                        .presentationDetents([.medium, .large])
                }
        }
    }

    private var sessionLostBanner: some View {
        VStack {
            Label("Session lost — please log in once; we'll persist session afterward.", systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.9))
                .foregroundStyle(.primary)
                .onTapGesture { sessionDetector.sessionLost = false }
            Spacer()
        }
        .transition(.move(edge: .top))
    }
}

struct SettingsView: View {
    @Binding var portalURL: String
    @Binding var allowAnyURL: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Portal")) {
                    TextField("Base URL", text: $portalURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Toggle("Allow any URL", isOn: $allowAnyURL)
                        .help("Enable to follow navigation outside of the base URL.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
        }
    }
}

struct DebugPanel: View {
    @ObservedObject var cookieVault: CookieVault
    @Binding var lastRestore: Date?
    @ObservedObject var sessionDetector: SessionDetector

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    HStack {
                        Text("Last restore")
                        Spacer()
                        if let lastRestore {
                            Text(lastRestore, format: .dateTime)
                        } else {
                            Text("—")
                        }
                    }
                    Toggle("Session lost banner", isOn: $sessionDetector.sessionLost)
                }

                Section("Cookies") {
                    if cookieVault.cookies.isEmpty {
                        Text("No cookies captured yet")
                    } else {
                        List(cookieVault.cookies) { cookie in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cookie.name)
                                    .font(.headline)
                                Text("Domain: \(cookie.domain) Path: \(cookie.path)")
                                    .font(.caption)
                                if let expiry = cookie.expiresDate {
                                    Text("Expires: \(expiry.formatted())")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }

                Section("Detection") {
                    Toggle("Enable login detection", isOn: $sessionDetector.isEnabled)
                    Text("Last login page URL: \(sessionDetector.lastLoginURL ?? "—")")
                        .font(.caption)
                }
            }
            .navigationTitle("Debug")
        }
    }
}
