import Foundation

/// Application constants for content constraints and performance thresholds
public enum Constants {
    // MARK: - Content Constraints
    
    /// Maximum number of videos in the content library
    public static let MAX_VIDEOS = 25
    
    /// Maximum number of scenarios
    public static let MAX_SCENARIOS = 5
    
    /// Maximum video duration in seconds
    public static let MAX_VIDEO_DURATION = 30
    
    // MARK: - Performance Thresholds
    
    /// Video load timeout in seconds
    public static let VIDEO_LOAD_TIMEOUT: TimeInterval = 2.0
    
    /// Minimum bandwidth requirement in Mbps
    public static let MIN_BANDWIDTH: Double = 5.0
}
