import SwiftUI
import SwiftData
import OSLog

private let appLogger = Logger(subsystem: "com.zonywhoop.LinkPaw", category: "App")

@main
struct LinkPawApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var updateManager = UpdateManager()
    @State private var urlToOpen: URL?

    init() {
        // Disable state restoration to prevent app from trying to restore previous windows on launch
        UserDefaults.standard.set(false, forKey: "ApplePersistenceIgnoreState")
    }

    var body: some Scene {
        WindowGroup("LinkPaw") {
            ContentView(profiles: profileManager.profiles, urlToOpen: urlToOpen)
                .environmentObject(updateManager)
                .onOpenURL { url in
                    appLogger.notice("onOpenURL received: \(url.absoluteString, privacy: .public)")
                    self.urlToOpen = url
                }
                .onAppear {
                    updateManager.checkForUpdates()
                }
        }
        .windowResizability(.contentSize)
        .modelContainer(for: UsageStats.self)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure we don't restore any windows
        if let window = NSApplication.shared.windows.first {
            window.isRestorable = false
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
