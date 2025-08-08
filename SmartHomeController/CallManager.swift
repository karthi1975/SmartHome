import Foundation
import Combine
import Vapi
import AVFoundation
import Daily

/// Manages a single "Daily + VAPI" call,
/// exposing start/end + live message handling.
class CallManager: ObservableObject {
    @Published var isCalling = false
    @Published var callHistory: [CallRecord] = []
    @Published var latestAgentResponse: String? = nil
    @Published var roomTemps: [String: Int] = [
        "kitchen": 78,
        "bedroom": 72,
        "living room": 74,
        "nursery": 70,
        "garage": 68,
        "laundry": 71,
        "outside": 80,
        "backyard": 79,
        "master": 73
    ]
    @Published var userSpeaking: Bool = false
    @Published var agentSpeaking: Bool = false
    @Published var isListening: Bool = false
    @Published var currentPage: String = "home" // Track current page to avoid redundant navigation
    @Published var currentContext: AppContext = .smartHome // Track current context for ToT

    private var vapi: Vapi?
    private var cancellables = Set<AnyCancellable>()
    private var currentCallStart: Date?
    private let historyKey = "callHistory"
    private var awaitingTempReduction: Bool = false
    private var tempRoomContext: String? = nil
    
    // Context buffer for handling split transcripts
    private var recentUserTranscripts: [String] = []
    private var transcriptBufferLimit = 3 // Keep last 3 user transcripts

    init() {
        loadHistory()
        
        // Listen for health education API responses
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HealthEducationAPIResponse"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let response = notification.userInfo?["response"] as? String {
                print("[DEBUG] Received Health Education API response notification")
                self?.handleHealthEducationAPIResponse(response)
            }
        }
        // Listen for page changes to keep currentPage in sync
        NotificationCenter.default.addObserver(
            forName: .pageChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let pageName = notification.object as? String {
                self?.currentPage = pageName.lowercased()
                print("[DEBUG] CallManager: Page changed to \(pageName)")
                
                // Update context based on page
                if pageName.lowercased() == "health education" {
                    self?.switchToHealthEducationContext()
                } else {
                    self?.switchToSmartHomeContext()
                }
            }
        }
    }

    /// Kick off a call with your Daily publicKey + assistantId
    func startCall(publicKey: String, assistantId: String) {
        // Initialize VAPI (no config options in this SDK)
        vapi = Vapi(publicKey: publicKey)
        vapi?.eventPublisher
            .receive(on: DispatchQueue.global(qos: .userInteractive)) // Use high priority queue
            .sink { event in
                // Handle events on background queue for better performance
                DispatchQueue.global(qos: .userInteractive).async {
                    switch event {
                    case .callDidStart:
                        DispatchQueue.main.async {
                            print("✅ Call started")
                            self.isCalling = true
                            self.isListening = true
                        }
                    case .callDidEnd:
                        DispatchQueue.main.async {
                            print("🛑 Call ended")
                            self.isCalling = false
                            self.isListening = false
                            self.userSpeaking = false
                            self.agentSpeaking = false
                            // Clear transcript buffer when call ends
                            self.recentUserTranscripts.removeAll()
                        }
                    case .transcript(let transcript):
                        print("📝 Transcript: \(transcript)")
                        DispatchQueue.main.async {
                            // Immediately set speaking states based on role and transcript type
                            print("[DEBUG] Processing transcript - role: \(transcript.role), type: \(transcript.transcriptType)")
                            if transcript.role == .user {
                                if transcript.transcriptType == .partial {
                                    // User is actively speaking
                                    print("[DEBUG] User speaking - setting userSpeaking=true, agentSpeaking=false")
                                    self.userSpeaking = true
                                    self.agentSpeaking = false
                                    
                                    // Notify about transcription update
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("TranscriptionUpdate"),
                                        object: nil,
                                        userInfo: ["transcript": transcript.transcript]
                                    )
                                } else if transcript.transcriptType == .final {
                                    // Debug: Print user transcript content
                                    print("[DEBUG] 🎙️ User final transcript: '\(transcript.transcript)'")
                                    
                                    // CRITICAL: If on Health Education page, immediately send to Health Education
                                    if self.currentPage.lowercased().contains("health") || self.currentContext == .healthEducation {
                                        print("[DEBUG] 🚨🚨🚨 ON HEALTH EDUCATION PAGE - PROCESSING MESSAGE")
                                        print("[DEBUG] 🚨 Current page: '\(self.currentPage)'")
                                        print("[DEBUG] 🚨 Current context: \(self.currentContext)")
                                        print("[DEBUG] 🚨 User said: '\(transcript.transcript)'")
                                        
                                        // Send to Health Education ViewModel IMMEDIATELY
                                        DispatchQueue.main.async {
                                            print("[DEBUG] 🚨 Posting HealthEducationUserMessage notification NOW")
                                            NotificationCenter.default.post(
                                                name: NSNotification.Name("HealthEducationUserMessage"),
                                                object: nil,
                                                userInfo: ["message": transcript.transcript]
                                            )
                                            
                                            // Also directly call the view model if available
                                            if let healthVM = HealthEducationViewModel.shared as? HealthEducationViewModel {
                                                print("[DEBUG] 🚨 DIRECTLY calling handleUserMessage")
                                                healthVM.handleUserMessage(transcript.transcript)
                                            }
                                        }
                                        
                                        // Don't process any other commands when in health education
                                        return
                                    }
                                    
                                    // Add to transcript buffer for context-aware processing
                                    self.recentUserTranscripts.append(transcript.transcript)
                                    if self.recentUserTranscripts.count > self.transcriptBufferLimit {
                                        self.recentUserTranscripts.removeFirst()
                                    }
                                    
                                    // Handle navigation from user speech (only if not health education)
                                    if let room = self.extractRoomName(from: transcript.transcript) {
                                        let normalizedRoom = room.lowercased()
                                        if self.currentPage.lowercased() != normalizedRoom {
                                            print("[DEBUG] User mentioned room: \(room), navigating from \(self.currentPage) to \(room)...")
                                            self.currentPage = normalizedRoom
                                            NotificationCenter.default.post(name: .navigateToRoom, object: room)
                                        } else {
                                            print("[DEBUG] User mentioned \(room) but already on \(self.currentPage) page - no navigation needed")
                                        }
                                    }
                                    
                                    // SECOND: Process temperature changes from USER commands
                                    print("[DEBUG] Processing temperature commands for user transcript")
                                    
                                    // Try current transcript first
                                    var tempCommand: (room: String, reduction: Int)? = self.extractTempReductionAction(transcript.transcript)
                                    
                                    // If no command found, try with context buffer (combine recent transcripts)
                                    if tempCommand == nil && self.recentUserTranscripts.count > 1 {
                                        let combinedTranscript = self.recentUserTranscripts.joined(separator: " ")
                                        print("[DEBUG] No command in current transcript, trying combined context: '\(combinedTranscript)'")
                                        tempCommand = self.extractTempReductionAction(combinedTranscript)
                                    }
                                    
                                    if let (room, reduction) = tempCommand {
                                        print("[DEBUG] USER temperature command detected: room=\(room.lowercased()), reduction=\(reduction)")
                                        print("[DEBUG] Available room view models: \(RoomView.roomViewModels.keys.sorted())")
                                        let normalizedRoom = room.isEmpty ? self.currentPage.lowercased() : room.lowercased()
                                        print("[DEBUG] room='\(room)', currentPage='\(self.currentPage)', normalizedRoom='\(normalizedRoom)'")
                                        if let tempVM = RoomView.roomViewModels[normalizedRoom] {
                                            print("[DEBUG] Found room view model for \(normalizedRoom), temp before: \(tempVM.temp)")
                                            tempVM.animateTemperatureChange(by: reduction)
                                            tempVM.setVoiceAction(reduction > 0 ? .increase : .decrease, duration: 1.0)
                                            print("[DEBUG] temp after: \(tempVM.temp)")
                                            // Clear buffer after successful command to prevent duplicate execution
                                            self.recentUserTranscripts.removeAll()
                                        } else if let tempVM = HomeControlsView.homeTempVM, (normalizedRoom == "home" || normalizedRoom == "favorites") {
                                            print("[DEBUG] Found home view model for \(normalizedRoom), temp before: \(tempVM.temp)")
                                            tempVM.animateTemperatureChange(by: reduction)
                                            tempVM.setVoiceAction(reduction > 0 ? .increase : .decrease, duration: 1.0)
                                            print("[DEBUG] temp after: \(tempVM.temp)")
                                            // Clear buffer after successful command to prevent duplicate execution
                                            self.recentUserTranscripts.removeAll()
                                        } else {
                                            print("[DEBUG] No view model found for \(normalizedRoom)")
                                        }
                                    } else {
                                        print("[DEBUG] No temperature command detected in transcript: '\(transcript.transcript)'")
                                    }
                                    
                                    // THIRD: Show speaking animation for microphone (after processing)
                                    print("[DEBUG] User final transcript - simulating speaking animation")
                                    self.userSpeaking = true
                                    self.agentSpeaking = false
                                    
                                    // Calculate duration based on transcript length (roughly 150 words per minute)
                                    let wordCount = transcript.transcript.split(separator: " ").count
                                    let estimatedDuration = max(1.5, min(Double(wordCount) * 0.4, 5.0)) // 1.5-5 seconds
                                    
                                    print("[DEBUG] User transcript has \(wordCount) words, estimated duration: \(estimatedDuration)s")
                                    
                                    // After estimated duration, set speaking to false and notify
                                    DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                                        print("[DEBUG] User finished speaking - setting userSpeaking=false")
                                        self.userSpeaking = false
                                        
                                        // Notify that user stopped speaking
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("UserStoppedSpeaking"),
                                            object: nil,
                                            userInfo: ["transcript": transcript.transcript]
                                        )
                                    }
                                }
                            } else if transcript.role == .assistant {
                                if transcript.transcriptType == .partial {
                                    // Agent is actively speaking
                                    print("[DEBUG] Agent speaking - setting agentSpeaking=true, userSpeaking=false")
                                    self.agentSpeaking = true
                                    self.userSpeaking = false
                                } else if transcript.transcriptType == .final {
                                    // Debug: Print all transcript content
                                    print("[DEBUG] Agent transcript received: '\(transcript.transcript)'")
                                    print("[DEBUG] Ignoring agent transcript for temperature changes - only user commands allowed")
                                    
                                    // FIRST: Handle navigation ONLY for agent responses, not temperature changes
                                    if let room = self.extractRoomName(from: transcript.transcript) {
                                        let normalizedRoom = room.lowercased()
                                        if self.currentPage.lowercased() != normalizedRoom {
                                            print("[DEBUG] Agent mentioned room: \(room), navigating from \(self.currentPage) to \(room)...")
                                            self.currentPage = normalizedRoom
                                            NotificationCenter.default.post(name: .navigateToRoom, object: room)
                                        } else {
                                            print("[DEBUG] Agent mentioned \(room) but already on \(self.currentPage) page - suppressing redundant navigation")
                                        }
                                    }
                                    
                                    // SECOND: Show speaking animation for microphone (after processing)
                                    print("[DEBUG] Agent final transcript - simulating speaking animation")
                                    self.agentSpeaking = true
                                    self.userSpeaking = false
                                    
                                    // Calculate duration based on transcript length (roughly 150 words per minute)
                                    let wordCount = transcript.transcript.split(separator: " ").count
                                    let estimatedDuration = max(2.0, min(Double(wordCount) * 0.4, 8.0)) // 2-8 seconds for agent
                                    
                                    print("[DEBUG] Agent transcript has \(wordCount) words, estimated duration: \(estimatedDuration)s")
                                    
                                    // After estimated duration, set speaking to false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                                        print("[DEBUG] Agent finished speaking - setting agentSpeaking=false")
                                        self.agentSpeaking = false
                                    }
                                }
                            }
                        }
                    case .functionCall(let functionCall):
                        print("🔧 Function call: \(functionCall)")
                        // You can access functionCall.name, functionCall.parameters, etc.
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)

        Task {
            do {
                _ = try await vapi?.start(assistantId: assistantId)
            } catch {
                print("⚠️ Failed to start call:", error)
            }
        }
    }

    /// Cleanly end the call
    func endCall() {
        vapi?.stop()
    }
    
    /// Update system prompt for specific contexts (e.g., health education)
    func updateSystemPrompt(_ prompt: String) {
        // Send system message to update the assistant's behavior
        let message = VapiMessage(type: "system", role: "system", content: prompt)
        if let vapi = vapi {
            Task {
                do {
                    try await vapi.send(message: message)
                    print("[DEBUG] System prompt updated successfully")
                } catch {
                    print("Failed to update system prompt: \(error)")
                }
            }
        }
    }
    
    /// Switch to Smart Home context with Tree of Thought
    func switchToSmartHomeContext() {
        currentContext = .smartHome
        let prompt = TreeOfThoughtPrompts.getPromptForContext(currentContext)
        updateSystemPrompt(prompt)
        print("[DEBUG] Switched to Smart Home context with ToT")
    }
    
    /// Switch to Health Education context with Tree of Thought
    func switchToHealthEducationContext() {
        currentContext = .healthEducation
        let prompt = TreeOfThoughtPrompts.getPromptForContext(currentContext)
        updateSystemPrompt(prompt)
        print("[DEBUG] Switched to Health Education context (transcription-only mode)")
    }
    
    /// Convenience method for health education context
    func startCall() {
        startCall(publicKey: "a9ac4b5f-2095-4073-a05b-c037965ffd0b",
                 assistantId: "e06725f5-cc23-4e06-ba89-7c33643bfbdb")
    }
    
    private func handleTranscript(_ transcript: Transcript) {
        DispatchQueue.main.async {
            // Immediately set speaking states based on role and transcript type
            print("[DEBUG] Processing transcript - role: \(transcript.role), type: \(transcript.transcriptType)")
            
            // Voice is always active - process all transcripts
            if transcript.role == .user || transcript.role == .assistant {
                // Send transcript update notification for health education view
                if transcript.role == .user && transcript.transcriptType == .partial {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("TranscriptionUpdate"),
                        object: nil,
                        userInfo: ["transcript": transcript.transcript]
                    )
                }
                
                if transcript.role == .user {
                    self.processUserTranscript(transcript.transcript, transcript: transcript)
                } else {
                    self.processAssistantTranscript(transcript)
                }
            }
        }
    }
    
    private func processUserTranscript(_ transcriptText: String, transcript: Transcript) {
        if transcript.transcriptType == .partial {
            // User is actively speaking
            print("[DEBUG] User speaking - setting userSpeaking=true, agentSpeaking=false")
            self.userSpeaking = true
            self.agentSpeaking = false
        } else if transcript.transcriptType == .final {
            // Debug: Print user transcript content
            print("[DEBUG] User transcript received: '\(transcriptText)'")
            
            // This code block is now handled above in the main transcript processing
            // Removed to prevent duplicate processing
            
            // Add to transcript buffer for context-aware processing
            self.recentUserTranscripts.append(transcript.transcript)
            if self.recentUserTranscripts.count > self.transcriptBufferLimit {
                self.recentUserTranscripts.removeFirst()
            }
            
            // FIRST: Check for health-related questions
            if self.isHealthRelatedQuestion(transcript.transcript) {
                print("[DEBUG] 🏥 Health-related question detected in transcript: '\(transcript.transcript)'")
                print("[DEBUG] 🏥 Navigating to Health Education")
                self.currentPage = "health education"
                
                // Post notification on main thread
                DispatchQueue.main.async {
                    print("[DEBUG] 🏥 Posting navigateToRoom notification with 'Health Education'")
                    NotificationCenter.default.post(name: .navigateToRoom, object: "Health Education")
                    
                    // Immediately trigger the Health Education API
                    print("[DEBUG] 🏥 Directly triggering Health Education API")
                    Task { @MainActor in
                        let viewModel = HealthEducationViewModel.shared
                        print("[DEBUG] 🏥 ViewModel isConfigured: \(viewModel.isConfigured)")
                        
                        // Add user message
                        viewModel.messages.append(HealthChatMessage(content: transcript.transcript, isUser: true))
                        
                        // Process the query directly
                        viewModel.currentInput = transcript.transcript
                        viewModel.sendMessage()
                        
                        print("[DEBUG] 🏥 API call triggered for: '\(transcript.transcript)'")
                    }
                    
                    // Also post notification for compatibility
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("[DEBUG] 🏥 Also posting HealthEducationUserMessage notification")
                        NotificationCenter.default.post(
                            name: NSNotification.Name("HealthEducationUserMessage"),
                            object: nil,
                            userInfo: ["message": transcript.transcript]
                        )
                    }
                }
                
                // Immediately update prompt to prevent VAPI from responding
                self.updateSystemPrompt("You are being redirected to health education. Please do not respond to this message.")
                // Switch context to health education
                self.switchToHealthEducationContext()
            }
            // SECOND: Handle navigation from user speech
            else if let room = self.extractRoomName(from: transcript.transcript) {
                let normalizedRoom = room.lowercased()
                if self.currentPage.lowercased() != normalizedRoom {
                    print("[DEBUG] User mentioned room: \(room), navigating from \(self.currentPage) to \(room)...")
                    self.currentPage = normalizedRoom
                    NotificationCenter.default.post(name: .navigateToRoom, object: room)
                } else {
                    print("[DEBUG] User mentioned \(room) but already on \(self.currentPage) page - no navigation needed")
                }
            }
            
            // THIRD: Process temperature changes from USER commands
            print("[DEBUG] Processing temperature commands for user transcript")
            
            // Try current transcript first
            var tempCommand: (room: String, reduction: Int)? = self.extractTempReductionAction(transcript.transcript)
            
            // If no command found, try with context buffer (combine recent transcripts)
            if tempCommand == nil && self.recentUserTranscripts.count > 1 {
                let combinedTranscript = self.recentUserTranscripts.joined(separator: " ")
                print("[DEBUG] No command in current transcript, trying combined context: '\(combinedTranscript)'")
                tempCommand = self.extractTempReductionAction(combinedTranscript)
            }
            
            if let (room, reduction) = tempCommand {
                print("[DEBUG] USER temperature command detected: room=\(room.lowercased()), reduction=\(reduction)")
                print("[DEBUG] Available room view models: \(RoomView.roomViewModels.keys.sorted())")
                let normalizedRoom = room.isEmpty ? self.currentPage.lowercased() : room.lowercased()
                print("[DEBUG] room='\(room)', currentPage='\(self.currentPage)', normalizedRoom='\(normalizedRoom)'")
                if let tempVM = RoomView.roomViewModels[normalizedRoom] {
                    print("[DEBUG] Found room view model for \(normalizedRoom), temp before: \(tempVM.temp)")
                    tempVM.animateTemperatureChange(by: reduction)
                    tempVM.setVoiceAction(reduction > 0 ? .increase : .decrease, duration: 1.0)
                    print("[DEBUG] temp after: \(tempVM.temp)")
                    // Clear buffer after successful command to prevent duplicate execution
                    self.recentUserTranscripts.removeAll()
                } else if let tempVM = HomeControlsView.homeTempVM, (normalizedRoom == "home" || normalizedRoom == "favorites") {
                    print("[DEBUG] Found home view model for \(normalizedRoom), temp before: \(tempVM.temp)")
                    tempVM.animateTemperatureChange(by: reduction)
                    tempVM.setVoiceAction(reduction > 0 ? .increase : .decrease, duration: 1.0)
                    print("[DEBUG] temp after: \(tempVM.temp)")
                    // Clear buffer after successful command to prevent duplicate execution
                    self.recentUserTranscripts.removeAll()
                } else {
                    print("[DEBUG] No view model found for \(normalizedRoom)")
                }
            } else {
                print("[DEBUG] No temperature command detected in transcript: '\(transcript.transcript)'")
            }
            
            // FOURTH: Show speaking animation for microphone (after processing)
            print("[DEBUG] User final transcript - simulating speaking animation")
            self.userSpeaking = true
            self.agentSpeaking = false
            
            // Calculate duration based on transcript length (roughly 150 words per minute)
            let wordCount = transcript.transcript.split(separator: " ").count
            let estimatedDuration = max(1.5, min(Double(wordCount) * 0.4, 5.0)) // 1.5-5 seconds
            
            print("[DEBUG] User transcript has \(wordCount) words, estimated duration: \(estimatedDuration)s")
            
            // After estimated duration, set speaking to false
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                print("[DEBUG] User finished speaking - setting userSpeaking=false")
                self.userSpeaking = false
            }
        }
    }
    
    private func processAssistantTranscript(_ transcript: Transcript) {
        if transcript.transcriptType == .partial {
            // Agent is actively speaking
            print("[DEBUG] Agent speaking - setting agentSpeaking=true, userSpeaking=false")
            self.agentSpeaking = true
            self.userSpeaking = false
        } else if transcript.transcriptType == .final {
            // Debug: Print all transcript content
            print("[DEBUG] Agent transcript received: '\(transcript.transcript)'")
            print("[DEBUG] Ignoring agent transcript for temperature changes - only user commands allowed")
            
            // In health education context, VAPI will provide voice responses
            // The API calls with images are triggered separately via notifications
            if self.currentContext == .healthEducation || self.currentPage.lowercased() == "health education" {
                print("[DEBUG] In health education context - VAPI providing voice response while API handles images")
            }
            
            // FIRST: Handle navigation ONLY for agent responses, not temperature changes
            if let room = self.extractRoomName(from: transcript.transcript) {
                let normalizedRoom = room.lowercased()
                if self.currentPage.lowercased() != normalizedRoom {
                    print("[DEBUG] Agent mentioned room: \(room), navigating from \(self.currentPage) to \(room)...")
                    self.currentPage = normalizedRoom
                    NotificationCenter.default.post(name: .navigateToRoom, object: room)
                } else {
                    print("[DEBUG] Agent mentioned \(room) but already on \(self.currentPage) page - suppressing redundant navigation")
                }
            }
            
            // SECOND: Show speaking animation for microphone (after processing)
            print("[DEBUG] Agent final transcript - simulating speaking animation")
            self.agentSpeaking = true
            self.userSpeaking = false
            
            // Calculate duration based on transcript length (roughly 150 words per minute)
            let wordCount = transcript.transcript.split(separator: " ").count
            let estimatedDuration = max(2.0, min(Double(wordCount) * 0.4, 8.0)) // 2-8 seconds for agent
            
            print("[DEBUG] Agent transcript has \(wordCount) words, estimated duration: \(estimatedDuration)s")
            
            // After estimated duration, set speaking to false
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                print("[DEBUG] Agent finished speaking - setting agentSpeaking=false")
                self.agentSpeaking = false
            }
        }
    }

    // --- Persistence (copied from VapiDemo) ---
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let records = try? JSONDecoder().decode([CallRecord].self, from: data)
        else { return }
        callHistory = records
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(callHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    // --- Agent response logic (unchanged) ---
    func receiveAgentResponse(_ response: String) {
        print("[DEBUG] receiveAgentResponse called with: \(response)")
        DispatchQueue.main.async {
            self.latestAgentResponse = response
        }
    }

    /// Read out the temperature value using VAPI (TTS) 
    func speakTemperature(room: String, temp: Int) async {
        // Send brief temperature update with instruction to confirm action without asking
        let message = VapiMessage(type: "transcript", role: "user", content: "Temperature changed to \(temp)°F. IMPORTANT: Just confirm this change briefly. Don't ask for permission or confirmation.")
        if let vapi = vapi {
            do {
                // Use high priority queue for faster TTS
                try await Task.detached(priority: .userInitiated) {
                    try await vapi.send(message: message)
                }.value
            } catch {
                print("Failed to send TTS message to VAPI: \(error)")
            }
        } else {
            print("VAPI is not connected.")
        }
    }
    
    /// Speak a response using VAPI (TTS)
    func speakResponse(_ text: String) async {
        print("[DEBUG] 🔊 speakResponse called with: '\(text.prefix(50))...'")
        
        // Send response for text-to-speech
        let message = VapiMessage(type: "transcript", role: "assistant", content: text)
        if let vapi = vapi {
            do {
                print("[DEBUG] 🔊 Sending TTS message to VAPI")
                // Use high priority queue for faster TTS
                try await Task.detached(priority: .userInitiated) {
                    try await vapi.send(message: message)
                }.value
                print("[DEBUG] 🔊✅ TTS message sent successfully")
            } catch {
                print("[DEBUG] 🔊❌ Failed to send TTS response to VAPI: \(error)")
            }
        } else {
            print("[DEBUG] 🔊❌ VAPI is not connected - cannot speak response")
        }
    }
    
    /// Announce current room temperature when visiting a room (without triggering agent questions)
    func announceRoomTemperature(room: String, temp: Int) async {
        // Send room temperature info but tell agent not to ask about changing it
        let message = VapiMessage(type: "transcript", role: "user", content: "Current \(room) temperature is \(temp)°F. IMPORTANT: Just acknowledge this. Don't ask if I want to change it or offer suggestions unless I specifically ask.")
        if let vapi = vapi {
            do {
                // Use high priority queue for faster TTS
                try await Task.detached(priority: .userInitiated) {
                    try await vapi.send(message: message)
                }.value
            } catch {
                print("Failed to send TTS message to VAPI: \(error)")
            }
        } else {
            print("VAPI is not connected.")
        }
    }

    private func isHealthRelatedQuestion(_ text: String) -> Bool {
        let lower = text.lowercased()
        
        // Health-related keywords and phrases
        let healthKeywords = [
            // Medical conditions
            "autonomic dysreflexia", "ad", "dysreflexia",
            "pressure injury", "pressure sore", "bedsore", "pressure ulcer",
            "spasticity", "spasm", "muscle spasm",
            "uti", "urinary tract infection", "bladder infection",
            "pain", "neuropathic pain", "nerve pain",
            
            // Body systems
            "bladder", "bowel", "catheter", "bowel routine",
            "blood pressure", "heart rate", "circulation",
            "breathing", "respiratory",
            
            // Symptoms
            "headache", "sweating", "fever", "chills",
            "nausea", "dizziness", "fatigue",
            "swelling", "edema", "rash",
            
            // Care and management
            "medication", "medicine", "prescription",
            "exercise", "physical therapy", "pt",
            "occupational therapy", "ot",
            "wheelchair", "transfer", "mobility",
            "diet", "nutrition", "hydration",
            
            // Health questions
            "what is", "how do i", "what are the signs",
            "symptoms of", "treatment for", "prevent",
            "manage", "care for", "help with",
            
            // Emergency
            "emergency", "urgent", "serious", "911",
            
            // General health terms
            "health", "medical", "doctor", "nurse",
            "hospital", "clinic", "therapy",
            "injury", "condition", "diagnosis",
            
            // Navigation to health page
            "health page", "health education", "health chat",
            "take me to health", "go to health"
        ]
        
        // Check if any health keyword is present
        return healthKeywords.contains { keyword in
            lower.contains(keyword)
        }
    }

    private func extractRoomName(from text: String) -> String? {
        let lower = text.lowercased()
        
        // Skip navigation if the text contains certain phrases that shouldn't trigger navigation
        let skipPhrases = [
            "autonomic dysreflexia",
            "blood pressure", 
            "medical emergency",
            "life threatening",
            "spinal cord",
            "symptoms",
            "what is",
            "how do",
            "can occur"
        ]
        
        // Don't navigate if any skip phrases are found
        if skipPhrases.contains(where: { lower.contains($0) }) {
            return nil
        }
        
        // First check for formal pattern "Shows the <room> page"
        let formalPattern = #"Shows the ([a-zA-Z ]+) page"#
        if let regex = try? NSRegularExpression(pattern: formalPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let roomRange = Range(match.range(at: 1), in: text) {
            return String(text[roomRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Only check for explicit navigation commands
        let navigationPhrases = [
            "go to", "navigate to", "show me", "take me to", "open", "switch to"
        ]
        
        // Check if this is actually a navigation request
        let hasNavigationIntent = navigationPhrases.contains { phrase in
            lower.contains(phrase)
        }
        
        // Only look for room names if there's navigation intent
        if hasNavigationIntent {
            let roomNames = [
                "kitchen", "living room", "bedroom", "garage", "laundry", "nursery",
                "outside", "backyard", "master", "entrance", "playroom", "elevator", 
                "support", "help", "help page", "health education", "health page", "home", "homepage"
            ]
            
            // Find any room name mentioned in the text
            if let room = roomNames.first(where: { lower.contains($0) }) {
                return room
            }
        }
        
        return nil
    }

    private func convertWordToNumber(_ word: String) -> Int? {
        let wordNumbers: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10
        ]
        return wordNumbers[word.lowercased()]
    }

    private func extractTempReductionAction(_ text: String) -> (room: String, reduction: Int)? {
        print("[DEBUG] Extracting temperature action from: '\(text)'")
        
        // ONLY match explicit commands with specific amounts - NO DEFAULTS
        let patterns = [
            // HIGH PRIORITY: Explicit decrease patterns (checked first)
            #"(lower|reduce|decrease|drop|turn down)\s+(?:it\s+)?(?:by\s+)?(\d+)"#,  // "lower it by 5" or "lower 5"
            #"(lower|reduce|decrease|drop|turn down)\s+(?:the\s+)?(?:([a-zA-Z ]+)\s+)?(?:temperature|temp)?\s+by\s+(\d+)"#,
            #"(lower|reduce|decrease|drop|turn down)\s+([a-zA-Z ]+)\s+by\s+(\d+)"#,
            
            // HIGH PRIORITY: Explicit increase patterns  
            #"(raise|increase|boost|turn up|warm up)\s+(?:it\s+)?(?:by\s+)?(\d+)"#,  // "increase it by 2" or "increase 2"
            #"(raise|increase|boost|turn up|warm up)\s+(?:the\s+)?(?:([a-zA-Z ]+)\s+)?(?:temperature|temp)?\s+by\s+(\d+)"#,
            #"(raise|increase|boost|turn up|warm up)\s+([a-zA-Z ]+)\s+by\s+(\d+)"#,
            
            // MEDIUM PRIORITY: Cross-transcript patterns (more flexible)
            #"increase\s+(?:the\s+)?([a-zA-Z ]+)?\s*(?:temp|temperature)?\s+by\s+(\d+)"#,  // "increase kitchen temp by 2"
            #"(?:can\s+you\s+)?increase\s+(?:the\s+)?([a-zA-Z ]+)?\s*(?:temp|temperature)?\s*.*?by\s+(\d+)"#,  // "can you increase kitchen temp ... by 2"
            
            // LOW PRIORITY: Context-dependent patterns (require full text analysis)
            #"by\s+(\d+)\s*degrees?"#,  // Just "by X degrees" (direction determined by context)
            
            // Patterns with "X degrees" at the beginning
            #"(\d+)\s+degrees?\s+(?:lower|down|decrease|reduce)"#,
            #"(\d+)\s+degrees?\s+(?:higher|up|increase|raise)"#,
            
            // Speech recognition error patterns (common misheard words) - DECREASE
            #"(harish|harris|harsh|laris|lower it|reduce it)\s+by\s+(\d+)"#,  // "lower it" often becomes "harish"
            #"(it|temperature)\s+by\s+(\d+)\s*(lower|down|decrease|reduce)"#,  // Alternative word order
            #"by\s+(\d+)\s*(degree|degrees)?\s*(lower|down|decrease|reduce)"#,  // Just "by X lower"
            
            // Even more flexible patterns for speech recognition errors
            #"(harish|harris|harsh|laris)\s*by\s*(\d+)\.?"#,  // Direct "harish by X" with optional period
            #"(\w+)\s+by\s+(\d+)\.?"#,  // Any word followed by "by X" - will need special handling
            
            // Past tense patterns with word numbers
            #"(lowered|reduced|decreased)\s+by\s+(one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s*degrees?"#,  // "lowered by five degrees"
            #"(raised|increased)\s+by\s+(one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s*degrees?"#,  // "raised by five degrees"
            
            // Word number patterns  
            #"(lower|reduce|decrease)\s+(?:it\s+)?by\s+(one|two|three|four|five|six|seven|eight|nine|ten)\s*degrees?"#,  // "lower it by five degrees"
            #"(raise|increase)\s+(?:it\s+)?by\s+(one|two|three|four|five|six|seven|eight|nine|ten)\s*degrees?"#  // "raise it by five degrees"
        ]
        
        for (index, pattern) in patterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                print("[DEBUG] Pattern \(index) matched: \(pattern)")
                
                var room = ""
                var amount = 0
                var isDecrease = false
                
                // Check which pattern matched and extract accordingly
                for i in 1..<match.numberOfRanges {
                    let range = match.range(at: i)
                    if range.location != NSNotFound, let stringRange = Range(range, in: text) {
                        let captured = String(text[stringRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Check if it's a number (digit or word)
                        if let number = Int(captured) {
                            amount = number
                        } else if let wordNumber = convertWordToNumber(captured) {
                            amount = wordNumber
                        }
                        // Check if it's a decrease command (including speech recognition errors and past tense)
                        else if captured.range(of: "(lower|reduce|decrease|drop|turn down|harish|harris|harsh|laris|lower it|reduce it|lowered|reduced|decreased)", options: .regularExpression) != nil {
                            isDecrease = true
                        }
                        // Check if it's an increase command (including past tense)
                        else if captured.range(of: "(raise|increase|boost|turn up|warm up|raised|increased)", options: .regularExpression) != nil {
                            isDecrease = false
                        }
                        // Check if it's a room name (not a command word or number)
                        else if captured.range(of: "(lower|reduce|decrease|drop|turn|raise|increase|boost|warm|temperature|temp|by|the|down|up|degrees?|harish|harris|harsh|laris|it|is|are|was|were|be|been|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|yeah|yes|no|ok|okay|one|two|three|four|five|six|seven|eight|nine|ten|lowered|reduced|decreased|raised|increased)", options: .regularExpression) == nil &&
                               !captured.isEmpty {
                            room = captured
                        }
                    }
                }
                
                // Special handling for patterns that need direction clarification
                if amount > 0 {
                    // Pattern 0-2: Explicit decrease patterns - should already be marked as decrease
                    if index >= 0 && index <= 2 {
                        isDecrease = true
                        print("[DEBUG] Explicit decrease pattern matched (index \(index))")
                    }
                    // Pattern 3-5: Explicit increase patterns - should already be marked as increase  
                    else if index >= 3 && index <= 5 {
                        isDecrease = false
                        print("[DEBUG] Explicit increase pattern matched (index \(index))")
                    }
                    // Pattern 6-7: Cross-transcript increase patterns - check context
                    else if index >= 6 && index <= 7 {
                        print("[DEBUG] Cross-transcript pattern matched - checking context")
                        // First check for explicit decrease commands (higher priority)
                        if text.range(of: "(lower|reduce|decrease|drop|turn down|harish|harris|harsh|laris)", options: .regularExpression) != nil {
                            isDecrease = true
                            print("[DEBUG] Decrease context detected in combined text - overriding pattern")
                        }
                        // Then check for increase commands
                        else if text.range(of: "(increase|raise|boost|turn up|warm up)", options: .regularExpression) != nil {
                            isDecrease = false
                            print("[DEBUG] Increase context detected in combined text")
                        }
                    }
                    // Pattern 8: Context-dependent "by X degrees" - analyze full context
                    else if index == 8 {  
                        print("[DEBUG] Context-dependent 'by X degrees' pattern - analyzing full context")
                        // Check recent context for command direction (prioritize decrease)
                        if text.range(of: "(lower|reduce|decrease|drop|turn down|harish|harris|harsh|laris)", options: .regularExpression) != nil {
                            isDecrease = true
                            print("[DEBUG] Standalone 'by X degrees' with decrease context")
                        } else if text.range(of: "(increase|raise|boost|turn up|warm up)", options: .regularExpression) != nil {
                            isDecrease = false
                            print("[DEBUG] Standalone 'by X degrees' with increase context")
                        } else {
                            // Default to decrease if no clear context (safer assumption)
                            isDecrease = true
                            print("[DEBUG] Standalone 'by X degrees' - no clear context, defaulting to decrease")
                        }
                    }
                }
                
                // Special handling for speech recognition error patterns and flexible patterns
                if amount > 0 && index >= 13 {  // Patterns 13+ are flexible patterns (adjusted for new ordering)
                    // For generic patterns, ignore extracted room name and use current page
                    if index == 16 {  // Generic "word by X" pattern (adjusted index)
                        room = ""  // Clear room to force current page usage
                        print("[DEBUG] Generic pattern matched - clearing room to use current page")
                        isDecrease = true  // Assume decrease for generic patterns
                    }
                    print("[DEBUG] Special handling: Flexible pattern matched")
                }
                
                // For past tense patterns, determine direction from the verb
                if amount > 0 && index >= 17 && index <= 20 {  // Past tense patterns (adjusted index)
                    // Past tense patterns should auto-detect increase/decrease from the captured verb
                    print("[DEBUG] Past tense pattern matched - direction auto-detected from verb")
                }
                
                // Only return if we have a valid amount
                if amount > 0 {
                    let finalReduction = isDecrease ? -amount : amount
                    print("[DEBUG] Extracted: room='\(room)', amount=\(amount), isDecrease=\(isDecrease), finalReduction=\(finalReduction)")
                    return (room, finalReduction)
                }
            }
        }
        
        print("[DEBUG] No explicit temperature command with amount found")
        return nil
    }
    
    // Helper function to extract room name from regex match
    private func extractRoomFromMatch(_ match: NSTextCheckingResult, text: String) -> String? {
        // Try to find the room name in the captured groups
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if range.location != NSNotFound, let stringRange = Range(range, in: text) {
                let captured = String(text[stringRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                // Skip if it's a command word or "the" or number
                if captured.range(of: "(lower|reduce|decrease|drop|turn|raise|increase|boost|warm|cool|heat|make|cooler|colder|warmer|hotter|temperature|temp|by|the|down|up)", options: .regularExpression) == nil &&
                   captured.range(of: "\\d+", options: .regularExpression) == nil &&
                   !captured.isEmpty {
                    return captured
                }
            }
        }
        return nil
    }
    
    // Helper function to extract amount from regex match
    private func extractAmountFromMatch(_ match: NSTextCheckingResult, text: String) -> Int? {
        // Find the number in the captured groups
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if range.location != NSNotFound, let stringRange = Range(range, in: text) {
                let captured = String(text[stringRange])
                if captured.range(of: "\\d+", options: .regularExpression) != nil {
                    return Int(captured)
                }
            }
        }
        return nil
    }

    /// Handle health education API responses and ensure VAPI provides voice response
    private func handleHealthEducationAPIResponse(_ response: String) {
        print("[DEBUG] Handling Health Education API response: '\(response.prefix(100))...'")
        
        // If VAPI is active, send a message to trigger the assistant to speak
        if let vapi = vapi, isCalling {
            Task {
                do {
                    // Send a message to the assistant to acknowledge the API response
                    let message = VapiMessage(type: "transcript", role: "user", content: "The health education system has provided a detailed response. Please acknowledge this and provide a brief voice summary.")
                    try await vapi.send(message: message)
                    print("[DEBUG] ✅ Sent VAPI message to trigger voice response")
                } catch {
                    print("[DEBUG] ❌ Failed to send VAPI message: \(error)")
                }
            }
        } else {
            print("[DEBUG] VAPI not active, cannot send voice response")
        }
    }
}

extension Notification.Name {
    static let navigateToRoom = Notification.Name("navigateToRoom")
    static let pageChanged = Notification.Name("pageChanged")
}

extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}