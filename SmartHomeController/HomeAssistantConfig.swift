import Foundation

struct HomeAssistantConfig: Codable {
    var serverURL: String
    var token: String
    var isConfigured: Bool
    
    static let `default` = HomeAssistantConfig(
        serverURL: "http://homeassistant.local:8123",
        token: "",
        isConfigured: false
    )
    
    static func load() -> HomeAssistantConfig {
        if let data = UserDefaults.standard.data(forKey: "HomeAssistantConfig"),
           let config = try? JSONDecoder().decode(HomeAssistantConfig.self, from: data) {
            return config
        }
        return .default
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "HomeAssistantConfig")
        }
    }
}

struct VAPIConfig: Codable {
    var publicKey: String
    var assistantId: String
    var isConfigured: Bool
    
    static let `default` = VAPIConfig(
        publicKey: "5237cafe-e298-49e5-9002-957a8f070d81",
        assistantId: "78a63676-e3f6-438d-88e9-33f53809df43",
        isConfigured: true  // Default to true since we have default values
    )
    
    static func load() -> VAPIConfig {
        if let data = UserDefaults.standard.data(forKey: "VAPIConfig"),
           let config = try? JSONDecoder().decode(VAPIConfig.self, from: data) {
            return config
        }
        return .default
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "VAPIConfig")
        }
    }
}

struct ZammadConfig: Codable {
    var baseURL: String
    var apiToken: String
    var isConfigured: Bool
    
    static let `default` = ZammadConfig(
        baseURL: "http://localhost:8080/api/v1",
        apiToken: "v1gmNy3Nkr29fk8C4HyuR5p9UFRdUJ3yO-Buzd6R_y9XWTIPbwfMVbTb5DMHS6pm",
        isConfigured: true  // Default to true since we have default values
    )
    
    static func load() -> ZammadConfig {
        if let data = UserDefaults.standard.data(forKey: "ZammadConfig"),
           let config = try? JSONDecoder().decode(ZammadConfig.self, from: data) {
            return config
        }
        return .default
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "ZammadConfig")
        }
    }
} 