import SwiftUI

struct DeviceDetailView: View {
    let deviceName: String
    @State private var responseText: String = ""
    @EnvironmentObject var api: HomeAssistantAPI
    
    // Map the device name to a specific command if needed.
    var command: String {
        let lower = deviceName.lowercased()
        if lower == "light switch" {
            return "switch on living room light"
        }
        return "turn on \(lower)"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(deviceName)
                .font(.largeTitle)
                .padding()
            
            Button("Send 'Turn On' Command") {
                Task {
                    do {
                        let result = try await api.sendConversationCommand(command)
                        responseText = result
                    } catch {
                        responseText = "Error: \(error.localizedDescription)"
                    }
                }
            }
            .padding()
            
            if !responseText.isEmpty {
                Text("Response: \(responseText)")
                    .padding()
            }
            
            Spacer()
        }
        .navigationTitle(deviceName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
