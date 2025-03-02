//
//  SecurityView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//


import SwiftUI

struct SecurityView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DeviceDetailView(deviceName: "Alarm Panel")) {
                    Text("Alarm Panel")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Door/Window Sensors")) {
                    Text("Door/Window Sensors")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Occupancy & Presence Sensors")) {
                    Text("Occupancy & Presence Sensors")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Camera Feeds")) {
                    Text("Camera Feeds")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Door Locks")) {
                    Text("Door Locks")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Security")
        }
    }
}
