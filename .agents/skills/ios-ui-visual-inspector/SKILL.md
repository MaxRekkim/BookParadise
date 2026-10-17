---
name: ios-ui-visual-inspector
description: Automated iOS Simulator & Mac Catalyst UI Runner, Tapping, Analytics, and Visual Material/Spacing Inspection. Use when testing iOS/macOS apps visually, verifying layout spacing (e.g. book covers, titles, author initials), capturing window screenshots, or running automated clicks/taps and collecting performance analytics.
---

# iOS UI & Visual Material Inspector

## Purpose
Enables autonomous agents to:
1. **Launch & Control Apple Simulator / Mac Catalyst Apps** (Xcode `simctl` or native Mac execution).
2. **Interact & Tap («Тыкать и смотреть как работает»)**: perform taps, clicks, scrolls, navigation transitions via Accessibility API and CLI.
3. **Collect Analytics & Telemetry**: inspect Memory RSS, CPU %, FPS, window geometry, and full Accessibility UI trees.
4. **Inspect Material & Visual Layout Correctness**: detect spacing defects (e.g., book cover touching the title, author initials detached from the title, font clipping, contrast issues) based on Apple Human Interface Guidelines (HIG).

---

## 1. Launching the App / Simulator

### Option A: Mac Catalyst / Designed for iPad (Fastest, zero-runtime download)
Apple Silicon Macs execute the exact same SwiftUI views natively:
```bash
# 1. Build Debug target
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project BookParadise.xcodeproj \
  -scheme BookParadise \
  -destination "generic/platform=macOS,variant=Mac Catalyst" \
  -configuration Debug \
  -derivedDataPath /tmp/DerivedData \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build

# 2. Launch application
open /tmp/DerivedData/Build/Products/Debug-maccatalyst/BookParadise.app

# 3. Bring to front
osascript -e 'tell application "BookParadise" to activate'
```

### Option B: Apple iOS Simulator (`simctl`)
```bash
# 1. List available simulators
xcrun simctl list devices

# 2. Boot simulator and launch GUI
xcrun simctl boot <DEVICE_UUID>
open -a Simulator

# 3. Install & launch app
xcrun simctl install booted /path/to/BookParadise.app
xcrun simctl launch booted com.maxim.bookparadise
```

---

## 2. Interacting & Tapping («Тыкать и смотреть как работает»)

Use the built-in Swift driver [`scripts/ui_driver.swift`](file:///Users/max/.gemini/antigravity/scratch/BookParadise/scripts/ui_driver.swift):

```bash
# 1. Dump UI hierarchy
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift -module-cache-path /tmp/module-cache scripts/ui_driver.swift dump

# 2. Click any UI element by text or accessibility label
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift -module-cache-path /tmp/module-cache scripts/ui_driver.swift click "Библиотека"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift -module-cache-path /tmp/module-cache scripts/ui_driver.swift click "Дашборд"

# 3. iOS Simulator tap via simctl / URL
xcrun simctl openurl booted "bookparadise://book/123"
```

---

## 3. High-Fidelity Screenshots & Visual Capture

Capture the exact window without background occlusion or desktop clutter:
```bash
# Get Window ID of the running app
WID=$(DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift -module-cache-path /tmp/module-cache -e '
import CoreGraphics
import Foundation
let list = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] ?? []
for w in list {
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let bounds = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let h = bounds["Height"] as? Int ?? 0
    let wid = w[kCGWindowNumber as String] as? Int ?? 0
    if (owner == "Книжный Рай" || owner == "BookParadise") && h > 400 {
        print("\(wid)")
        exit(0)
    }
}
exit(1)
')

# Take crisp isolated window screenshot
screencapture -l$WID /tmp/ui_snapshot.png
```

---

## 4. Visual Material & Spacing Inspection

### Layout Guidelines (Apple HIG 8pt Grid):
- **Cover -> Title spacing**: $\in [8..12]\,\text{pt}$.
  - $\Delta < 6\,\text{pt} \implies$ 🚨 **Bug: Cover touching title (вплотную к названию)**.
- **Title -> Author spacing**: $\in [2..6]\,\text{pt}$.
  - $\Delta > 12\,\text{pt} \implies$ 🚨 **Bug: Author detached from title (инициалы автора далеко)**.

### Run Spacing Checker:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift -module-cache-path /tmp/module-cache scripts/ui_driver.swift inspect
```

### Architectural Fix Pattern for SwiftUI Book Grids:
Never use a rigid fixed frame on the title alone while placing author in a parent stack:
```swift
// ❌ WRONG: Causes single-line titles to leave a 24pt gap to author, while cover is only 6pt away
VStack(spacing: 6) {
    BookCoverView(...)
    Text(book.title).frame(height: 32, alignment: .topLeading)
    Text(book.author)
}

// ✅ CORRECT: Title & Author grouped in a tight 3pt stack; Cover separated by 8pt
VStack(alignment: .leading, spacing: 8) {
    BookCoverView(...)
    VStack(alignment: .leading, spacing: 3) {
        Text(book.title).lineLimit(2)
        Text(book.author).lineLimit(1)
    }
    .frame(height: 44, alignment: .topLeading)
}
```
