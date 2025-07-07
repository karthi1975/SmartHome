//
//  SettingsView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//


import SwiftUI
//import LiveKit
import Speech

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var config: HomeAssistantConfig = HomeAssistantConfig.load()
    @State private var vapiConfig: VAPIConfig = VAPIConfig.load()
    @State private var zammadConfig: ZammadConfig = ZammadConfig.load()
    @State private var url: String = ""
    @State private var token: String = ""
    @State private var vapiPublicKey: String = ""
    @State private var vapiAssistantId: String = ""
    @State private var zammadBaseURL: String = ""
    @State private var zammadApiToken: String = ""
    @State private var isTesting = false
    @State private var testResultMessage: String = ""
    @State private var testResultSuccess: Bool = false
    
    var body: some View {
        ZStack {
            NavigationView {
            Form {
                Section(header: Text("Home Assistant Connection")) {
                    TextField("API URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("Long-Lived Access Token", text: $token)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("VAPI Voice Assistant Configuration")) {
                    TextField("Public Key", text: $vapiPublicKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                    TextField("Assistant ID", text: $vapiAssistantId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                }
                
                Section(header: Text("Zammad Support System Configuration")) {
                    TextField("Base URL (e.g., http://localhost:8080/api/v1)", text: $zammadBaseURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("API Token", text: $zammadApiToken)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                }
                
                Section {
                    Button(action: save) {
                        Text("Save All Settings")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(url.isEmpty || token.isEmpty || vapiPublicKey.isEmpty || vapiAssistantId.isEmpty || zammadBaseURL.isEmpty || zammadApiToken.isEmpty)
                    Button(action: testConnection) {
                        if isTesting {
                            ProgressView()
                        } else {
                            Text("Test Home Assistant Connection")
                        }
                    }
                    .disabled(url.isEmpty || token.isEmpty || isTesting)
                    if !testResultMessage.isEmpty {
                        Text(testResultMessage)
                            .foregroundColor(testResultSuccess ? .green : .red)
                            .font(.subheadline)
                            .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image("tetradapt-main-logo-BLKWHT")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                        Text("TETR")
                            .font(.system(size: 22, weight: .bold, design: .default))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 8)
                }
            }
            .onAppear {
                config = HomeAssistantConfig.load()
                vapiConfig = VAPIConfig.load()
                zammadConfig = ZammadConfig.load()
                url = config.serverURL
                token = config.token
                vapiPublicKey = vapiConfig.publicKey
                vapiAssistantId = vapiConfig.assistantId
                zammadBaseURL = zammadConfig.baseURL
                zammadApiToken = zammadConfig.apiToken
            }
            }
            GlobalMicrophoneOverlay()
        }
    }
    
    private func save() {
        config.serverURL = url
        config.token = token
        config.isConfigured = !url.isEmpty && !token.isEmpty
        config.save()
        
        vapiConfig.publicKey = vapiPublicKey
        vapiConfig.assistantId = vapiAssistantId
        vapiConfig.isConfigured = !vapiPublicKey.isEmpty && !vapiAssistantId.isEmpty
        vapiConfig.save()
        
        zammadConfig.baseURL = zammadBaseURL
        zammadConfig.apiToken = zammadApiToken
        zammadConfig.isConfigured = !zammadBaseURL.isEmpty && !zammadApiToken.isEmpty
        zammadConfig.save()
    }
    
    private func testConnection() {
        isTesting = true
        testResultMessage = ""
        Task {
            let config = HomeAssistantConfig.load()
            guard let url = URL(string: "\(config.serverURL)/api/") else {
                await MainActor.run {
                    testResultMessage = "Invalid URL."
                    testResultSuccess = false
                    isTesting = false
                }
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        await MainActor.run {
                            testResultMessage = "Connection successful!"
                            testResultSuccess = true
                        }
                    } else {
                        let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                        await MainActor.run {
                            testResultMessage = "Error: \(httpResponse.statusCode)\n\(errorBody)"
                            testResultSuccess = false
                        }
                    }
                } else {
                    await MainActor.run {
                        testResultMessage = "No response from server."
                        testResultSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    testResultMessage = error.localizedDescription
                    testResultSuccess = false
                }
            }
            await MainActor.run { isTesting = false }
        }
    }
}
