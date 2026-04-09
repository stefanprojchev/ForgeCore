# ForgeCore

Thread-safe utilities for Swift concurrency — `LockedState` and `SendableFileManager`.

## Requirements

- iOS 16+
- Swift 6.0+

## Installation

### Swift Package Manager

Add ForgeCore to your project via Xcode:

1. **File > Add Package Dependencies...**
2. Enter the repository URL
3. Select the version rule and add to your target

Or add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/stefanprojchev/ForgeCore.git", from: "1.0.0")
]
```

## Quick Start

```swift
import ForgeCore

// Thread-safe mutable state
let counter = LockedState(0)
counter.withLock { $0 += 1 }
let value = counter.withLock { $0 } // 1

// Sendable file manager
let fm = SendableFileManager()
if fm.fileExists(atPath: "/tmp/data.json") {
    try fm.removeItem(at: URL(fileURLWithPath: "/tmp/data.json"))
}
```

## LockedState

A thread-safe mutable state container backed by `NSLock`. The enclosing type can be plain `Sendable` — the wrapped `State` does not need to conform to `Sendable` itself.

```swift
let state = LockedState(MyMutableState())

// Exclusive read/write access
state.withLock { $0.count += 1 }

// Return values from the lock
let snapshot = state.withLock { $0 }

// Throwing closures are supported
try state.withLock { try $0.validate() }
```

## SendableFileManager

A `Sendable` wrapper around `FileManager.default` conforming to the `FileManaging` protocol. Use it anywhere you need file system operations in a concurrent context.

```swift
let fm = SendableFileManager()

fm.fileExists(atPath: path)
try fm.createDirectory(at: url, withIntermediateDirectories: true)
try fm.copyItem(at: source, to: destination)
try fm.moveItem(at: source, to: destination)
try fm.removeItem(at: url)
```

The `FileManaging` protocol enables dependency injection — swap in a mock for tests.

## Thread Safety

`LockedState` uses `NSLock` for exclusive access. `SendableFileManager` delegates to `FileManager.default`, which Apple documents as thread-safe. Both types conform to `Sendable`.

## Forge Ecosystem

ForgeCore is part of the **Forge** family of Swift packages for iOS:

| Package | Description |
|---------|-------------|
| **ForgeCore** | Thread-safe utilities — `LockedState` and `SendableFileManager` |
| [ForgeInject](https://github.com/stefanprojchev/ForgeInject) | Lightweight dependency injection with property wrapper |
| [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) | Reactive system observers (connectivity, lifecycle, keyboard, and more) |
| [ForgeStorage](https://github.com/stefanprojchev/ForgeStorage) | Type-safe persistence — key-value, file storage, and Keychain |
| [ForgeBackgroundTasks](https://github.com/stefanprojchev/ForgeBackgroundTasks) | BGTaskScheduler registration, scheduling, and dispatch |
| [ForgeLocation](https://github.com/stefanprojchev/ForgeLocation) | Location-based triggers — geofencing, significant changes, visits |
| [ForgePush](https://github.com/stefanprojchev/ForgePush) | Push notification management — permissions, tokens, silent and visible routing |
| [ForgeOrchestrator](https://github.com/stefanprojchev/ForgeOrchestrator) | Sequence, pipeline, and monitor orchestrators for iOS app flows |

## License

MIT License. See [LICENSE](LICENSE) for details.
