import SwiftUI
#if canImport(AVKit) && !os(macOS)
import AVKit

/// A wrapper around AVRoutePickerView to provide an AirPlay button in SwiftUI.
struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.activeTintColor = UIColor(Color.terracotta)
        routePickerView.tintColor = .white
        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // No updates needed
    }
}
#else
struct AirPlayView: View {
    var body: some View {
        Image(systemName: "airplayvideo")
            .foregroundStyle(.white)
    }
}
#endif
