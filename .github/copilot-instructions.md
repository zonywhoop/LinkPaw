# LinkPaw Copilot Instructions

You are an AI coding assistant for the LinkPaw project.
LinkPaw is a macOS browser picker/shim written in Swift using SwiftUI.

## Project Context
-   **Goal:** Intercept links and choose browser/container (Firefox, Chrome, etc.).
-   **Key Files:**
    -   `LinkPaw/LinkPawApp.swift`: App entry.
    -   `LinkPaw/ContentView.swift`: Main UI.
    -   `LinkPaw/scripts/firefox-container`: Logic for opening Firefox containers.

## Guidelines
1.  **Swift/SwiftUI:** Follow modern Swift conventions. Use MVVM.
2.  **Security:** Sanitize all URL inputs. Prevent command injection in shell calls.
3.  **Documentation:** Add docstrings to all functions and types.
4.  **Testing:** Suggest unit tests for new logic.

## Reference
See `docs/AI_CONTEXT.md` for full project details.
