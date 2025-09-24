import SwiftUI
import Combine

struct RoomView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var callManager: CallManager
    var roomName: String

    @State private var showingAddDevice = false
    @State private var editingDevice: SmartDevice? = nil
    @State private var isEditing = false
    @StateObject private var tempVM: AnimatedTempCardViewModel
    // Store blinds view models for each blinds device
    @State private var blindsViewModels: [UUID: AnimatedBlindsViewModel] = [:]
    // Store toaster view models for each toaster device
    @State private var toasterViewModels: [UUID: AnimatedToasterViewModel] = [:]
    static var roomViewModels: [String: AnimatedTempCardViewModel] = [:]

    init(roomName: String) {
        self.roomName = roomName
        let initialTemp = CallManager().roomTemps[roomName.lowercased()] ?? 70
        _tempVM = StateObject(wrappedValue: AnimatedTempCardViewModel(
            initialTemp: initialTemp,
            updateTemp: { newTemp in
                // This closure will be replaced in .onAppear
            }
        ))
    }

    var body: some View {
        let devices = deviceStore.devices(for: roomName)
        ZStack {
            VStack(spacing: 0) {
            HStack {
                Text("Devices in \(roomName)")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "Done" : "Edit")
                        .foregroundColor(.blue)
                        .font(.body)
                }
                Button(action: {
                    editingDevice = nil
                    showingAddDevice = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
            .padding([.top, .horizontal])
            ScrollView {
                VStack(spacing: 16) {
                    // Show all devices including temp and blinds with interactive controls
                    ForEach(devices) { device in
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 4) {
                                getCardView(for: device)
                                Text(device.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            if isEditing {
                                HStack(spacing: 0) {
                                    Button(action: {
                                        editingDevice = device
                                        showingAddDevice = true
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.blue)
                                            .padding(8)
                                    }
                                    Button(action: {
                                        if let idx = devices.firstIndex(where: { $0.id == device.id }) {
                                            deviceStore.removeDevice(at: IndexSet(integer: idx), from: roomName)
                                        }
                                    }) {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.red)
                                            .padding(8)
                                    }
                                }
                            }
                        }
                    }
                    // Add Device Card - Always at the bottom
                    Button(action: { showingAddDevice = true }) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            Text("Add Device")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            }
        }
        .sheet(isPresented: $showingAddDevice) {
            AddDeviceView(
                deviceToEdit: editingDevice,
                onSave: { device in
                    if let editing = editingDevice {
                        deviceStore.updateDevice(device, in: roomName)
                    } else {
                        deviceStore.addDevice(device, to: roomName)
                    }
                    showingAddDevice = false
                },
                onCancel: { showingAddDevice = false }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateBlinds"))) { notification in
            guard let userInfo = notification.userInfo,
                  let targetRoom = userInfo["room"] as? String,
                  let position = userInfo["position"] as? Int else { return }
            
            let isVoiceCommand = userInfo["isVoiceCommand"] as? Bool ?? false
            let action = userInfo["action"] as? String ?? ""
            
            let normalizedRoom = targetRoom.isEmpty ? roomName.lowercased() : targetRoom.lowercased()
            if normalizedRoom == roomName.lowercased() {
                // Update all blinds in this room
                for device in deviceStore.devices(for: roomName).filter({ $0.type == .blinds }) {
                    // Update view model
                    if let blindsVM = blindsViewModels[device.id] {
                        blindsVM.setPosition(position)
                        if isVoiceCommand {
                            // Trigger voice animation based on action
                            if action == "open" {
                                blindsVM.setVoiceAction(.open, duration: 2.0)
                            } else if action == "close" {
                                blindsVM.setVoiceAction(.close, duration: 2.0)
                            } else {
                                blindsVM.setVoiceAction(.adjusting, duration: 2.0)
                            }
                            blindsVM.handleVoiceCommand("Set to \(position)%")
                        }
                    } else {
                        // Create new view model if needed
                        let newVM = AnimatedBlindsViewModel()
                        newVM.setPosition(position)
                        if isVoiceCommand {
                            // Trigger voice animation based on action
                            if action == "open" {
                                newVM.setVoiceAction(.open, duration: 2.0)
                            } else if action == "close" {
                                newVM.setVoiceAction(.close, duration: 2.0)
                            } else {
                                newVM.setVoiceAction(.adjusting, duration: 2.0)
                            }
                            newVM.handleVoiceCommand("Set to \(position)%")
                        }
                        blindsViewModels[device.id] = newVM
                    }
                    
                    // Update device in store
                    var updatedDevice = device
                    updatedDevice.attributes["position"] = .int(position)
                    deviceStore.updateDevice(updatedDevice, in: roomName)
                }
            }
        }
        .onAppear {
            print("[DEBUG] RoomView for \(roomName) appeared, registering view model")

            // Get the temperature from the actual HVAC device
            var actualTemp = 70
            if let hvacDevice = deviceStore.devices(for: roomName).first(where: { $0.type == .temp }) {
                // Get temperature from device attributes
                if case .int(let temp) = hvacDevice.attributes["temperature"] {
                    actualTemp = temp
                } else if let tempStr = hvacDevice.value, let temp = Int(tempStr) {
                    actualTemp = temp
                }
                print("[DEBUG] Found HVAC device with temperature: \(actualTemp)°F")
            }

            // Register the view model for this room with actual temperature
            tempVM.setTemp(actualTemp)
            callManager.roomTemps[roomName.lowercased()] = actualTemp

            let updateClosure: (Int) -> Void = { newTemp in
                callManager.roomTemps[roomName.lowercased()] = newTemp
                // Also update the device in the store
                if let hvacDevice = deviceStore.devices(for: roomName).first(where: { $0.type == .temp }) {
                    var updatedDevice = hvacDevice
                    updatedDevice.attributes["temperature"] = .int(newTemp)
                    updatedDevice.value = String(newTemp)
                    deviceStore.updateDevice(updatedDevice, in: roomName)
                }
            }
            // Set the update closure on the view model using the new method
            tempVM.setUpdateTempClosure(updateClosure)
            tempVM.objectWillChange.send() // ensure update

            RoomView.roomViewModels[roomName.lowercased()] = tempVM
            print("[DEBUG] Registered \(roomName.lowercased()) view model with temp \(actualTemp). Total registered: \(RoomView.roomViewModels.keys.sorted())")

            // Initialize blinds view models for all blinds devices
            for device in deviceStore.devices(for: roomName).filter({ $0.type == .blinds }) {
                if blindsViewModels[device.id] == nil {
                    let blindsVM = AnimatedBlindsViewModel()
                    blindsVM.position = device.position ?? 50
                    blindsViewModels[device.id] = blindsVM
                }
            }

            // Initialize toaster view models for all toaster devices
            for device in deviceStore.devices(for: roomName).filter({ $0.type == .toaster }) {
                if toasterViewModels[device.id] == nil {
                    let toasterVM = AnimatedToasterViewModel()
                    toasterVM.isOn = device.isOn
                    toasterViewModels[device.id] = toasterVM
                }
            }

            // Removed auto-test animation - temperature should only change on explicit user commands
            // Automatically read out the current temperature using VAPI, with a medium delay
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                await callManager.speakTemperature(room: roomName, temp: actualTemp)
            }
        }
        .onDisappear {
            // Don't remove view models on disappear to allow voice commands from any page
            // View models will be updated when rooms are revisited
            print("[DEBUG] RoomView for \(roomName) disappeared but keeping view model for voice control")
        }
    }
    
    @ViewBuilder
    private func getCardView(for device: SmartDevice) -> some View {
        switch device.type {
        case .temp:
            TempCard(viewModel: tempVM, roomName: roomName)
                .environmentObject(callManager)
        case .blinds:
            if let blindsVM = blindsViewModels[device.id] {
                AnimatedBlindsCard(
                    viewModel: blindsVM,
                    onClose: { updateBlindsPosition(device, position: 0) },
                    onDown: { updateBlindsPosition(device, position: max(blindsVM.position - 10, 0)) },
                    onUp: { updateBlindsPosition(device, position: min(blindsVM.position + 10, 100)) },
                    onOpen: { updateBlindsPosition(device, position: 100) }
                )
            } else {
                // Create a new view model if needed
                BlindsCard(
                    onClose: { updateBlindsPosition(device, position: 0) },
                    onDown: { updateBlindsPosition(device, position: max((device.position ?? 50) - 10, 0)) },
                    onUp: { updateBlindsPosition(device, position: min((device.position ?? 50) + 10, 100)) },
                    onOpen: { updateBlindsPosition(device, position: 100) }
                )
            }
        case .oven:
            OvenCard(
                status: device.isOn ? "On" : "Off",
                temperature: "\(Int(device.currentTemperature ?? 375)) °F",
                isOn: device.isOn,
                onPowerToggle: { toggleDevice(device) }
            )
        case .dishwasher:
            DishwasherCard(status: device.status ?? "Idle")
        case .fridge:
            FridgeCard(temperature: "\(Int(device.currentTemperature ?? 40)) °F")
        case .toaster:
            if let toasterVM = toasterViewModels[device.id] {
                AnimatedToasterCard(
                    viewModel: toasterVM,
                    onToggle: { toggleDevice(device) }
                )
            } else {
                // Create a new view model if needed
                ToasterCard(
                    isOn: device.isOn,
                    onToggle: { toggleDevice(device) }
                )
            }
        default:
            // For other device types, show a basic card
            HStack {
                Image(systemName: device.type.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                Text(device.name)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: .constant(device.isOn))
                    .labelsHidden()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func updateBlindsPosition(_ device: SmartDevice, position: Int) {
        // Get or create the blinds view model for this device
        let blindsVM: AnimatedBlindsViewModel
        if let existingVM = blindsViewModels[device.id] {
            blindsVM = existingVM
        } else {
            blindsVM = AnimatedBlindsViewModel()
            blindsViewModels[device.id] = blindsVM
        }
        
        // Update the blinds view model position
        blindsVM.setPosition(position)
        
        // Update the device in store with new position
        if let index = deviceStore.devices(for: roomName).firstIndex(where: { $0.id == device.id }) {
            var updatedDevice = device
            // Update position in attributes
            updatedDevice.attributes["position"] = .int(position)
            deviceStore.updateDevice(updatedDevice, in: roomName)
        }
        
        // Animate the blinds with voice feedback
        Task {
            await callManager.speakResponse("Setting \(device.name) to \(position) percent")
        }
    }
    
    private func toggleDevice(_ device: SmartDevice) {
        // Toggle device state
        if let index = deviceStore.devices(for: roomName).firstIndex(where: { $0.id == device.id }) {
            var updatedDevice = device
            updatedDevice.isOn.toggle()
            updatedDevice.state = updatedDevice.isOn ? "on" : "off"
            deviceStore.updateDevice(updatedDevice, in: roomName)
            
            // Update view model for animated devices
            if device.type == .toaster, let toasterVM = toasterViewModels[device.id] {
                if updatedDevice.isOn {
                    toasterVM.startToasting()
                } else {
                    toasterVM.stopToasting()
                }
            }
            
            // Voice feedback
            let status = updatedDevice.isOn ? "on" : "off"
            Task {
                await callManager.speakResponse("Turning \(device.name) \(status)")
            }
        }
    }
} 