import Foundation

#if canImport(OSLog)
import OSLog
public let logger: Logger = Logger(subsystem: "site.app.showcase", category: "Showcase")
#else
public struct Logger: Sendable {
    public init(subsystem: String, category: String) {}
    public func debug(_ message: String) { print("DEBUG: \(message)") }
    public func info(_ message: String) { print("INFO: \(message)") }
    public func warning(_ message: String) { print("WARNING: \(message)") }
    public func error(_ message: String) { print("ERROR: \(message)") }
}
public let logger = Logger(subsystem: "site.app.showcase", category: "Showcase")
#endif
