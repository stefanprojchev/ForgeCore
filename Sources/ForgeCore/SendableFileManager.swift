import Foundation

/// Sendable interface for file system operations.
public protocol FileManaging: Sendable {
    func fileExists(atPath path: String) -> Bool
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
    func enumerator(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options: FileManager.DirectoryEnumerationOptions
    ) -> FileManager.DirectoryEnumerator?
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func removeItem(at url: URL) throws
    func copyItem(at src: URL, to dst: URL) throws
    func moveItem(at src: URL, to dst: URL) throws
}

/// Default implementation wrapping `FileManager.default`.
/// Assumes all called methods are thread-safe per Apple's documentation.
/// Do not set `FileManager.default.delegate` from other threads when using this.
public struct SendableFileManager: FileManaging {
    // MARK: - Properties

    /// `FileManager.default` is thread-safe per Apple's documentation. Accessed via a computed
    /// property so we don't need to store a non-Sendable reference inside this `Sendable` struct.
    private var fm: FileManager { FileManager.default }

    // MARK: - Initialization

    public init() {}

    // MARK: - Implementation

    public func fileExists(atPath path: String) -> Bool {
        fm.fileExists(atPath: path)
    }

    public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try fm.attributesOfItem(atPath: path)
    }

    public func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: options)
    }

    public func enumerator(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options: FileManager.DirectoryEnumerationOptions
    ) -> FileManager.DirectoryEnumerator? {
        fm.enumerator(at: url, includingPropertiesForKeys: keys, options: options)
    }

    public func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fm.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }

    public func removeItem(at url: URL) throws {
        try fm.removeItem(at: url)
    }

    public func copyItem(at src: URL, to dst: URL) throws {
        try fm.copyItem(at: src, to: dst)
    }

    public func moveItem(at src: URL, to dst: URL) throws {
        try fm.moveItem(at: src, to: dst)
    }
}
