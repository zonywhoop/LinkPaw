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
    
    let container: ModelContainer

    init() {
        // Disable state restoration to prevent app from trying to restore previous windows on launch
        UserDefaults.standard.set(false, forKey: "ApplePersistenceIgnoreState")
        
        let appSupport = URL.applicationSupportDirectory
        let folder = appSupport.appending(path: "com.zonywhoop.LinkPaw", directoryHint: .isDirectory)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        
        let config = ModelConfiguration("UsageStats", url: folder.appending(path: "stats.sqlite"))
        
        do {
            container = try ModelContainer(for: UsageStats.self, configurations: config)
        } catch {
            appLogger.critical("Failed to create ModelContainer: \(error.localizedDescription, privacy: .public)")
            // Fallback to default if custom config fails
            container = try! ModelContainer(for: UsageStats.self)
        }
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
        .modelContainer(container)
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
