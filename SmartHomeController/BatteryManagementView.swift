//
//  BatteryManagementView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//


import SwiftUI

struct BatteryManagementView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DeviceDetailView(deviceName: "Battery Management")) {
                    Text("Battery Management")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Battery")
        }
    }
}