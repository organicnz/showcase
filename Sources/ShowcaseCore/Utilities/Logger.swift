import Foundation

/// Simple logging utility for the Showcase app
public enum Logger {
    public static func error(_ message: String, error: Error? = nil) {
        #if DEBUG
        print("❌ ERROR: \(message)")
        if let error = error {
            print("   Details: \(error)")
        }
        #endif
    }

    public static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ INFO: \(message)")
        #endif
    }

    public static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ WARNING: \(message)")
        #endif
    }

    public static func debug(_ message: String) {
        #if DEBUG
        print("🔍 DEBUG: \(message)")
        #endif
    }
}
