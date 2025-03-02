//
//  SmartHomeControllerApp.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//
import SwiftUI
    

// MARK: - Main App Entry
@main
struct SmartHomeControllerApp: App {
    @StateObject var api = HomeAssistantAPI()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
        }
    }
}
