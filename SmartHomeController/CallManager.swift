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

    // Wake word detection
    @Published var isWakeWordActive = false
    @Published var wakeWordDetectedTime: Date? = nil
    private let wakeWordTimeout: TimeInterval = 10.0 // 10 seconds timeout after wake word
    private var wakeWordTimer: Timer? = nil

    // Voice-guided ticket creation state
    @Published var ticketCreationState: TicketCreationState = .idle
    @Published var pendingTicketData: TicketFormData = TicketFormData()
    private var ticketCreationStep: Int = 0

    enum TicketCreationState {
        case idle
        case askingForIssue
        case waitingForIssue
        case askingForPriority
        case waitingForPriority
        case confirmingTicket
        case submitting
        case completed
    }

    struct TicketFormData {
        var subject: String = ""
        var description: String = ""
        var priority: String = "normal"
        var email: String = "karthi@tetradapt.us"
    }

    private var vapi: Vapi?
    private var cancellables = Set<AnyCancellable>()
    private var currentCallStart: Date?
    private let historyKey = "callHistory"
    private var awaitingTempReduction: Bool = false
    private var tempRoomContext: String? = nil
    
    // Context buffer for handling split transcripts
    private var recentUserTranscripts: [String] = []
    private var transcriptBufferLimit = 3 // Keep last 3 user transcripts

    // Clean transcript to remove garbled text
    private func cleanTranscript(_ text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if text is valid (not garbled)
        if cleaned.isEmpty || cleaned.count < 2 {
            return ""
        }

        // Filter out known garbled patterns
        if cleaned.contains("Kjdshf") || cleaned.contains("kjsdhf") {
            return ""
        }

        // Check for too many consonants in a row (likely garbled)
        let words = cleaned.components(separatedBy: .whitespaces)
        for word in words {
            let consonantPattern = "(?i)[bcdfghjklmnpqrstvwxyz]{6,}"
            if word.range(of: consonantPattern, options: .regularExpression) != nil {
                return ""
            }
            // Check if word is too long without vowels
            if word.count > 12 && word.lowercased().rangeOfCharacter(from: CharacterSet(charactersIn: "aeiouAEIOU")) == nil {
                return ""
            }
        }

        // Check if text has at least some valid words
        if cleaned.rangeOfCharacter(from: .letters) == nil {
            return ""
        }

        return cleaned
    }

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
                    self?.switchToSmartHomeContext(room: pageName)
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

                                    // Clean and validate the transcript before sending
                                    let cleanedTranscript = self.cleanTranscript(transcript.transcript)
                                    if !cleanedTranscript.isEmpty {
                                        // Notify about transcription update only if valid
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("TranscriptionUpdate"),
                                            object: nil,
                                            userInfo: ["transcript": cleanedTranscript]
                                        )
                                    }
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

                                    // PRIORITY CHECK: If we're in ticket creation flow, process that FIRST
                                    print("[DEBUG] 🔍 Checking ticket state in Vapi handler: \(self.ticketCreationState)")
                                    if self.ticketCreationState != .idle {
                                        print("[DEBUG] 🎫🔴 In ticket flow, processing ticket input: '\(transcript.transcript)'")
                                        self.processTicketVoiceInput(transcript.transcript)
                                        return
                                    }

                                    // Check for ticket creation commands FIRST (before room navigation)
                                    if self.isTicketCreationRequest(transcript.transcript) {
                                        print("[DEBUG] 🎫 Starting voice-guided ticket creation flow")

                                        // Start the voice-guided ticket creation flow
                                        self.startVoiceGuidedTicketCreation()

                                        // Don't process other commands when creating ticket
                                        return
                                    }

                                    // Handle navigation from user speech (only if not health education or ticket creation)
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
        // For now, just log the prompt update
        print("[DEBUG] System prompt update requested: \(prompt)")
        // The actual Vapi SDK would handle this through its own message format
    }
    
    /// Switch to Smart Home context with Tree of Thought
    func switchToSmartHomeContext(room: String? = nil) {
        currentContext = .smartHome

        // Get the temperature for the room if available
        var temperature: Int? = nil
        if let room = room?.lowercased() {
            temperature = roomTemps[room]
        }

        let prompt = TreeOfThoughtPrompts.getPromptForContext(currentContext, room: room, temperature: temperature)
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
                    let cleanedTranscript = self.cleanTranscript(transcript.transcript)
                    if !cleanedTranscript.isEmpty {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("TranscriptionUpdate"),
                            object: nil,
                            userInfo: ["transcript": cleanedTranscript]
                        )
                    }
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
        print("[DEBUG] 📍 processUserTranscript called with: '\(transcriptText)' (type: \(transcript.transcriptType))")
        print("[DEBUG] 📍 Current ticketCreationState: \(ticketCreationState)")

        if transcript.transcriptType == .partial {
            // User is actively speaking
            print("[DEBUG] User speaking - setting userSpeaking=true, agentSpeaking=false")
            self.userSpeaking = true
            self.agentSpeaking = false
        } else if transcript.transcriptType == .final {
            // Debug: Print user transcript content
            print("[DEBUG] 🎙️ User final transcript: '\(transcriptText)'")

            // PRIORITY: If we're waiting for ticket input, process it immediately
            print("[DEBUG] 🔍🔍🔍 CHECKING TICKET STATE: \(ticketCreationState)")
            if ticketCreationState != .idle {
                print("[DEBUG] 🎫🔴 PRIORITY: In ticket flow (state: \(ticketCreationState)), bypassing all checks")
                print("[DEBUG] 🎫🔴 User said: '\(transcriptText)'")
                print("[DEBUG] 🎫🔴 About to call processUserTranscriptInternal")

                // Keep wake word active during ticket flow
                if !isWakeWordActive {
                    print("[DEBUG] 🎫🔴 Activating wake word for ticket flow")
                    activateWakeWord()
                } else {
                    print("[DEBUG] 🎫🔴 Resetting wake word timer")
                    resetWakeWordTimer()
                }

                // Skip all wake word checks and process immediately
                processUserTranscriptInternal(transcriptText, transcript: transcript)
                return
            } else {
                print("[DEBUG] 🔍🔍🔍 NOT IN TICKET FLOW - State is idle")
            }

            // FIRST: Check for wake word
            if detectWakeWord(transcriptText) {
                activateWakeWord()
                // Remove wake word from transcript for further processing
                var cleanedTranscript = transcriptText
                let wakeWords = ["hi luna", "hey luna", "hai luna", "hello luna", "ok luna", "okay luna"]
                for word in wakeWords {
                    cleanedTranscript = cleanedTranscript.lowercased().replacingOccurrences(of: word, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // If there's remaining text after wake word, process it
                if !cleanedTranscript.isEmpty {
                    processCommandAfterWakeWord(cleanedTranscript, originalTranscript: transcript)
                }
                return
            }
            
            // If wake word is not active AND we're not in ticket creation flow, ignore the command
            if !isWakeWordActive && ticketCreationState == .idle {
                print("[DEBUG] 🌙 Wake word not active and not in ticket flow, ignoring command: '\(transcriptText)'")
                return
            }

            // Allow processing if in ticket creation flow even without wake word
            if ticketCreationState != .idle {
                print("[DEBUG] 🎫 In ticket creation flow, processing without wake word")
            }
            
            // Reset wake word timer since user is still talking (unless in ticket flow)
            if ticketCreationState == .idle {
                resetWakeWordTimer()
            }
            
            // Process the command with wake word active
            processUserTranscriptInternal(transcriptText, transcript: transcript)
        }
    }
    
    // processAssistantTranscript is defined below after helper functions
    
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
        // Log temperature announcement
        print("[DEBUG] Speaking temperature: \(room) is \(temp)°F")
        // TODO: Use actual Vapi SDK message format for TTS
    }
    
    /// Speak a response using VAPI (TTS)
    func speakResponse(_ text: String) async {
        print("[DEBUG] 🔊 speakResponse called with: '\(text.prefix(50))...'")
        // TODO: Use actual Vapi SDK message format for TTS
    }
    
    /// Announce current room temperature when visiting a room (without triggering agent questions)
    func announceRoomTemperature(room: String, temp: Int) async {
        // Log room temperature announcement
        print("[DEBUG] Announcing room temperature: \(room) is \(temp)°F")
        // TODO: Use actual Vapi SDK message format for announcements
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

    private func extractBlindsAction(_ text: String) -> (room: String, action: String, position: Int?)? {
        print("[DEBUG] Extracting blinds action from: '\(text)'")
        let lowerText = text.lowercased()
        
        // Patterns for blinds commands
        let patterns = [
            // Open/close commands
            #"(open|close|shut)\s+(?:the\s+)?blinds"#,
            #"blinds\s+(up|down|open|close)"#,
            
            // Percentage commands
            #"(?:set\s+)?blinds\s+(?:to\s+)?(\d+)\s*(?:percent|%)"#,
            #"blinds\s+(\d+)\s*(?:percent|%)?"#,
            
            // Room-specific commands
            #"(open|close)\s+(?:the\s+)?([a-zA-Z ]+)\s+blinds"#,
            #"([a-zA-Z ]+)\s+blinds\s+(up|down|open|close)"#,
        ]
        
        var room = ""
        var action = ""
        var position: Int? = nil
        
        // Check for open/close/up/down commands
        if lowerText.contains("open") || lowerText.contains("up") {
            action = "open"
            position = 100
        } else if lowerText.contains("close") || lowerText.contains("shut") || lowerText.contains("down") {
            action = "close"
            position = 0
        } else if lowerText.contains("half") {
            action = "set"
            position = 50
        }
        
        // Extract percentage if mentioned
        let percentageRegex = try? NSRegularExpression(pattern: #"(\d+)\s*(?:percent|%)"#, options: .caseInsensitive)
        if let match = percentageRegex?.firstMatch(in: lowerText, options: [], range: NSRange(location: 0, length: lowerText.count)) {
            if let percentRange = Range(match.range(at: 1), in: lowerText) {
                if let percent = Int(lowerText[percentRange]) {
                    position = min(max(percent, 0), 100)
                    action = "set"
                }
            }
        }
        
        // Extract room name if mentioned
        let roomNames = ["kitchen", "living room", "bedroom", "office", "bathroom", "dining room"]
        for roomName in roomNames {
            if lowerText.contains(roomName) {
                room = roomName
                break
            }
        }
        
        // Only return if we have a valid action
        if !action.isEmpty {
            return (room, action, position)
        }
        
        return nil
    }
    
    @MainActor
    private func processBlindsCommand(room: String, action: String, position: Int?) {
        print("[DEBUG] Processing blinds command for room: \(room), action: \(action), position: \(String(describing: position))")
        
        // Post notification to update blinds with voice action
        let targetPosition = position ?? (action == "open" ? 100 : 0)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateBlinds"),
            object: nil,
            userInfo: [
                "room": room,
                "position": targetPosition,
                "action": action,
                "isVoiceCommand": true
            ]
        )
        
        // Speak confirmation
        Task {
            let actionText = position != nil ? "to \(position!)%" : action == "open" ? "opened" : "closed"
            await speakResponse("Blinds \(actionText)")
        }
    }
    
    private func processCommandAfterWakeWord(_ cleanedTranscript: String, originalTranscript: Transcript) {
        // Process the cleaned transcript directly
        // We can't modify the transcript struct, so we pass the original but use the cleaned text
        processUserTranscriptInternal(cleanedTranscript, transcript: originalTranscript)
    }
    
    private func processUserTranscriptInternal(_ transcriptText: String, transcript: Transcript) {
        // This contains all the original processing logic
        // Moved here to be reusable after wake word detection

        // Add to transcript buffer for context-aware processing
        self.recentUserTranscripts.append(transcriptText)
        if self.recentUserTranscripts.count > self.transcriptBufferLimit {
            self.recentUserTranscripts.removeFirst()
        }

        // Check if we're in ticket creation flow - process ANY state except idle
        print("[DEBUG] 🔍 Checking ticket creation state: \(ticketCreationState)")
        if ticketCreationState != .idle {
            print("[DEBUG] ✅ In ticket creation flow (state: \(ticketCreationState)), calling processTicketVoiceInput")
            print("[DEBUG] 🎤 User input: '\(transcriptText)'")

            // Update system prompt to make VAPI wait while we process
            self.updateSystemPrompt("The app is processing your request and filling the form. Please wait silently while the form is being filled. Do not provide any response.")

            processTicketVoiceInput(transcriptText)
            return
        } else {
            print("[DEBUG] ⚠️ NOT in active ticket flow. State: \(ticketCreationState)")
        }

        // Check if user is on support page and wants to submit/send the ticket
        if currentPage.lowercased() == "support" || currentPage.lowercased() == "create ticket" {
            let lowerText = transcriptText.lowercased()
            if lowerText.contains("submit") || lowerText.contains("send it") ||
               lowerText.contains("send the ticket") || lowerText.contains("submit the ticket") ||
               lowerText.contains("create it") || lowerText.contains("go ahead") ||
               lowerText.contains("confirm") || lowerText.contains("yes") {
                print("[DEBUG] 🎫 User wants to submit ticket from support page")
                // Trigger ticket submission
                NotificationCenter.default.post(
                    name: NSNotification.Name("SubmitTicketVoiceCommand"),
                    object: nil
                )
                return
            }
        }

        // Check for ticket creation requests (including "support page", "create ticket", etc.)
        // First check the current transcript
        if self.isTicketCreationRequest(transcriptText) {
            print("[DEBUG] 🎫 Starting voice-guided ticket creation for: '\(transcriptText)'")
            startVoiceGuidedTicketCreation()
            return
        }

        // Also check combined recent context for fragmented commands
        if recentUserTranscripts.count > 0 {
            let combinedContext = recentUserTranscripts.joined(separator: " ")
            print("[DEBUG] 🎫 Checking combined context for ticket request: '\(combinedContext)'")

            // More lenient check for support page navigation
            let lowerContext = combinedContext.lowercased()
            if (lowerContext.contains("support") && lowerContext.contains("page")) ||
               (lowerContext.contains("luna") && lowerContext.contains("support")) ||
               self.isTicketCreationRequest(combinedContext) {
                print("[DEBUG] 🎫 Starting voice-guided ticket creation from combined context: '\(combinedContext)'")
                startVoiceGuidedTicketCreation()
                return
            }
        }

        // Check for health-related questions
        if self.isHealthRelatedQuestion(transcriptText) {
            print("[DEBUG] 🏥 Health-related question detected in transcript: '\(transcriptText)'")
            self.handleHealthEducationQuery(transcriptText)
            return
        }

        // Handle navigation from user speech
        if let room = self.extractRoomName(from: transcriptText) {
            let normalizedRoom = room.lowercased()
            if self.currentPage.lowercased() != normalizedRoom {
                print("[DEBUG] User mentioned room: \(room), navigating from \(self.currentPage) to \(room)...")
                self.currentPage = normalizedRoom
                NotificationCenter.default.post(name: .navigateToRoom, object: room)
            }
        }

        // Process temperature changes
        self.processTemperatureCommand(transcriptText)

        // Process blinds commands
        self.processBlindsVoiceCommand(transcriptText)

        // Show speaking animation
        self.showUserSpeakingAnimation(for: transcriptText)
    }
    
    private func handleHealthEducationQuery(_ query: String) {
        print("[DEBUG] 🏥 Navigating to Health Education")
        self.currentPage = "health education"
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .navigateToRoom, object: "Health Education")
            
            Task { @MainActor in
                let viewModel = HealthEducationViewModel.shared
                viewModel.messages.append(HealthChatMessage(content: query, isUser: true))
                viewModel.currentInput = query
                viewModel.sendMessage()
            }
        }
        
        self.updateSystemPrompt("You are being redirected to health education. Please do not respond to this message.")
        self.switchToHealthEducationContext()
    }
    
    private func processTemperatureCommand(_ transcriptText: String) {
        print("[DEBUG] Processing temperature commands for user transcript")
        
        var tempCommand: (room: String, reduction: Int)? = self.extractTempReductionAction(transcriptText)
        
        if tempCommand == nil && self.recentUserTranscripts.count > 1 {
            let combinedTranscript = self.recentUserTranscripts.joined(separator: " ")
            tempCommand = self.extractTempReductionAction(combinedTranscript)
        }
        
        if let (room, reduction) = tempCommand {
            print("[DEBUG] USER temperature command detected: room=\(room.lowercased()), reduction=\(reduction)")
            let normalizedRoom = room.isEmpty ? self.currentPage.lowercased() : room.lowercased()
            
            if let tempVM = RoomView.roomViewModels[normalizedRoom] {
                tempVM.animateTemperatureChange(by: reduction)
                tempVM.setVoiceAction(reduction > 0 ? .increase : .decrease, duration: 1.0)
                self.recentUserTranscripts.removeAll()
            } else if let tempVM = HomeControlsView.homeTempVM, (normalizedRoom == "home" || normalizedRoom == "favorites") {
                tempVM.animateTemperatureChange(by: reduction)
                tempVM.setVoiceAction(reduction > 0 ? .increase : .decrease, duration: 1.0)
                self.recentUserTranscripts.removeAll()
            }
        }
    }
    
    private func processBlindsVoiceCommand(_ transcriptText: String) {
        print("[DEBUG] Processing blinds commands for user transcript")
        
        var blindsCommand: (room: String, action: String, position: Int?)? = self.extractBlindsAction(transcriptText)
        
        if blindsCommand == nil && self.recentUserTranscripts.count > 1 {
            let combinedTranscript = self.recentUserTranscripts.joined(separator: " ")
            blindsCommand = self.extractBlindsAction(combinedTranscript)
        }
        
        if let (room, action, position) = blindsCommand {
            print("[DEBUG] USER blinds command detected: room=\(room), action=\(action), position=\(String(describing: position))")
            let normalizedRoom = room.isEmpty ? self.currentPage.lowercased() : room.lowercased()
            
            Task { @MainActor in
                self.processBlindsCommand(room: normalizedRoom, action: action, position: position)
            }
        }
    }
    
    private func showUserSpeakingAnimation(for transcript: String) {
        print("[DEBUG] User final transcript - simulating speaking animation")
        self.userSpeaking = true
        self.agentSpeaking = false
        
        let wordCount = transcript.split(separator: " ").count
        let estimatedDuration = max(1.5, min(Double(wordCount) * 0.4, 5.0))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
            self.userSpeaking = false
        }
    }
    
    // MARK: - Wake Word Detection
    
    private func detectWakeWord(_ text: String) -> Bool {
        let lowerText = text.lowercased()
        let wakeWordPatterns = [
            "hi luna",
            "hey luna",
            "hai luna",
            "hello luna",
            "ok luna",
            "okay luna"
        ]
        
        for pattern in wakeWordPatterns {
            if lowerText.contains(pattern) {
                return true
            }
        }
        
        // Also check for variations with punctuation removed
        let cleanedText = lowerText.replacingOccurrences(of: "[^a-z ]", with: "", options: .regularExpression)
        for pattern in wakeWordPatterns {
            if cleanedText.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    private func activateWakeWord() {
        print("[DEBUG] 🌙 Wake word activated - Luna is listening")
        isWakeWordActive = true
        wakeWordDetectedTime = Date()
        
        // Cancel previous timer if exists
        wakeWordTimer?.invalidate()
        
        // Set timeout to deactivate after period of inactivity
        wakeWordTimer = Timer.scheduledTimer(withTimeInterval: wakeWordTimeout, repeats: false) { [weak self] _ in
            self?.deactivateWakeWord()
        }
        
        // Visual feedback
        Task { @MainActor in
            // Post notification for UI to show activation
            NotificationCenter.default.post(
                name: NSNotification.Name("WakeWordActivated"),
                object: nil
            )
            
            // Speak confirmation
            await speakResponse("Yes, I'm listening")
        }
    }
    
    private func deactivateWakeWord() {
        // Don't deactivate if we're in ticket creation flow
        if ticketCreationState != .idle {
            print("[DEBUG] 🎫 Preventing wake word deactivation - in ticket flow")
            resetWakeWordTimer()
            return
        }

        print("[DEBUG] 🌙 Wake word deactivated - Luna sleeping")
        isWakeWordActive = false
        wakeWordDetectedTime = nil
        wakeWordTimer?.invalidate()
        wakeWordTimer = nil
        
        // Post notification for UI
        NotificationCenter.default.post(
            name: NSNotification.Name("WakeWordDeactivated"),
            object: nil
        )
    }
    
    private func resetWakeWordTimer() {
        // Reset the timer when user continues speaking
        if isWakeWordActive {
            wakeWordTimer?.invalidate()
            wakeWordTimer = Timer.scheduledTimer(withTimeInterval: wakeWordTimeout, repeats: false) { [weak self] _ in
                self?.deactivateWakeWord()
            }
        }
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
        
        // If VAPI is active, log that we would trigger voice response
        if vapi != nil && isCalling {
            print("[DEBUG] Health education response ready for voice summary")
            // TODO: Use actual Vapi SDK message format to trigger voice response
        } else {
            print("[DEBUG] VAPI not active, cannot send voice response")
        }
    }

    // MARK: - Ticket Creation Helpers

    /// Check if the user's command is a ticket creation request
    private func isTicketCreationRequest(_ text: String) -> Bool {
        let lower = text.lowercased()

        // Ticket creation keywords and phrases
        let ticketKeywords = [
            "create a ticket",
            "create ticket",
            "submit a ticket",
            "submit ticket",
            "open a ticket",
            "open ticket",
            "report an issue",
            "report a problem",
            "maintenance request",
            "submit a maintenance",
            "submit maintenance",
            "need help with",
            "file a complaint",
            "file complaint",
            "need support",
            "support page",
            "go to support",
            "to support page",
            "to support",
            "open support",
            "show support",
            "i have an issue",
            "i have a problem",
            "i've an issue",
            "i've got an issue",
            "i've a problem",
            "i've got a problem",
            "have an issue",
            "have a problem",
            "connection issue",
            "connection problem",
            "connectivity issue",
            "connectivity problem",
            "i have issue",
            "i have problem",
            "got an issue",
            "got a problem",
            "experiencing an issue",
            "experiencing a problem",
            "facing an issue",
            "facing a problem",
            "issue with",
            "problem with",
            "there's an issue",
            "there's a problem",
            "there is an issue",
            "there is a problem"
        ]

        // Check for ticket keywords
        for keyword in ticketKeywords {
            if lower.contains(keyword) {
                return true
            }
        }

        // Check for patterns like "broken X", "leaking Y", "not working"
        let issuePatterns = [
            "broken", "leaking", "not working", "not responding",
            "doesn't work", "malfunction", "damaged", "faulty"
        ]

        for pattern in issuePatterns {
            if lower.contains(pattern) && (lower.contains("ticket") || lower.contains("report") || lower.contains("help")) {
                return true
            }
        }

        return false
    }

    /// Extract ticket details from voice command
    private func extractTicketDetails(from text: String) -> (subject: String, description: String, location: String, issue: String) {
        let lower = text.lowercased()

        // Extract location (room)
        var location = ""
        let rooms = ["kitchen", "bathroom", "bedroom", "living room", "garage", "laundry", "office", "basement", "attic", "hallway", "dining room"]
        for room in rooms {
            if lower.contains(room) {
                location = room.capitalized
                break
            }
        }

        // Extract issue type
        var issue = ""
        let issueTypes = [
            ("broken", "Broken Equipment"),
            ("leaking", "Water Leak"),
            ("not working", "Not Working"),
            ("is not working", "Not Working"),
            ("isn't working", "Not Working"),
            ("not responding", "Device Not Responding"),
            ("doesn't work", "Not Working"),
            ("does not work", "Not Working"),
            ("malfunction", "Malfunction"),
            ("damaged", "Damage"),
            ("faulty", "Faulty Equipment"),
            ("won't turn on", "Won't Turn On"),
            ("won't turn off", "Won't Turn Off"),
            ("stuck", "Stuck/Jammed"),
            ("making noise", "Unusual Noise")
        ]

        for (keyword, issueType) in issueTypes {
            if lower.contains(keyword) {
                issue = issueType
                break
            }
        }

        // Extract device/item with more comprehensive list
        var device = ""
        let devices = [
            ("air conditioner", "Air Conditioner"),
            ("ac unit", "Air Conditioner"),
            ("ac", "Air Conditioner"),
            ("heater", "Heater"),
            ("heating", "Heater"),
            ("faucet", "Faucet"),
            ("sink", "Sink"),
            ("toilet", "Toilet"),
            ("shower", "Shower"),
            ("bathtub", "Bathtub"),
            ("light", "Light"),
            ("lights", "Lights"),
            ("bulb", "Light Bulb"),
            ("door", "Door"),
            ("window", "Window"),
            ("lock", "Lock"),
            ("garage door", "Garage Door"),
            ("dishwasher", "Dishwasher"),
            ("refrigerator", "Refrigerator"),
            ("fridge", "Refrigerator"),
            ("freezer", "Freezer"),
            ("oven", "Oven"),
            ("stove", "Stove"),
            ("microwave", "Microwave"),
            ("washer", "Washing Machine"),
            ("washing machine", "Washing Machine"),
            ("dryer", "Dryer"),
            ("disposal", "Garbage Disposal"),
            ("fan", "Fan"),
            ("smoke detector", "Smoke Detector"),
            ("thermostat", "Thermostat"),
            ("outlet", "Electrical Outlet"),
            ("switch", "Light Switch")
        ]

        for (keyword, deviceName) in devices {
            if lower.contains(keyword) {
                device = deviceName
                break
            }
        }

        // Create more descriptive subject
        var subject = ""
        if !device.isEmpty && !issue.isEmpty {
            subject = "\(device) - \(issue)"
            if !location.isEmpty {
                subject = "\(location) \(subject)"
            }
        } else if !device.isEmpty {
            subject = "\(device) Issue"
            if !location.isEmpty {
                subject = "\(location) - \(subject)"
            }
        } else if !issue.isEmpty {
            subject = issue
            if !location.isEmpty {
                subject = "\(location) - \(subject)"
            }
        } else {
            // Try to extract meaningful info from the command
            let cleanedCommand = text
                .replacingOccurrences(of: "create a ticket", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "create ticket", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "submit a ticket", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "submit ticket", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: CharacterSet(charactersIn: " -,"))

            if !cleanedCommand.isEmpty && cleanedCommand.count > 3 {
                subject = cleanedCommand.capitalized
            } else {
                subject = "Maintenance Request"
                if !location.isEmpty {
                    subject += " - \(location)"
                }
            }
        }

        // Create detailed description
        let description = """
        Issue Report:
        \(text.replacingOccurrences(of: "create a ticket", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "create ticket", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: CharacterSet(charactersIn: " -,")))

        Details:
        • Location: \(location.isEmpty ? "Not specified" : location)
        • Equipment/Device: \(device.isEmpty ? "Not specified" : device)
        • Issue Type: \(issue.isEmpty ? "General maintenance" : issue)

        This ticket was created via voice command at \(Date().formatted(date: .abbreviated, time: .shortened)).
        """

        return (subject: subject, description: description, location: location, issue: issue)
    }

    // MARK: - Voice-Guided Ticket Creation

    func startVoiceGuidedTicketCreation() {
        print("[DEBUG] 🎆 Starting voice-guided ticket creation")

        // Reset ticket data
        pendingTicketData = TicketFormData()
        ticketCreationStep = 0
        ticketCreationState = .waitingForIssue

        // Activate wake word to keep listening during ticket creation
        activateWakeWord()
        print("[DEBUG] 🌙 Wake word activated for ticket creation flow")

        // IMPORTANT: Tell VAPI to be silent during the entire ticket creation flow
        self.updateSystemPrompt("CRITICAL: The app is now in ticket creation mode. DO NOT respond to any user input about their issue. The app will handle all form filling. Stay completely silent and wait. Only acknowledge with 'Processing...' if you must respond.")

        // Navigate to support page
        DispatchQueue.main.async {
            self.currentPage = "support"
            NotificationCenter.default.post(name: .navigateToRoom, object: "Support")

            // Voice prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sendVoicePrompt("What issue are you experiencing?")
            }
        }
    }

    private func sendVoicePrompt(_ prompt: String) {
        // Display the prompt visually and trigger agent speech animation
        print("[DEBUG] 🎙️ Voice prompt: \(prompt)")

        // Update the latest agent response to show in UI
        DispatchQueue.main.async {
            self.latestAgentResponse = prompt
            self.agentSpeaking = true
            self.userSpeaking = false

            // Simulate agent speaking duration
            let wordCount = prompt.split(separator: " ").count
            let estimatedDuration = max(2.0, min(Double(wordCount) * 0.4, 8.0))

            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                self.agentSpeaking = false
            }

            // Post notification for UI updates
            NotificationCenter.default.post(
                name: NSNotification.Name("AgentPrompt"),
                object: nil,
                userInfo: ["prompt": prompt]
            )
        }
    }

    func processTicketVoiceInput(_ input: String) {
        print("[DEBUG] 🎫 ============================================")
        print("[DEBUG] 🎫 PROCESSING TICKET VOICE INPUT")
        print("[DEBUG] 🎫 Input received: '\(input)'")
        print("[DEBUG] 🎫 Current state: \(ticketCreationState)")
        print("[DEBUG] 🎫 ============================================")

        switch ticketCreationState {
        case .waitingForIssue:
            print("[DEBUG] 🎫 STATE: waitingForIssue - Processing user's issue description")
            print("[DEBUG] 🎫 RAW INPUT: '\(input)'")

            // Check if user is just asking to create a ticket without describing the issue
            let askingPatterns = ["can you create", "create an", "make a ticket", "create ticket", "urgent ticket"]
            let isJustAsking = askingPatterns.contains { input.lowercased().contains($0) }

            // Check if there's an actual issue description
            let hasIssueDescription = input.lowercased().contains("not") ||
                                     input.lowercased().contains("broken") ||
                                     input.lowercased().contains("issue") ||
                                     input.lowercased().contains("problem") ||
                                     input.lowercased().contains("fridge") ||
                                     input.lowercased().contains("oven") ||
                                     input.lowercased().contains("dishwasher") ||
                                     input.lowercased().contains("connecting") ||
                                     input.count > 20 // Longer descriptions likely contain issue details

            if isJustAsking && !hasIssueDescription {
                // User is asking to create ticket but hasn't described the issue
                print("[DEBUG] 🎫 User asking to create ticket but no issue described yet")
                Task {
                    await speakResponse("Please describe the issue you're experiencing.")
                }

                // Store this as partial input to combine with next input
                pendingTicketData.description = ""
                return
            }

            // Check if we need to combine with previous context
            var finalDescription = input
            if !pendingTicketData.description.isEmpty {
                // Combine with previous input
                finalDescription = pendingTicketData.description + " " + input
                print("[DEBUG] 🎫 Combined input: '\(finalDescription)'")
            } else if recentUserTranscripts.count > 1 {
                // Check last few transcripts for context
                let recentContext = recentUserTranscripts.suffix(3).joined(separator: " ")
                if recentContext.lowercased().contains("fridge") ||
                   recentContext.lowercased().contains("not connecting") ||
                   recentContext.lowercased().contains("wifi") {
                    finalDescription = recentContext
                    print("[DEBUG] 🎫 Using recent context: '\(finalDescription)'")
                }
            }

            // Clean the description by removing greeting and navigation phrases
            finalDescription = cleanTicketDescription(finalDescription)

            // User provided the issue description
            pendingTicketData.description = finalDescription
            pendingTicketData.subject = extractTicketSubject(from: finalDescription)

            print("[DEBUG] 🎫 ✅ FORM DATA SET:")
            print("[DEBUG] 🎫   Subject: '\(pendingTicketData.subject)'")
            print("[DEBUG] 🎫   Description: '\(pendingTicketData.description)'")

            // Animate form field updates - STEP 1: Fill Subject
            DispatchQueue.main.async {
                print("[DEBUG] 📤 Posting voiceGuidedTicketUpdate for subject: \(self.pendingTicketData.subject)")
                NotificationCenter.default.post(
                    name: .voiceGuidedTicketUpdate,
                    object: nil,
                    userInfo: [
                        "subject": self.pendingTicketData.subject,
                        "animateField": "subject"
                    ]
                )
            }

            // STEP 2: Fill Description after delay (wait for subject animation to complete)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                print("[DEBUG] 📤 Posting voiceGuidedTicketUpdate for description: \(self.pendingTicketData.description)")
                NotificationCenter.default.post(
                    name: .voiceGuidedTicketUpdate,
                    object: nil,
                    userInfo: [
                        "description": self.pendingTicketData.description,
                        "animateField": "description"
                    ]
                )
            }

            // STEP 3: Ask for priority after fields are filled (wait for description animation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                self.ticketCreationState = .waitingForPriority
                // Restore VAPI's ability to respond now that form is filled
                self.updateSystemPrompt("The form has been filled. Now please ask the user about priority.")
                self.sendVoicePrompt("How urgent is this issue? Please say low, normal, or urgent.")
            }

        case .waitingForPriority:
            print("[DEBUG] 🎫 STATE: waitingForPriority - Processing priority: '\(input)'")

            // User provided priority
            let priority = extractPriority(from: input)
            pendingTicketData.priority = priority

            print("[DEBUG] 🎫 Priority extracted: \(priority)")

            // Animate priority selection with visual feedback
            DispatchQueue.main.async {
                print("[DEBUG] 📤 Posting priority animation: \(priority)")
                NotificationCenter.default.post(
                    name: .voiceGuidedTicketUpdate,
                    object: nil,
                    userInfo: [
                        "priority": priority,
                        "animatePriority": true
                    ]
                )

                // Voice feedback for priority selection
                let priorityMessage = priority == "high" ? "Setting urgent priority" :
                                     priority == "low" ? "Setting low priority" :
                                     "Setting normal priority"
                self.latestAgentResponse = priorityMessage
            }

            // Wait for animation then ask for confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.ticketCreationState = .confirmingTicket
                let priorityDisplay = self.pendingTicketData.priority == "high" ? "urgent" : self.pendingTicketData.priority
                let confirmPrompt = "Ready to submit a \(priorityDisplay) priority ticket about '\(self.pendingTicketData.subject)'. Should I submit this ticket?"
                self.sendVoicePrompt(confirmPrompt)
            }

        case .confirmingTicket:
            print("[DEBUG] 🎫 STATE: confirmingTicket - User response: '\(input)'")

            // Check for confirmation
            if isConfirmation(input) {
                print("[DEBUG] 🎫 User confirmed - submitting ticket")
                ticketCreationState = .submitting

                // Voice feedback
                DispatchQueue.main.async {
                    self.sendVoicePrompt("Great! Submitting your ticket now...")
                    self.latestAgentResponse = "Submitting ticket..."
                }

                // Trigger submission with animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.submitTicketWithAnimation()
                }
            } else if isRejection(input) {
                print("[DEBUG] 🎫 User cancelled ticket creation")
                // Cancel and reset
                ticketCreationState = .idle
                pendingTicketData = TicketFormData()
                deactivateWakeWord()
                print("[DEBUG] 🌙 Wake word deactivated after ticket cancellation")
                sendVoicePrompt("No problem, I've cancelled the ticket.")
            } else {
                // Ask again
                sendVoicePrompt("I need your confirmation. Please say yes to submit or no to cancel.")
            }

        default:
            break
        }
    }

    private func cleanTicketDescription(_ description: String) -> String {
        var cleaned = description

        // First, clean up encoding issues and weird characters
        // Remove any non-printable characters
        cleaned = cleaned.components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters).inverted).joined()

        // Remove all variations of greetings and filler words (case insensitive)
        let phrasesToRemove = [
            // Greetings and agent names
            "Can you hey, Luna", "Can you hey Luna", "Hey, Luna", "Hey Luna",
            "Hi, Luna", "Hi Luna", "Hello, Luna", "Hello Luna",
            "Hey, Nava", "Hey Nava", "Hi, Nava", "Hi Nava",
            "Can you", "Could you", "Would you",

            // Navigation and support phrases
            "Can you go to the", "go to the", "go to support page",
            "go to support", "support page", "open support",
            "navigate to support", "take me to support",

            // Filler words and sounds
            "Um,", "um", "Uh,", "uh", "Ah,", "ah",
            "please help", "help me with",

            // Question starters
            "Hi.", "Hey.", "Hello.",

            // Weird punctuation
            "?", ". .", ",.", ".,", "..", ",,"
        ]

        // Remove all phrases (case insensitive)
        for phrase in phrasesToRemove {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }

        // Extract the actual problem statement
        // Look for key problem indicators
        if let range = cleaned.range(of: "my ", options: .caseInsensitive) {
            // Extract from "my" onwards (this usually starts the actual problem)
            cleaned = String(cleaned[range.lowerBound...])
        }

        // Clean up extra whitespace and punctuation
        cleaned = cleaned
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "^[,. ]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[,. ]+$", with: "", options: .regularExpression)

        // Capitalize first letter
        if !cleaned.isEmpty {
            let firstChar = cleaned.prefix(1)
            if firstChar.lowercased() == "m" && cleaned.lowercased().hasPrefix("my ") {
                // Keep "My" capitalized for problem descriptions
                cleaned = "My" + cleaned.dropFirst(2)
            } else {
                cleaned = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
            }
        }

        // Validate the cleaned text
        if cleaned.isEmpty || cleaned.count < 5 {
            return "Issue reported via voice"
        }

        // Final cleanup - ensure it's a proper sentence
        if !cleaned.hasSuffix(".") && !cleaned.hasSuffix("!") && !cleaned.hasSuffix("?") {
            cleaned = cleaned + "."
        }

        return cleaned
    }

    private func extractTicketSubject(from description: String) -> String {
        // Extract a concise subject from the description
        let lower = description.lowercased()

        // Look for specific device issues
        if lower.contains("fridge") || lower.contains("refrigerator") {
            if lower.contains("connect") {
                return "Fridge Connection Issue"
            }
            return "Fridge Issue"
        }

        // Look for key problem indicators
        if let device = extractDevice(from: description) {
            if lower.contains("not working") {
                return "\(device) Not Working"
            } else if lower.contains("connect") {
                return "\(device) Connection Issue"
            }
            return "\(device) Issue"
        }

        // Default to first few words
        let words = description.split(separator: " ")
        if words.count <= 5 {
            return description
        }
        return words.prefix(5).joined(separator: " ")
    }

    private func extractDevice(from text: String) -> String? {
        let devices = ["thermostat", "light", "lights", "door", "lock", "camera", "sensor", "alarm", "blinds", "ac", "heater", "fridge", "oven", "dishwasher"]
        for device in devices {
            if text.lowercased().contains(device) {
                return device.capitalized
            }
        }
        return nil
    }

    private func extractPriority(from input: String) -> String {
        let lowercased = input.lowercased()

        print("[DEBUG] 🎫 Extracting priority from: '\(input)' (lowercased: '\(lowercased)')")

        // High priority keywords - including common speech recognition errors
        if lowercased.contains("urgent") || lowercased.contains("ugerent") ||
           lowercased.contains("urgently") || lowercased.contains("high") ||
           lowercased.contains("emergency") || lowercased.contains("critical") ||
           lowercased.contains("asap") || lowercased.contains("immediately") ||
           lowercased.contains("very important") || lowercased.contains("right now") {
            print("[DEBUG] 🎫 Detected HIGH priority")
            return "high"
        }

        // Low priority keywords
        else if lowercased.contains("low") || lowercased.contains("minor") ||
                lowercased.contains("not urgent") || lowercased.contains("whenever") ||
                lowercased.contains("no rush") || lowercased.contains("not important") {
            print("[DEBUG] 🎫 Detected LOW priority")
            return "low"
        }

        // Normal priority keywords or default
        else if lowercased.contains("normal") || lowercased.contains("regular") ||
                lowercased.contains("standard") || lowercased.contains("medium") {
            print("[DEBUG] 🎫 Detected NORMAL priority")
            return "normal"
        }

        // Default to normal if no keywords found
        print("[DEBUG] 🎫 No priority keywords found, defaulting to NORMAL")
        return "normal"
    }

    private func isConfirmation(_ input: String) -> Bool {
        let confirmWords = ["yes", "yeah", "yep", "sure", "okay", "ok", "confirm", "submit", "go ahead", "do it"]
        let lowercased = input.lowercased()
        return confirmWords.contains { lowercased.contains($0) }
    }

    private func isRejection(_ input: String) -> Bool {
        let rejectWords = ["no", "nope", "cancel", "stop", "don't", "never mind", "forget it"]
        let lowercased = input.lowercased()
        return rejectWords.contains { lowercased.contains($0) }
    }

    private func updateTicketForm() {
        // Post notification to update the form fields with animation
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .voiceGuidedTicketUpdate,
                object: nil,
                userInfo: [
                    "subject": self.pendingTicketData.subject,
                    "description": self.pendingTicketData.description,
                    "email": self.pendingTicketData.email,
                    "animate": true
                ]
            )
        }
    }

    private func updatePrioritySelection(_ priority: String) {
        // Post notification to animate priority selection
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .voiceGuidedTicketUpdate,
                object: nil,
                userInfo: [
                    "priority": priority,
                    "animatePriority": true
                ]
            )
        }
    }

    private func submitTicketWithAnimation() {
        ticketCreationState = .submitting

        print("[DEBUG] 🎫 Submitting ticket with animation")
        print("[DEBUG] 🎫   Subject: \(pendingTicketData.subject)")
        print("[DEBUG] 🎫   Description: \(pendingTicketData.description)")
        print("[DEBUG] 🎫   Priority: \(pendingTicketData.priority)")
        print("[DEBUG] 🎫   Email: \(pendingTicketData.email)")

        // Trigger submit button animation and submission
        DispatchQueue.main.async {
            // First, trigger the button press animation
            NotificationCenter.default.post(
                name: .voiceGuidedTicketSubmit,
                object: nil,
                userInfo: [
                    "subject": self.pendingTicketData.subject,
                    "description": self.pendingTicketData.description,
                    "priority": self.pendingTicketData.priority,
                    "email": self.pendingTicketData.email,
                    "animateButton": true
                ]
            )

            // Give voice feedback about submission progress
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.sendVoicePrompt("Creating your ticket in the system...")
            }

            // Handle completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.ticketCreationState = .completed
                let ticketNumber = Int.random(in: 10000...99999)
                self.sendVoicePrompt("Perfect! Your ticket number \(ticketNumber) has been created successfully. You'll receive a confirmation email shortly.")

                // Reset state after completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.ticketCreationState = .idle
                    self.pendingTicketData = TicketFormData()
                    self.deactivateWakeWord()
                    print("[DEBUG] 🌙 Wake word deactivated after ticket completion")

                    // Navigate back to home after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.currentPage = "home"
                        NotificationCenter.default.post(name: .navigateToRoom, object: "Home")
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let navigateToRoom = Notification.Name("navigateToRoom")
    static let pageChanged = Notification.Name("pageChanged")
    static let voiceGuidedTicketUpdate = Notification.Name("voiceGuidedTicketUpdate")
    static let voiceGuidedTicketSubmit = Notification.Name("voiceGuidedTicketSubmit")
}

extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}