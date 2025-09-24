import SwiftUI

struct TestHealthEducationFlow: View {
    @StateObject private var viewModel = HealthEducationViewModel.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test Health Education Flow")
                .font(.title)
            
            Button("Test Direct Message") {
                // Simulate sending a message directly
                viewModel.currentInput = "What is blood pressure in autonomic dysreflexia?"
                viewModel.sendMessage()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Test Notification") {
                // Simulate notification from VAPI
                NotificationCenter.default.post(
                    name: NSNotification.Name("HealthEducationUserMessage"),
                    object: nil,
                    userInfo: ["message": "What is blood pressure in autonomic dysreflexia?"]
                )
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if viewModel.isLoading {
                ProgressView("Loading...")
            }
            
            ScrollView {
                ForEach(viewModel.messages) { message in
                    HStack {
                        if message.isUser {
                            Spacer()
                            Text(message.content)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            VStack(alignment: .leading) {
                                Text(message.content)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                
                                if let images = message.images, !images.isEmpty {
                                    Text("Images: \(images.count)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if let error = viewModel.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            viewModel.checkConfiguration()
        }
    }
}