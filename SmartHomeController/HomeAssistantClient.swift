import Foundation
import Combine

class HomeAssistantClient: ObservableObject {
    static let shared = HomeAssistantClient()
    private var config: HomeAssistantConfig { HomeAssistantConfig.load() }

    @Published var isConnected: Bool = false
    @Published var discoveredDevices: [SmartDevice] = []

    private init() {}

    func callService(domain: String, service: String, entityId: String? = nil, data: [String: Any]? = nil) async throws {
        guard config.isConfigured else { throw URLError(.userAuthenticationRequired) }
        guard let url = URL(string: "\(config.serverURL)/api/services/\(domain)/\(service)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var serviceData: [String: Any] = [:]
        if let entityId = entityId { serviceData["entity_id"] = entityId }
        if let data = data { serviceData.merge(data) { $1 } }
        request.httpBody = try? JSONSerialization.data(withJSONObject: serviceData)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func testConnection() async -> Bool {
        guard let url = URL(string: "\(config.serverURL)/api/") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return true
            }
        } catch {}
        return false
    }

    // Stub for AddDeviceView
    func discoverDevices() async throws {
        // TODO: Implement device discovery
    }

    // Example: Add more methods as needed (getStates, etc.)
} 