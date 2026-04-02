# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build
xcodebuild -scheme Dark -configuration Debug build

# Run all tests
xcodebuild -scheme Dark -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run unit tests only
xcodebuild -scheme DarkTests -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run UI tests only
xcodebuild -scheme DarkUITests -destination 'platform=iOS Simulator,name=iPhone 16' test

# Clean
xcodebuild clean -scheme Dark
```

## Project Overview

Native SwiftUI app targeting iOS 26.4 / macOS 26.4 / xrOS 26.4, built with Xcode. Bundle ID: `com.SamuraiStudios.Dark`.

**Three targets:**
- `Dark` — main application
- `DarkTests` — unit tests using the Swift Testing framework (`import Testing`, `#expect`, `#require`)
- `DarkUITests` — UI automation tests using XCTest (`XCUIApplication`)

## Architecture

Currently in early/template state. Entry point is [Dark/DarkApp.swift](Dark/DarkApp.swift) (`@main`), which creates a `WindowGroup` with [Dark/ContentView.swift](Dark/ContentView.swift).

## Testing Notes

Unit tests use the **Swift Testing** framework (not XCTest). Use `@Test`, `#expect()`, and `#require()` macros — not `XCTAssert*`. UI tests still use XCTest/XCUITest.
