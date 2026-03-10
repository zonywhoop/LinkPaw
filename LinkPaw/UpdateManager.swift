import Foundation
import AppKit

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
