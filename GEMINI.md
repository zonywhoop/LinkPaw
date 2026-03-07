# Project Context: Marketplace

## 1. Project Overview
**Goal:** Provide a web browser for MacOS that will prompt to the user with a list of available browsers and containers/profiles to open a clicked link in.
**Core Features:** 
  1. Get a list of FireFox containers
  2. Get a list of Google Chrome profiles
  3. Get a list of other installed browsers such as Brave, Opera, etc and show those as options as well.
  4. Create a web browser shim for MacOS that when a link is clicked and opened in the app, a small window will appear and allow the selection of what browser the link will open in.
  5. Open the link the selected browser container or profile

**Notes:** 
  1. The script `scripts/firefox-container` has everything needed to open a URL in a FireFox container using the plugin from `https://github.com/honsiorovskyi/open-url-in-container`.
  2. Use the Switch language in an Xcode project so we have have properly signed MacOS builds
  3. Produce a new build after any code changes and fix any issues that come up
  4. All code should be written to protect against URL injection and escape attacks and use best practices from OWASP

## 2. Coding Conventions
*   **Style:** Use spaces over tabs. Ensure all methods and classes are documented to include 1. intended purpose, 2. input names and types, 3. output types and expected values
*   **Language:** Use Swift as the application language of choice
