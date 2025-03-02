//
//  HomeAssistantAPI.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//

import Foundation
import SwiftUI

class HomeAssistantAPI: ObservableObject {
    @AppStorage("homeAssistantURL") var baseURL: String = "http://localhost:8123"
    @AppStorage("homeAssistantToken") var token: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJiOTZkZGU0MGZkNGI0NjEwYTg1MzAyNTA2MzQyZGJhMyIsImlhdCI6MTczOTgyNzU4OCwiZXhwIjoyMDU1MTg3NTg4fQ.l-tm5pnI8Yi4-TwI8hXSVkAJl-HNnvICZvnT-0Ivbj8"

    /// Sends a conversation command to Home Assistant and returns the spoken response.
    func sendConversationCommand(_ command: String) async throws -> String {
        // Construct the URL from the base URL and endpoint.
        guard let url = URL(string: "\(baseURL)/api/conversation/process") else {
            throw URLError(.badURL)
        }
        
        // Create and configure the URLRequest.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["text": command, "language": "en"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Execute the request using async/await.
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Check for unauthorized status.
        if httpResponse.statusCode == 401 {
            if let responseText = String(data: data, encoding: .utf8) {
                print("❌ Unauthorized response: \(responseText)")
            }
            throw NSError(domain: "HomeAssistantAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: Invalid Token"])
        }
        
        // Debug: Print raw JSON response.
        if let jsonString = String(data: data, encoding: .utf8) {
            print("✅ Raw JSON Response from Home Assistant: \(jsonString)")
        }
        
        // Parse the JSON response.
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseDict = json["response"] as? [String: Any],
              let speechDict = responseDict["speech"] as? [String: Any],
              let plain = speechDict["plain"] as? [String: Any],
              let speech = plain["speech"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        return speech
    }
}
