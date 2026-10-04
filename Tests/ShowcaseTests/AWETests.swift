import XCTest
@testable import ShowcaseCore

/// Thread-safe counter for observing how many times the runner invokes a step
/// or reports progress. `AWE.Step.action` and `Runner.execute(onProgress:)` are
/// both `@Sendable`, so a captured `var` is not legal under strict concurrency —
/// the counter has to be a shared reference.
private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
    }
}

final class AWETests: XCTestCase {
    
    /// Verifies that a simple 3-step workflow completes successfully.
    func testSuccessfulWorkflow() async throws {
        let runner = AWE.Runner()
        
        let step1 = AWE.Step(id: "step1", label: "Step 1") { .success }
        let step2 = AWE.Step(id: "step2", label: "Step 2") { .success }
        let step3 = AWE.Step(id: "step3", label: "Step 3") { .success }
        
        let workflow = AWE.Workflow(name: "Test Success", steps: [step1, step2, step3])
        
        let progressCount = Counter()
        try await runner.execute(workflow) { _ in
            progressCount.increment()
        }
        
        // Progress should be reported for each step start, plus initial and final states
        XCTAssertGreaterThan(progressCount.value, 3)
    }
    
    /// Verifies that the retry logic works as expected.
    func testRetryLogic() async throws {
        let runner = AWE.Runner()
        let attempts = Counter()
        
        let retryStep = AWE.Step(id: "retry_step", label: "Retry Step", retryLimit: 2) {
            attempts.increment()
            if attempts.value < 3 {
                return .retry(reason: "Simulated failure")
            }
            return .success
        }
        
        let workflow = AWE.Workflow(name: "Test Retry", steps: [retryStep])
        
        // Use a shorter backoff for testing if possible, 
        // but since we hardcoded it in AWE, this test might take ~3-4 seconds.
        try await runner.execute(workflow)
        
        XCTAssertEqual(attempts.value, 3, "Step should have been attempted 3 times (1 initial + 2 retries)")
    }
    
    /// Verifies that retries are exhausted and an error is thrown.
    func testRetryExhaustion() async throws {
        let runner = AWE.Runner()
        let attempts = Counter()
        
        let failingStep = AWE.Step(id: "fail_step", label: "Failing Step", retryLimit: 1) {
            attempts.increment()
            return .retry(reason: "Persistent failure")
        }
        
        let workflow = AWE.Workflow(name: "Test Exhaustion", steps: [failingStep])
        
        do {
            try await runner.execute(workflow)
            XCTFail("Workflow should have failed")
        } catch {
            XCTAssertEqual(attempts.value, 2, "Should have attempted twice (initial + 1 retry)")
        }
    }
    
    /// Verifies that fatal errors stop the workflow immediately.
    func testFatalError() async throws {
        let runner = AWE.Runner()
        
        let fatalStep = AWE.Step(id: "fatal_step", label: "Fatal Step") {
            throw NSError(domain: "Test", code: 500, userInfo: nil)
        }
        
        let nextStep = AWE.Step(id: "next_step", label: "Next Step") {
            XCTFail("Next step should not be reached")
            return .success
        }
        
        let workflow = AWE.Workflow(name: "Test Fatal", steps: [fatalStep, nextStep])
        
        do {
            try await runner.execute(workflow)
            XCTFail("Workflow should have failed")
        } catch {
            // Expected
        }
    }
}
