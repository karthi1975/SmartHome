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
                                    
                                    // Debug: Print user transcript content
                                    print("[DEBUG] User transcript received: '\(transcript.transcript)'")
                                    
                                    // Handle navigation from user speech
                                    if let room = self.extractRoomName(from: transcript.transcript) {
                                        print("[DEBUG] User mentioned room: \(room), navigating...")
                                        NotificationCenter.default.post(name: .navigateToRoom, object: room)
                                    }
                                    
                                    // Only process temperature changes from USER commands
                                    if let (room, reduction) = self.extractTempReductionAction(transcript.transcript) {
                                        print("[DEBUG] USER temperature command detected: room=\(room.lowercased()), reduction=\(reduction)")
                                        print("[DEBUG] Available room view models: \(RoomView.roomViewModels.keys.sorted())")
                                        if let tempVM = RoomView.roomViewModels[room.lowercased()] {
                                            print("[DEBUG] Found view model for \(room.lowercased()), triggering animation")
                                            tempVM.animateTemperatureChange(by: reduction)
                                        } else {
                                            print("[DEBUG] No view model found for \(room.lowercased())")
                                        }
                                    } else {
                                        print("[DEBUG] No temperature command detected in user transcript: '\(transcript.transcript)'")
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
                                    // Handle navigation ONLY for agent responses, not temperature changes
                                    if let room = self.extractRoomName(from: transcript.transcript) {
                                        print("[DEBUG] Agent mentioned room: \(room), navigating...")
                                        NotificationCenter.default.post(name: .navigateToRoom, object: room)
                                    }
                                    // Debug: Print all transcript content
                                    print("[DEBUG] Agent transcript received: '\(transcript.transcript)'")
                                    print("[DEBUG] Ignoring agent transcript for temperature changes - only user commands allowed")
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
        
        // 1. DECREASE BY AMOUNT patterns - STRICT: only explicit user commands
        let decreaseByPatterns = [
            #"(lower|reduce|decrease|drop|turn down)\s+(the\s+)?([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#,
            #"(lower|reduce|decrease|drop|turn down)\s+([a-zA-Z ]+)\s+by\s+(\d+)"#
        ]
        
        // 2. INCREASE BY AMOUNT patterns - STRICT: only explicit user commands  
        let increaseByPatterns = [
            #"(raise|increase|boost|turn up|warm up)\s+(the\s+)?([a-zA-Z ]+)\s+(temperature|temp)\s+by\s+(\d+)"#,
            #"(raise|increase|boost|turn up|warm up)\s+([a-zA-Z ]+)\s+by\s+(\d+)"#
        ]
        
        // Process DECREASE patterns
        for pattern in decreaseByPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                
                // Extract room and amount from the specific pattern groups
                let room = extractRoomFromMatch(match, text: text)
                let amount = extractAmountFromMatch(match, text: text)
                
                if let room = room, let amount = amount {
                    let currentTemp = getCurrentTemp(for: room)
                    let validChange = validateTempChange(currentTemp: currentTemp, change: -amount)
                    print("[DEBUG] DECREASE BY: room=\(room), amount=\(amount), current=\(currentTemp), validChange=\(validChange)")
                    return (room, validChange)
                }
            }
        }
        
        // Process INCREASE patterns
        for pattern in increaseByPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                
                // Extract room and amount from the specific pattern groups
                let room = extractRoomFromMatch(match, text: text)
                let amount = extractAmountFromMatch(match, text: text)
                
                if let room = room, let amount = amount {
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
    
    // Helper function to extract room name from regex match
    private func extractRoomFromMatch(_ match: NSTextCheckingResult, text: String) -> String? {
        // Try to find the room name in the captured groups
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if range.location != NSNotFound, let stringRange = Range(range, in: text) {
                let captured = String(text[stringRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                // Skip if it's a command word or "the" or number
                if !captured.range(of: "(lower|reduce|decrease|drop|turn|raise|increase|boost|warm|temperature|temp|by|the)", options: .regularExpression, range: nil, locale: nil) != nil &&
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
}

extension Notification.Name {
    static let navigateToRoom = Notification.Name("navigateToRoom")
}

extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}