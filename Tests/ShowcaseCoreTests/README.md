# ShowcaseCore Integration Tests

This directory contains comprehensive integration tests for the ShowcaseCore module, specifically for the Supabase service layer.

## Test Files

### SupabaseIntegrationTests.swift
Integration tests for the `SupabaseClient` actor that verify:
- ✅ `fetchScenarios()` returns only active scenarios sorted by `order_index`
- ✅ `fetchVideos()` returns only active videos for a scenario sorted by `order_index`
- ✅ `fetchAllVideos()` returns only active videos sorted by `order_index`
- ✅ Storage URL generation for videos, images, and audio
- ✅ Retry logic with transient failures
- ✅ Graceful handling of invalid scenario IDs

**Validates Requirements:** 4.1, 4.2, 4.3, 4.6, 9.2

### VideoServiceTests.swift
Integration tests for the `VideoService` actor with mock `SupabaseClient` that verify:
- ✅ `loadScenarios()` delegates to SupabaseClient correctly
- ✅ `loadScenario()` fetches videos for a specific scenario
- ✅ `loadAllVideos()` fetches all videos for library view
- ✅ Network error mapping (URLError → NetworkError)
- ✅ Offline error handling (NetworkError.offline)
- ✅ Timeout error handling (NetworkError.timeout)
- ✅ Generic error propagation
- ✅ Empty state handling
- ✅ User-friendly error messages

**Validates Requirements:** 1.2, 2.2, 4.6, 9.2, 9.3

### PlaybackStateTests.swift
Unit tests for the `PlaybackState` enum (already existing).

### VideoTests.swift
Unit tests for the `Video` model (already existing).

## Running the Tests

### Option 1: Xcode (Recommended)
1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```
2. Select the `ShowcaseCore` scheme
3. Press `Cmd+U` to run all tests
4. Or use `Cmd+6` to open the Test Navigator and run specific tests

### Option 2: Command Line (Limited)
Due to a Swift Package Manager limitation with `@main` entry points in library targets, running tests via `swift test` may encounter linker errors. The tests compile successfully but cannot be executed via SPM command line.

```bash
# This will build the tests successfully
swift build --target ShowcaseCoreTests

# This may fail with duplicate symbol '_main' error
swift test --filter ShowcaseCoreTests
```

**Workaround:** Use Xcode to run the tests, or temporarily comment out the `@main` attribute in `Sources/ShowcaseApp/ShowcaseApp.swift` when running tests from the command line.

## Test Requirements

### Real Supabase Connection
The `SupabaseIntegrationTests` require a real connection to the Supabase backend. Ensure:
1. The `.env.local` file contains valid `SUPABASE_URL` and `SUPABASE_ANON_KEY`
2. The Supabase database has test data (scenarios and videos)
3. Network connectivity is available

### Mock Testing
The `VideoServiceTests` use a mock `SupabaseClient` and do not require network connectivity. These tests verify:
- Service layer logic
- Error handling and mapping
- Actor isolation correctness

## Test Coverage

| Component | Coverage | Notes |
|-----------|----------|-------|
| SupabaseClient | ✅ Integration | Tests against real Supabase backend |
| VideoService | ✅ Unit + Integration | Tests with mock SupabaseClient |
| NetworkError | ✅ Unit | Tests error descriptions and equality |
| PlaybackState | ✅ Unit | Tests state transitions and computed properties |
| Video | ✅ Unit | Tests Codable, Hashable, and URL generation |
| Scenario | ⚠️ Partial | Covered indirectly through integration tests |

## Adding New Tests

When adding new integration tests:

1. **For SupabaseClient tests:**
   - Add to `SupabaseIntegrationTests.swift`
   - Use `async throws` for test methods
   - Test against real Supabase data
   - Document which requirement is validated

2. **For VideoService tests:**
   - Add to `VideoServiceTests.swift`
   - Use the `MockSupabaseClient` actor
   - Test error handling paths
   - Verify actor isolation

3. **Test naming convention:**
   ```swift
   func test<Component><Action><ExpectedResult>() async throws {
       // Test implementation
   }
   ```

4. **Documentation:**
   - Add doc comments with `/// **Validates: Requirement X.Y**`
   - Explain what the test verifies
   - Include edge cases

## Troubleshooting

### "No such module 'SkipTest'" Error
This is expected during the build process. The `SkipTest` module is conditionally imported for Skip transpilation and doesn't affect Swift-only test execution.

### "Duplicate symbol '_main'" Error
This occurs when running `swift test` from the command line due to the `@main` attribute in `ShowcaseApp.swift`. Use Xcode to run tests instead.

### Tests Fail with Network Errors
Ensure:
- Supabase credentials are configured in `.env.local`
- Network connectivity is available
- Supabase project has test data

### Actor Isolation Warnings
All service layer code uses Swift 6 strict concurrency. Ensure:
- Mock client methods are called with `await`
- Test methods are marked `async throws`
- Actor-isolated properties are accessed through methods

## CI/CD Integration

For automated testing in CI/CD pipelines:

```yaml
# .github/workflows/test.yml
- name: Run Tests
  run: |
    # Set Supabase credentials from secrets
    echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env.local
    echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env.local
    
    # Run tests in Xcode
    xcodebuild test \
      -scheme ShowcaseCore \
      -destination 'platform=macOS'
```

## References

- **Requirements:** `.kiro/specs/meshchersky-park-showcase-app/requirements.md`
- **Design:** `.kiro/specs/meshchersky-park-showcase-app/design.md`
- **Tasks:** `.kiro/specs/meshchersky-park-showcase-app/tasks.md`
- **Swift Concurrency:** [Swift.org - Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- **XCTest:** [Apple Developer - XCTest](https://developer.apple.com/documentation/xctest)
