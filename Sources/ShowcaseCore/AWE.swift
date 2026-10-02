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
    // Moved to Models.swift for shared access
    public typealias WorkflowState = ShowcaseCore.WorkflowState
    
    // MARK: - Runner
    
    /// The execution engine for workflows.
    /// Isolated to an actor to ensure thread-safe state management during execution.
    ///
    /// - Note: DB persistence is **opt-in** (`persist: false` by default).
    ///   The read-only "Initial Load" workflow runs on every app launch —
    ///   persisting its state to `workflow_states` on every launch costs
    ///   1 SELECT + N UPSERTs per device per launch for zero user value and
    ///   was a measurable source of Disk IO / WAL bloat (each launch inserted
    ///   a new row because the workflow id is random per launch).
    ///   Only pass `persist: true` for long-running *write* workflows that
    ///   genuinely need crash-resume.
    public actor Runner {
        private var activeWorkflows: [UUID: WorkflowState] = [:]

        public init() {}

        /// Executes a workflow step-by-step.
        ///
        /// - Parameters:
        ///   - workflow: The workflow to execute.
        ///   - persist: When `true`, load/persist state in Supabase
        ///     `workflow_states` for crash-resume. Defaults to `false`
        ///     (in-memory only — no DB IO).
        ///   - onProgress: An optional closure to track progress updates.
        public func execute(
            _ workflow: Workflow,
            persist: Bool = false,
            onProgress: (@Sendable (WorkflowState) -> Void)? = nil
        ) async throws {
            // Only touch the database when crash-resume is actually needed.
            let existingState: WorkflowState? = if persist {
                try? await SupabaseManager.shared.fetchWorkflowState(name: workflow.name)
            } else {
                nil
            }

            var state = existingState ?? WorkflowState(
                id: workflow.id,
                workflowName: workflow.name,
                currentStepIndex: 0,
                completedSteps: [],
                status: .running,
                updatedAt: Date()
            )

            state.status = .running
            activeWorkflows[workflow.id] = state
            // Evict on scope exit (success or throw): entries are keyed by a
            // per-run UUID, so without this the dictionary grows by one entry
            // per execution for the lifetime of the process.
            defer { activeWorkflows.removeValue(forKey: workflow.id) }
            onProgress?(state)

            // Resume from persisted position only when persistence is on;
            // otherwise always start from step 0 (fresh in-memory state).
            let startIndex = persist ? state.currentStepIndex : 0

            for index in startIndex..<workflow.steps.count {
                let step = workflow.steps[index]
                state.currentStepIndex = index
                state.updatedAt = Date()

                // Persist state to Supabase only when opted in.
                if persist {
                    try? await SupabaseManager.shared.updateWorkflowState(state)
                }
                onProgress?(state)

                let result = try await executeStepWithRetries(step)

                switch result {
                case .success:
                    state.completedSteps.append(step.id)
                case .failure(let error):
                    state.status = .failed
                    state.updatedAt = Date()
                    if persist {
                        try? await SupabaseManager.shared.updateWorkflowState(state)
                    }
                    onProgress?(state)
                    throw error
                case .retry(let reason):
                    state.status = .failed
                    state.updatedAt = Date()
                    if persist {
                        try? await SupabaseManager.shared.updateWorkflowState(state)
                    }
                    onProgress?(state)
                    throw NSError(domain: "AWE", code: 1, userInfo: [NSLocalizedDescriptionKey: "Retry limit exhausted: \(reason)"])
                }
            }

            state.status = .completed
            state.updatedAt = Date()
            if persist {
                try? await SupabaseManager.shared.updateWorkflowState(state)
            }
            // NOTE: no activeWorkflows write here — the dictionary is
            // write-only bookkeeping and defer evicts the entry on exit.
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
            let seconds = Int(pow(2.0, Double(attempt)))
            try await Task.sleep(for: .seconds(seconds))
        }
    }
}
