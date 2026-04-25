import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("App Info") {
                Text("Meshchersky Park Showcase")
                Text("Version 1.0.0 (Swift 6.3)")
            }
            Section("Mirroring") {
                Text("AirPlay Status: Connected")
            }
        }
    }
}
