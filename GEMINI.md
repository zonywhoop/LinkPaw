# Project Context: Marketplace

## 1. Project Overview
**Goal:** Create a method of getting the tab container list from FireFox and creating browsers in MacOs that launch urls in those specific containers.
**Core Features:** 
  1. Get a list of FireFox containers
  2. Get a list of Google Chrome profiles
  3. Create a web browser shim for MacOS that when a link is clicked and opened in the app, a small window will appear and allow the selection of what browser the link will open in.
  4. Open the link the selected browser container or profile
**Notes:** 
  1. The script `scripts/firefox-container` has everything needed to open a URL in a FireFox container using the plugin from `https://github.com/honsiorovskyi/open-url-in-container`.
  2. Use the language best supported on an out of the box version of MacOS
  3. Produce a new build after any code changes and fix any issues that come up
  4. All code should be written to protect against URL injection and escape attacks and use best practices from OWASP

## 2. Coding Conventions

If you have specific coding rules, list them here.

*   **Style:** Use spaces over tabs. Ensure all methods and classes are documented to include 1. intended purpose, 2. input names and types, 3. output types and expected values
*   **Language:** Use Swift as the application language of choice
