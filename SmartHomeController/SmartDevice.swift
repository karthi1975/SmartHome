//
//  KitchenDevice.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 6/4/25.
//
import SwiftUI
import Foundation

// CodableValue enum for Codable-friendly arbitrary values
enum CodableValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([CodableValue])
    case dictionary([String: CodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: CodableValue].self) {
            self = .dictionary(value)
        } else if let value = try? container.decode([CodableValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown type in CodableValue")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable, Codable {
    case fahrenheit = "°F"
    case celsius = "°C"

    var id: String { self.rawValue }
}

enum DeviceType: String, Codable, CaseIterable {
    case avr
    case blinds
    case cameras
    case coffeemaker
    case dishwasher
    case dryer
    case fridge
    case lights
    case lock
    case music
    case oven
    case stove
    case streamer
    case temp
    case tv
    case washer

    var entityDomain: String {
        switch self {
        case .lights: return "light"
        case .blinds: return "cover"
        case .temp: return "climate"
        case .dishwasher, .fridge, .oven, .tv, .music, .stove, .streamer, .washer, .dryer, .coffeemaker, .avr: return "switch"
        case .cameras: return "camera"
        case .lock: return "lock"
        default: return "switch"
        }
    }
    
    var icon: String {
        switch self {
        case .avr: return "AVR_Smarthome"
        case .blinds: return "Blinds_Smarthome"
        case .cameras: return "Cameras_Smarthome"
        case .coffeemaker: return "CoffeeMaker_Smarthome"
        case .dishwasher: return "Dishwasher_Smarthome"
        case .dryer: return "Dryer_Smarthome"
        case .fridge: return "Fridge_Smarthome"
        case .lights: return "Lights_Smarthome"
        case .lock: return "Lock_Smarthome"
        case .music: return "Music_Smarthome"
        case .oven: return "Oven_Smarthome"
        case .stove: return "Stove_Smarthome"
        case .streamer: return "Streamer_Smarthome"
        case .temp: return "Temp__Smarthome"
        case .tv: return "TV_Smarthome"
        case .washer: return "Washer_Smarthome"
        }
    }
    
    var defaultAttributes: [String: Any] {
        switch self {
        case .temp:
            return ["min_temp": 15, "max_temp": 30, "current_temperature": 20]
        case .blinds:
            return ["current_position": 0, "supported_features": 15]
        case .music:
            return ["volume_level": 0.5, "is_volume_muted": false]
        case .cameras:
            return ["stream_source": "", "still_image_url": ""]
        default:
            return [:]
        }
    }
}

struct SmartDevice: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: DeviceType
    var room: String
    var entityId: String
    var state: String
    var attributes: [String: CodableValue]
    var services: [String: [String: CodableValue]]
    var template: DeviceTemplate?
    var groups: [UUID] // Array of group IDs
    var lastUpdated: Date
    var value: String? = nil
    var isOn: Bool = false
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, name, type, room, entityId, state, attributes, services, template, groups, lastUpdated, value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(DeviceType.self, forKey: .type)
        room = try container.decode(String.self, forKey: .room)
        entityId = try container.decode(String.self, forKey: .entityId)
        state = try container.decode(String.self, forKey: .state)
        attributes = try container.decode([String: CodableValue].self, forKey: .attributes)
        services = try container.decode([String: [String: CodableValue]].self, forKey: .services)
        template = try container.decodeIfPresent(DeviceTemplate.self, forKey: .template)
        groups = try container.decode([UUID].self, forKey: .groups)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        value = try container.decode(String?.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(room, forKey: .room)
        try container.encode(entityId, forKey: .entityId)
        try container.encode(state, forKey: .state)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(services, forKey: .services)
        try container.encodeIfPresent(template, forKey: .template)
        try container.encode(groups, forKey: .groups)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(value, forKey: .value)
    }
    
    // MARK: - Initialization
    init(id: UUID, name: String, type: DeviceType, room: String, entityId: String, state: String = "unknown", attributes: [String: CodableValue] = [:], services: [String: [String: CodableValue]] = [:], template: DeviceTemplate? = nil, groups: [UUID] = [], lastUpdated: Date = Date(), value: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.room = room
        self.entityId = entityId
        self.state = state
        self.attributes = attributes
        self.services = services
        self.template = template ?? DeviceTemplate.template(for: type)
        self.groups = groups
        self.lastUpdated = lastUpdated
        self.value = value
    }
    
    // Convenience initializer for just DeviceType
    init(type: DeviceType) {
        self.id = UUID()
        self.name = type.rawValue.capitalized
        self.type = type
        self.room = ""
        self.entityId = ""
        self.state = "unknown"
        self.attributes = [:]
        self.services = [:]
        self.template = DeviceTemplate.template(for: type)
        self.groups = []
        self.lastUpdated = Date()
        self.value = nil
    }
    
    // MARK: - Device State Management
    mutating func updateState(_ newState: String, attributes: [String: CodableValue]? = nil) {
        self.state = newState
        if let attributes = attributes {
            self.attributes = attributes
        }
        self.lastUpdated = Date()
    }
    
    // MARK: - Group Management
    mutating func addToGroup(_ groupId: UUID) {
        if !groups.contains(groupId) {
            groups.append(groupId)
        }
    }
    
    mutating func removeFromGroup(_ groupId: UUID) {
        groups.removeAll { $0 == groupId }
    }
    
    // MARK: - Template Management
    mutating func applyTemplate(_ template: DeviceTemplate) {
        self.template = template
        // Apply default attributes and services from template
        for (key, value) in template.defaultAttributes {
            if attributes[key] == nil {
                attributes[key] = value
            }
        }
        for (key, value) in template.defaultServices {
            if services[key] == nil {
                services[key] = value
            }
        }
    }
    
    // MARK: - Device Type Specific Properties
    var temperature: Double? {
        if let temp = attributes["temperature"] as? Double {
            return temp
        }
        return nil
    }
    
    var brightness: Int? {
        if let bright = attributes["brightness"] as? Int {
            return bright
        }
        return nil
    }
    
    var position: Int? {
        if let pos = attributes["position"] as? Int {
            return pos
        }
        return nil
    }
    
    var batteryLevel: Int? {
        if let battery = attributes["battery_level"] as? Int {
            return battery
        }
        return nil
    }
    
    var isLocked: Bool {
        state.lowercased() == "locked"
    }
    
    var isPlaying: Bool {
        state.lowercased() == "playing"
    }
    
    var volume: Double? {
        if let vol = attributes["volume_level"] as? Double {
            return vol
        }
        return nil
    }
    
    var mediaTitle: String? {
        attributes["media_title"] as? String
    }
    
    var mediaArtist: String? {
        attributes["media_artist"] as? String
    }
    
    var isRecording: Bool {
        attributes["recording"] as? Bool ?? false
    }
    
    var motionDetected: Bool {
        attributes["motion_detected"] as? Bool ?? false
    }
    
    var nightVision: Bool {
        attributes["night_vision"] as? Bool ?? false
    }
    
    var autoLock: Bool {
        attributes["auto_lock"] as? Bool ?? false
    }
    
    var doorSensor: Bool {
        attributes["door_sensor"] as? Bool ?? false
    }
    
    var presetMode: String? {
        attributes["preset_mode"] as? String
    }
    
    var hvacAction: String? {
        attributes["hvac_action"] as? String
    }
    
    var targetTemperature: Double? {
        attributes["target_temperature"] as? Double
    }
    
    var currentTemperature: Double? {
        attributes["current_temperature"] as? Double
    }
    
    var humidity: Double? {
        attributes["humidity"] as? Double
    }
    
    var targetHumidity: Double? {
        attributes["target_humidity"] as? Double
    }
    
    var fanSpeed: String? {
        attributes["fan_speed"] as? String
    }
    
    var isMuted: Bool {
        attributes["is_volume_muted"] as? Bool ?? false
    }
    
    var mediaContentType: String? {
        attributes["media_content_type"] as? String
    }
    
    var effect: String? {
        attributes["effect"] as? String
    }
    
    var colorTemp: Int? {
        attributes["color_temp"] as? Int
    }
    
    var rgbColor: [Int]? {
        attributes["rgb_color"] as? [Int]
    }
    
    var isDocked: Bool {
        attributes["is_docked"] as? Bool ?? false
    }
    
    var isCharging: Bool {
        attributes["is_charging"] as? Bool ?? false
    }
    
    var status: String? {
        attributes["status"] as? String
    }
    
    var error: String? {
        attributes["error"] as? String
    }
    
    var lastCleaned: Date? {
        if let timestamp = attributes["last_cleaned"] as? String {
            return ISO8601DateFormatter().date(from: timestamp)
        }
        return nil
    }
    
    var cleaningTime: Int? {
        attributes["cleaning_time"] as? Int
    }
    
    var filterLife: Int? {
        attributes["filter_life"] as? Int
    }
    
    var sideBrushLife: Int? {
        attributes["side_brush_life"] as? Int
    }
    
    var mainBrushLife: Int? {
        attributes["main_brush_life"] as? Int
    }
    
    var isIdle: Bool {
        state.lowercased() == "idle"
    }
    
    var isReturning: Bool {
        state.lowercased() == "returning"
    }
    
    var isCleaning: Bool {
        state.lowercased() == "cleaning"
    }
    
    var isError: Bool {
        state.lowercased() == "error"
    }
    
    var isOffline: Bool {
        state.lowercased() == "offline"
    }
    
    var isUnavailable: Bool {
        state.lowercased() == "unavailable"
    }
    
    var isUnknown: Bool {
        state.lowercased() == "unknown"
    }
    
    var isStandby: Bool {
        state.lowercased() == "standby"
    }
    
    var isActive: Bool {
        state.lowercased() == "active"
    }
    
    var isInactive: Bool {
        state.lowercased() == "inactive"
    }
    
    var isOpen: Bool {
        state.lowercased() == "open"
    }
    
    var isClosed: Bool {
        state.lowercased() == "closed"
    }
    
    var isOpening: Bool {
        state.lowercased() == "opening"
    }
    
    var isClosing: Bool {
        state.lowercased() == "closing"
    }
    
    var isMoving: Bool {
        state.lowercased() == "moving"
    }
    
    var isLocking: Bool {
        state.lowercased() == "locking"
    }
    
    var isUnlocking: Bool {
        state.lowercased() == "unlocking"
    }
    
    var isJammed: Bool {
        state.lowercased() == "jammed"
    }
    
    var isAlarm: Bool {
        state.lowercased() == "alarm"
    }
    
    var isTriggered: Bool {
        state.lowercased() == "triggered"
    }
    
    var isArmed: Bool {
        state.lowercased() == "armed"
    }
    
    var isDisarmed: Bool {
        state.lowercased() == "disarmed"
    }
    
    var isPending: Bool {
        state.lowercased() == "pending"
    }
    
    var isReady: Bool {
        state.lowercased() == "ready"
    }
    
    var isRunning: Bool {
        state.lowercased() == "running"
    }
    
    var isCompleted: Bool {
        state.lowercased() == "completed"
    }
    
    var isFailed: Bool {
        state.lowercased() == "failed"
    }
    
    var isCancelled: Bool {
        state.lowercased() == "cancelled"
    }
    
    var isScheduled: Bool {
        state.lowercased() == "scheduled"
    }
    
    var isQueued: Bool {
        state.lowercased() == "queued"
    }
    
    var isWaiting: Bool {
        state.lowercased() == "waiting"
    }
    
    var isProcessing: Bool {
        state.lowercased() == "processing"
    }
    
    var isAborted: Bool {
        state.lowercased() == "aborted"
    }
    
    var isSuspended: Bool {
        state.lowercased() == "suspended"
    }
    
    var isTerminated: Bool {
        state.lowercased() == "terminated"
    }
    
    var isRestarted: Bool {
        state.lowercased() == "restarted"
    }
    
    var isInitialized: Bool {
        state.lowercased() == "initialized"
    }
    
    var isConfigured: Bool {
        state.lowercased() == "configured"
    }
    
    var isUnconfigured: Bool {
        state.lowercased() == "unconfigured"
    }
    
    var isEnabled: Bool {
        state.lowercased() == "enabled"
    }
    
    var isDisabled: Bool {
        state.lowercased() == "disabled"
    }
    
    var isBlocked: Bool {
        state.lowercased() == "blocked"
    }
    
    var isUnblocked: Bool {
        state.lowercased() == "unblocked"
    }
}
