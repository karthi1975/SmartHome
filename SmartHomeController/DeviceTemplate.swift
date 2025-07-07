import Foundation

struct DeviceTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: DeviceType
    let defaultAttributes: [String: CodableValue]
    let defaultServices: [String: [String: CodableValue]]
    let icon: String
    let description: String
    
    static let templates: [DeviceTemplate] = [
        DeviceTemplate(
            id: UUID(),
            name: "Smart Light",
            type: .lights,
            defaultAttributes: [
                "brightness": .int(255),
                "color_temp": .int(4000),
                "rgb_color": .array([.int(255), .int(255), .int(255)]),
                "effect": .string("none")
            ],
            defaultServices: [
                "turn_on": ["brightness_pct": .int(100)],
                "turn_off": [:],
                "set_brightness": ["brightness_pct": .int(50)],
                "set_color_temp": ["kelvin": .int(4000)]
            ],
            icon: "Lights_Smarthome",
            description: "Smart light with brightness and color control"
        ),
        DeviceTemplate(
            id: UUID(),
            name: "Smart Speaker",
            type: .music,
            defaultAttributes: [
                "volume_level": .double(0.5),
                "is_volume_muted": .bool(false),
                "media_content_type": .string("music"),
                "media_title": .string("")
            ],
            defaultServices: [
                "volume_set": ["volume_level": .double(0.5)],
                "volume_mute": ["is_volume_muted": .bool(true)],
                "media_play": [:],
                "media_pause": [:],
                "media_stop": [:]
            ],
            icon: "Music_Smarthome",
            description: "Smart speaker with media controls"
        ),
        DeviceTemplate(
            id: UUID(),
            name: "Smart Lock",
            type: .lock,
            defaultAttributes: [
                "battery_level": .int(100),
                "door_sensor": .bool(false),
                "auto_lock": .bool(true)
            ],
            defaultServices: [
                "lock": [:],
                "unlock": [:],
                "set_auto_lock": ["auto_lock": .bool(true)]
            ],
            icon: "Lock_Smarthome",
            description: "Smart lock with auto-lock feature"
        ),
        DeviceTemplate(
            id: UUID(),
            name: "Smart Camera",
            type: .cameras,
            defaultAttributes: [
                "motion_detected": .bool(false),
                "recording": .bool(false),
                "night_vision": .bool(false)
            ],
            defaultServices: [
                "turn_on": [:],
                "turn_off": [:],
                "start_recording": [:],
                "stop_recording": [:],
                "set_night_vision": ["night_vision": .bool(true)]
            ],
            icon: "Cameras_Smarthome",
            description: "Smart camera with motion detection"
        ),
        DeviceTemplate(
            id: UUID(),
            name: "Smart Thermostat",
            type: .temp,
            defaultAttributes: [
                "current_temperature": .int(20),
                "target_temperature": .int(22),
                "hvac_action": .string("idle"),
                "preset_mode": .string("home")
            ],
            defaultServices: [
                "set_temperature": ["temperature": .int(22)],
                "set_preset_mode": ["preset_mode": .string("home")],
                "set_hvac_mode": ["hvac_mode": .string("heat")]
            ],
            icon: "Temp__Smarthome",
            description: "Smart thermostat with preset modes"
        )
    ]
    
    static func template(for type: DeviceType) -> DeviceTemplate? {
        templates.first { $0.type == type }
    }
} 