# ForgeCore

Thread-safe primitives for iOS Swift packages.

![Swift 6.3+](https://img.shields.io/badge/Swift-6.3+-orange.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18+-blue.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
[![Release](https://img.shields.io/github/v/release/stefanprojchev/ForgeCore)](https://github.com/stefanprojchev/ForgeCore/releases)

---

ForgeCore is the shared foundation for the **Forge** family of iOS packages. It provides a small, focused set of thread-safe primitives built on Swift 6's `Synchronization` framework.

Most consumers use ForgeCore indirectly through other Forge packages. You only import it directly when you need its primitives in your own code.

## Features

- **`LockedState<State>`** — thread-safe mutable state container wrapping `Mutex<State>` from the standard library `Synchronization` framework. Typed-throws, `sending` parameter semantics, no `@unchecked Sendable` escape hatches.
- **`SendableFileManager`** — a `Sendable`-conforming wrapper around `FileManager` for safe use in concurrent contexts.
- **Zero dependencies** — ForgeCore has no external dependencies beyond the Swift standard library and Foundation.

## Requirements

- **iOS** 18+
- **macOS** 15+
- **Swift** 6.3+ (Xcode 26 or later)

## Installation

### Xcode

1. **File → Add Package Dependencies…**
2. Paste `https://github.com/stefanprojchev/ForgeCore.git`
3. Set rule to **Up to Next Major** from `1.0.0`

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/stefanprojchev/ForgeCore.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["ForgeCore"]
    )
]
```

## Quick Start

### LockedState

```swift
import ForgeCore

// Thread-safe mutable state — no locks, no @unchecked, no races.
let cache = LockedState<[String: User]>([:])

cache.withLock { dict in
    dict["alice"] = User(name: "Alice")
}

let alice = cache.withLock { $0["alice"] }
```

Typed-throws propagate concrete error types:

```swift
enum CacheError: Error { case full }

do {
    try cache.withLock { (dict: inout [String: User]) throws(CacheError) in
        guard dict.count < 100 else { throw CacheError.full }
        dict["bob"] = User(name: "Bob")
    }
} catch {
    // error is statically typed as CacheError
}
```

### SendableFileManager

```swift
import ForgeCore

let fm = SendableFileManager()

// Pass freely across isolation domains — it's Sendable.
actor FileService {
    let fm: FileManaging

    init(fm: FileManaging = SendableFileManager()) {
        self.fm = fm
    }

    func exists(_ path: String) -> Bool {
        fm.fileExists(atPath: path)
    }
}
```

## The Forge Family

ForgeCore is part of the **Forge** family of Swift packages for iOS.

| Package | Description |
|---|---|
| **ForgeCore** | Thread-safe primitives for iOS Swift packages. |
| [ForgeInject](https://github.com/stefanprojchev/ForgeInject) | Dependency injection with constructor and property wrapper support. |
| [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) | Reactive system observers — connectivity, lifecycle, keyboard, and more. |
| [ForgeStorage](https://github.com/stefanprojchev/ForgeStorage) | Type-safe key-value, file, and Keychain storage. |
| [ForgeDB](https://github.com/stefanprojchev/ForgeDB) | Type-safe repository pattern and GRDB-backed SQLite persistence. |
| [ForgeOrchestrator](https://github.com/stefanprojchev/ForgeOrchestrator) | Orchestrate app flows — startup gates, data pipelines, and continuous monitors. |
| [ForgePush](https://github.com/stefanprojchev/ForgePush) | Push notification management — permissions, tokens, and routing. |
| [ForgeLocation](https://github.com/stefanprojchev/ForgeLocation) | Location triggers — geofencing, significant changes, and visits. |
| [ForgeBackgroundTasks](https://github.com/stefanprojchev/ForgeBackgroundTasks) | Background task scheduling and dispatch. |

## License

ForgeCore is released under the MIT License. See [LICENSE](LICENSE).
