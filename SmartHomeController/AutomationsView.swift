//
//  AutomationsView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//


import SwiftUI

struct AutomationsView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DeviceDetailView(deviceName: "Wake Up")) {
                    Text("Wake Up")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Sleep")) {
                    Text("Sleep")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Arm/Disarm Security")) {
                    Text("Arm/Disarm Security")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Automations")
        }
    }
}
