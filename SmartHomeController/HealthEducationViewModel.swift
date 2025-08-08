import Foundation
import SwiftUI

// MARK: - Chat Message Model
struct HealthChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let sources: [String]?
    let confidence: Double?
    let followUpSuggestions: [String]?
    let images: [ImageData]? // Enhanced image data with metadata
    let decodedImages: [Data]? // Decoded image data
    let voiceAnswer: String?
    let pageReferences: [Int]?
    let processingTime: Double?
    let modelUsed: String?
    
    init(content: String, isUser: Bool, sources: [String]? = nil, confidence: Double? = nil, 
         followUpSuggestions: [String]? = nil, images: [ImageData]? = nil, decodedImages: [Data]? = nil,
         voiceAnswer: String? = nil, pageReferences: [Int]? = nil,
         processingTime: Double? = nil, modelUsed: String? = nil) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.sources = sources
        self.confidence = confidence
        self.followUpSuggestions = followUpSuggestions
        self.images = images
        self.decodedImages = decodedImages
        self.voiceAnswer = voiceAnswer
        self.pageReferences = pageReferences
        self.processingTime = processingTime
        self.modelUsed = modelUsed
    }
}

// MARK: - Health Education View Model
@MainActor
class HealthEducationViewModel: ObservableObject {
    static let shared = HealthEducationViewModel()
    
    @Published var messages: [HealthChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var topics: [String] = []
    @Published var isListening = false
    @Published var transcribedText: String = ""
    @Published var showVoiceAnimation = false
    @Published var showSettings = false
    @Published var isConfigured: Bool = false
    
    private let api = HealthEducationAPI.shared
    private let settings = HealthEducationSettings.shared
    private var callManager: CallManager?
    private var chatHistory: [ChatMessage] = [] // API format history
    
    // Suggested questions for users
    let suggestedQuestions = [
        "What is blood pressure in AD?",
        "How do I prevent pressure injuries?",
        "What are the signs of a UTI?",
        "How should I manage my bowel routine?",
        "What exercises can I do safely?"
    ]
    
    private init() {
        print("[DEBUG] 🚀 HealthEducationViewModel singleton init")
        
        // Initialize immediately with hardcoded token
        isConfigured = true
        print("[DEBUG] 🚀 Token available: \(settings.apiToken.prefix(20))...")
        
        Task {
            await initializeChat()
        }
        
        // Listen for VAPI assistant responses globally
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HealthEducationAssistantResponse"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let response = notification.userInfo?["response"] as? String {
                print("[DEBUG] Received VAPI assistant response notification")
                self?.handleAssistantResponse(response)
            }
        }
        
        // Listen for user messages from VAPI
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HealthEducationUserMessage"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("[DEBUG] 🎯 HealthEducationUserMessage notification received in ViewModel")
            print("[DEBUG] Notification object: \(String(describing: notification.object))")
            print("[DEBUG] Notification userInfo: \(String(describing: notification.userInfo))")
            
            if let message = notification.userInfo?["message"] as? String {
                print("[DEBUG] 🎯 Received user message notification: '\(message)'")
                print("[DEBUG] isConfigured: \(self?.isConfigured ?? false)")
                print("[DEBUG] Current messages count: \(self?.messages.count ?? 0)")
                
                // Immediately handle the message
                DispatchQueue.main.async {
                    print("[DEBUG] 🎯 Calling handleUserMessage with: '\(message)'")
                    self?.handleUserMessage(message)
                }
            } else {
                print("[DEBUG] ❌ No message in notification userInfo")
            }
        }
    }
    
    func setCallManager(_ manager: CallManager) {
        self.callManager = manager
    }
    
    // MARK: - Initialization
    private func initializeChat() async {
        // Token is hardcoded, no need for auto-login
        isConfigured = true
        
        print("[DEBUG] Health Education API configured with hardcoded token")
        print("[DEBUG] Token available: \(settings.apiToken.prefix(20))...")
        
        // Load suggested topics
        topics = api.getSuggestedTopics()
        
        // Test API connection in debug mode
        #if DEBUG
        Task {
            print("[DEBUG] Testing API connection with hardcoded token...")
            await api.testAPIConnection()
        }
        #endif
    }
    
    // MARK: - Check Configuration
    func checkConfiguration() {
        print("[DEBUG] HealthEducation checkConfiguration called")
        print("[DEBUG] Using hardcoded token: \(settings.apiToken.prefix(20))...")
        
        // Always configured with hardcoded token
        isConfigured = true
        
        // Initialize if there are no messages yet
        if messages.isEmpty {
            print("[DEBUG] No messages, initializing chat")
            Task {
                await initializeChat()
            }
        } else {
            print("[DEBUG] Already configured with existing messages")
        }
    }
    
    // MARK: - Send Message
    func sendMessage() {
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[DEBUG] 📤 sendMessage() called with currentInput: '\(currentInput)'")
        print("[DEBUG] 📤 Trimmed input: '\(trimmedInput)'")
        
        guard !trimmedInput.isEmpty else { 
            print("[DEBUG] ❌ Empty input, not sending message")
            return 
        }
        
        let userMessage = trimmedInput
        print("[DEBUG] 📤 Sending message: '\(userMessage)'")
        
        // Add user message to UI immediately
        Task { @MainActor in
            let newMessage = HealthChatMessage(content: userMessage, isUser: true)
            messages.append(newMessage)
            print("[DEBUG] ✅ User message added to UI. Total messages: \(messages.count)")
            
            // Clear input and show loading
            currentInput = ""
            isLoading = true
            
            // Force UI update
            objectWillChange.send()
        }
        
        // Process the query
        Task {
            print("[DEBUG] 📤 Starting processQuery task for: '\(userMessage)'")
            await processQuery(userMessage)
            print("[DEBUG] 📤 processQuery task completed")
        }
    }
    
    // MARK: - Process Query
    private func processQuery(_ query: String) async {
        print("[DEBUG] 🚀🚀🚀 processQuery START")
        print("[DEBUG] 🚀 Query: '\(query)'")
        print("[DEBUG] 🚀 isConfigured: \(isConfigured)")
        print("[DEBUG] 🚀 API Token exists: \(!settings.apiToken.isEmpty)")
        print("[DEBUG] 🚀 Thread: \(Thread.current)")
        
        guard isConfigured else {
            print("[DEBUG] ❌ API not configured")
            await MainActor.run {
                self.error = "Please configure API settings first"
                self.isLoading = false
            }
            return
        }
        
        print("[DEBUG] 🚀 API is configured, proceeding with query")
        
        // Set loading state on main thread
        await MainActor.run {
            print("[DEBUG] 🚀 Setting loading state")
            self.isLoading = true
            self.error = nil
            self.objectWillChange.send()
        }
        
        do {
            print("[DEBUG] 🌐 About to call API.askQuestion")
            
            // Update chat history in API format
            chatHistory.append(ChatMessage(role: "user", content: query))
            
            // Keep only last 10 messages for context
            if chatHistory.count > 10 {
                chatHistory = Array(chatHistory.suffix(10))
            }
            
            print("[DEBUG] 🌐 Calling api.askQuestion with query: '\(query)'")
            let response = try await api.askQuestion(query, chatHistory: chatHistory)
            
            // Debug: Print response details
            print("[DEBUG] 🌐 API Response received:")
            print("  - Answer: \(response.answer)")
            print("  - Sources: \(response.sources)")
            print("  - Images count: \(response.images?.count ?? 0)")
            print("  - Model used: \(response.modelUsed ?? "Unknown")")
            
            // Decode images if present
            var decodedImages: [Data]? = nil
            
            // Check both images array and has_images flag
            print("[DEBUG] Has images flag: \(response.hasImages ?? false)")
            print("[DEBUG] Images array: \(response.images?.count ?? 0) items")
            
            if let images = response.images, !images.isEmpty {
                print("[DEBUG] Processing \(images.count) images...")
                decodedImages = []
                for (index, imageData) in images.enumerated() {
                    print("[DEBUG] Processing image \(index + 1):")
                    print("  - Image ID: \(imageData.imageId)")
                    print("  - Description: \(imageData.description ?? "None")")
                    print("  - Has base64: \(imageData.base64Data != nil)")
                    print("  - Has URL: \(imageData.imageUrl != nil)")
                    
                    if let base64String = imageData.base64Data {
                        // Clean base64 string (remove data URL prefix if present)
                        let cleanBase64 = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
                                                      .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                                                      .replacingOccurrences(of: "data:image/jpg;base64,", with: "")
                                                      .replacingOccurrences(of: "data:image/gif;base64,", with: "")
                                                      .replacingOccurrences(of: " ", with: "")
                                                      .replacingOccurrences(of: "\n", with: "")
                                                      .replacingOccurrences(of: "\r", with: "")
                        
                        // Try standard base64 decoding
                        if let data = Data(base64Encoded: cleanBase64) {
                            decodedImages?.append(data)
                            print("[DEBUG] Successfully decoded base64 image \(index + 1)")
                        } else if let data = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters) {
                            // Try with ignoring unknown characters
                            decodedImages?.append(data)
                            print("[DEBUG] Successfully decoded base64 image \(index + 1) with ignoreUnknownCharacters")
                        } else {
                            print("[DEBUG] Failed to decode base64 image \(index + 1)")
                            print("[DEBUG] Base64 string length: \(cleanBase64.count)")
                            print("[DEBUG] First 100 chars: \(String(cleanBase64.prefix(100)))")
                        }
                    } else if let imagePath = imageData.imageUrl ?? imageData.filePath {
                        // Load image from URL or file path with authentication
                        do {
                            let data = try await api.loadImage(from: imagePath)
                            decodedImages?.append(data)
                            print("[DEBUG] Successfully loaded image from path: \(imagePath)")
                        } catch {
                            print("[DEBUG] Failed to load image from path: \(error)")
                        }
                    } else {
                        print("[DEBUG] No image data available for image \(index + 1)")
                        print("[DEBUG]   - filename: \(imageData.filename ?? "nil")")
                        print("[DEBUG]   - filePath: \(imageData.filePath ?? "nil")")
                        print("[DEBUG]   - imageUrl: \(imageData.imageUrl ?? "nil")")
                    }
                }
                if decodedImages?.isEmpty == true {
                    decodedImages = nil
                    print("[DEBUG] No images were successfully decoded")
                } else {
                    print("[DEBUG] Successfully decoded \(decodedImages?.count ?? 0) images")
                }
            } else {
                print("[DEBUG] No images in response")
            }
            
            // Add assistant response to history
            chatHistory.append(ChatMessage(role: "assistant", content: response.answer))
            
            // Add assistant response to UI
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                print("[DEBUG] 📱 UPDATING UI WITH RESPONSE")
                print("[DEBUG] 📱 Main thread: \(Thread.isMainThread)")
                
                let newMessage = HealthChatMessage(
                    content: response.answer,
                    isUser: false,
                    sources: response.sources.isEmpty ? nil : response.sources.map { $0.value },
                    confidence: response.confidenceScore,
                    followUpSuggestions: response.followUpSuggestions?.isEmpty == false ? response.followUpSuggestions : nil,
                    images: response.images,
                    decodedImages: decodedImages,
                    voiceAnswer: response.voiceAnswer,
                    pageReferences: response.pageReferences,
                    processingTime: response.processingTime,
                    modelUsed: response.modelUsed
                )
                
                print("[DEBUG] 📱✅ Created new message:")
                print("  - Content length: \(newMessage.content.count) chars")
                print("  - Content preview: \(String(newMessage.content.prefix(100)))...")
                print("  - Has images: \(newMessage.images != nil)")
                print("  - Images count: \(newMessage.images?.count ?? 0)")
                print("  - Decoded images count: \(newMessage.decodedImages?.count ?? 0)")
                print("  - Sources: \(newMessage.sources ?? [])")
                print("  - Messages before adding: \(self.messages.count)")
                
                // Extra debug for images
                if let images = newMessage.images {
                    print("[DEBUG] 📱 Image details:")
                    for (index, img) in images.enumerated() {
                        print("  Image \(index + 1):")
                        print("    - ID: \(img.imageId ?? "nil")")
                        print("    - Has base64: \(img.base64Data != nil)")
                        print("    - Has decoded: \(index < (newMessage.decodedImages?.count ?? 0))")
                    }
                }
                
                // Add to messages array
                self.messages.append(newMessage)
                self.isLoading = false
                
                print("[DEBUG] 📱✅✅ MESSAGE ADDED TO UI")
                print("[DEBUG] 📱 Total messages now: \(self.messages.count)")
                print("[DEBUG] 📱 Last message is user: \(self.messages.last?.isUser ?? false)")
                print("[DEBUG] 📱 Last message content preview: \(String(self.messages.last?.content.prefix(50) ?? ""))")
                
                // Force UI update multiple ways
                self.objectWillChange.send()
                
                // Additional force refresh
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
                
                // Speak the response using VAPI if active
                if let callManager = callManager {
                    // Generate brief voice summary
                    let voiceSummary: String
                    
                    if let providedVoiceAnswer = response.voiceAnswer, !providedVoiceAnswer.isEmpty {
                        // Use backend-provided voice answer if available
                        voiceSummary = providedVoiceAnswer
                        print("[DEBUG] 🔊 Using backend voice answer: \(voiceSummary)")
                    } else {
                        // Generate brief summary from detailed answer
                        voiceSummary = generateBriefVoiceSummary(from: response.answer, query: query)
                        print("[DEBUG] 🔊 Generated voice summary: \(voiceSummary)")
                    }
                    
                    print("[DEBUG] 🔊 Voice summary length: \(voiceSummary.count) characters")
                    
                    // CRITICAL: Send voice response through VAPI
                    Task {
                        // Ensure VAPI is connected
                        if !callManager.isCalling {
                            print("[DEBUG] 🔊 Starting VAPI call for voice response")
                            callManager.startCall()
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second to connect
                        }
                        
                        // Send the voice response
                        print("[DEBUG] 🔊🎯 SENDING VOICE RESPONSE: \(voiceSummary)")
                        
                        // Method 1: Direct message to VAPI
                        await callManager.speakResponse(voiceSummary)
                        
                        // Method 2: Notification for fallback
                        NotificationCenter.default.post(
                            name: NSNotification.Name("HealthEducationAPIResponse"),
                            object: nil,
                            userInfo: ["response": voiceSummary]
                        )
                        
                        print("[DEBUG] 🔊✅ Voice response sent via both methods")
                    }
                }
            }
            
        } catch {
            print("[DEBUG] Error processing query: \(error)")
            
            // Handle specific error cases
            if case HealthEducationAPIError.notAuthenticated = error {
                await MainActor.run {
                    self.error = "Please log in to use Health Education. Tap the settings button above."
                    messages.append(HealthChatMessage(
                        content: "Please log in to access Health Education features. Tap the settings button (⚙️) above to configure your account.",
                        isUser: false
                    ))
                    isLoading = false
                }
            } else if case HealthEducationAPIError.tokenExpired = error {
                await MainActor.run {
                    self.error = "Your session has expired. Attempting to reconnect..."
                    // Clear the expired token
                    settings.clearSettings()
                    isLoading = false
                }
                
                // Try auto-login again
                await api.performAutoLogin()
                
                if settings.isConfigured {
                    // Auto-login succeeded, retry the query
                    print("[DEBUG] Auto-login after token expiration succeeded, retrying query")
                    await MainActor.run {
                        self.error = nil
                    }
                    await self.processQuery(query)
                } else {
                    // Auto-login failed, show manual login message
                    await MainActor.run {
                        messages.append(HealthChatMessage(
                            content: "Your session has expired and auto-login failed. Please tap the settings button (⚙️) above to log in manually.",
                            isUser: false
                        ))
                    }
                }
            } else if case HealthEducationAPIError.networkError = error {
                await MainActor.run {
                    self.error = "Network connection error. Please check your internet connection."
                    messages.append(HealthChatMessage(
                        content: "Unable to connect to the Health Education service. Please check your internet connection and try again.",
                        isUser: false
                    ))
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    self.error = error.localizedDescription
                    messages.append(HealthChatMessage(
                        content: "I'm sorry, I couldn't process your question. \(self.error ?? "Unknown error")",
                        isUser: false
                    ))
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Voice Input
    func startVoiceInput() {
        guard let callManager = callManager else {
            error = "Voice input not available"
            return
        }
        
        isListening = true
        showVoiceAnimation = true
        transcribedText = ""
        
        print("[DEBUG] 🎤🎯 Starting voice input for Health Education...")
        
        // CRITICAL: Ensure we're in health education context and page
        callManager.currentPage = "health education"
        callManager.switchToHealthEducationContext()
        print("[DEBUG] 🎤🎯 Set context and page for voice input")
        
        // Start listening for user transcription updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TranscriptionUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let transcript = notification.userInfo?["transcript"] as? String {
                self?.transcribedText = transcript
                print("[DEBUG] 🎤 Transcription updated: '\(transcript)'")
            }
        }
        
        // Listen for when user stops speaking to trigger API call
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserStoppedSpeaking"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // Get transcript from notification or use stored one
            let transcript = (notification.userInfo?["transcript"] as? String) ?? self.transcribedText
            
            if !transcript.isEmpty {
                print("[DEBUG] 🎤🎯 User stopped speaking, processing: '\(transcript)'")
                
                // DIRECTLY process the message to ensure it works
                self.handleUserMessage(transcript)
                
                // Clear transcribed text
                self.transcribedText = ""
            }
        }
        
        // Start call if not already active
        if !callManager.isCalling {
            callManager.startCall()
        }
    }
    
    private func processVoiceInput() {
        let userMessage = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        print("[DEBUG] 🎤 Processing voice input: '\(userMessage)'")
        
        // Stop listening
        isListening = false
        showVoiceAnimation = false
        
        // Remove observers
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("TranscriptionUpdate"),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("UserStoppedSpeaking"),
            object: nil
        )
        
        // Add user message to chat
        Task { @MainActor in
            let newMessage = HealthChatMessage(content: userMessage, isUser: true)
            messages.append(newMessage)
            print("[DEBUG] ✅ Voice message added to UI. Total messages: \(messages.count)")
            
            // Clear transcribed text and show loading
            transcribedText = ""
            isLoading = true
            
            // Force UI update
            objectWillChange.send()
        }
        
        // Process the query
        Task {
            await processQuery(userMessage)
        }
    }
    
    func stopVoiceInput() {
        isListening = false
        showVoiceAnimation = false
        
        // Remove observers
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("TranscriptionUpdate"),
            object: nil
        )
        
        // Process transcribed text if any
        if !transcribedText.isEmpty {
            let userMessage = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("[DEBUG] 🎤 Voice input stopped with message: '\(userMessage)'")
            
            // Add user message to chat
            Task { @MainActor in
                let newMessage = HealthChatMessage(content: userMessage, isUser: true)
                messages.append(newMessage)
                print("[DEBUG] ✅ Voice message added to UI. Total messages: \(messages.count)")
                
                // Clear transcribed text and show loading
                transcribedText = ""
                isLoading = true
                
                // Force UI update
                objectWillChange.send()
            }
            
            // Process the query
            Task {
                await processQuery(userMessage)
            }
        } else {
            print("[DEBUG] 🎤 Voice input stopped with no transcribed text")
        }
        
        // Don't end call here, let it stay active for continuous conversation
    }
    
    // MARK: - Clear Chat
    func clearChat() {
        print("[DEBUG] clearChat called - removing all messages")
        messages.removeAll()
        chatHistory.removeAll()
        Task {
            await initializeChat()
        }
    }
    
    // MARK: - Use Follow-up Suggestion
    func useFollowUpSuggestion(_ suggestion: String) {
        currentInput = suggestion
        sendMessage()
    }
    
    // MARK: - Generate Brief Voice Summary
    private func generateBriefVoiceSummary(from detailedAnswer: String, query: String) -> String {
        // Take first 1-2 sentences and add guide to screen
        let sentences = detailedAnswer.components(separatedBy: ". ")
        var summary = ""
        
        // Extract key information based on question type
        let queryLower = query.lowercased()
        
        if queryLower.contains("what is") || queryLower.contains("what are") {
            // Definition questions - give brief definition
            if let firstSentence = sentences.first {
                summary = firstSentence
                if !firstSentence.hasSuffix(".") {
                    summary += "."
                }
            }
        } else if queryLower.contains("how to") || queryLower.contains("how do") {
            // How-to questions - give main action
            if detailedAnswer.contains("•") || detailedAnswer.contains("1.") {
                // Has bullet points or numbered list - take first item
                summary = "The key is to " + (sentences.first?.lowercased() ?? "follow the steps")
            } else {
                summary = sentences.first ?? "Follow the steps shown"
            }
        } else if queryLower.contains("symptoms") || queryLower.contains("signs") {
            // Symptom questions - mention 2-3 main symptoms
            summary = "Main symptoms include " + (sentences.first ?? "what's shown on your screen")
        } else {
            // Default - take first sentence
            summary = sentences.first ?? "See the details on your screen"
        }
        
        // Ensure it's brief (max ~150 characters for 10-15 seconds of speech)
        if summary.count > 150 {
            // Truncate to first complete phrase
            if let commaIndex = summary.prefix(150).lastIndex(of: ",") {
                summary = String(summary[..<commaIndex])
            } else if let periodIndex = summary.prefix(150).lastIndex(of: ".") {
                summary = String(summary[..<periodIndex])
            } else {
                summary = String(summary.prefix(147)) + "..."
            }
        }
        
        // Add guide to screen
        summary += " Check your screen for complete details and images."
        
        return summary
    }
    
    // MARK: - Retry Last Message
    func retryLastMessage() {
        guard let lastUserMessage = messages.reversed().first(where: { $0.isUser }) else { return }
        
        // Remove error message if present
        if let lastMessage = messages.last, !lastMessage.isUser {
            messages.removeLast()
        }
        
        Task {
            await processQuery(lastUserMessage.content)
        }
    }
    
    // MARK: - Handle Assistant Response from VAPI
    private func handleAssistantResponse(_ response: String) {
        // For health education, we completely suppress VAPI's text responses
        // We only want to show the API response with images
        // The API call is triggered by handleUserMessage
        
        print("[DEBUG] VAPI response received but suppressed: \(response)")
        
        // Do not add VAPI responses to the chat at all
        // The user will only see the rich API response with images
    }
    
    
    // Properties for message buffering
    private var messageBuffer: String = ""
    private var messageTimer: Timer?
    
    // MARK: - Handle User Message from VAPI
    func handleUserMessage(_ message: String) {
        print("[DEBUG] 🔥🔥🔥 handleUserMessage START")
        print("[DEBUG] 🔥 Message: '\(message)'")
        print("[DEBUG] 🔥 Thread: \(Thread.current)")
        
        // Don't process empty or very short messages
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { 
            print("[DEBUG] ❌ Empty message received, ignoring")
            return 
        }
        
        // Ensure we're on main thread for UI updates
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("[DEBUG] 🔥 On main thread now")
            print("[DEBUG] 🔥 isConfigured: \(self.isConfigured)")
            print("[DEBUG] 🔥 Current messages before: \(self.messages.count)")
            
            // Check if API is configured
            guard self.isConfigured else {
                print("[DEBUG] ❌ API not configured, cannot process message")
                self.error = "Please configure API settings first"
                return
            }
            
            // Check for duplicate messages (prevent double processing)
            if let lastMessage = self.messages.last, 
               lastMessage.isUser && 
               lastMessage.content == trimmedMessage {
                print("[DEBUG] ⚠️ Duplicate message detected, skipping")
                return
            }
            
            // Add user message to UI
            print("[DEBUG] 🔥 Adding user message to chat UI")
            let userMessage = HealthChatMessage(content: trimmedMessage, isUser: true)
            self.messages.append(userMessage)
            print("[DEBUG] 🔥✅ User message added. Total messages: \(self.messages.count)")
            
            // Show loading state
            self.isLoading = true
            
            // Force UI update
            self.objectWillChange.send()
            
            // Add a placeholder for assistant response
            print("[DEBUG] 🔥 Adding loading indicator")
            
            // Process the query through API
            print("[DEBUG] 🔥🎯 Starting API call for: '\(trimmedMessage)'")
            Task { @MainActor in
                print("[DEBUG] 🔥 In Task, calling processQuery")
                await self.processQuery(trimmedMessage)
                print("[DEBUG] 🔥✅ processQuery completed")
            }
        }
    }
    
    // MARK: - Check if statement is complete
    private func isCompleteStatement(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for question marks or periods
        if trimmed.hasSuffix("?") || trimmed.hasSuffix(".") || trimmed.hasSuffix("!") {
            return true
        }
        
        // Check for complete question patterns
        let questionWords = ["what", "how", "when", "where", "why", "who", "which", "can", "should", "could", "would", "is", "are", "do", "does"]
        let lowerText = trimmed.lowercased()
        
        // If it starts with a question word and has at least a subject and verb, consider it complete
        for word in questionWords {
            if lowerText.hasPrefix(word + " ") {
                let words = trimmed.split(separator: " ")
                if words.count >= 3 { // Lowered threshold: Question word + subject + object
                    return true
                }
            }
        }
        
        // Check for very short fragments that are likely incomplete
        let words = trimmed.split(separator: " ")
        if words.count <= 2 && !trimmed.hasSuffix("?") {
            return false
        }
        
        // Default to true for longer statements
        return words.count >= 4 // Lowered from 5 to 4
    }
    
    // MARK: - Process buffered message
    private func processBufferedMessage() {
        let completeMessage = messageBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !completeMessage.isEmpty else { return }
        
        print("[DEBUG] Processing buffered message: '\(completeMessage)'")
        
        // Clear buffer
        messageBuffer = ""
        messageTimer?.invalidate()
        messageTimer = nil
        
        // Don't add duplicate messages
        if let lastMessage = messages.last, lastMessage.isUser && lastMessage.content == completeMessage {
            print("[DEBUG] Duplicate message detected, skipping")
            return
        }
        
        // Add user message to chat
        messages.append(HealthChatMessage(content: completeMessage, isUser: true))
        
        // Update chat history for context
        chatHistory.append(ChatMessage(role: "user", content: completeMessage))
        
        // Process the query through the API to get full response with images
        print("[DEBUG] Sending query to Health Education API: '\(completeMessage)'")
        Task {
            await processQuery(completeMessage)
        }
    }
    
    // MARK: - Test Voice Response
    
    func testVoiceResponse() {
        guard let callManager = callManager else {
            print("[DEBUG] CallManager not available for voice test")
            return
        }
        
        print("[DEBUG] Testing voice response...")
        
        Task {
            // Ensure VAPI is connected
            if !callManager.isCalling {
                print("[DEBUG] Starting VAPI call for voice test")
                callManager.startCall()
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            }
            
            // Test with a simple message
            let testMessage = "This is a test voice response from the health education system."
            print("[DEBUG] Sending test voice message: '\(testMessage)'")
            
            do {
                await callManager.speakResponse(testMessage)
                print("[DEBUG] ✅ Test voice message sent successfully")
            } catch {
                print("[DEBUG] ❌ Failed to send test voice message: \(error)")
            }
        }
    }
    
    // MARK: - Test UI Update
    func testUIUpdate() {
        print("[DEBUG] Testing UI update...")
        
        Task { @MainActor in
            let testMessage = HealthChatMessage(
                content: "This is a test message to verify UI updates are working properly.",
                isUser: false
            )
            
            print("[DEBUG] Adding test message to UI")
            messages.append(testMessage)
            
            print("[DEBUG] ✅ Test message added. Total messages: \(messages.count)")
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    // MARK: - Test REST API
    func testRESTAPI() {
        print("[DEBUG] 🧪 Testing REST API...")
        
        Task {
            do {
                let testQuery = "what is blood pressure in AD?"
                print("[DEBUG] 🧪 Testing with query: '\(testQuery)'")
                
                let response = try await api.askQuestion(testQuery)
                print("[DEBUG] 🧪 ✅ REST API test successful!")
                print("[DEBUG] 🧪 Response answer: \(response.answer)")
                print("[DEBUG] 🧪 Response voice answer: \(response.voiceAnswer ?? "nil")")
                print("[DEBUG] 🧪 Response has images: \(response.images != nil)")
                print("[DEBUG] 🧪 Response images count: \(response.images?.count ?? 0)")
                
                // Add the test response to UI
                await MainActor.run {
                    let testMessage = HealthChatMessage(
                        content: response.answer,
                        isUser: false,
                        images: response.images,
                        voiceAnswer: response.voiceAnswer,
                        pageReferences: response.pageReferences
                    )
                    messages.append(testMessage)
                    print("[DEBUG] 🧪 ✅ Test response added to UI. Total messages: \(messages.count)")
                }
                
            } catch {
                print("[DEBUG] 🧪 ❌ REST API test failed: \(error)")
            }
        }
    }
    
    // MARK: - Test Complete Voice-to-API Flow
    func testCompleteVoiceFlow() {
        print("[DEBUG] 🧪🎯 Testing complete voice-to-API flow...")
        
        // Test query
        let testQuery = "what is blood pressure in AD?"
        print("[DEBUG] 🧪🎯 Test query: '\(testQuery)'")
        
        // Method 1: Direct handleUserMessage (most reliable)
        print("[DEBUG] 🧪🎯 Method 1: Direct handleUserMessage")
        handleUserMessage(testQuery)
        
        // Method 2: Simulate voice input flow
        Task {
            await Task.sleep(2_000_000_000) // Wait 2 seconds
            
            print("[DEBUG] 🧪🎯 Method 2: Simulating voice input flow")
            transcribedText = testQuery
            processVoiceInput()
        }
        
        // Method 3: Post notification directly
        Task {
            await Task.sleep(4_000_000_000) // Wait 4 seconds
            
            print("[DEBUG] 🧪🎯 Method 3: Posting notification directly")
            NotificationCenter.default.post(
                name: NSNotification.Name("HealthEducationUserMessage"),
                object: nil,
                userInfo: ["message": testQuery]
            )
        }
        
        print("[DEBUG] 🧪🎯 All test methods initiated - check logs for results")
    }
    
    deinit {
        messageTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

