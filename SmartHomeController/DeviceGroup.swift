import Foundation

struct DeviceGroup: Codable, Identifiable {
    let id: UUID
    var name: String
    var devices: [String] // Array of device IDs
    var type: GroupType
    var icon: String
    var description: String
    
    enum GroupType: String, Codable {
        case room = "room"
        case scene = "scene"
        case automation = "automation"
        case custom = "custom"
    }
}

class DeviceGroupManager: ObservableObject {
    @Published private(set) var groups: [DeviceGroup] = []
    private let userDefaults = UserDefaults.standard
    private let groupsKey = "device_groups"
    
    init() {
        loadGroups()
    }
    
    func addGroup(name: String, devices: [String], type: DeviceGroup.GroupType, icon: String, description: String) {
        let group = DeviceGroup(
            id: UUID(),
            name: name,
            devices: devices,
            type: type,
            icon: icon,
            description: description
        )
        
        groups.append(group)
        saveGroups()
    }
    
    func updateGroup(_ group: DeviceGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
        }
    }
    
    func removeGroup(_ group: DeviceGroup) {
        groups.removeAll { $0.id == group.id }
        saveGroups()
    }
    
    func groupsForDevice(_ deviceId: String) -> [DeviceGroup] {
        groups.filter { $0.devices.contains(deviceId) }
    }
    
    func addDeviceToGroup(_ deviceId: String, groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            var group = groups[index]
            if !group.devices.contains(deviceId) {
                group.devices.append(deviceId)
                groups[index] = group
                saveGroups()
            }
        }
    }
    
    func removeDeviceFromGroup(_ deviceId: String, groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            var group = groups[index]
            group.devices.removeAll { $0 == deviceId }
            groups[index] = group
            saveGroups()
        }
    }
    
    private func saveGroups() {
        if let encoded = try? JSONEncoder().encode(groups) {
            userDefaults.set(encoded, forKey: groupsKey)
        }
    }
    
    private func loadGroups() {
        if let data = userDefaults.data(forKey: groupsKey),
           let decoded = try? JSONDecoder().decode([DeviceGroup].self, from: data) {
            groups = decoded
        }
    }
} 