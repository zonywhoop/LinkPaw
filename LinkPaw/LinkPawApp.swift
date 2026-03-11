import SwiftUI
import SwiftData
import OSLog

private let appLogger = Logger(subsystem: "com.zonywhoop.LinkPaw", category: "App")

@main
struct LinkPawApp: App {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var updateManager = UpdateManager()
    @State private var urlToOpen: URL?

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
