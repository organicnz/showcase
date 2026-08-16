import SwiftUI

#if os(Android)
/// Dummy Namespace for Android compatibility where matchedGeometryEffect is not yet supported in Skip.
@propertyWrapper
public struct SkipNamespace {
    public struct ID: Hashable, Sendable {
        public init() {}
    }
    
    public init() {}
    
    public var wrappedValue: ID {
        return ID()
    }
    
    public var projectedValue: ID {
        return ID()
    }
}
#endif

#if os(Android)
public typealias NamespaceID = SkipNamespace.ID
#else
public typealias NamespaceID = Namespace.ID
#endif

#if os(Android)
extension View {
    /// No-op fallback for matchedGeometryEffect on Android.
    public func matchedGeometryEffect<ID>(id: ID, in namespace: SkipNamespace.ID, properties: MatchedGeometryProperties = .frame, anchor: UnitPoint = .center, isSource: Bool = true) -> some View where ID : Hashable {
        self
    }
}

/// Dummy MatchedGeometryProperties for Android fallback.
public struct MatchedGeometryProperties: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let frame = MatchedGeometryProperties(rawValue: 1 << 0)
    public static let size = MatchedGeometryProperties(rawValue: 1 << 1)
}
#endif
