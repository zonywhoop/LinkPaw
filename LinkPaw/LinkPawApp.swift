import SwiftUI

@main
struct LinkPawApp: App {
    @StateObject private var profileManager = ProfileManager()
    @State private var urlToOpen: URL?

    var body: some Scene {
        WindowGroup {
            ContentView(profiles: profileManager.profiles, urlToOpen: urlToOpen)
                .onOpenURL { url in
                    self.urlToOpen = url
                }
        }
        .windowResizability(.contentSize)
    }
}
