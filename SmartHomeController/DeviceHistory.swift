import Foundation

struct DeviceEvent: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let timestamp: Date
    let eventType: EventType
    let oldValue: String?
    let newValue: String?
    let source: String
    
    enum EventType: String, Codable {
        case stateChange = "state_change"
        case serviceCall = "service_call"
        case error = "error"
        case discovery = "discovery"
        case configuration = "configuration"
    }
}

class DeviceHistoryManager: ObservableObject {
    @Published private(set) var events: [DeviceEvent] = []
    private let maxEvents = 1000
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "device_events"
    
    init() {
        loadEvents()
    }
    
    func addEvent(deviceId: String, type: DeviceEvent.EventType, oldValue: String? = nil, newValue: String? = nil, source: String = "app") {
        let event = DeviceEvent(
            id: UUID(),
            deviceId: deviceId,
            timestamp: Date(),
            eventType: type,
            oldValue: oldValue,
            newValue: newValue,
            source: source
        )
        
        events.insert(event, at: 0)
        if events.count > maxEvents {
            events.removeLast()
        }
        
        saveEvents()
    }
    
    func eventsForDevice(_ deviceId: String) -> [DeviceEvent] {
        events.filter { $0.deviceId == deviceId }
    }
    
    func clearHistory() {
        events.removeAll()
        saveEvents()
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            userDefaults.set(encoded, forKey: eventsKey)
        }
    }
    
    private func loadEvents() {
        if let data = userDefaults.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([DeviceEvent].self, from: data) {
            events = decoded
        }
    }
} 