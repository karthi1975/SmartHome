import SwiftUI

struct DeviceDiscoveryView: View {
    @ObservedObject var deviceDiscovery: HomeAssistantDeviceDiscovery
    @Environment(\.dismiss) private var dismiss
    @State private var selectedZone = ""
    @State private var searchText = ""
    @State private var showingAllDevices = false
    
    let onDeviceSelected: (HADevice) -> Void
    
    private var filteredDevices: [HADevice] {
        let devices = deviceDiscovery.discoveredDevices
        
        if searchText.isEmpty {
            return devices
        } else {
            return devices.filter { device in
                let name = device.name?.lowercased() ?? ""
                let entityId = device.entityId.lowercased()
                let area = device.area?.lowercased() ?? ""
                let zone = device.zone?.lowercased() ?? ""
                let searchLower = searchText.lowercased()
                
                return name.contains(searchLower) ||
                       entityId.contains(searchLower) ||
                       area.contains(searchLower) ||
                       zone.contains(searchLower)
            }
        }
    }
    
    private var supportedDevices: [HADevice] {
        filteredDevices.filter { $0.type != nil }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Zone Selection
                VStack(spacing: 12) {
                    SearchBar(text: $searchText, placeholder: "Search devices...")
                    
                    // Zone Selection
                    HStack {
                        Text("Zone:")
                        TextField("Enter zone/area name", text: $selectedZone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Search Zone") {
                            Task {
                                await deviceDiscovery.discoverDevicesInZone(selectedZone)
                            }
                        }
                        .disabled(selectedZone.isEmpty || deviceDiscovery.isDiscovering)
                    }
                    
                    // Action Buttons
                    HStack {
                        Button("Discover All") {
                            Task {
                                await deviceDiscovery.discoverAllDevices()
                            }
                        }
                        .disabled(deviceDiscovery.isDiscovering)
                        
                        Spacer()
                        
                        Button("Refresh Areas") {
                            Task {
                                await deviceDiscovery.fetchAreas()
                            }
                        }
                        .disabled(deviceDiscovery.isDiscovering)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Device List
                if deviceDiscovery.isDiscovering {
                    VStack {
                        Spacer()
                        ProgressView("Discovering devices...")
                        Spacer()
                    }
                } else if supportedDevices.isEmpty {
                    VStack {
                        Spacer()
                        Text("No supported devices found")
                            .foregroundColor(.secondary)
                        Text("Try searching in a different zone or check your Home Assistant configuration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List(supportedDevices) { device in
                        DeviceDiscoveryRow(device: device) {
                            onDeviceSelected(device)
                        }
                    }
                }
            }
            .navigationTitle("Discover Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Show All Devices") {
                            showingAllDevices = true
                        }
                        
                        if let lastDiscovery = deviceDiscovery.lastDiscoveryDate {
                            Button("Last Discovery: \(lastDiscovery.formatted(date: .abbreviated, time: .shortened))") {
                                // Info only
                            }
                            .disabled(true)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: .constant(deviceDiscovery.errorMessage != nil)) {
                Button("OK") {
                    deviceDiscovery.errorMessage = nil
                }
            } message: {
                if let error = deviceDiscovery.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showingAllDevices) {
                AllDevicesView(deviceDiscovery: deviceDiscovery)
            }
        }
    }
}

struct DeviceDiscoveryRow: View {
    let device: HADevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Device Icon
                if let deviceType = device.type {
                    Image(deviceType.icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? device.entityId)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(device.entityId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("State: \(device.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let area = device.area {
                            Text("• \(area)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if let zone = device.zone {
                            Text("• \(zone)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                if device.type != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}

struct AllDevicesView: View {
    @ObservedObject var deviceDiscovery: HomeAssistantDeviceDiscovery
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(deviceDiscovery.discoveredDevices) { device in
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? device.entityId)
                        .font(.headline)
                    
                    Text(device.entityId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("State: \(device.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let type = device.type {
                            Text("• \(type.rawValue)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text("• Unsupported")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("All Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}