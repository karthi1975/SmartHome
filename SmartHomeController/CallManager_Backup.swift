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

    private var vapi: Vapi?
    private var cancellables = Set<AnyCancellable>()
    private var currentCallStart: Date?
    private let historyKey = "callHistory"
    private var awaitingTempReduction: Bool = false
    private var tempRoomContext: String? = nil

    init() {
        loadHistory()
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
                        }
                    case .transcript(let transcript):
                        print("📝 Transcript: \(transcript)")
                        DispatchQueue.main.async {
                            // Immediately set speaking states based on role and transcript type
                            if transcript.role == .user {
                                if transcript.transcriptType == .partial {
                                    // User is actively speaking
                                    self.userSpeaking = true
                                    self.agentSpeaking = false
                                } else if transcript.transcriptType == .final {
                                    // User finished speaking - stop immediately
                                    self.userSpeaking = false
                                    // Handle navigation from user speech
                                    if let room = self.extractRoomName(from: transcript.transcript) {
                                        print("[DEBUG] User mentioned room: \(room), navigating...")
                                        NotificationCenter.default.post(name: .navigateToRoom, object: room)
                                    }
                                }
                            } else if transcript.role == .assistant {
                                if transcript.transcriptType == .partial {
                                    // Agent is actively speaking
                                    self.agentSpeaking = true
                                    self.userSpeaking = false
                                } else if transcript.transcriptType == .final {
                                    // Agent finished speaking
                                    self.agentSpeaking = false
                                    // Handle navigation and temperature changes
                                    if let room = self.extractRoomName(from: transcript.transcript) {
                                        NotificationCenter.default.post(name: .navigateToRoom, object: room)
                                    }
                                    // Debug: Print all transcript content
                                    print("[DEBUG] Agent transcript received: '\(transcript.transcript)'")
                                    
                                    if let (room, reduction) = self.extractTempReductionAction(transcript.transcript) {
                                        print("[DEBUG] Temperature action detected: room=\(room.lowercased()), reduction=\(reduction)")
                                        print("[DEBUG] Available room view models: \(RoomView.roomViewModels.keys.sorted())")
                                        if let tempVM = RoomView.roomViewModels[room.lowercased()] {
                                            print("[DEBUG] Found view model for \(room.lowercased()), triggering animation")
                                            tempVM.animateTemperatureChange(by: reduction)
                                        } else {
                                            print("[DEBUG] No view model found for \(room.lowercased())")
                                            // Try manual trigger for debugging
                                            print("[DEBUG] Trying to manually create animation...")
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                if let kitchenVM = RoomView.roomViewModels["kitchen"] {
                                                    print("[DEBUG] Manual kitchen animation trigger")
                                                    kitchenVM.animateTemperatureChange(by: -2)
                                                }
                                            }
                                        }
                                    } else {
                                        print("[DEBUG] No temperature action detected in transcript: '\(transcript.transcript)'")
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

    /// Central event dispatcher
    private func handle(_ event: Vapi.Event) {
        switch event {
        case .callDidStart:
            print("✅ Call started")
            currentCallStart = Date()
            isCalling = true
        case .callDidEnd:
            print("🛑 Call ended")
            isCalling = false
            if let start = currentCallStart {
                let duration = Date().timeIntervalSince(start)
                let record = CallRecord(timestamp: start, duration: duration)
                callHistory.insert(record, at: 0)
                saveHistory()
                currentCallStart = nil
            }
            vapi = nil
            cancellables.removeAll()
        case let .error(err):
            print("🚨 VAPI error:", err)
        default:
            break
        }
    }

    /// Inspect the incoming payload dictionary
    private func handleMessagePayload(_ payload: [String: Any],
                                      from participant: Daily.ParticipantID)
    {
        // 1️⃣ Transcript payload?
        if let text = payload["transcript"] as? String {
            print("[Transcript from \(participant)]: \(text)")
            // e.g. append to a @Published transcript log…
            processVapiMessage(payload)
        } else if let fnCall = payload["function_call"] as? [String: Any],
                  let name   = fnCall["name"] as? String,
                  let args   = fnCall["arguments"] as? [String: Any] {
            print("[Function call] \(name)(\(args))")
            handleFunctionCall(name, args: args)
        } else {
            print("[Raw payload] from \(participant):", payload)
        }
    }

    /// Dispatch one of your own "function calls"
    private func handleFunctionCall(_ name: String, args: [String: Any]) {
        switch name {
        case "setVolume":
            if let level = args["level"] as? Int {
                print("🔊 Setting volume to \(level)")
                // your device-API.setVolume(level)
            }
        case "showImage":
            if let url = args["url"] as? String {
                print("🖼️ Show image at", url)
                // yourImageLoader.load(url)
            }
        default:
            print("❓ Unknown function:", name)
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

    func processUserSpeech(_ transcript: String) {
        print("[STT] processUserSpeech received transcript: \(transcript)")
        let lower = transcript.lowercased()
        let roomNames = [
            "kitchen", "living room", "bedroom", "garage", "laundry", "nursery",
            "outside", "backyard", "master", "entrance", "playroom", "elevator", "support", "home", "homepage"
        ]
        // Navigation trigger from STT
        if let room = roomNames.first(where: { lower.contains($0) }) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .navigateToRoom, object: room)
            }
        }
        if let room = roomNames.first(where: { lower.contains($0) && lower.contains("hot") }) {
            // Show room page and ask if should reduce
            let temp = roomTemps[room] ?? 70
            receiveAgentResponse("(Shows the \(room.capitalized) page) The \(room) temperature is currently \(temp)°F. Would you like me to reduce it?")
            awaitingTempReduction = true
            tempRoomContext = room
        } else if awaitingTempReduction && (lower.contains("yes") || lower.contains("reduce") || lower.contains("decrease")) {
            // Ask for how many degrees
            if let room = tempRoomContext {
                receiveAgentResponse("By how many degrees should I reduce the \(room) temperature?")
            } else {
                receiveAgentResponse("By how many degrees should I reduce the temperature?")
            }
            // Stay in awaitingTempReduction state
        } else if awaitingTempReduction, let number = extractNumber(from: lower), let room = tempRoomContext {
            // Reduce temp and confirm
            roomTemps[room, default: 70] -= number
            let temp = roomTemps[room] ?? 70
            receiveAgentResponse("Reduced the \(room) temperature by \(number) degrees. It is now \(temp)°F.")
            awaitingTempReduction = false
            tempRoomContext = nil
        } else if let room = roomNames.first(where: { lower.contains($0) && (lower.contains("increase") || lower.contains("raise") || lower.contains("up")) }) {
            let number = extractNumber(from: lower) ?? 2
            roomTemps[room, default: 70] += number
            let temp = roomTemps[room] ?? 70
            receiveAgentResponse("Increased the \(room) temperature by \(number) degrees. It is now \(temp)°F.")
        } else {
            receiveAgentResponse("I'm sorry, I didn't understand. Please try again.")
        }
    }

    private func extractNumber(from text: String) -> Int? {
        let pattern = "\\d+"
        if let match = text.range(of: pattern, options: .regularExpression) {
            return Int(text[match])
        }
        return nil
    }

    // MARK: - Message Processing
    private func processVapiMessage(_ payload: [String: Any]) {
        // Handle different types of messages from VAPI
        // Check for transcript messages
        if let transcript = payload["transcript"] as? [String: Any] {
            handleTranscript(transcript)
        }
        // Check for function call messages
        if let functionCall = payload["functionCall"] as? [String: Any],
           let name = functionCall["name"] as? String,
           let arguments = functionCall["arguments"] as? [String: Any] {
            handleFunctionCall(name, args: arguments)
        }
        // Check for other message types
        if let messageType = payload["type"] as? String {
            switch messageType {
            case "transcript":
                if let text = payload["text"] as? String,
                   let role = payload["role"] as? String {
                    handleTranscriptMessage(text: text, role: role)
                }
            case "function-call":
                if let functionCall = payload["functionCall"] as? [String: Any],
                   let name = functionCall["name"] as? String,
                   let arguments = functionCall["arguments"] as? [String: Any] {
                    handleFunctionCall(name, args: arguments)
                }
            case "conversation-update":
                handleConversationUpdate(payload)
            case "metadata":
                handleMetadata(payload)
            default:
                print("[VAPI] Unknown message type: \(messageType)")
            }
        }
    }

    // MARK: - Specific Message Handlers
    private func handleTranscript(_ transcript: [String: Any]) {
        guard let text = transcript["text"] as? String,
              let role = transcript["role"] as? String else { return }
        print("[VAPI] Transcript - \(role): \(text)")
        // Update UI with transcript
        DispatchQueue.main.async {
            // Update your UI here with the transcript
            // For example, add to a conversation view
        }
    }

    private func handleTranscriptMessage(text: String, role: String) {
        print("[VAPI] Transcript Message - \(role): \(text)")
        // Process transcript based on role (user, assistant, system)
        switch role {
        case "user":
            // Handle user speech
            break
        case "assistant":
            // Handle assistant response
            break
        case "system":
            // Handle system messages
            break
        default:
            break
        }
    }

    private func handleConversationUpdate(_ payload: [String: Any]) {
        // Handle conversation state updates
        print("[VAPI] Conversation update received")
    }

    private func handleMetadata(_ payload: [String: Any]) {
        // Handle metadata messages
        if let callId = payload["callId"] as? String {
            print("[VAPI] Call ID: \(callId)")
        }
    }

    private func extractRoomName(from text: String) -> String? {
        let lower = text.lowercased()
        
        // First check for formal pattern "Shows the <room> page"
        let formalPattern = #"Shows the ([a-zA-Z ]+) page"#
        if let regex = try? NSRegularExpression(pattern: formalPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let roomRange = Range(match.range(at: 1), in: text) {
            return String(text[roomRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Then check for any room names mentioned in context
        let roomNames = [
            "kitchen", "living room", "bedroom", "garage", "laundry", "nursery",
            "outside", "backyard", "master", "entrance", "playroom", "elevator", "support", "home", "homepage"
        ]
        
        // Find any room name mentioned in the text
        if let room = roomNames.first(where: { lower.contains($0) }) {
            return room
        }
        
        return nil
    }

    /// Read out the temperature value using VAPI (TTS)
    func speakTemperature(room: String, temp: Int) async {
        let message = VapiMessage(type: "transcript", role: "user", content: "The temperature in \(room) is currently \(temp) degrees Fahrenheit.")
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

    private func extractTempReductionAction(_ text: String) -> (room: String, reduction: Int)? {
        print("[DEBUG] Extracting temperature action from: '\(text)'")
        
        // Helper function to get current temperature for a room
        func getCurrentTemp(for room: String) -> Int {
            if let tempVM = RoomView.roomViewModels[room.lowercased()] {
                return tempVM.temp
            } else if let tempVM = HomeControlsView.homeTempVM, room.lowercased() == "home" {
                return tempVM.temp
            } else {
                return roomTemps[room.lowercased()] ?? 70 // fallback to stored temp or default
            }
        }
        
        // Helper function to validate and constrain temperature changes
        func validateTempChange(currentTemp: Int, change: Int, targetTemp: Int? = nil) -> Int {
            let minTemp = 45  // Minimum safe temperature 
            let maxTemp = 85  // Maximum safe temperature
            
            if let target = targetTemp {
                // When setting to specific temperature
                let clampedTarget = max(minTemp, min(maxTemp, target))
                let validChange = clampedTarget - currentTemp
                print("[DEBUG] Target temp: \(target), clamped to: \(clampedTarget), change: \(validChange)")
                return validChange
            } else {
                // When changing by amount
                let newTemp = currentTemp + change
                if newTemp < minTemp {
                    let validChange = minTemp - currentTemp
                    print("[DEBUG] Change \(change) would go below minimum. Limited to: \(validChange)")
                    return validChange
                } else if newTemp > maxTemp {
                    let validChange = maxTemp - currentTemp
                    print("[DEBUG] Change \(change) would go above maximum. Limited to: \(validChange)")
                    return validChange
                } else {
                    print("[DEBUG] Change \(change) is within safe limits")
                    return change
                }
            }
        }
        
        // 1. DECREASE BY AMOUNT patterns (user says "reduce kitchen temp by 6")
        let decreaseByPatterns = [
            #"(lower|reduce|decrease|drop|bring down|turn down).{0,20}([a-zA-Z ]+).{0,20}(temperature|temp).{0,10}(by|to)\s*(\d+)"#,
            #"(lowers|decreases|reduced|reduces|drops|brought down|turned down)\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#,
            #"reduced\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#,
            #"I've\s+(reduced|lowered|decreased)\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#
        ]
        
        for pattern in decreaseByPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                
                // Find room and amount indices dynamically
                var roomIdx = -1
                var amountIdx = -1
                
                for i in 1..<match.numberOfRanges {
                    let range = match.range(at: i)
                    if range.location != NSNotFound, let stringRange = Range(range, in: text) {
                        let captured = String(text[stringRange])
                        if captured.matches("\\d+") {
                            amountIdx = i
                        } else if !captured.matches("(lower|reduce|decrease|drop|bring|turn|lowers|decreases|reduced|reduces|drops|brought|turned|temperature|temp|by|to|the|I've)") {
                            roomIdx = i
                        }
                    }
                }
                
                if roomIdx != -1 && amountIdx != -1,
                   let roomRange = Range(match.range(at: roomIdx), in: text),
                   let amountRange = Range(match.range(at: amountIdx), in: text) {
                    let room = String(text[roomRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let amount = Int(text[amountRange]) ?? 0
                    let currentTemp = getCurrentTemp(for: room)
                    let validChange = validateTempChange(currentTemp: currentTemp, change: -amount)
                    print("[DEBUG] DECREASE BY: room=\(room), amount=\(amount), current=\(currentTemp), validChange=\(validChange)")
                    return (room, validChange)
                }
            }
        }
        
        // 2. SET TO SPECIFIC TEMPERATURE patterns
        let setToPatterns = [
            #"(set|lower|reduce|decrease|change).{0,20}([a-zA-Z ]+).{0,20}(temperature|temp).{0,10}to\s*(\d+)"#,
            #"(sets|lowers|reduces|decreases|changes)\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+to\s+(\d+)"#,
            #"set\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+to\s+(\d+)"#
        ]
        
        for pattern in setToPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                
                var roomIdx = -1
                var targetIdx = -1
                
                for i in 1..<match.numberOfRanges {
                    let range = match.range(at: i)
                    if range.location != NSNotFound, let stringRange = Range(range, in: text) {
                        let captured = String(text[stringRange])
                        if captured.matches("\\d+") {
                            targetIdx = i
                        } else if !captured.matches("(set|lower|reduce|decrease|change|sets|lowers|reduces|decreases|changes|temperature|temp|to|the)") {
                            roomIdx = i
                        }
                    }
                }
                
                if roomIdx != -1 && targetIdx != -1,
                   let roomRange = Range(match.range(at: roomIdx), in: text),
                   let targetRange = Range(match.range(at: targetIdx), in: text) {
                    let room = String(text[roomRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let target = Int(text[targetRange]) ?? 70
                    let currentTemp = getCurrentTemp(for: room)
                    let validChange = validateTempChange(currentTemp: currentTemp, change: 0, targetTemp: target)
                    print("[DEBUG] SET TO: room=\(room), target=\(target), current=\(currentTemp), validChange=\(validChange)")
                    return (room, validChange)
                }
            }
        }
        
        // 3. INCREASE BY AMOUNT patterns
        let increaseByPatterns = [
            #"(raise|increase|boost|turn up|warm up).{0,20}([a-zA-Z ]+).{0,20}(temperature|temp).{0,10}by\s*(\d+)"#,
            #"(raises|increases|increased|boosts|turned up|warmed up)\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#,
            #"increased\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#,
            #"I've\s+(increased|raised|boosted)\s+the\s+([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#
        ]
        
        for pattern in increaseByPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                
                var roomIdx = -1
                var amountIdx = -1
                
                for i in 1..<match.numberOfRanges {
                    let range = match.range(at: i)
                    if range.location != NSNotFound, let stringRange = Range(range, in: text) {
                        let captured = String(text[stringRange])
                        if captured.matches("\\d+") {
                            amountIdx = i
                        } else if !captured.matches("(raise|increase|boost|turn|warm|raises|increases|increased|boosts|turned|warmed|temperature|temp|by|up|the|I've)") {
                            roomIdx = i
                        }
                    }
                }
                
                if roomIdx != -1 && amountIdx != -1,
                   let roomRange = Range(match.range(at: roomIdx), in: text),
                   let amountRange = Range(match.range(at: amountIdx), in: text) {
                    let room = String(text[roomRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let amount = Int(text[amountRange]) ?? 0
                    let currentTemp = getCurrentTemp(for: room)
                    let validChange = validateTempChange(currentTemp: currentTemp, change: amount)
                    print("[DEBUG] INCREASE BY: room=\(room), amount=\(amount), current=\(currentTemp), validChange=\(validChange)")
                    return (room, validChange)
                }
            }
        }
        
        print("[DEBUG] No temperature action pattern matched")
        return nil
    }
}

extension Notification.Name {
    static let navigateToRoom = Notification.Name("navigateToRoom")
}

extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

