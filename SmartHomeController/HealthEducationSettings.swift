import Foundation
import SwiftUI

// MARK: - Health Education Settings
class HealthEducationSettings: ObservableObject {
    static let shared = HealthEducationSettings()
    
    @Published var apiBaseURL: String {
        didSet {
            UserDefaults.standard.set(apiBaseURL, forKey: "healthEducationAPIBaseURL")
        }
    }
    
    @Published var apiToken: String {
        didSet {
            // Store in Keychain for security in production
            UserDefaults.standard.set(apiToken, forKey: "healthEducationAPIToken")
        }
    }
    
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "healthEducationUsername")
        }
    }
    
    @Published var isConfigured: Bool {
        didSet {
            UserDefaults.standard.set(isConfigured, forKey: "healthEducationConfigured")
        }
    }
    
    @Published var autoLoginUsername: String {
        didSet {
            UserDefaults.standard.set(autoLoginUsername, forKey: "healthEducationAutoLoginUsername")
        }
    }
    
    @Published var autoLoginPassword: String {
        didSet {
            UserDefaults.standard.set(autoLoginPassword, forKey: "healthEducationAutoLoginPassword")
        }
    }
    
    private init() {
        // Load from UserDefaults (use Keychain in production)
        self.apiBaseURL = UserDefaults.standard.string(forKey: "healthEducationAPIBaseURL") ?? "http://209.38.150.181:8000"
        
        // HARDCODED TOKEN FOR IMMEDIATE USE
        // Note: This token expires after 24 hours. Generate new token with:
        // curl -X POST http://209.38.150.181:8000/auth/login -d "username=admin&password=admin123"
        let hardcodedToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NDY3NjgxOH0.SoNdU8muI14yVnQ0CzM1uvH6F6oBowJsCblQTKdKZhs"
        
        // Use saved token if exists, otherwise use hardcoded token
        let savedToken = UserDefaults.standard.string(forKey: "healthEducationAPIToken") ?? ""
        if !savedToken.isEmpty {
            self.apiToken = savedToken
        } else {
            // Use hardcoded token and save it
            self.apiToken = hardcodedToken
            UserDefaults.standard.set(hardcodedToken, forKey: "healthEducationAPIToken")
        }
        
        self.username = UserDefaults.standard.string(forKey: "healthEducationUsername") ?? "admin"
        self.isConfigured = true  // Always configured with hardcoded token
        
        // Set default auto-login credentials to admin
        self.autoLoginUsername = UserDefaults.standard.string(forKey: "healthEducationAutoLoginUsername") ?? "admin"
        self.autoLoginPassword = UserDefaults.standard.string(forKey: "healthEducationAutoLoginPassword") ?? "admin123"
    }
    
    func saveCredentials(username: String, token: String) {
        self.username = username
        self.apiToken = token
        self.isConfigured = !token.isEmpty
    }
    
    func saveToken(_ token: String) {
        self.apiToken = token
        self.isConfigured = !token.isEmpty
    }
    
    func clearSettings() {
        apiToken = ""
        username = ""
        isConfigured = false
    }
}

// MARK: - Settings View
struct HealthEducationSettingsView: View {
    @ObservedObject var settings = HealthEducationSettings.shared
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var urlInput: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoggingIn = false
    @State private var selectedRole = "doctor1"
    @Environment(\.dismiss) var dismiss
    
    let predefinedUsers = [
        ("admin", "admin123", "Administrator"),
        ("doctor1", "doctor123", "Doctor"),
        ("nurse1", "nurse123", "Nurse"),
        ("patient1", "patient123", "Patient"),
        ("caregiver1", "caregiver123", "Caregiver")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                if !settings.isConfigured {
                    Section(header: Text("Quick Login")) {
                        Picker("Select User", selection: $selectedRole) {
                            ForEach(predefinedUsers, id: \.0) { user in
                                Text("\(user.2) (\(user.0))").tag(user.0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button(action: quickLogin) {
                            if isLoggingIn {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Login as \(selectedRole)")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(isLoggingIn)
                    }
                    
                    Section(header: Text("Custom Login")) {
                        TextField("Username", text: $usernameInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Password", text: $passwordInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button(action: customLogin) {
                            if isLoggingIn {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Login")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(usernameInput.isEmpty || passwordInput.isEmpty || isLoggingIn)
                    }
                } else {
                    Section(header: Text("Current Session")) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.green)
                            Text("Logged in as: \(settings.username)")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: logout) {
                            Label("Logout", systemImage: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("API Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Base URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter API URL", text: $urlInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                if settings.isConfigured {
                    Section(header: Text("Actions")) {
                        Button(action: testConnection) {
                            Label("Test Connection", systemImage: "network")
                        }
                        
                        Button(action: logout) {
                            Label("Logout All Sessions", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Instructions")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To access Health Education:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("1. Select a predefined user or enter custom credentials")
                            .font(.caption)
                        Text("2. Click Login to authenticate")
                            .font(.caption)
                        Text("3. Start asking health-related questions")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Health Education Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .onAppear {
                urlInput = settings.apiBaseURL
            }
            .alert("Configuration", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func quickLogin() {
        isLoggingIn = true
        if let user = predefinedUsers.first(where: { $0.0 == selectedRole }) {
            Task {
                do {
                    try await HealthEducationAPI.shared.login(username: user.0, password: user.1)
                    settings.saveCredentials(username: user.0, token: HealthEducationAPI.shared.token)
                    alertMessage = "Successfully logged in as \(user.2)"
                    showingAlert = true
                } catch {
                    alertMessage = "Login failed: \(error.localizedDescription)"
                    showingAlert = true
                }
                isLoggingIn = false
            }
        }
    }
    
    private func customLogin() {
        isLoggingIn = true
        Task {
            do {
                try await HealthEducationAPI.shared.login(username: usernameInput, password: passwordInput)
                settings.saveCredentials(username: usernameInput, token: HealthEducationAPI.shared.token)
                alertMessage = "Successfully logged in"
                showingAlert = true
                passwordInput = "" // Clear password after login
            } catch {
                alertMessage = "Login failed: \(error.localizedDescription)"
                showingAlert = true
            }
            isLoggingIn = false
        }
    }
    
    private func logout() {
        HealthEducationAPI.shared.logout()
        usernameInput = ""
        passwordInput = ""
        alertMessage = "Logged out successfully"
        showingAlert = true
    }
    
    private func testConnection() {
        Task {
            do {
                let isHealthy = try await HealthEducationAPI.shared.checkHealth()
                alertMessage = isHealthy ? "Connection successful!" : "Connection failed"
            } catch {
                alertMessage = "Connection failed: \(error.localizedDescription)"
            }
            showingAlert = true
        }
    }
}