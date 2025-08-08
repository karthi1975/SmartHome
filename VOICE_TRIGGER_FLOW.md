# 🎙️ Voice Trigger to Text & Image Rendering - Health Education Chat

## Overview
This document explains how voice triggers work to fetch and display text and images in the Health Education chat page.

## 🔄 Complete Voice Flow

### 1. Voice Input Trigger (HealthEducationView.swift:236-248)
```swift
// Voice button in UI
Button(action: {
    if viewModel.isListening {
        viewModel.stopVoiceInput()
    } else {
        viewModel.startVoiceInput()  // ← VOICE TRIGGER STARTS HERE
    }
}) {
    Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
    .foregroundColor(viewModel.isListening ? .red : Color(red: 172/255, green: 32/255, blue: 41/255))
}
```

### 2. Voice Input Processing (HealthEducationViewModel.swift:456-500)
```swift
func startVoiceInput() {
    isListening = true
    showVoiceAnimation = true
    
    // Switch to health education context (applies Tree of Thought)
    callManager.switchToHealthEducationContext()
    
    // Listen for transcription updates
    NotificationCenter.default.addObserver(
        forName: NSNotification.Name("TranscriptionUpdate"),
        object: nil,
        queue: .main
    ) { [weak self] notification in
        if let transcript = notification.userInfo?["transcript"] as? String {
            self?.transcribedText = transcript
        }
    }
    
    // Listen for when user stops speaking
    NotificationCenter.default.addObserver(
        forName: NSNotification.Name("UserStoppedSpeaking"),
        object: nil,
        queue: .main
    ) { [weak self] notification in
        if !self.transcribedText.isEmpty {
            self.processVoiceInput() // ← TRIGGER API CALL
        }
    }
}
```

### 3. Process Voice Input → API Call (HealthEducationViewModel.swift:502-542)
```swift
private func processVoiceInput() {
    let userMessage = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Add user message to chat UI
    messages.append(HealthChatMessage(content: userMessage, isUser: true))
    
    // Process query through API
    Task {
        await processQuery(userMessage) // ← CALLS HEALTH EDUCATION API
    }
}
```

### 4. API Call & Response Processing (HealthEducationViewModel.swift:198-453)
```swift
private func processQuery(_ query: String) async {
    // Call Health Education API
    let response = try await api.askQuestion(query, chatHistory: chatHistory)
    
    // Response contains:
    // - answer: Full detailed text
    // - images: Array of image data with metadata
    // - voice_answer: Optional brief summary for voice
    
    // DECODE IMAGES
    var decodedImages: [Data]? = nil
    if let images = response.images, !images.isEmpty {
        decodedImages = []
        for imageData in images {
            if let base64String = imageData.base64Data {
                // Decode base64 image
                let cleanBase64 = base64String
                    .replacingOccurrences(of: "data:image/png;base64,", with: "")
                    .replacingOccurrences(of: " ", with: "")
                
                if let data = Data(base64Encoded: cleanBase64) {
                    decodedImages?.append(data)
                }
            }
        }
    }
    
    // CREATE UI MESSAGE WITH TEXT AND IMAGES
    let newMessage = HealthChatMessage(
        content: response.answer,           // ← FULL TEXT FOR SCREEN
        isUser: false,
        images: response.images,            // ← IMAGE METADATA
        decodedImages: decodedImages,       // ← DECODED IMAGE DATA
        voiceAnswer: response.voiceAnswer   // ← BRIEF VOICE SUMMARY
    )
    
    messages.append(newMessage)
    
    // GENERATE VOICE RESPONSE
    let voiceSummary: String
    if let providedVoiceAnswer = response.voiceAnswer {
        voiceSummary = providedVoiceAnswer  // Use backend-provided brief summary
    } else {
        // Auto-generate brief summary (first 1-2 sentences)
        voiceSummary = generateBriefVoiceSummary(from: response.answer, query: query)
    }
    
    // SPEAK BRIEF SUMMARY (10-15 seconds)
    await callManager.speakResponse(voiceSummary)
}
```

### 5. Render Text & Images in UI (HealthEducationView.swift:291-573)
```swift
struct MessageBubble: View {
    let message: HealthChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // TEXT CONTENT
            Text(message.content)  // ← FULL DETAILED TEXT
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(16)
            
            // IMAGES WITH METADATA
            if let imageMetadata = message.images, !imageMetadata.isEmpty {
                if let decodedImages = message.decodedImages {
                    // RENDER IMAGES
                    if decodedImages.count == 1 {
                        // Single image - full width
                        if let imageData = decodedImages.first,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(8)
                        }
                    } else if decodedImages.count == 2 {
                        // Two images - side by side
                        HStack(spacing: 8) {
                            ForEach(decodedImages, id: \.self) { imageData in
                                if let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 200)
                                }
                            }
                        }
                    } else {
                        // 3+ images - horizontal scroll
                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(decodedImages, id: \.self) { imageData in
                                    if let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .frame(width: 200, height: 200)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

## 🎯 Key Points

### Voice Trigger Flow:
1. **User taps mic button** → `startVoiceInput()`
2. **VAPI transcribes speech** → `TranscriptionUpdate` notification
3. **User stops speaking** → `UserStoppedSpeaking` notification
4. **Process voice input** → `processVoiceInput()`
5. **API call** → `api.askQuestion(query)`
6. **Decode images** → Base64 to Data conversion
7. **Render UI** → Text + Images displayed
8. **Speak summary** → Brief voice response (10-15 sec)

### Data Flow:
```
Voice Input → Transcription → API Call → Response {
    answer: "Full detailed text...",
    images: [base64 encoded images],
    voice_answer: "Brief summary"
} → UI Rendering {
    Screen: Full text + All images
    Voice: Brief summary only
}
```

## 📱 Example Interaction

**User speaks**: "What is autonomic dysreflexia?"

**System processes**:
1. VAPI transcribes: "What is autonomic dysreflexia?"
2. API called with query
3. API returns:
   - Full text explanation (500+ words)
   - 2-3 anatomical diagrams
   - Brief voice summary (30 words)

**User experiences**:
- **Hears** (10 sec): "It's when your blood pressure suddenly spikes way above normal, which can be really dangerous. Check your screen for complete details and images."
- **Sees on screen**:
  - Complete medical explanation
  - Anatomical diagrams showing nerve pathways
  - Warning signs checklist
  - Emergency protocol
  - Source references

## 🔧 Testing Voice Trigger

### Manual Test:
1. Open Health Education view
2. Tap microphone button
3. Say: "What are the symptoms of a UTI?"
4. Wait for response
5. Verify:
   - Voice speaks brief summary
   - Screen shows full text
   - Images are displayed if available

### Programmatic Test (HealthEducationViewModel.swift:875-888):
```swift
func testCompleteVoiceFlow() {
    // Simulate voice input
    transcribedText = "what is blood pressure in AD?"
    
    // Process the voice input (triggers full flow)
    processVoiceInput()
}
```

## 🎨 UI Voice Animation (HealthEducationView.swift:609-657)
```swift
struct VoiceInputAnimation: View {
    var body: some View {
        VStack {
            // Animated voice wave bars
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 4, height: CGFloat.random(in: 10...40))
                        .animation(.easeInOut(duration: 0.5))
                }
            }
            
            // Status text
            Text(isProcessing ? "Processing..." : "Listening...")
        }
    }
}
```

## 🔍 Debug Points

Enable debug logging to trace voice flow:

```swift
// In HealthEducationViewModel.swift
print("[DEBUG] 🎤 Starting voice input...")
print("[DEBUG] 🎤 Transcription updated: '\(transcript)'")
print("[DEBUG] 🎤 Processing voice input: '\(userMessage)'")
print("[DEBUG] 🌐 API Response received:")
print("  - Answer: \(response.answer)")
print("  - Images count: \(response.images?.count ?? 0)")
print("[DEBUG] ✅ Message added to UI with \(decodedImages?.count ?? 0) images")
```

## 📊 Performance Considerations

1. **Image Decoding**: Done asynchronously to prevent UI freezing
2. **Voice Summary**: Limited to 150 characters (~10-15 seconds)
3. **UI Updates**: Force refresh with `objectWillChange.send()`
4. **Memory**: Images are decoded on-demand, not preloaded

## 🚀 Quick Start Test

```bash
# Test the voice trigger flow
./test_complete_flow.sh

# Test just the API
./test_real_api.sh

# Test with hardcoded token
./test_hardcoded_token.sh
```

## 📝 Summary

The voice trigger system:
1. **Captures voice** via VAPI integration
2. **Transcribes** speech to text
3. **Calls API** with transcribed query
4. **Receives** full text + images + brief summary
5. **Renders** complete content on screen
6. **Speaks** only the brief summary

This separation ensures:
- Natural conversational voice (not reading long text)
- Complete visual information with images
- No cognitive overload from simultaneous audio/visual processing