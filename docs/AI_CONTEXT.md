# LinkPaw AI Development Context

## Project Overview
**Name:** LinkPaw
**Platform:** macOS (Swift, SwiftUI)
**Goal:** A browser picker/shim that intercepts links and allows users to choose which browser/profile/container to open them in.

## Core Features
1.  **Browser Interception:** Acts as the default browser to catch links.
2.  **Firefox Containers:** Supports opening links in specific Firefox Multi-Account Containers using `ext+container:` protocol.
3.  **Chrome Profiles:** Supports opening links in specific Chrome profiles.
4.  **Multi-Browser:** Supports Brave, Opera, Safari, etc.
5.  **Security:** URL injection protection is critical.

## Architecture
*   **Language:** Swift 5+
*   **UI Framework:** SwiftUI
*   **Pattern:** MVVM (Model-View-ViewModel)
*   **Build System:** Xcode / xcodebuild
*   **Package Manager:** Swift Package Manager (if applicable) or standard Xcode project.

## Key Files & Directories
*   `LinkPaw/`: Main application source.
    *   `LinkPawApp.swift`: Entry point.
    *   `ContentView.swift`: Main UI.
    *   `scripts/firefox-container`: Helper script for Firefox container logic.
*   `scripts/`: Release and utility scripts.
    *   `release.sh`: Release automation.

## Coding Standards
*   **Style:** SwiftLint conventions. Spaces over tabs (4 spaces).
*   **Documentation:** All public methods/classes must have docstrings describing purpose, parameters, and return values.
*   **Error Handling:** Use Swift `Result` type or `do-catch` blocks. Avoid force unwrapping (`!`).
*   **Security:** Sanitize all URLs.

## Development Workflow
1.  **Build:** Use Xcode or `xcodebuild`.
2.  **Test:** Write XCTest cases for logic.
3.  **Release:** Use `./scripts/release.sh <version>`.

## AI Agent Guidelines
*   **Tone:** Professional, concise, technical.
*   **Action:** When fixing bugs, always add a regression test.
*   **Safety:** Never commit secrets. Check for `git` status before committing.
