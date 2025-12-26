import SwiftUI

@main
struct SolarPortalWrapperApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var cookieVault = CookieVault()
    @State private var lastRestore: Date? = nil

    var body: some Scene {
        WindowGroup {
            ContentView(cookieVault: cookieVault, lastRestore: $lastRestore)
                .onChange(of: scenePhase) { newValue in
                    switch newValue {
                    case .background:
                        cookieVault.snapshotCookies()
                    case .active:
                        cookieVault.restoreCookies { success in
                            if success {
                                lastRestore = Date()
                            }
                        }
                    default:
                        break
                    }
                }
        }
    }
}
