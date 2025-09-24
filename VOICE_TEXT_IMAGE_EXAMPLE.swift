// 🎙️ Voice Trigger → Text & Image Rendering Example
// This file demonstrates the complete flow from voice input to visual output

import SwiftUI

// MARK: - 1. Voice Trigger Button
struct VoiceTriggerExample: View {
    @StateObject var viewModel = HealthEducationViewModel.shared
    
    var body: some View {
        Button(action: {
            // START VOICE INPUT
            viewModel.startVoiceInput()
        }) {
            Image(systemName: "mic.fill")
                .font(.title)
                .foregroundColor(.red)
        }
    }
}

// MARK: - 2. Voice Input Processing
extension HealthEducationViewModel {
    
    func handleVoiceInput() {
        // Example: User says "What is autonomic dysreflexia?"
        let voiceTranscript = "What is autonomic dysreflexia?"
        
        // Add to chat as user message
        let userMessage = HealthChatMessage(
            content: voiceTranscript,
            isUser: true
        )
        messages.append(userMessage)
        
        // Process through API
        Task {
            await fetchHealthEducationResponse(query: voiceTranscript)
        }
    }
    
    // MARK: - 3. API Call & Response Processing
    func fetchHealthEducationResponse(query: String) async {
        // API returns this structure:
        let apiResponse = """
        {
            "answer": "Autonomic Dysreflexia (AD) is a potentially life-threatening medical emergency that affects people with spinal cord injuries at T6 or above. It occurs when there is an irritation, pain, or stimulus below the level of injury that the body cannot properly regulate. The condition causes a sudden and severe increase in blood pressure, typically 20-40 mmHg above baseline. Common triggers include bladder distension, bowel impaction, pressure sores, tight clothing, or temperature extremes. Symptoms include severe headache, profuse sweating above the injury level, facial flushing, nasal congestion, goosebumps, and bradycardia. Immediate treatment involves sitting the person upright, loosening tight clothing, and identifying/removing the trigger. If blood pressure remains elevated, emergency medical attention is required.",
            
            "voice_answer": "It's when your blood pressure suddenly spikes way above normal, which can be really dangerous. Check your screen for complete details and warning signs.",
            
            "images": [
                {
                    "imageId": "ad_anatomy_01",
                    "base64Data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
                    "description": "Anatomical diagram showing nerve pathways affected in AD",
                    "pageNumber": 3,
                    "documentSource": "SCI Medical Guide 2024"
                },
                {
                    "imageId": "ad_symptoms_02", 
                    "base64Data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
                    "description": "Visual guide to recognizing AD symptoms",
                    "pageNumber": 5,
                    "documentSource": "Emergency Response Protocol"
                }
            ],
            
            "sources": ["SCI Medical Guide 2024", "Emergency Response Protocol"],
            "confidence": 0.95,
            "pageReferences": [3, 5, 7, 12]
        }
        """
        
        // Parse response
        let response = try! JSONDecoder().decode(HealthEducationResponse.self, from: apiResponse.data(using: .utf8)!)
        
        // MARK: - 4. Process Images
        var decodedImages: [Data] = []
        for imageData in response.images ?? [] {
            if let base64 = imageData.base64Data,
               let data = Data(base64Encoded: base64) {
                decodedImages.append(data)
            }
        }
        
        // MARK: - 5. Create Chat Message with Text & Images
        let assistantMessage = HealthChatMessage(
            content: response.answer,              // Full detailed text
            isUser: false,
            sources: response.sources,
            confidence: response.confidence,
            images: response.images,               // Image metadata
            decodedImages: decodedImages,          // Actual image data
            voiceAnswer: response.voiceAnswer,     // Brief voice summary
            pageReferences: response.pageReferences
        )
        
        // Add to UI
        await MainActor.run {
            messages.append(assistantMessage)
        }
        
        // MARK: - 6. Speak Brief Summary (Voice Output)
        let voiceSummary = response.voiceAnswer ?? generateBriefSummary(from: response.answer)
        await callManager.speakResponse(voiceSummary)
        // Voice says: "It's when your blood pressure suddenly spikes way above normal, 
        //              which can be really dangerous. Check your screen for complete details and warning signs."
    }
    
    func generateBriefSummary(from text: String) -> String {
        // Take first 1-2 sentences, max 150 characters
        let sentences = text.components(separatedBy: ". ")
        var summary = sentences.first ?? ""
        
        if summary.count > 150 {
            summary = String(summary.prefix(147)) + "..."
        }
        
        return summary + " Check your screen for complete details."
    }
}

// MARK: - 7. UI Rendering (Text + Images)
struct MessageBubbleWithImages: View {
    let message: HealthChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: Text Content
            Text(message.content)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
            
            // MARK: Images
            if let images = message.decodedImages, !images.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                        if let uiImage = UIImage(data: imageData),
                           let metadata = message.images?[index] {
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Display Image
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                // Image Caption
                                if let description = metadata.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Source Info
                                HStack {
                                    if let page = metadata.pageNumber {
                                        Label("Page \(page)", systemImage: "doc.text")
                                            .font(.caption2)
                                    }
                                    
                                    if let source = metadata.documentSource {
                                        Text("• \(source)")
                                            .font(.caption2)
                                    }
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // MARK: Metadata
            HStack(spacing: 16) {
                if let sources = message.sources, !sources.isEmpty {
                    Label("\(sources.count) sources", systemImage: "doc.text")
                        .font(.caption)
                }
                
                if let confidence = message.confidence {
                    Label("\(Int(confidence * 100))%", systemImage: "checkmark.shield")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - 8. Complete Voice Animation View
struct VoiceListeningAnimation: View {
    @State private var animationAmount = 1.0
    let isListening: Bool
    let transcribedText: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Animated bars
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 4, height: CGFloat.random(in: 10...40))
                        .scaleEffect(animationAmount)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: animationAmount
                        )
                }
            }
            .frame(height: 40)
            .onAppear { animationAmount = 2.0 }
            
            // Transcribed text preview
            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal)
            } else if isListening {
                Text("Listening...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - 9. Test Function
func testVoiceTriggerFlow() {
    let viewModel = HealthEducationViewModel.shared
    
    // Simulate voice input
    viewModel.transcribedText = "What are the symptoms of a UTI?"
    
    // Process it
    viewModel.processVoiceInput()
    
    // Expected output:
    // 1. User message added to chat: "What are the symptoms of a UTI?"
    // 2. API called with query
    // 3. Response received with:
    //    - Full text explanation
    //    - Images (if available)
    //    - Brief voice summary
    // 4. Screen shows: Complete text + Images
    // 5. Voice speaks: "You'd typically see fever, cloudy or smelly urine, 
    //                   and maybe increased muscle spasms. Check your screen for the complete list."
}

// MARK: - 10. Usage Example
struct HealthEducationChatView: View {
    @StateObject var viewModel = HealthEducationViewModel.shared
    
    var body: some View {
        VStack {
            // Chat messages with text and images
            ScrollView {
                ForEach(viewModel.messages) { message in
                    MessageBubbleWithImages(message: message)
                }
            }
            
            // Voice input button
            HStack {
                Button(action: { viewModel.startVoiceInput() }) {
                    Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                        .foregroundColor(viewModel.isListening ? .red : .gray)
                }
                
                TextField("Type a question...", text: $viewModel.currentInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    viewModel.sendMessage()
                }
            }
            .padding()
        }
    }
}

// MARK: - Data Models
struct HealthEducationResponse: Codable {
    let answer: String
    let voiceAnswer: String?
    let images: [ImageData]?
    let sources: [String]
    let confidence: Double?
    let pageReferences: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case answer
        case voiceAnswer = "voice_answer"
        case images
        case sources
        case confidence
        case pageReferences = "page_references"
    }
}

struct ImageData: Codable {
    let imageId: String?
    let base64Data: String?
    let description: String?
    let pageNumber: Int?
    let documentSource: String?
    
    enum CodingKeys: String, CodingKey {
        case imageId = "image_id"
        case base64Data = "base64_data"
        case description
        case pageNumber = "page_number"
        case documentSource = "document_source"
    }
}