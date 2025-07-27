import SwiftUI

@main
struct CrossSumsMacApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MacMainMenuView()
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 700)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if os(macOS)
struct SettingsView: View {
    var body: some View {
        VStack {
            Text("CrossSums Settings")
                .font(.title2)
                .padding()
            
            Text("Settings will be added here")
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(width: 400, height: 300)
    }
}
#endif