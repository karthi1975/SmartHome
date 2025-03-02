//
//  CommunicationView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//


import SwiftUI

struct CommunicationView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DeviceDetailView(deviceName: "Zoom Buddy Call")) {
                    Text("Zoom Buddy Call")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Voice Services")) {
                    Text("Voice Services")
                }
                NavigationLink(destination: DeviceDetailView(deviceName: "Sip-N-Puff")) {
                    Text("Sip-N-Puff")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Communication")
        }
    }
}
