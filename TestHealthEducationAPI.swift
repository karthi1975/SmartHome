import Foundation
import SwiftUI

// Test script to verify the Health Education API connection
// This script simulates the full flow: STT -> Notification -> API Call

@MainActor
class TestHealthEducationAPI {
    private let api = HealthEducationAPI.shared
    private let settings = HealthEducationSettings.shared
    
    func runTests() async {
        print("\n==== Starting Health Education API Tests ====\n")
        
        // Test 1: Check API Configuration
        print("Test 1: Checking API Configuration...")
        print("  - Base URL: \(settings.apiBaseURL)")
        print("  - Token exists: \(!settings.apiToken.isEmpty)")
        print("  - Is configured: \(settings.isConfigured)")
        
        // Test 2: Perform Auto-login
        print("\nTest 2: Attempting Auto-login...")
        await api.performAutoLogin()
        print("  - Authentication status: \(api.isAuthenticated)")
        
        // Test 3: Test Direct API Call
        if api.isAuthenticated {
            print("\nTest 3: Testing Direct API Call...")
            do {
                let testQuery = "what is blood pressure in AD?"
                print("  - Query: '\(testQuery)'")
                
                let response = try await api.askQuestion(testQuery, includeImages: true)
                
                print("  - Response received!")
                print("    - Answer length: \(response.answer.count) characters")
                print("    - Images count: \(response.images?.count ?? 0)")
                print("    - Sources count: \(response.sources.count)")
                
                if let images = response.images {
                    for (index, img) in images.enumerated() {
                        print("    - Image \(index + 1):")
                        print("      - ID: \(img.imageId ?? "nil")")
                        print("      - Has base64: \(img.base64Data != nil)")
                        print("      - Base64 length: \(img.base64Data?.count ?? 0)")
                        print("      - Has URL: \(img.imageUrl != nil)")
                        print("      - Description: \(img.description ?? "nil")")
                    }
                }
                
                // Print first 200 chars of answer
                let preview = String(response.answer.prefix(200))
                print("    - Answer preview: \(preview)...")
                
            } catch {
                print("  - Error: \(error)")
            }
        } else {
            print("\nTest 3: Skipped (not authenticated)")
        }
        
        // Test 4: Simulate STT -> Notification flow
        print("\nTest 4: Simulating STT to API flow...")
        print("  - Creating HealthEducationViewModel...")
        let viewModel = HealthEducationViewModel()
        
        // Wait for initialization
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        print("  - ViewModel initialized:")
        print("    - Is configured: \(viewModel.isConfigured)")
        print("    - Messages count: \(viewModel.messages.count)")
        
        // Post notification to simulate STT transcript
        print("  - Posting notification to simulate STT transcript...")
        let testMessage = "what is autonomic dysreflexia?"
        
        NotificationCenter.default.post(
            name: NSNotification.Name("HealthEducationUserMessage"),
            object: nil,
            userInfo: ["message": testMessage]
        )
        
        print("  - Notification posted with message: '\(testMessage)'")
        
        // Wait for processing
        print("  - Waiting for API response...")
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        print("  - Final state:")
        print("    - Messages count: \(viewModel.messages.count)")
        print("    - Is loading: \(viewModel.isLoading)")
        print("    - Error: \(viewModel.error ?? "none")")
        
        // Print messages
        for (index, msg) in viewModel.messages.enumerated() {
            print("\n  Message \(index + 1):")
            print("    - Is user: \(msg.isUser)")
            print("    - Content preview: \(String(msg.content.prefix(100)))...")
            print("    - Has images: \(msg.images != nil)")
            print("    - Images count: \(msg.images?.count ?? 0)")
            print("    - Decoded images count: \(msg.decodedImages?.count ?? 0)")
        }
        
        print("\n==== Tests Complete ====\n")
    }
}

// Run the test
Task {
    let tester = TestHealthEducationAPI()
    await tester.runTests()
}