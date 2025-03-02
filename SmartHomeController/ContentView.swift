//
//  ContentView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FavoritesView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
            
            SecurityView()
                .tabItem {
                    Image(systemName: "shield.fill")
                    Text("Security")
                }
            
            CommunicationView()
                .tabItem {
                    Image(systemName: "phone.fill")
                    Text("Communication")
                }
            
            AutomationsView()
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Automations")
                }
            
            BatteryManagementView()
                .tabItem {
                    Image(systemName: "battery.100")
                    Text("Battery")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}
