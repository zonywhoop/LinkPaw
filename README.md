# LinkPaw 🐾

LinkPaw is a macOS "browser shim" that acts as an intelligent intermediary for your web links. Instead of opening a link in a single default browser, LinkPaw intercepts the click and presents a clean, fast interface to choose exactly which browser, profile, or container should handle the request.

## Core Features

*   **Firefox Container Support:** Open links directly into specific Firefox Multi-Account Containers.
*   **Chrome Profile Support:** Target specific Google Chrome profiles.
*   **Multi-Browser Support:** Quickly switch between Brave, Opera, Safari, and other installed browsers.
*   **Security Focused:** Built with Swift for native performance and signed macOS builds, with protections against URL injection.

## Installation

### 1. Install LinkPaw
Download the latest `.dmg` or `.zip` from the [Releases](https://github.com/zonywhoop/LinkPaw/releases) page and move `LinkPaw.app` to your `/Applications` folder.

### 2. Set as Default Browser
Open **System Settings** > **Desktop & Dock** > **Default web browser** and select **LinkPaw**.

### 3. Firefox Container Integration (Required for Containers)
To enable the Firefox Container feature, you must install the helper extension in Firefox:

1.  Open Firefox.
2.  Install the **[Open URL in Container](https://github.com/honsiorovskyi/open-url-in-container)** extension.
3.  Ensure the extension is active. LinkPaw uses a specialized script to communicate with this extension via a custom protocol.

## Development & Releasing

### Prerequisites
*   Xcode 15+
*   macOS 14.0+
*   GitHub CLI (`gh`) for automated releases.

### Creating a Release
LinkPaw uses a specific versioning format: `v{year}.{release}.{bugfix}.{build}` (e.g., `v26.02.01.0`).

To build, sign, tag, and upload a new release to GitHub:
```bash
./scripts/release.sh 26.02.01
```

This script will:
1. Update `Info.plist` with the new version.
2. Commit and Tag the release in Git.
3. Archive and Export the signed `.app`.
4. Create `.dmg` and `.zip` artifacts.
5. Create a GitHub Release and upload the assets.

## License
Copyright © 2026 Zonywhoop. All rights reserved.
