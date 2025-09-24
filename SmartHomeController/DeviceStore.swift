import SwiftUI
import AVKit

class DeviceStore: ObservableObject {
    @Published var devicesByRoom: [String: [SmartDevice]] = [:] // e.g., ["Master": [SmartDevice], "Bedroom": [SmartDevice]]

    private let userDefaultsKey = "devicesByRoom"

    init() {
        load()
    }

    func addDevice(_ device: SmartDevice, to room: String) {
        devicesByRoom[room, default: []].append(device)
        save()
    }

    func removeDevice(at offsets: IndexSet, from room: String) {
        devicesByRoom[room]?.remove(atOffsets: offsets)
        save()
    }

    func devices(for room: String) -> [SmartDevice] {
        devicesByRoom[room] ?? []
    }

    func updateDevice(_ device: SmartDevice, in room: String) {
        if let idx = devicesByRoom[room]?.firstIndex(where: { $0.id == device.id }) {
            devicesByRoom[room]?[idx] = device
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(devicesByRoom) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: [SmartDevice]].self, from: data) {
            devicesByRoom = decoded
        }

        // Always ensure Kitchen has HVAC device
        ensureKitchenHVAC()
    }

    private func ensureKitchenHVAC() {
        // Remove any duplicate temp devices first
        var kitchenDevices = devicesByRoom["Kitchen"] ?? []

        // Filter out all temp devices
        kitchenDevices = kitchenDevices.filter { $0.type != .temp }

        // Use a stable UUID for the Kitchen HVAC device
        let stableHVACId = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890") ?? UUID()

        // Create the single Kitchen HVAC device
        let hvacDevice = SmartDevice(
            id: stableHVACId,
            name: "Kitchen HVAC",
            type: .temp,
            room: "Kitchen",
            entityId: "climate.kitchen",
            state: "heat",
            attributes: [
                "temperature": CodableValue.int(78),
                "target_temp_high": CodableValue.int(80),
                "target_temp_low": CodableValue.int(65),
                "hvac_mode": CodableValue.string("heat"),
                "preset_mode": CodableValue.string("comfort"),
                "unit": CodableValue.string("°F")
            ],
            services: [:],
            template: nil,
            groups: [],
            lastUpdated: Date(),
            value: "78"
        )

        kitchenDevices.append(hvacDevice)
        devicesByRoom["Kitchen"] = kitchenDevices
        save()
    }
} 