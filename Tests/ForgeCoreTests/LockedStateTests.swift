import Testing
import Foundation
import ForgeCore

@Suite("LockedState")
struct LockedStateTests {

    // MARK: - Basic Operations

    @Test("Reads initial value")
    func readsInitialValue() {
        let state = LockedState(42)
        let value = state.withLock { $0 }
        #expect(value == 42)
    }

    @Test("Mutates value in place")
    func mutatesValue() {
        let state = LockedState(0)
        state.withLock { $0 += 10 }
        let value = state.withLock { $0 }
        #expect(value == 10)
    }

    @Test("Returns value from closure")
    func returnsFromClosure() {
        let state = LockedState(["a": 1, "b": 2])
        let count = state.withLock { $0.count }
        #expect(count == 2)
    }

    @Test("Throwing closure propagates error")
    func throwingClosure() {
        let state = LockedState(0)

        #expect(throws: TestError.self) {
            try state.withLock { _ -> Int in
                throw TestError.failed
            }
        }
    }

    @Test("Throwing closure does not corrupt state on failure")
    func throwingDoesNotCorrupt() {
        let state = LockedState(5)

        try? state.withLock { state -> Void in
            state = 99
            throw TestError.failed
        }

        // State was mutated before the throw — that's expected.
        // The point is the lock is released and state is accessible.
        let value = state.withLock { $0 }
        #expect(value == 99)
    }

    // MARK: - Complex State

    @Test("Works with struct state")
    func structState() {
        struct Counter: Sendable {
            var value = 0
        }

        let state = LockedState(Counter())
        state.withLock { $0.value += 1 }
        state.withLock { $0.value += 1 }
        let count = state.withLock { $0.value }
        #expect(count == 2)
    }

    @Test("Works with dictionary state")
    func dictionaryState() {
        let state = LockedState<[String: Int]>([:])
        state.withLock { $0["key"] = 42 }
        let value = state.withLock { $0["key"] }
        #expect(value == 42)
    }

    @Test("Works with non-Sendable state")
    func nonSendableState() {
        let state = LockedState<[() -> Void]>([])
        state.withLock { $0.append { } }
        let count = state.withLock { $0.count }
        #expect(count == 1)
    }

    // MARK: - Thread Safety

    @Test("Concurrent increments produce correct total")
    func concurrentIncrements() async {
        let state = LockedState(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    state.withLock { $0 += 1 }
                }
            }
        }

        let total = state.withLock { $0 }
        #expect(total == 1000)
    }

    @Test("Concurrent reads and writes do not crash")
    func concurrentReadsAndWrites() async {
        let state = LockedState<[String: Int]>([:])

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    state.withLock { $0["key-\(i)"] = i }
                }
                group.addTask {
                    _ = state.withLock { $0["key-\(i)"] }
                }
            }
        }
    }

    @Test("Concurrent mixed operations produce consistent state")
    func concurrentMixedOps() async {
        let state = LockedState<Set<Int>>([])

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    state.withLock { _ = $0.insert(i) }
                }
            }
        }

        let count = state.withLock { $0.count }
        #expect(count == 100)
    }

    // MARK: - Typed Throws

    @Test("Typed throws preserves the concrete error type")
    func typedThrowsPreservesType() {
        enum SpecificError: Error, Equatable {
            case alpha
            case beta
        }

        let state = LockedState(0)

        // The closure uses typed throws. Because `withLock` forwards the error type parameter,
        // the catch clause can bind a concrete `SpecificError` without `as` casting.
        do {
            try state.withLock { (_: inout Int) throws(SpecificError) in
                throw SpecificError.alpha
            }
            Issue.record("Expected SpecificError.alpha to be thrown")
        } catch {
            // `error` has static type `SpecificError` here — no `any Error` erasure.
            #expect(error == .alpha)
        }
    }

    @Test("Lock is released after closure throws under concurrent load")
    func lockReleasedAfterConcurrentThrows() async {
        struct Boom: Error {}

        let state = LockedState(0)

        // Half the tasks throw, half mutate. If the lock isn't released on throw,
        // the mutating tasks would starve or the final count would be wrong.
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<200 {
                if i.isMultiple(of: 2) {
                    group.addTask {
                        try? state.withLock { _ -> Void in
                            throw Boom()
                        }
                    }
                } else {
                    group.addTask {
                        state.withLock { $0 += 1 }
                    }
                }
            }
        }

        let total = state.withLock { $0 }
        #expect(total == 100)
    }

    @Test("State protected across actor isolation boundaries")
    func statePreservedAcrossActors() async {
        actor Consumer {
            var lastSeen: Int = 0
            func update(to value: Int) {
                lastSeen = value
            }
        }

        let state = LockedState(0)
        let consumer = Consumer()

        // Multiple tasks on different isolation domains all touch the same LockedState,
        // then publish their observation to an actor. No races, no data corruption.
        await withTaskGroup(of: Int.self) { group in
            for i in 1...50 {
                group.addTask {
                    state.withLock { $0 = i }
                    return state.withLock { $0 }
                }
            }
            for await value in group {
                await consumer.update(to: value)
            }
        }

        // The final value is whichever task happened to run last; the invariant is
        // that we reached the actor without crashing and that state is non-zero.
        let lastSeen = await consumer.lastSeen
        #expect(lastSeen >= 1)
        #expect(lastSeen <= 50)
    }

    @Test("Recursive calls from the same task deadlock-safe via sequential access")
    func sequentialAccessDoesNotDeadlock() {
        // LockedState / Mutex is NOT re-entrant. Ensure sequential (non-nested) calls
        // on the same task are fine — catches regressions where we accidentally
        // introduce recursive locking.
        let state = LockedState(0)

        for _ in 0..<100 {
            state.withLock { $0 += 1 }
        }

        #expect(state.withLock { $0 } == 100)
    }
}
