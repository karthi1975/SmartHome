import SwiftUI

struct RoomView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var callManager: CallManager
    var roomName: String

    @State private var showingAddDevice = false
    @State private var editingDevice: SmartDevice? = nil
    @State private var isEditing = false
    @StateObject private var tempVM: AnimatedTempCardViewModel
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
                    // Always show the animated TempCard for temperature control via voice commands
                    TempCard(viewModel: tempVM, roomName: roomName)
                        .environmentObject(callManager)
                    // Show the rest of the devices (excluding temp)
                    ForEach(devices.filter { $0.type != .temp }) { device in
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 4) {
                                Text(device.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.gray)
                            }
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
            GlobalMicrophoneOverlay()
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
        .onAppear {
            print("[DEBUG] RoomView for \(roomName) appeared, registering view model")
            // Register the view model for this room
            tempVM.setTemp(callManager.roomTemps[roomName.lowercased()] ?? 70)
            let updateClosure: (Int) -> Void = { newTemp in
                callManager.roomTemps[roomName.lowercased()] = newTemp
            }
            // Set the update closure on the view model using the new method
            tempVM.setUpdateTempClosure(updateClosure)
            tempVM.objectWillChange.send() // ensure update
            
            RoomView.roomViewModels[roomName.lowercased()] = tempVM
            print("[DEBUG] Registered \(roomName.lowercased()) view model. Total registered: \(RoomView.roomViewModels.keys.sorted())")
            
            // Removed auto-test animation - temperature should only change on explicit user commands
            // Automatically read out the current temperature using VAPI, with a medium delay
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                await callManager.speakTemperature(room: roomName, temp: tempVM.temp)
            }
        }
        .onDisappear {
            // Don't remove view models on disappear to allow voice commands from any page
            // View models will be updated when rooms are revisited
            print("[DEBUG] RoomView for \(roomName) disappeared but keeping view model for voice control")
        }
    }
} 