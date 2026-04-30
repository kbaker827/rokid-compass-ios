import SwiftUI

struct ContentView: View {
    @StateObject private var vm = CompassViewModel()

    var body: some View {
        TabView {
            CompassView()
                .tabItem { Label("Compass", systemImage: "location.north.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .environmentObject(vm)
        .tint(.green)
    }
}
