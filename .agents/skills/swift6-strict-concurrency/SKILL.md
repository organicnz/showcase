---
name: swift6-strict-concurrency
description: Strict concurrency safety standards and architectural patterns for Swift 6.3+. Use when working with actors, @Observable view models on @MainActor, Sendable models, structured concurrency, task cancellation, and data-race elimination across iOS and Android (Skip).
---

# Swift 6 Strict Concurrency Mastery

The Showcase codebase targets **Swift 6.3.1** with **Complete Strict Concurrency Checking** enabled (`SWIFT_STRICT_CONCURRENCY = complete`). This skill enforces data-race freedom and thread safety across all core logic, view models, and background execution services.

---

## 1. Concurrency Boundaries & Actor Model

In the Showcase architecture:
* **UI State & Presentation:** Isolated to `@MainActor` (SwiftUI views, `@Observable` ViewModels).
* **Network & Database Client:** Isolated to background actors (`SupabaseManager`, `AWE.Runner`).
* **Data Transfer Objects:** Immutable `Sendable` structs.

```
┌──────────────────────────────────────────────┐
│  @MainActor (UI & ViewModel)                 │
│  - ShowcaseViewModel (@Observable)           │
│  - SwiftUI Views                             │
└──────────────────────┬───────────────────────┘
                       │ await (across isolation)
┌──────────────────────▼───────────────────────┐
│  Actor Isolation (Background I/O)            │
│  - SupabaseManager                           │
│  - AWE.Runner                                │
│  - URLCache / Network Pipeline               │
└──────────────────────────────────────────────┘
```

---

## 2. Actor Guidelines (`SupabaseManager`)

1. **All I/O must remain inside the actor:**
   ```swift
   public actor SupabaseManager {
       public static let shared = SupabaseManager()
       private let client: SupabaseClient

       public func fetchScenarios() async throws -> [Scenario] {
           return try await client
               .from("scenarios")
               .select()
               .order("order_index")
               .execute()
               .value
       }
   }
   ```

2. **Synchronous Pure Functions (`nonisolated`):**
   If a method performs pure string formatting or computation and does not touch actor-isolated mutable state, mark it `nonisolated` so callers don't incur async hop overhead:
   ```swift
   public nonisolated func publicVideoURL(for storagePath: String) -> URL? {
       // Pure URL construction without mutating actor state
       guard let baseURL = URL(string: Self.supabaseURL) else { return nil }
       return baseURL.appendingPathComponent("storage/v1/object/public/\(storagePath)")
   }
   ```

---

## 3. View Models with `@MainActor` & `@Observable`

All reactive view models driving SwiftUI views must be decorated with `@MainActor`:

```swift
@MainActor
@Observable
public final class ShowcaseViewModel {
    public private(set) var scenarios: [Scenario] = []
    public private(set) var activeScenario: Scenario?
    public private(set) var isLoading: Bool = false
    public var errorMessage: String?

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Await actor-isolated fetch without blocking the main thread
            let fetched = try await SupabaseManager.shared.fetchScenarios()
            self.scenarios = fetched
            self.activeScenario = fetched.first
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
```

---

## 4. `Sendable` Conformance Rules

Every model transferred across actors must conform to `Sendable`:
* **Use Structs:** Use value types with immutable (`let`) stored properties.
* **Collections of Sendables:** `[Scenario]`, `[Video]`, and `[String]` are automatically `Sendable`.
* **Enums:** Enums with `Sendable` associated values are `Sendable`.
* **Closures:** Any closure crossing an actor boundary must be marked `@Sendable`:
  ```swift
  public func performOperation(completion: @escaping @Sendable (Result<Data, Error>) -> Void)
  ```

### Example Model:
```swift
public struct Video: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let scenarioId: UUID
    public let title: String
    public let subtitle: String?
    public let storagePath: String
    public let durationSec: Int?
    public let orderIndex: Int
    public let active: Bool
}
```

---

## 5. Structured Concurrency & Task Cancellation

* **Never use unstructured `Task.detached`:** Use structured `async let` or `TaskGroup`.
* **Respect Cooperative Cancellation:** Check `Task.isCancelled` during long loops, prefetching, or batch downloads:
  ```swift
  for video in videos {
      try Task.checkCancellation()
      await prefetchThumbnail(for: video)
  }
  ```
* **Clean up on View Disappearance:** Store active `Task` handles in the view model and cancel them in `.onDisappear` or `deinit`.

---

## 6. Skip & Kotlin Coroutines Bridge

When transpiled by Skip into Kotlin:
* `actor` maps to a Kotlin thread-safe state holder or Mutex-guarded class.
* `@MainActor` maps to Kotlin's `Dispatchers.Main`.
* `async/await` maps directly to Kotlin `suspend` functions.
* Adhering strictly to standard Swift 6 concurrency ensures that the generated Kotlin code utilizes idiomatic Coroutines without thread deadlock or state race conditions.
