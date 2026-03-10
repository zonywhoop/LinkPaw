import SwiftUI

@main
struct LinkPawApp: App {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var updateManager = UpdateManager()
    @State private var urlToOpen: URL?

    var body: some Scene {
        WindowGroup {
            ContentView(profiles: profileManager.profiles, urlToOpen: urlToOpen)
                .environmentObject(updateManager)
                .onOpenURL { url in
                    self.urlToOpen = url
                }
                .onAppear {
                    updateManager.checkForUpdates()
                }
        }
        .windowResizability(.contentSize)
    }
}
