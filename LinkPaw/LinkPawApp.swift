import SwiftUI

@main
struct LinkPawApp: App {
    @StateObject private var profileManager = ProfileManager()
    @State private var urlToOpen: URL?

    var body: some Scene {
        WindowGroup {
            ContentView(profiles: profileManager.profiles, urlToOpen: urlToOpen ?? URL(string: "https://duckduckgo.com")!)
                .onOpenURL { url in
                    self.urlToOpen = url
                }
        }
    }
}
