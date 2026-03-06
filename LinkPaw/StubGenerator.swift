import Foundation
import AppKit

/// StubGenerator handles the creation of standalone macOS Application bundles (stubs)
/// that act as browsers for specific Firefox containers.
class StubGenerator {
    private let fileManager = FileManager.default
    
    /// Directory where stubs will be created (typically ~/Applications/LinkPaw Browsers)
    private var stubsDirectory: URL? {
        fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first?
            .appendingPathComponent("LinkPaw Browsers")
    }
    
    /// Generates stub applications for a list of browser profiles.
    /// - Parameter profiles: [BrowserProfile] - The list of discovered browser profiles.
    /// - Returns: Void
    func generateStubs(for profiles: [BrowserProfile]) {
        guard let stubsDir = stubsDirectory else { return }
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: stubsDir, withIntermediateDirectories: true)
        
        // Get the path to the master firefox-container script
        guard let masterScriptPath = Bundle.main.path(forResource: "firefox-container", ofType: nil) else {
            print("Error: Could not find master firefox-container script")
            return
        }
        
        for profile in profiles {
            // We only generate stubs for Firefox containers for now, per requirements
            if case .firefox(let container) = profile {
                createStub(for: container, at: stubsDir, scriptSource: masterScriptPath)
            }
        }
    }
    
    /// Creates an individual application stub for a specific Firefox container.
    /// - Parameters:
    ///   - container: FirefoxContainer - The container to create a stub for.
    ///   - dir: URL - The directory where the stub should be created.
    ///   - scriptSource: String - The path to the source 'firefox-container' script to be bundled.
    /// - Returns: Void
    private func createStub(for container: FirefoxContainer, at dir: URL, scriptSource: String) {
        let appName = "FF - \(container.name)"
        let appURL = dir.appendingPathComponent("\(appName).app")
        
        print("Generating stub: \(appURL.path)")
        
        // Escape container name for AppleScript string literal
        let escapedContainerName = container.name
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // 1. Create AppleScript source
        // Use quoted form of for all arguments to be safe
        // Use -- to separate URL from options to prevent flag confusion
        let appleScript = """
        on open location this_url
            set scriptPath to (path to me as string) & "Contents:Resources:firefox-container"
            set posixScriptPath to POSIX path of scriptPath
            do shell script (quoted form of posixScriptPath) & " --name " & (quoted form of "\(escapedContainerName)") & " -- " & (quoted form of this_url)
        end open location
        
        on run
            -- If launched without URL, just open Firefox in that container
            set scriptPath to (path to me as string) & "Contents:Resources:firefox-container"
            set posixScriptPath to POSIX path of scriptPath
            do shell script (quoted form of posixScriptPath) & " --name " & (quoted form of "\(escapedContainerName)") & " -- about:newtab"
        end run
        """
        
        let tempScriptURL = fileManager.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).applescript")
        
        do {
            try appleScript.write(to: tempScriptURL, atomically: true, encoding: .utf8)
            
            // 2. Compile AppleScript to App Bundle using osacompile
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osacompile")
            process.arguments = ["-o", appURL.path, tempScriptURL.path]
            try process.run()
            process.waitUntilExit()
            
            // Clean up temp script
            try? fileManager.removeItem(at: tempScriptURL)
            
            // 3. Copy firefox-container script into the App Bundle Resources
            let resourcesURL = appURL.appendingPathComponent("Contents/Resources")
            let destScriptURL = resourcesURL.appendingPathComponent("firefox-container")
            
            // osacompile creates the Resources folder
            if fileManager.fileExists(atPath: destScriptURL.path) {
                try? fileManager.removeItem(at: destScriptURL)
            }
            try fileManager.copyItem(atPath: scriptSource, toPath: destScriptURL.path)
            
            // Make executable just in case
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destScriptURL.path)
            
            // 4. Update Info.plist to register as a browser
            updateInfoPlist(at: appURL.appendingPathComponent("Contents/Info.plist"))
            
        } catch {
            print("Failed to create stub for \(container.name): \(error)")
        }
    }
    
    /// Updates the Info.plist of the generated app bundle to register it as a web browser.
    /// - Parameter plistURL: URL - The path to the Info.plist file.
    /// - Returns: Void
    private func updateInfoPlist(at plistURL: URL) {
        guard let data = try? Data(contentsOf: plistURL),
              var plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
            return
        }
        
        // Add URL Types to handle http and https
        let urlTypes: [[String: Any]] = [
            [
                "CFBundleURLName": "Web Site URL",
                "CFBundleURLSchemes": ["http", "https"],
                "LSHandlerRank": "Alternate" 
            ]
        ]
        
        plist["CFBundleURLTypes"] = urlTypes
        plist["LSBackgroundOnly"] = true 
        
        // Write back
        if let newData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
            try? newData.write(to: plistURL)
        }
    }
}
