import Foundation

/// **Antigravity Workflow Engine (AWE)**
///
/// A minimal, production-ready engine for executing multi-step asynchronous tasks.
/// Designed with clear separation between definition and execution.
public enum AWE {
    
    // MARK: - Core Types
    
    /// The result of a single workflow step.
    public enum StepResult: Sendable {
        case success
        case failure(Error)
        case retry(reason: String)
    }
    
    /// A single unit of work within a workflow.
    public struct Step: Sendable, Identifiable {
        public let id: String
        public let label: String
        public let action: @Sendable () async throws -> StepResult
        public let retryLimit: Int
        
        public init(
            id: String,
            label: String,
            retryLimit: Int = 3,
            action: @escaping @Sendable () async throws -> StepResult
        ) {
            self.id = id
            self.label = label
            self.retryLimit = retryLimit
            self.action = action
        }
    }
    
    /// A collection of steps to be executed in sequence.
    public struct Workflow: Sendable {
        public let id: UUID
        public let name: String
        public let steps: [Step]
        
        public init(name: String, steps: [Step]) {
            self.id = UUID()
            self.name = name
            self.steps = steps
        }
    }
    
    /// The current state of a running workflow.
    public struct WorkflowState: Sendable, Codable {
        public let workflowId: UUID
        public var currentStepIndex: Int
        public var completedSteps: [String]
        public var status: Status
        
        public enum Status: String, Codable, Sendable {
            case pending, running, completed, failed
        }
    }
    
    // MARK: - Runner
    
    /// The execution engine for workflows.
    /// Isolated to an actor to ensure thread-safe state management during execution.
    public actor Runner {
        private var activeWorkflows: [UUID: WorkflowState] = [:]
        
        public init() {}
        
        /// Executes a workflow step-by-step.
        ///
        /// - Parameters:
        ///   - workflow: The workflow to execute.
        ///   - progress: An optional closure to track progress updates.
        public func execute(_ workflow: Workflow, onProgress: (@Sendable (WorkflowState) -> Void)? = nil) async throws {
            var state = WorkflowState(
                workflowId: workflow.id,
                currentStepIndex: 0,
                completedSteps: [],
                status: .running
            )
            
            activeWorkflows[workflow.id] = state
            onProgress?(state)
            
            for (index, step) in workflow.steps.enumerated() {
                state.currentStepIndex = index
                onProgress?(state)
                
                let result = try await executeStepWithRetries(step)
                
                switch result {
                case .success:
                    state.completedSteps.append(step.id)
                case .failure(let error):
                    state.status = .failed
                    onProgress?(state)
                    throw error
                case .retry(let reason):
                    // Should not happen if retries are exhausted in executeStepWithRetries
                    state.status = .failed
                    onProgress?(state)
                    throw NSError(domain: "AWE", code: 1, userInfo: [NSLocalizedDescriptionKey: "Retry limit exhausted: \(reason)"])
                }
            }
            
            state.status = .completed
            activeWorkflows[workflow.id] = state
            onProgress?(state)
        }
        
        private func executeStepWithRetries(_ step: Step) async throws -> StepResult {
            var attempts = 0
            
            while attempts <= step.retryLimit {
                do {
                    let result = try await step.action()
                    if case .retry(let reason) = result {
                        attempts += 1
                        logger.warning("AWE: Step '\(step.label)' requested retry. Reason: \(reason). Attempt \(attempts)/\(step.retryLimit)")
                        try await backoff(attempt: attempts)
                        continue
                    }
                    return result
                } catch {
                    attempts += 1
                    if attempts > step.retryLimit {
                        return .failure(error)
                    }
                    logger.warning("AWE: Step '\(step.label)' failed with error: \(error). Retrying \(attempts)/\(step.retryLimit)")
                    try await backoff(attempt: attempts)
                }
            }
            
            return .failure(NSError(domain: "AWE", code: 2, userInfo: [NSLocalizedDescriptionKey: "Max retries reached for step: \(step.label)"]))
        }
        
        private func backoff(attempt: Int) async throws {
            let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
            try await Task.sleep(nanoseconds: delay)
        }
    }
}
