import Synchronization

/// Thread-safe mutable state container backed by `Mutex` from the Synchronization framework.
/// Provides exclusive access to mutable state with full Swift 6 concurrency safety.
///
/// `LockedState` is a `final class` so multiple owners can share the same protected state by reference.
/// The underlying `Mutex` is `Sendable`, which makes `LockedState` `Sendable` without any
/// `@unchecked` escape hatches.
public final class LockedState<State>: Sendable {
    private let mutex: Mutex<State>

    public init(_ initial: sending State) {
        self.mutex = Mutex(initial)
    }

    /// Acquires the lock, runs `body` with exclusive access to the protected state, and releases the lock.
    /// Supports throwing closures via typed throws — non-throwing closures use `throws(Never)` and need no `try`.
    public func withLock<R, E: Error>(
        _ body: (inout sending State) throws(E) -> sending R
    ) throws(E) -> sending R {
        try mutex.withLock(body)
    }
}
