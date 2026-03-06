import SwiftUI

// MARK: - Data Models
struct FirefoxContainer: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let isPrivate: Bool
    
    init(name: String, isPrivate: Bool = false) {
        self.name = name
        self.isPrivate = isPrivate
    }
}

struct ChromeProfile: Identifiable, Hashable {
    var id: String { "\(browserName)-\(name)-\(isPrivate)" }
    let name: String
    let directory: String
    let browserName: String // e.g. "Google Chrome", "Microsoft Edge", "Brave"
    let isPrivate: Bool
}

struct GenericBrowser: Identifiable, Hashable {
    var id: String { "\(bundleIdentifier)-\(isPrivate)" }
    let name: String
    let bundleIdentifier: String
    let appPath: String
    let isPrivate: Bool
}

enum BrowserProfile: Identifiable, Hashable {
    case firefox(FirefoxContainer)
    case chrome(ChromeProfile)
    case generic(GenericBrowser)
    
    var id: String {
        switch self {
        case .firefox(let container): return "ff-\(container.id)"
        case .chrome(let profile): return "gc-\(profile.id)"
        case .generic(let browser): return "gen-\(browser.id)"
        }
    }
    
    var name: String {
        switch self {
        case .firefox(let container): 
            if container.isPrivate { return "Firefox Private" }
            if container.name == "Default" { return "Firefox Default" }
            return container.name
        case .chrome(let profile): 
            if profile.isPrivate { return "\(profile.browserName) Private" }
            return profile.name
        case .generic(let browser): 
            if browser.isPrivate { return "\(browser.name) Private" }
            return browser.name
        }
    }
    
    var subtitle: String {
        switch self {
        case .firefox: return "Firefox"
        case .chrome(let profile): return profile.browserName
        case .generic(let browser): return browser.name
        }
    }
    
    var isPrivate: Bool {
        switch self {
        case .firefox(let c): return c.isPrivate
        case .chrome(let p): return p.isPrivate
        case .generic(let g): return g.isPrivate
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    let profiles: [BrowserProfile]
    let urlToOpen: URL?
    @State private var showingSyncStatus = false
    @State private var showingDefaultPrompt = false
    @FocusState private var listIsFocused: Bool
    @StateObject private var statusManager = BrowserStatusManager()

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                if let url = urlToOpen {
                    HeaderView(url: url)
                    
                    if profiles.isEmpty {
                        Text("No browsers found.")
                            .foregroundColor(.secondary)
                            .frame(maxHeight: .infinity)
                    } else {
                        List(profiles) { profile in
                            Button(action: {
                                Launcher.launch(url: url, in: profile)
                                NSApplication.shared.terminate(nil)
                            }) {
                                HStack {
                                    Spacer()
                                    Text("\(profile.name) - \(profile.subtitle)")
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.bordered)
                            .id(profile.id)
                        }
                        .focused($listIsFocused)
                        .onAppear {
                            listIsFocused = true
                        }
                    }
                } else {
                    // ... home screen view ...
                    VStack(spacing: 30) {
                        LinkPawIcon(size: 160)
                            .padding(.top, 40)
                        
                        Text("LinkPaw")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if !statusManager.isDefault {
                            VStack(spacing: 16) {
                                Text("LinkPaw is not your default browser.")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Button(action: {
                                    statusManager.setAsDefault()
                                }) {
                                    Text("Set LinkPaw as Default Browser")
                                        .font(.headline)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                
                                Text("Links will open in this app, allowing you to choose the target container or profile.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.orange.opacity(0.1)))
                            .padding(.horizontal, 30)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("LinkPaw is your default browser.")
                                    .font(.headline)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(0.1)))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                let generator = StubGenerator()
                                generator.generateStubs(for: profiles)
                                showingSyncStatus = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showingSyncStatus = false
                                }
                            }) {
                                Label("Sync Browser Stubs", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(minWidth: 200)
                            }
                            .buttonStyle(.bordered)
                            
                            if showingSyncStatus {
                                Text("Stubs generated in 'Applications/LinkPaw Browsers'")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Button("Check Default Status Again") {
                                statusManager.checkIfDefault()
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onKeyPress { event in
                if let char = event.characters.first?.lowercased() {
                    if let match = profiles.first(where: { $0.name.lowercased().hasPrefix(char) }) {
                        withAnimation {
                            proxy.scrollTo(match.id, anchor: .top)
                        }
                        return .handled
                    }
                }
                return .ignored
            }
        }
        .frame(minWidth: 400, minHeight: 600)
        .onAppear {
            handleURLOnAppear()
        }
        .onChange(of: urlToOpen) { newValue in
            if let url = newValue {
                MeetingAppManager.tryLaunchInNativeApp(url: url)
            }
        }
        .alert("Set as Default Browser?", isPresented: $showingDefaultPrompt) {
            Button("Set as Default") {
                statusManager.setAsDefault()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("LinkPaw needs to be your default browser to help you manage your container and profile links.")
        }
    }

    private func handleURLOnAppear() {
        statusManager.checkIfDefault()
        
        if let url = urlToOpen {
            MeetingAppManager.tryLaunchInNativeApp(url: url)
        } else if !statusManager.isDefault {
            showingDefaultPrompt = true
        }
    }
}

// MARK: - Meeting App Manager
struct MeetingAppManager {
    static func tryLaunchInNativeApp(url: URL) {
        let urlString = url.absoluteString.lowercased()
        
        // Zoom URLs: zoom.us/j/ or zoom.us/s/
        if urlString.contains("zoom.us/j/") || urlString.contains("zoom.us/s/") {
            if launchApp(bundleID: "us.zoom.xos", url: url) {
                NSApplication.shared.terminate(nil)
                return
            }
        }
        
        // Teams URLs: teams.microsoft.com/l/meetup-join/
        if urlString.contains("teams.microsoft.com/l/meetup-join/") {
            // Check for New Teams first, then Classic
            if launchApp(bundleID: "com.microsoft.teams2", url: url) || 
               launchApp(bundleID: "com.microsoft.teams", url: url) {
                NSApplication.shared.terminate(nil)
                return
            }
        }
    }
    
    @discardableResult
    private static func launchApp(bundleID: String, url: URL) -> Bool {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration, completionHandler: nil)
            return true
        }
        return false
    }
}

// MARK: - Browser Status Manager
class BrowserStatusManager: ObservableObject {
    @Published var isDefault: Bool = false
    private let bundleID = "com.zonywhoop.LinkPaw" as CFString
    
    func checkIfDefault() {
        if let currentHandler = LSCopyDefaultHandlerForURLScheme("https" as CFString)?.takeRetainedValue() {
            isDefault = (currentHandler as String) == (bundleID as String)
        } else {
            isDefault = false
        }
    }
    
    func setAsDefault() {
        LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID)
        LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID)
        // Refresh after a short delay to allow system dialog to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.checkIfDefault()
        }
    }
}

// MARK: - Helper Views & Extensions
struct HeaderView: View {
    let url: URL
    
    var body: some View {
        VStack {
            Text("Open Link In...")
                .font(.headline)
            
            Text(url.absoluteString)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(EffectView())
        .border(Color(NSColor.separatorColor), width: 1)
    }
}

struct EffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .headerView
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Profile Discovery & Models
private struct FirefoxCodable: Codable {
    let identities: [Identity]
    struct Identity: Codable {
        let name: String?
    }
}
private struct ChromeCodable: Codable {
    let profile: Profile
    struct Profile: Codable {
        let info_cache: [String: InfoCache]
    }
    struct InfoCache: Codable {
        let name: String
    }
}

/// ProfileManager handles the discovery of Firefox containers and Chrome profiles
/// by scanning the user's Library directory.
class ProfileManager: ObservableObject {
    /// The list of discovered browser profiles.
    @Published var profiles: [BrowserProfile] = []

    /// Initializes the manager and performs initial discovery.
    init() {
        let discovered = findFirefoxContainers() + findChromiumProfiles() + findGenericBrowsers()
        self.profiles = discovered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Scans Firefox profile directories for containers.json to discover containers.
    /// - Returns: [BrowserProfile] - A list of discovered Firefox container profiles.
    private func findFirefoxContainers() -> [BrowserProfile] {
        let fileManager = FileManager.default
        guard let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return [] }
        
        let profilesDirURL = libraryDir.appendingPathComponent("Application Support/Firefox/Profiles")
        
        var results: [BrowserProfile] = []
        
        // Add Firefox Standard and Private
        results.append(.firefox(FirefoxContainer(name: "Default", isPrivate: false)))
        results.append(.firefox(FirefoxContainer(name: "Private", isPrivate: true)))
        
        if let profileDirContents = try? fileManager.contentsOfDirectory(at: profilesDirURL, includingPropertiesForKeys: nil) {
            let profileURL = profileDirContents.first(where: { $0.lastPathComponent.hasSuffix(".default-release") }) ?? profileDirContents.first
            
            if let finalProfileURL = profileURL {
                let containersJsonURL = finalProfileURL.appendingPathComponent("containers.json")
                if fileManager.fileExists(atPath: containersJsonURL.path),
                   let data = try? Data(contentsOf: containersJsonURL),
                   let decoded = try? JSONDecoder().decode(FirefoxCodable.self, from: data) {
                    
                    let containers: [BrowserProfile] = decoded.identities.compactMap { identity in
                        guard let name = identity.name, !name.starts(with: "userContextIdInternal") else { return nil }
                        return .firefox(FirefoxContainer(name: name, isPrivate: false))
                    }
                    results.append(contentsOf: containers)
                }
            }
        }
        
        return results
    }

    /// Scans various Chromium browsers' Local State to discover user profiles.
    /// - Returns: [BrowserProfile] - A list of discovered Chromium-based profiles.
    private func findChromiumProfiles() -> [BrowserProfile] {
        let chromiumConfigs = [
            ("Google Chrome", "Application Support/Google/Chrome/Local State"),
            ("Microsoft Edge", "Application Support/Microsoft Edge/Local State"),
            ("Brave", "Application Support/BraveSoftware/Brave-Browser/Local State")
        ]
        
        let fileManager = FileManager.default
        guard let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return [] }
        
        var allProfiles: [BrowserProfile] = []
        
        for (browserName, relativePath) in chromiumConfigs {
            let localStateURL = libraryDir.appendingPathComponent(relativePath)
            
            guard fileManager.fileExists(atPath: localStateURL.path),
                  let data = try? Data(contentsOf: localStateURL),
                  let decoded = try? JSONDecoder().decode(ChromeCodable.self, from: data) else { continue }

            for (dir, info) in decoded.profile.info_cache {
                allProfiles.append(.chrome(ChromeProfile(name: info.name, directory: dir, browserName: browserName, isPrivate: false)))
                // Add private mode for each Chromium browser (usually one is enough, but we'll add it per-browser)
                if dir == "Default" {
                   allProfiles.append(.chrome(ChromeProfile(name: "Private", directory: dir, browserName: browserName, isPrivate: true)))
                }
            }
        }
        
        return allProfiles
    }

    /// Discovers standalone browsers that don't follow the Chromium profile pattern (like Safari).
    /// - Returns: [BrowserProfile] - A list of discovered standalone browsers.
    private func findGenericBrowsers() -> [BrowserProfile] {
        let potentialBrowsers = [
            ("Safari", "com.apple.Safari", "/Applications/Safari.app"),
            ("Arc", "company.thebrowser.Browser", "/Applications/Arc.app"),
            ("Vivaldi", "com.vivaldi.Vivaldi", "/Applications/Vivaldi.app")
        ]
        
        let fileManager = FileManager.default
        var browsers: [BrowserProfile] = []
        
        for (name, bundleId, path) in potentialBrowsers {
            if fileManager.fileExists(atPath: path) {
                browsers.append(.generic(GenericBrowser(name: name, bundleIdentifier: bundleId, appPath: path, isPrivate: false)))
                browsers.append(.generic(GenericBrowser(name: name, bundleIdentifier: bundleId, appPath: path, isPrivate: true)))
            }
        }
        
        return browsers
    }
}


/// Launcher provides static methods for opening URLs in specific browser profiles.
struct Launcher {
    /// Launches a URL in the specified browser profile using a shell process.
    /// Validates the URL scheme to ensure only http/https links are processed.
    /// - Parameters:
    ///   - url: URL - The web address to open.
    ///   - profile: BrowserProfile - The Firefox container or Chrome profile to use.
    /// - Returns: Void
    static func launch(url: URL, in profile: BrowserProfile) {
        // OWASP: Input Validation. Ensure we only open web protocols to prevent protocol-based attacks.
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            print("Security Warning: Blocked attempt to open non-web URL scheme: \(url.scheme ?? "none")")
            return
        }

        let urlString = url.absoluteString
        let task = Process()
        let pipe = Pipe()
        task.standardError = pipe
        task.standardOutput = pipe
        
        switch profile {
        case .firefox(let container):
            if container.isPrivate {
                task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                task.arguments = ["-n", "-b", "org.mozilla.firefox", "--args", "--private-window", "--", urlString]
            } else if container.name == "Default" {
                task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                task.arguments = ["-b", "org.mozilla.firefox", "--", urlString]
            } else {
                guard let scriptPath = Bundle.main.path(forResource: "firefox-container", ofType: nil) else {
                    print("Error: Could find firefox-container script in bundle")
                    return
                }
                
                let chmodTask = Process()
                chmodTask.executableURL = URL(fileURLWithPath: "/bin/chmod")
                chmodTask.arguments = ["+x", scriptPath]
                try? chmodTask.run()
                chmodTask.waitUntilExit()

                task.executableURL = URL(fileURLWithPath: "/bin/bash")
                task.arguments = [scriptPath, "--name", container.name, "--", urlString]
            }
            
        case .chrome(let profile):
            let binaryPath: String
            switch profile.browserName {
            case "Microsoft Edge":
                binaryPath = "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
            case "Brave":
                binaryPath = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
            default: // Google Chrome
                binaryPath = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            }
            task.executableURL = URL(fileURLWithPath: binaryPath)
            var args = ["--profile-directory=\(profile.directory)"]
            if profile.isPrivate {
                args.append("-incognito")
            }
            args.append("--")
            args.append(urlString)
            task.arguments = args
            
        case .generic(let browser):
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            var args: [String] = []
            if browser.isPrivate {
                args = ["-n", "-a", browser.name, "--args"]
                if browser.bundleIdentifier == "com.apple.Safari" {
                    args.append("-private") 
                } else if browser.name == "Arc" {
                    args.append("--incognito")
                } else {
                    args.append("--private-window")
                }
                args.append("--")
            } else {
                args = ["-b", browser.bundleIdentifier]
                args.append("--")
            }
            args.append(urlString)
            task.arguments = args
        }
        
        do {
            try task.run()
            if case .firefox(let c) = profile, !c.isPrivate && c.name != "Default" {
                task.waitUntilExit()
            }
        } catch {
            print("Error launching process: \(error)")
        }
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            profiles: [
                .firefox(FirefoxContainer(name: "Personal")),
                .firefox(FirefoxContainer(name: "Default")),
                .firefox(FirefoxContainer(name: "Private", isPrivate: true)),
                .chrome(ChromeProfile(name: "Default", directory: "Default", browserName: "Google Chrome", isPrivate: false)),
                .generic(GenericBrowser(name: "Safari", bundleIdentifier: "com.apple.Safari", appPath: "/Applications/Safari.app", isPrivate: false))
            ],
            urlToOpen: nil
        )
    }
}
