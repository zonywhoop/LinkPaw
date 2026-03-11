import SwiftUI
import AppKit
import SwiftData
import CryptoKit
import Security

// MARK: - Usage Stats Model
@Model
final class UsageStats {
    var urlHash: String
    var browserId: String
    var count: Int
    var lastUsed: Date
    
    init(urlHash: String, browserId: String) {
        self.urlHash = urlHash
        self.browserId = browserId
        self.count = 1
        self.lastUsed = Date()
    }
}

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
    @EnvironmentObject private var updateManager: UpdateManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var statsManager = StatsManager()
    
    let profiles: [BrowserProfile]
    let urlToOpen: URL?
    @State private var showingSyncStatus = false
    @State private var showingDefaultPrompt = false
    @FocusState private var listIsFocused: Bool
    @StateObject private var statusManager = BrowserStatusManager()

    private var requiredWidth: CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        let maxWidth = profiles.reduce(0) { currentMax, profile in
            let text = "\(profile.name) - \(profile.subtitle)"
            let width = (text as NSString).size(withAttributes: [.font: font]).width
            return max(currentMax, width)
        }
        // Add 20px padding on each side (total 40px)
        return max(400, maxWidth + 40)
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                if updateManager.isUpdateAvailable {
                    UpdateBannerView(version: updateManager.latestVersion ?? "", downloadURL: updateManager.downloadURL)
                }
                
                if let url = urlToOpen {
                    HeaderView(url: url)
                    
                    if profiles.isEmpty {
                        VStack {
                            Text("No browsers found.")
                                .foregroundColor(.secondary)
                            Text("Profile count: \(profiles.count)")
                                .font(.caption)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List(profiles) { profile in
                            Button(action: {
                                statsManager.recordSelection(url: url, profile: profile, context: modelContext)
                                Launcher.launch(url: url, in: profile)
                                // Add a short delay before terminating to ensure SwiftData flushes to disk
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NSApplication.shared.terminate(nil)
                                }
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
                            .buttonStyle(SystemHighlightButtonStyle())
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
                        .padding(.bottom, 20)

                        // Footer with Version, License, and GitHub info
                        VStack(spacing: 8) {
                            HStack(spacing: 15) {
                                Button(action: {
                                    updateManager.checkForUpdates(manual: true)
                                }) {
                                    Label("Check for Updates", systemImage: "arrow.clockwise.circle")
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)

                                Link(destination: URL(string: "https://github.com/zonywhoop/LinkPaw")!) {
                                    Label("GitHub", systemImage: "link")
                                }
                                .foregroundColor(.blue)
                            }
                            .font(.subheadline)

                            VStack(spacing: 4) {
                                Text("© 2026 zonywhoop")
                                Text("Licensed under GNU GPL v2")
                                    .font(.system(size: 10))
                                
                                if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                    Text("Version \(currentVersion)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
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
        .frame(minWidth: requiredWidth, maxWidth: requiredWidth, minHeight: 600)
        .onAppear {
            handleURLOnAppear()
        }
        .onChange(of: urlToOpen) { oldURL, newURL in
            if let url = newURL {
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
        .padding(.top, 40)
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

// MARK: - Stats Manager
@MainActor
class StatsManager: ObservableObject {
    private let saltKey = "com.zonywhoop.LinkPaw.salt"
    private var salt: Data?
    
    init() {
        self.salt = getOrCreateSalt()
    }
    
    func recordSelection(url: URL, profile: BrowserProfile, context: ModelContext) {
        let sanitizedURL = sanitizeURL(url)
        let hash = generateHash(for: sanitizedURL)
        let browserId = profile.id
        
        // Print store location to help user find it
        if let storeURL = context.container.configurations.first?.url {
            print("Usage stats database: \(storeURL.path)")
        }
        
        let descriptor = FetchDescriptor<UsageStats>(
            predicate: #Predicate<UsageStats> { record in
                record.urlHash == hash && record.browserId == browserId
            }
        )
        
        do {
            if let existing = try context.fetch(descriptor).first {
                existing.count += 1
                existing.lastUsed = Date()
            } else {
                let newRecord = UsageStats(urlHash: hash, browserId: browserId)
                context.insert(newRecord)
            }
            try context.save()
        } catch {
            print("Error saving selection stats: \(error)")
        }
    }
    
    private func sanitizeURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.query = nil
        components.fragment = nil
        return components.string ?? url.absoluteString
    }
    
    private func generateHash(for sanitizedURL: String) -> String {
        guard let salt = self.salt, let urlData = sanitizedURL.data(using: .utf8) else {
            let hash = SHA256.hash(data: sanitizedURL.data(using: .utf8) ?? Data())
            return hash.map { String(format: "%02x", $0) }.joined()
        }
        var saltedData = urlData
        saltedData.append(salt)
        let hash = SHA256.hash(data: saltedData)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func getOrCreateSalt() -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: saltKey,
            kSecReturnData as String: true
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        var newSalt = Data(count: 32)
        _ = newSalt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: saltKey,
            kSecValueData as String: newSalt
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        return newSalt
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
        if let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://")!) {
            isDefault = Bundle(url: appURL)?.bundleIdentifier == (bundleID as String)
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
struct UpdateBannerView: View {
    let version: String
    let downloadURL: URL?
    @EnvironmentObject private var updateManager: UpdateManager

    var body: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.blue)
            Text("A new version (\(version)) is available!")
                .fontWeight(.medium)
            Spacer()
            if let url = downloadURL {
                Button("Update Now") {
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("View Release") {
                    if let repoURL = URL(string: "https://github.com/zonywhoop/LinkPaw/releases/latest") {
                        NSWorkspace.shared.open(repoURL)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            Button(action: {
                updateManager.isUpdateAvailable = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .border(Color.blue.opacity(0.2), width: 1)
    }
}

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

struct SystemHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(NSColor.selectedControlColor).opacity(0.8) : Color(NSColor.selectedControlColor).opacity(0.4))
            .cornerRadius(6)
            .foregroundColor(.primary)
    }
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
        .environmentObject(UpdateManager())
        .modelContainer(for: UsageStats.self, inMemory: true)
    }
}

// MARK: - Update Manager
/// UpdateManager handles checking for new versions of LinkPaw from GitHub releases.
class UpdateManager: ObservableObject {
    /// Whether a newer version is available.
    @Published var isUpdateAvailable = false
    /// The version string of the latest release.
    @Published var latestVersion: String?
    /// The URL to download the latest DMG.
    @Published var downloadURL: URL?
    
    private let repoOwner = "zonywhoop"
    private let repoName = "LinkPaw"
    private let lastCheckKey = "lastUpdateTimeCheck"
    
    /// Checks for updates if enough time has passed since the last check.
    /// - Parameter manual: If true, ignores the time throttle.
    func checkForUpdates(manual: Bool = false) {
        if !manual {
            let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
            let now = Date().timeIntervalSince1970
            // Check once every 24 hours (86400 seconds)
            if now - lastCheck < 86400 {
                return
            }
        }
        
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
        
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    
                    let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                    
                    if self?.isNewer(latest: latestVersion, current: currentVersion) ?? false {
                        var downloadURL: URL?
                        if let assets = json["assets"] as? [[String: Any]] {
                            for asset in assets {
                                if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                                   let urlString = asset["browser_download_url"] as? String {
                                    downloadURL = URL(string: urlString)
                                    break
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.latestVersion = latestVersion
                            self?.downloadURL = downloadURL
                            self?.isUpdateAvailable = true
                        }
                    }
                }
            } catch {
                print("Error parsing update JSON: \(error)")
            }
        }.resume()
    }
    
    /// Compares two version strings.
    /// - Parameters:
    ///   - latest: The latest version string (e.g., "1.2.3").
    ///   - current: The current version string (e.g., "1.2.2").
    /// - Returns: True if latest is newer than current.
    private func isNewer(latest: String, current: String) -> Bool {
        let latestComponents = latest.split(separator: ".").compactMap { Int($0.filter { "0123456789".contains($0) }) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0.filter { "0123456789".contains($0) }) }
        
        let count = max(latestComponents.count, currentComponents.count)
        for i in 0..<count {
            let l = i < latestComponents.count ? latestComponents[i] : 0
            let c = i < currentComponents.count ? currentComponents[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}
