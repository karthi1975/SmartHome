import SwiftUI

struct DeviceCard: View {
    let device: SmartDevice
    var isEditing: Bool = false
    var onRemove: (() -> Void)? = nil
    @StateObject private var api = HomeAssistantClient.shared
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                if device.type == .blinds {
                    VStack(spacing: 0) {
                        BlindsCard(
                            onClose: { setBlindsPosition(0) },
                            onDown: { setBlindsPosition(max((device.position ?? 0) - 10, 0)) },
                            onUp: { setBlindsPosition(min((device.position ?? 0) + 10, 100)) },
                            onOpen: { setBlindsPosition(100) }
                        )
                        if isEditing, let onRemove = onRemove {
                            Button(action: onRemove) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                    }
                } else {
                    // Card with controls and status only
                    HStack(alignment: .center, spacing: 16) {
                        switch device.type {
                        case .dishwasher:
                            HStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Image("Clock_Smarthome")
                                        .resizable()
                                        .frame(width: 36, height: 36)
                                    Text(device.status ?? "Idle")
                                        .font(.subheadline)
                                    Text("Current Status")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Image(device.type.icon)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                Spacer()
                                Image("Power_Smarthome")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .onTapGesture { toggleDevice() }
                            }
                        case .fridge:
                            HStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text("\(device.currentTemperature ?? 40, specifier: "%.0f") °F")
                                        .font(.subheadline)
                                    Text("Current Temp")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Image(device.type.icon)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                Spacer()
                            }
                        case .oven:
                            HStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text(device.isOn ? "On" : "Off")
                                        .font(.subheadline)
                                    Text("Current Status")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Image(device.type.icon)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                VStack(spacing: 8) {
                                    Text("\(device.currentTemperature ?? 375, specifier: "%.0f") °F")
                                        .font(.subheadline)
                                    Text("Current Temp")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(spacing: 2) {
                                    Image("Power_Smarthome")
                                        .resizable()
                                        .frame(width: 36, height: 36)
                                        .onTapGesture { toggleDevice() }
                                    Text(device.isOn ? "On" : "Off")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        case .stove:
                            HStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text(device.isOn ? "On" : "Off")
                                        .font(.subheadline)
                                    Text("Current Status")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Image(device.type.icon)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                Spacer()
                            }
                        case .temp:
                            HStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text("\(device.currentTemperature ?? 70, specifier: "%.0f") °F")
                                        .font(.subheadline)
                                    Text("Current")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                ControlButton(asset: "Down_Smarthome", label: "Down") { setTemperature((device.currentTemperature ?? 70) - 1) }
                                ControlButton(asset: "Up_Smarthome", label: "Up") { setTemperature((device.currentTemperature ?? 70) + 1) }
                            }
                        default:
                            HStack {
                                Image(device.type.icon)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.08), radius: 4, x: 0, y: 2)
                }
            }
            // Device name/label below the card
            Text(device.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func toggleDevice() {
        Task {
            do {
                try await api.callService(
                    domain: device.type.entityDomain,
                    service: "toggle",
                    entityId: device.entityId
                )
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func setBlindsPosition(_ position: Int) {
        Task {
            do {
                try await api.callService(
                    domain: device.type.entityDomain,
                    service: "set_position",
                    entityId: device.entityId,
                    data: ["position": position]
                )
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func setTemperature(_ temperature: Double) {
        Task {
            do {
                try await api.callService(
                    domain: device.type.entityDomain,
                    service: "set_temperature",
                    entityId: device.entityId,
                    data: ["temperature": temperature]
                )
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// Helper for control buttons with asset icons
private struct ControlButton: View {
    let asset: String
    let label: String
    let action: () -> Void
    var body: some View {
        VStack(spacing: 2) {
            Button(action: action) {
                Image(asset)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Control Components

struct LightControls: View {
    @Binding var device: SmartDevice
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                        .font(.title)
                        .foregroundColor(device.isOn ? .yellow : .gray)
                }
                
                if let brightness = device.brightness {
                    Slider(value: .constant(Double(brightness) / 255.0))
                }
            }
            
            if let colorTemp = device.colorTemp {
                HStack {
                    Text("Color Temp")
                    Slider(value: .constant(Double(colorTemp) / 6500.0))
                }
            }
        }
    }
}

struct BlindsControls: View {
    @Binding var device: SmartDevice
    let onPositionChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { onPositionChange(100) }) {
                    Image("Up_Smarthome")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Spacer()
                Text("\(Int(device.position ?? 0))%")
                Spacer()
                Button(action: { onPositionChange(0) }) {
                    Image("Down_Smarthome")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            Slider(value: Binding(
                get: { Double(device.position ?? 0) },
                set: { onPositionChange(Int($0)) }
            ), in: 0...100, step: 1)
        }
    }
}

struct TemperatureControls: View {
    @Binding var device: SmartDevice
    let onTemperatureChange: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            if let currentTemp = device.currentTemperature {
                Text("\(Int(currentTemp))°")
                    .font(.title)
            }
            
            if let targetTemp = device.targetTemperature {
                HStack {
                    Button(action: { onTemperatureChange((device.currentTemperature ?? 20) - 1) }) {
                        Image("Down_Smarthome")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    
                    Text("\(Int(device.currentTemperature ?? 20))°C")
                        .font(.headline)
                    
                    Button(action: { onTemperatureChange((device.currentTemperature ?? 20) + 1) }) {
                        Image("Up_Smarthome")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
            }
            
            if let mode = device.presetMode {
                Text(mode.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MediaControls: View {
    @Binding var device: SmartDevice
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    // Previous track
                }) {
                    Image(systemName: "backward.fill")
                }
                
                Button(action: {
                    // Play/Pause
                }) {
                    Image(systemName: device.isPlaying ? "pause.fill" : "play.fill")
                }
                
                Button(action: {
                    // Next track
                }) {
                    Image(systemName: "forward.fill")
                }
            }
            
            if let volume = device.volume {
                HStack {
                    Image(systemName: "speaker.fill")
                    Slider(value: .constant(volume))
                    Image(systemName: "speaker.wave.3.fill")
                }
            }
            
            if let title = device.mediaTitle {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }
}

struct CameraControls: View {
    @Binding var device: SmartDevice
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    // Toggle recording
                }) {
                    Image(systemName: device.isRecording ? "record.circle.fill" : "record.circle")
                        .foregroundColor(device.isRecording ? .red : .gray)
                }
                
                Button(action: {
                    // Toggle night vision
                }) {
                    Image(systemName: device.nightVision ? "moon.fill" : "moon")
                }
            }
            
            if device.motionDetected {
                Text("Motion Detected")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct LockControls: View {
    @Binding var device: SmartDevice
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                // Toggle lock
            }) {
                Image(systemName: device.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.title)
                    .foregroundColor(device.isLocked ? .green : .red)
            }
            
            if device.doorSensor {
                Text("Door Open")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct BasicControls: View {
    @Binding var device: SmartDevice
    
    var body: some View {
        Button(action: {
            // Toggle device
        }) {
            Image(systemName: device.isOn ? "power" : "power")
                .font(.title)
                .foregroundColor(device.isOn ? .green : .gray)
        }
    }
}

struct DeviceConfigurationView: View {
    @Binding var device: SmartDevice
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedTemplate: DeviceTemplate?
    
    init(device: Binding<SmartDevice>) {
        self._device = device
        self._name = State(initialValue: device.wrappedValue.name)
        self._selectedTemplate = State(initialValue: device.wrappedValue.template)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Info")) {
                    TextField("Name", text: $name)
                    
                    if let template = selectedTemplate {
                        Text("Template: \(template.name)")
                    }
                }
                
                Section(header: Text("YAML Configuration")) {
                    Text("""
                    # Home Assistant Configuration
                    \(device.entityId):
                      name: \(device.name)
                      type: \(device.type.rawValue)
                      room: \(device.room)
                      template: \(device.template?.name ?? "none")
                      attributes:
                        \(device.attributes.map { "\($0.key): \($0.value)" }.joined(separator: "\n    "))
                      services:
                        \(device.services.map { "\($0.key):\n      \($0.value.map { "\($0.key): \($0.value)" }.joined(separator: "\n      "))" }.joined(separator: "\n    "))
                    """)
                    .font(.system(.body, design: .monospaced))
                }
            }
            .navigationTitle("Device Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        device.name = name
                        if let template = selectedTemplate {
                            device.applyTemplate(template)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct BlindsControlButton: View {
    let asset: String
    let label: String
    let action: () -> Void
    var body: some View {
        VStack(spacing: 2) {
            Button(action: action) {
                ZStack {
                    Image("ButtonBase_Smarthome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                    Image(asset)
                        .resizable()
                        .frame(width: 28, height: 28)
                }
            }
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.black)
            }
        }
        .frame(width: 56)
    }
} 
