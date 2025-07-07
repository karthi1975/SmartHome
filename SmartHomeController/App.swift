import SwiftUI

@main
struct SmartHomeControllerApp: App {
    @StateObject var deviceStore = DeviceStore()
    @StateObject var callManager = CallManager()
    @StateObject var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deviceStore)
                .environmentObject(callManager)
                .environmentObject(appState)
        }
    }
} 