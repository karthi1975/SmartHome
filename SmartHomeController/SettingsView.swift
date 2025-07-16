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
    @State private var isTestingZammad = false
    @State private var zammadTestResultMessage: String = ""
    @State private var zammadTestResultSuccess: Bool = false
    @State private var debugLoggingEnabled = false
    
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
                    TextField("Base URL (e.g., https://tickets.homeadapt.us/api/v1)", text: $zammadBaseURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("API Token", text: $zammadApiToken)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                    
                    Button(action: testZammadToken) {
                        HStack {
                            if isTestingZammad {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.shield")
                            }
                            Text("Test Zammad Token")
                        }
                    }
                    .disabled(zammadBaseURL.isEmpty || zammadApiToken.isEmpty || isTestingZammad)
                    
                    if !zammadTestResultMessage.isEmpty {
                        Text(zammadTestResultMessage)
                            .foregroundColor(zammadTestResultSuccess ? .green : .red)
                            .font(.subheadline)
                            .padding(.top, 4)
                    }
                }
                
                Section(header: Text("Debug & Testing")) {
                    Toggle("Enable Debug Logging", isOn: $debugLoggingEnabled)
                        .onChange(of: debugLoggingEnabled) { value in
                            UserDefaults.standard.set(value, forKey: "DebugLoggingEnabled")
                        }
                    
                    Button(action: testZammadPermissions) {
                        HStack {
                            if isTestingZammad {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "shield.checkered")
                            }
                            Text("Test Zammad Permissions")
                        }
                    }
                    .disabled(zammadBaseURL.isEmpty || zammadApiToken.isEmpty || isTestingZammad)
                    
                    Button(action: resetZammadConfig) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset Zammad Config")
                        }
                    }
                    .foregroundColor(.red)
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
                debugLoggingEnabled = UserDefaults.standard.bool(forKey: "DebugLoggingEnabled")
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
    
    private func testZammadToken() {
        isTestingZammad = true
        zammadTestResultMessage = ""
        zammadTestResultSuccess = false
        
        // Create a temporary ZammadConfig with the current settings
        let tempConfig = ZammadConfig(
            baseURL: zammadBaseURL,
            apiToken: zammadApiToken,
            isConfigured: true
        )
        
        // Save temporarily to test
        tempConfig.save()
        
        // Test different token formats
        ZammadClient.shared.testTokenFormats { result in
            DispatchQueue.main.async {
                self.isTestingZammad = false
                switch result {
                case .success(let message):
                    self.zammadTestResultMessage = "✅ Token works! \(message)"
                    self.zammadTestResultSuccess = true
                case .failure(let error):
                    self.zammadTestResultMessage = "❌ Token failed: \(error.localizedDescription)"
                    self.zammadTestResultSuccess = false
                }
            }
        }
    }
    
    private func testZammadPermissions() {
        isTestingZammad = true
        zammadTestResultMessage = ""
        zammadTestResultSuccess = false
        
        // Create a temporary ZammadConfig with the current settings
        let tempConfig = ZammadConfig(
            baseURL: zammadBaseURL,
            apiToken: zammadApiToken,
            isConfigured: true
        )
        
        // Save temporarily to test
        tempConfig.save()
        
        // Test creating a dummy ticket to check permissions
        ZammadClient.shared.createTicket(
            subject: "Test Ticket - Permission Check",
            body: "This is a test ticket to verify API permissions. This ticket can be deleted.",
            customer: "test@example.com",
            group: "Users",
            priority: "2 normal",
            attachment: nil
        ) { result in
            DispatchQueue.main.async {
                self.isTestingZammad = false
                switch result {
                case .success:
                    self.zammadTestResultMessage = "✅ Token has full permissions! Test ticket created successfully."
                    self.zammadTestResultSuccess = true
                case .failure(let error):
                    if let nsError = error as NSError?, nsError.code == 403 {
                        self.zammadTestResultMessage = "❌ Token authenticated but lacks permissions for ticket creation. Check token permissions in Zammad."
                    } else {
                        self.zammadTestResultMessage = "❌ Permission test failed: \(error.localizedDescription)"
                    }
                    self.zammadTestResultSuccess = false
                }
            }
        }
    }
    
    private func resetZammadConfig() {
        // Clear UserDefaults for ZammadConfig
        UserDefaults.standard.removeObject(forKey: "ZammadConfig")
        
        // Force synchronize to ensure the removal takes effect immediately
        UserDefaults.standard.synchronize()
        
        // Reset to default values
        zammadConfig = ZammadConfig.default
        zammadBaseURL = zammadConfig.baseURL
        zammadApiToken = zammadConfig.apiToken
        
        // Clear test results
        zammadTestResultMessage = "✅ Configuration reset to defaults"
        zammadTestResultSuccess = true
        
        print("DEBUG: Reset Zammad config - URL: \(zammadBaseURL), Token: \(zammadApiToken)")
    }
}
