//
//  FavoritesView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//


import SwiftUI

struct FavoritesView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Room 1")) {
                    NavigationLink(destination: DeviceDetailView(deviceName: "TV")) {
                        Text("TV")
                    }
                    NavigationLink(destination: DeviceDetailView(deviceName: "AppleTV")) {
                        Text("AppleTV")
                    }
                    NavigationLink(destination: DeviceDetailView(deviceName: "Roku")) {
                        Text("Roku")
                    }
                    NavigationLink(destination: DeviceDetailView(deviceName: "HVAC")) {
                        Text("HVAC")
                    }
                    NavigationLink(destination: DeviceDetailView(deviceName: "Light Switch")) {
                        Text("Light Switch")
                    }
                    NavigationLink(destination: DeviceDetailView(deviceName: "Appliance1")) {
                        Text("Appliance1")
                    }
                    NavigationLink(destination: DeviceDetailView(deviceName: "Appliance2")) {
                        Text("Appliance2")
                    }
                }
                Section(header: Text("Room 2")) {
                    NavigationLink(destination: DeviceDetailView(deviceName: "Device 1")) {
                        Text("Device 1")
                    }
                    NavigationLink(destination: DeviceDetailView(deviceName: "Device 2")) {
                        Text("Device 2")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Favorites")
        }
    }
}