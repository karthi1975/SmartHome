import Foundation
import Combine

// MARK: - Home Assistant Models for Device Discovery
struct HADevice: Codable, Identifiable {
    let id: String
    let name: String?
    let entityId: String
    let state: String
    let attributes: [String: CodableValue]
    let deviceClass: String?
    let platform: String?
    let area: String?
    let zone: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "entity_id"
        case name = "friendly_name"
        case state
        case attributes
        case deviceClass = "device_class"
        case platform
        case area = "area_id"
        case zone = "zone"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.entityId = self.id
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.state = try container.decode(String.self, forKey: .state)
        self.attributes = try container.decode([String: CodableValue].self, forKey: .attributes)
        self.deviceClass = try container.decodeIfPresent(String.self, forKey: .deviceClass)
        self.platform = try container.decodeIfPresent(String.self, forKey: .platform)
        self.area = try container.decodeIfPresent(String.self, forKey: .area)
        self.zone = try container.decodeIfPresent(String.self, forKey: .zone)
    }
    
    init(id: String, name: String?, entityId: String, state: String, attributes: [String: CodableValue], deviceClass: String?, platform: String?, area: String?, zone: String?) {
        self.id = id
        self.name = name
        self.entityId = entityId
        self.state = state
        self.attributes = attributes
        self.deviceClass = deviceClass
        self.platform = platform
        self.area = area
        self.zone = zone
    }
}

struct HAArea: Codable, Identifiable {
    let id: String
    let name: String
    let picture: String?
    let aliases: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "area_id"
        case name
        case picture
        case aliases
    }
}

struct HAZone: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String?
    let latitude: Double?
    let longitude: Double?
    let radius: Double?
    let passive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "entity_id"
        case name
        case icon
        case latitude
        case longitude
        case radius
        case passive
    }
}

// MARK: - Device Discovery Service
class HomeAssistantDeviceDiscovery: ObservableObject {
    @Published var discoveredDevices: [HADevice] = []
    @Published var availableAreas: [HAArea] = []
    @Published var availableZones: [HAZone] = []
    @Published var isDiscovering = false
    @Published var lastDiscoveryDate: Date?
    @Published var errorMessage: String?
    
    private let client = HomeAssistantClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Device Type Mapping
    private func mapToDeviceType(entityId: String, deviceClass: String?, attributes: [String: CodableValue]) -> DeviceType? {
        let domain = entityId.split(separator: ".").first?.lowercased() ?? ""
        
        switch domain {
        case "light":
            return .lights
        case "switch":
            // Try to infer device type from entity ID or friendly name
            let lowerEntityId = entityId.lowercased()
            if lowerEntityId.contains("dishwasher") { return .dishwasher }
            if lowerEntityId.contains("fridge") || lowerEntityId.contains("refrigerator") { return .fridge }
            if lowerEntityId.contains("oven") { return .oven }
            if lowerEntityId.contains("stove") { return .stove }
            if lowerEntityId.contains("washer") { return .washer }
            if lowerEntityId.contains("dryer") { return .dryer }
            if lowerEntityId.contains("coffee") { return .coffeemaker }
            if lowerEntityId.contains("tv") { return .tv }
            if lowerEntityId.contains("music") || lowerEntityId.contains("speaker") { return .music }
            if lowerEntityId.contains("streamer") { return .streamer }
            if lowerEntityId.contains("avr") || lowerEntityId.contains("receiver") { return .avr }
            return nil // Generic switch - user can categorize
        case "cover":
            return .blinds
        case "climate":
            return .temp
        case "lock":
            return .lock
        case "camera":
            return .cameras
        default:
            return nil
        }
    }
    
    // MARK: - Zone-Based Device Discovery
    func discoverDevicesInZone(_ zoneName: String) async {
        await MainActor.run {
            isDiscovering = true
            errorMessage = nil
        }
        
        do {
            let devices = try await fetchDevicesFromHomeAssistant()
            let filteredDevices = devices.filter { device in
                // Filter by zone/area
                let deviceZone = device.zone ?? device.area ?? ""
                let deviceName = device.name ?? device.entityId
                
                return deviceZone.lowercased().contains(zoneName.lowercased()) ||
                       deviceName.lowercased().contains(zoneName.lowercased())
            }
            
            await MainActor.run {
                self.discoveredDevices = filteredDevices
                self.lastDiscoveryDate = Date()
                self.isDiscovering = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to discover devices: \(error.localizedDescription)"
                self.isDiscovering = false
            }
        }
    }
    
    // MARK: - Fetch All Devices
    func discoverAllDevices() async {
        await MainActor.run {
            isDiscovering = true
            errorMessage = nil
        }
        
        do {
            let devices = try await fetchDevicesFromHomeAssistant()
            
            await MainActor.run {
                self.discoveredDevices = devices
                self.lastDiscoveryDate = Date()
                self.isDiscovering = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to discover devices: \(error.localizedDescription)"
                self.isDiscovering = false
            }
        }
    }
    
    // MARK: - Fetch Areas/Zones
    func fetchAreas() async {
        do {
            let areas = try await fetchAreasFromHomeAssistant()
            await MainActor.run {
                self.availableAreas = areas
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch areas: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchZones() async {
        do {
            let zones = try await fetchZonesFromHomeAssistant()
            await MainActor.run {
                self.availableZones = zones
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch zones: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Convert to SmartDevice
    func convertToSmartDevice(_ haDevice: HADevice, room: String) -> SmartDevice? {
        guard let deviceType = mapToDeviceType(
            entityId: haDevice.entityId,
            deviceClass: haDevice.deviceClass,
            attributes: haDevice.attributes
        ) else {
            return nil
        }
        
        let name = haDevice.name ?? haDevice.entityId.replacingOccurrences(of: "_", with: " ").capitalized
        
        return SmartDevice(
            id: UUID(),
            name: name,
            type: deviceType,
            room: room,
            entityId: haDevice.entityId,
            state: haDevice.state,
            attributes: haDevice.attributes,
            services: [:],
            template: DeviceTemplate.template(for: deviceType),
            groups: [],
            lastUpdated: Date()
        )
    }
    
    // MARK: - Filter Devices by Type
    func devicesOfType(_ deviceType: DeviceType) -> [HADevice] {
        return discoveredDevices.filter { device in
            mapToDeviceType(
                entityId: device.entityId,
                deviceClass: device.deviceClass,
                attributes: device.attributes
            ) == deviceType
        }
    }
    
    // MARK: - Private API Methods
    private func fetchDevicesFromHomeAssistant() async throws -> [HADevice] {
        let config = HomeAssistantConfig.load()
        guard config.isConfigured else {
            throw HomeAssistantError.notConfigured
        }
        
        guard let url = URL(string: "\(config.serverURL)/api/states") else {
            throw HomeAssistantError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HomeAssistantError.badResponse
        }
        
        // Parse the JSON response
        let decoder = JSONDecoder()
        let states = try decoder.decode([HAStateResponse].self, from: data)
        
        return states.compactMap { state in
            HADevice(
                id: state.entityId,
                name: state.attributes["friendly_name"]?.stringValue,
                entityId: state.entityId,
                state: state.state,
                attributes: state.attributes,
                deviceClass: state.attributes["device_class"]?.stringValue,
                platform: state.attributes["platform"]?.stringValue,
                area: state.attributes["area_id"]?.stringValue,
                zone: state.attributes["zone"]?.stringValue
            )
        }
    }
    
    private func fetchAreasFromHomeAssistant() async throws -> [HAArea] {
        let config = HomeAssistantConfig.load()
        guard config.isConfigured else {
            throw HomeAssistantError.notConfigured
        }
        
        guard let url = URL(string: "\(config.serverURL)/api/config/area_registry") else {
            throw HomeAssistantError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HomeAssistantError.badResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([HAArea].self, from: data)
    }
    
    private func fetchZonesFromHomeAssistant() async throws -> [HAZone] {
        let config = HomeAssistantConfig.load()
        guard config.isConfigured else {
            throw HomeAssistantError.notConfigured
        }
        
        guard let url = URL(string: "\(config.serverURL)/api/states") else {
            throw HomeAssistantError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HomeAssistantError.badResponse
        }
        
        let decoder = JSONDecoder()
        let states = try decoder.decode([HAStateResponse].self, from: data)
        
        // Filter for zone entities
        return states.compactMap { state in
            guard state.entityId.hasPrefix("zone.") else { return nil }
            
            return HAZone(
                id: state.entityId,
                name: state.attributes["friendly_name"] as? String ?? state.entityId,
                icon: state.attributes["icon"] as? String,
                latitude: state.attributes["latitude"] as? Double,
                longitude: state.attributes["longitude"] as? Double,
                radius: state.attributes["radius"] as? Double,
                passive: state.attributes["passive"] as? Bool
            )
        }
    }
}

// MARK: - Helper Models
private struct HAStateResponse: Codable {
    let entityId: String
    let state: String
    let attributes: [String: CodableValue]
    
    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
    }
}

// MARK: - Error Types
enum HomeAssistantError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case badResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Home Assistant is not configured"
        case .invalidURL:
            return "Invalid Home Assistant URL"
        case .badResponse:
            return "Bad response from Home Assistant"
        case .decodingError:
            return "Failed to decode Home Assistant response"
        }
    }
}

// MARK: - CodableValue Extension for String Extraction
extension CodableValue {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        default:
            return nil
        }
    }
}

// MARK: - HADevice Extension for Device Type
extension HADevice {
    var type: DeviceType? {
        let domain = entityId.split(separator: ".").first?.lowercased() ?? ""
        
        switch domain {
        case "light":
            return .lights
        case "switch":
            let lowerEntityId = entityId.lowercased()
            if lowerEntityId.contains("dishwasher") { return .dishwasher }
            if lowerEntityId.contains("fridge") || lowerEntityId.contains("refrigerator") { return .fridge }
            if lowerEntityId.contains("oven") { return .oven }
            if lowerEntityId.contains("stove") { return .stove }
            if lowerEntityId.contains("washer") { return .washer }
            if lowerEntityId.contains("dryer") { return .dryer }
            if lowerEntityId.contains("coffee") { return .coffeemaker }
            if lowerEntityId.contains("tv") { return .tv }
            if lowerEntityId.contains("music") || lowerEntityId.contains("speaker") { return .music }
            if lowerEntityId.contains("streamer") { return .streamer }
            if lowerEntityId.contains("avr") || lowerEntityId.contains("receiver") { return .avr }
            return nil
        case "cover":
            return .blinds
        case "climate":
            return .temp
        case "lock":
            return .lock
        case "camera":
            return .cameras
        default:
            return nil
        }
    }
}