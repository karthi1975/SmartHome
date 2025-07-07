import SwiftUI

struct HomeAssistantConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL: String = HomeAssistantConfig.load().serverURL
    @State private var token: String = HomeAssistantConfig.load().token
    @State private var isTesting = false
    @State private var testResult: String? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration")) {
                    TextField("Server URL", text: $serverURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    SecureField("Long-Lived Access Token", text: $token)
                        .autocapitalization(.none)
                }
                Section {
                    Button(action: saveConfig) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                }
                Section {
                    Button(action: testConnection) {
                        if isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Test Connection")
                        }
                    }
                }
                if let testResult = testResult {
                    Section {
                        Text(testResult)
                            .foregroundColor(testResult == "Success!" ? .green : .red)
                    }
                }
            }
            .navigationTitle("Home Assistant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveConfig() {
        let config = HomeAssistantConfig(serverURL: serverURL, token: token, isConfigured: !serverURL.isEmpty && !token.isEmpty)
        config.save()
        alertMessage = "Settings saved!"
        showAlert = true
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            let ok = await HomeAssistantClient.shared.testConnection()
            await MainActor.run {
                isTesting = false
                testResult = ok ? "Success!" : "Failed to connect. Check URL and token."
            }
        }
    }
} 