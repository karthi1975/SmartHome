import SwiftUI

struct PlayroomView: View {
    @Binding var showSidebarOverlay: Bool
    @EnvironmentObject var deviceStore: DeviceStore
    @State private var showingAddDevice = false
    @State private var isEditing: Bool = false
    let roomName = "Playroom"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with Edit/Done button and Add Device button
                HStack {
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .foregroundColor(.blue)
                            .font(.body)
                            .padding(.leading)
                    }
                    Spacer()
                    Text("Playroom Devices")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: { showingAddDevice = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    .padding(.trailing)
                }
                .padding(.horizontal)

                // Device Cards
                VStack(spacing: 16) {
                    ForEach(deviceStore.devices(for: roomName), id: \.id) { device in
                        DeviceCard(device: device, isEditing: isEditing, onRemove: {
                            if let idx = deviceStore.devices(for: roomName).firstIndex(where: { $0.id == device.id }) {
                                deviceStore.removeDevice(at: IndexSet(integer: idx), from: roomName)
                            }
                        })
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
            .padding(.vertical)
        }
        .sheet(isPresented: $showingAddDevice) {
            AddDeviceView { newDevice in
                deviceStore.addDevice(newDevice, to: roomName)
                showingAddDevice = false
            }
        }
    }
}

#Preview {
    PlayroomView(showSidebarOverlay: .constant(false))
} 