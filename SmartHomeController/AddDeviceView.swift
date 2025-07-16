import SwiftUI

struct AddDeviceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var api: HomeAssistantClient
    @StateObject private var deviceDiscovery = HomeAssistantDeviceDiscovery()
    @State private var selectedType: DeviceType?
    @State private var selectedDevice: SmartDevice?
    @State private var selectedHADevice: HADevice?
    @State private var isDiscovering = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDiscoverySheet = false
    @State private var selectedZone = ""
    @State private var currentRoom = ""
    var deviceToEdit: SmartDevice? = nil
    var onSave: ((SmartDevice) -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    // Only allow these device types
    private let allowedTypes: [DeviceType] = [.blinds, .dishwasher, .fridge, .oven, .temp]

    // Device-specific fields
    @State private var name: String = ""
    @State private var tempValue: Int = 70
    @State private var ovenTemp: Int = 350
    @State private var ovenIsOn: Bool = false
    @State private var blindsPosition: Int = 0
    @State private var fridgeTemp: Int = 40
    @State private var dishwasherStatus: String = "Idle"

    @ViewBuilder
    private func tempSettings() -> some View {
        Stepper(value: $tempValue, in: 32...120) {
            Text("Temperature: \(tempValue) °F")
        }
    }

    @ViewBuilder
    private func ovenSettings() -> some View {
        Stepper(value: $ovenTemp, in: 100...500) {
            Text("Oven Temp: \(ovenTemp) °F")
        }
        Toggle("Oven On", isOn: $ovenIsOn)
    }

    @ViewBuilder
    private func blindsSettings() -> some View {
        Stepper(value: $blindsPosition, in: 0...100) {
            Text("Blinds Position: \(blindsPosition)%")
        }
    }

    @ViewBuilder
    private func fridgeSettings() -> some View {
        Stepper(value: $fridgeTemp, in: 30...60) {
            Text("Fridge Temp: \(fridgeTemp) °F")
        }
    }

    @ViewBuilder
    private func dishwasherSettings() -> some View {
        TextField("Status", text: $dishwasherStatus)
    }

    @ViewBuilder
    private func deviceSettingsSection(for type: DeviceType) -> some View {
        Section(header: Text("Device Settings")) {
            TextField("Name", text: $name)
            switch type {
            case .temp: tempSettings()
            case .oven: ovenSettings()
            case .blinds: blindsSettings()
            case .fridge: fridgeSettings()
            case .dishwasher: dishwasherSettings()
            @unknown default: EmptyView()
            }
        }
    }

    @ViewBuilder
    private func deviceTypeSelectionSection() -> some View {
        if deviceToEdit == nil {
            Section(header: Text("Add Device")) {
                // Home Assistant Discovery Option
                DeviceOptionRow(
                    icon: "house.fill",
                    title: "Discover from Home Assistant",
                    description: "Find devices in your Home Assistant setup"
                ) {
                    showDiscoverySheet = true
                }
                .sheet(isPresented: $showDiscoverySheet) {
                    DeviceDiscoveryView(
                        deviceDiscovery: deviceDiscovery,
                        onDeviceSelected: { haDevice in
                            selectedHADevice = haDevice
                            showDiscoverySheet = false
                        }
                    )
                }
                
                // Manual Device Creation
                DeviceOptionRow(
                    icon: "plus.circle.fill",
                    title: "Create Manual Device",
                    description: "Add a device manually"
                ) {
                    // Show manual device type selection
                }
            }
            
            // Show device type selection if manual creation is chosen
            if selectedHADevice == nil {
                Section(header: Text("Device Type")) {
                    ForEach(allowedTypes, id: \.self) { type in
                        Button(action: { selectedType = type }) {
                            HStack {
                                Image(type.icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Text(type.rawValue.capitalized)
                                Spacer()
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                deviceTypeSelectionSection()
                
                // Show Home Assistant device info if selected
                if let haDevice = selectedHADevice {
                    Section(header: Text("Home Assistant Device")) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(haDevice.name ?? haDevice.entityId)
                                    .font(.headline)
                                Text(haDevice.entityId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("State: \(haDevice.state)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                selectedHADevice = nil
                                showDiscoverySheet = true
                            }
                        }
                        
                        TextField("Room", text: $currentRoom)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                if let type = deviceToEdit?.type ?? selectedType ?? selectedHADevice?.type {
                    deviceSettingsSection(for: type)
                }
            }
            .navigationTitle(deviceToEdit == nil ? "Add Device" : "Edit Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(deviceToEdit == nil ? "Add" : "Save") {
                        let device: SmartDevice
                        
                        if let haDevice = selectedHADevice {
                            // Create device from Home Assistant discovery
                            let room = currentRoom.isEmpty ? "Unknown" : currentRoom
                            device = deviceDiscovery.convertToSmartDevice(haDevice, room: room) ?? SmartDevice(type: .temp)
                        } else {
                            // Create device manually
                            let type = deviceToEdit?.type ?? selectedType!
                            device = deviceToEdit ?? SmartDevice(type: type)
                        }
                        
                        var finalDevice = device
                        finalDevice.name = name.isEmpty ? device.name : name
                        
                        // Apply manual settings if not from HA
                        if selectedHADevice == nil {
                            switch finalDevice.type {
                            case .temp:
                                finalDevice.value = "\(tempValue)"
                            case .oven:
                                finalDevice.value = "\(ovenTemp)"
                                finalDevice.isOn = ovenIsOn
                            case .blinds:
                                finalDevice.value = "\(blindsPosition)"
                            case .fridge:
                                finalDevice.value = "\(fridgeTemp)"
                            case .dishwasher:
                                finalDevice.value = dishwasherStatus ?? ""
                            @unknown default:
                                break
                            }
                        }
                        
                        onSave?(finalDevice)
                        dismiss()
                    }
                    .disabled(isAddButtonDisabled)
                }
            }
            .onAppear {
                // Pre-fill fields if editing
                if let device = deviceToEdit {
                    selectedType = device.type
                    name = device.name
                    currentRoom = device.room
                    switch device.type {
                    case .temp:
                        tempValue = Int(device.value ?? "70") ?? 70
                    case .oven:
                        ovenTemp = Int(device.value ?? "350") ?? 350
                        ovenIsOn = device.isOn
                    case .blinds:
                        blindsPosition = Int(device.value ?? "0") ?? 0
                    case .fridge:
                        fridgeTemp = Int(device.value ?? "40") ?? 40
                    case .dishwasher:
                        dishwasherStatus = device.value ?? ""
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
    
    private var isAddButtonDisabled: Bool {
        // For editing existing device
        if deviceToEdit != nil {
            return name.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        // For Home Assistant device
        if selectedHADevice != nil {
            return currentRoom.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        // For manual device creation
        return selectedType == nil || name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

struct DeviceOptionRow: View {
    let icon: String
    let title: String
    let description: String
    var action: () -> Void // Closure to perform when row is tapped

    var body: some View {
        Button(action: action) {
            HStack {
                Image(icon)
                    .font(.title2)
                    .frame(width: 30)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle()) // To remove default button styling
    }
} 
