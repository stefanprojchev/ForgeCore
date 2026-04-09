import Testing
import Foundation
import ForgeCore

@Suite("SendableFileManager")
struct SendableFileManagerTests {

    private let fm = SendableFileManager()
    private let tempDir = URL.temporaryDirectory.appending(path: "ForgeCoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)

    // MARK: - Setup

    private func setUp() throws {
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    private func tearDown() {
        try? fm.removeItem(at: tempDir)
    }

    // MARK: - createDirectory / fileExists

    @Test("Creates directory and verifies it exists")
    func createAndExists() throws {
        try setUp()
        defer { tearDown() }

        let subdir = tempDir.appending(path: "sub", directoryHint: .isDirectory)
        try fm.createDirectory(at: subdir, withIntermediateDirectories: true)

        #expect(fm.fileExists(atPath: subdir.path()))
    }

    @Test("fileExists returns false for non-existent path")
    func fileExistsFalse() {
        #expect(!fm.fileExists(atPath: "/nonexistent/path/\(UUID().uuidString)"))
    }

    // MARK: - removeItem

    @Test("Removes a file")
    func removeFile() throws {
        try setUp()
        defer { tearDown() }

        let file = tempDir.appending(path: "test.txt")
        try Data("hello".utf8).write(to: file)
        #expect(fm.fileExists(atPath: file.path()))

        try fm.removeItem(at: file)
        #expect(!fm.fileExists(atPath: file.path()))
    }

    @Test("Removes a directory recursively")
    func removeDirectory() throws {
        try setUp()
        defer { tearDown() }

        let subdir = tempDir.appending(path: "nested", directoryHint: .isDirectory)
        try fm.createDirectory(at: subdir, withIntermediateDirectories: true)
        try Data("data".utf8).write(to: subdir.appending(path: "file.txt"))

        try fm.removeItem(at: subdir)
        #expect(!fm.fileExists(atPath: subdir.path()))
    }

    // MARK: - copyItem / moveItem

    @Test("Copies a file")
    func copyFile() throws {
        try setUp()
        defer { tearDown() }

        let src = tempDir.appending(path: "source.txt")
        let dst = tempDir.appending(path: "copy.txt")
        try Data("content".utf8).write(to: src)

        try fm.copyItem(at: src, to: dst)

        #expect(fm.fileExists(atPath: src.path()))
        #expect(fm.fileExists(atPath: dst.path()))
    }

    @Test("Moves a file")
    func moveFile() throws {
        try setUp()
        defer { tearDown() }

        let src = tempDir.appending(path: "original.txt")
        let dst = tempDir.appending(path: "moved.txt")
        try Data("content".utf8).write(to: src)

        try fm.moveItem(at: src, to: dst)

        #expect(!fm.fileExists(atPath: src.path()))
        #expect(fm.fileExists(atPath: dst.path()))
    }

    // MARK: - attributesOfItem

    @Test("Returns file attributes")
    func fileAttributes() throws {
        try setUp()
        defer { tearDown() }

        let file = tempDir.appending(path: "attrs.txt")
        try Data("hello".utf8).write(to: file)

        let attrs = try fm.attributesOfItem(atPath: file.path())
        let size = attrs[.size] as? UInt64
        #expect(size == 5)
    }

    // MARK: - contentsOfDirectory

    @Test("Lists directory contents")
    func listContents() throws {
        try setUp()
        defer { tearDown() }

        try Data("a".utf8).write(to: tempDir.appending(path: "a.txt"))
        try Data("b".utf8).write(to: tempDir.appending(path: "b.txt"))

        let contents = try fm.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        #expect(contents.count == 2)
    }

    // MARK: - enumerator

    @Test("Enumerates directory recursively")
    func enumerate() throws {
        try setUp()
        defer { tearDown() }

        let subdir = tempDir.appending(path: "sub", directoryHint: .isDirectory)
        try fm.createDirectory(at: subdir, withIntermediateDirectories: true)
        try Data("a".utf8).write(to: tempDir.appending(path: "root.txt"))
        try Data("b".utf8).write(to: subdir.appending(path: "nested.txt"))

        guard let enumerator = fm.enumerator(
            at: tempDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            #expect(Bool(false), "Enumerator should not be nil")
            return
        }

        let urls = enumerator.compactMap { $0 as? URL }
        #expect(urls.count >= 2)
    }

    // MARK: - Thread Safety

    @Test("Concurrent operations do not crash")
    func concurrentOps() async throws {
        try setUp()
        defer { tearDown() }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask { [fm, tempDir] in
                    let file = tempDir.appending(path: "file-\(i).txt")
                    try? Data("data-\(i)".utf8).write(to: file)
                    _ = fm.fileExists(atPath: file.path())
                }
            }
        }
    }
}
