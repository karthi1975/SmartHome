////
////  ContentView.swift
////  SmartHomeController
////
////  Created by karthikeyan jeyabalan on 2/13/25.
////

import SwiftUI
import Vapi
import AVKit

enum MainPage: String, CaseIterable, Identifiable {
    case home = "Home"
    case kitchen = "Kitchen"
    case master = "Master"
    case bedroom = "Bedroom"
    case livingRm = "Living Rm"
    case laundry = "Laundry"
    case outside = "Outside"
    case entrance = "Entrance"
    case backyard = "Backyard"
    case nursery = "Nursery"
    case playroom = "Playroom"
    case garage = "Garage"
    case elevator = "Elevator"
    case support = "Support"

    var id: String { self.rawValue }
}

struct ContentView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var callManager: CallManager
    @EnvironmentObject var appState: AppState

    @State private var selectedPage: MainPage = .home
    
    @State private var selectedRoom = Room(
        name: "Favorites",
        iconName: "Home_Smarthome",
        selectedIconName: "Home_Red_Smarthome"
    )
    
    // Rooms
    private let leftColumnRooms: [Room] = [
        Room(name: "Favorites", iconName: "Home_Smarthome", selectedIconName: "Home_Red_Smarthome"),
        Room(name: "Master", iconName: "MasterBedrm_Smarthome", selectedIconName: "MasterBedrm_Red_Smarthome"),
        Room(name: "Bedroom", iconName: "Bedroom_Smarthome", selectedIconName: "Bedroom_Red_Smarthome"),
        Room(name: "Living Rm", iconName: "LivingRm_Smarthome", selectedIconName: "LivingRm_Red_Smarthome"),
        Room(name: "Kitchen", iconName: "Kitchen_Smarthome", selectedIconName: "Kitchen_Red_Smarthome"),
        Room(name: "Laundry", iconName: "Laundry_Smarthome", selectedIconName: "Laundry_Red_Smarthome"),
        Room(name: "Outside", iconName: "Outside_Smarthome", selectedIconName: "Outside_Red_Smarthome"),
        Room(name: "Entrance", iconName: "Entrance_Smarthome", selectedIconName: "Entrance_Red_Smarthome"),
        Room(name: "Backyard", iconName: "Backyard_Smarthome", selectedIconName: "Backyard_Red_Smarthome"),
    ]
    
    private let rightColumnRooms: [Room] = [
        Room(name: "Nursery", iconName: "Nursery_Smarthome", selectedIconName: "Nursery_Red_Smarthome"),
        Room(name: "Playroom", iconName: "Playroom_Smarthome", selectedIconName: "Playroom_Red_Smarthome"),
        Room(name: "Garage", iconName: "Garage_Smarthome", selectedIconName: "Garage_Red_Smarthome"),
        Room(name: "Elevator", iconName: "Elevator_Smarthome", selectedIconName: "Elevator_Red_Smarthome"),
        Room(name: "Support", iconName: "Support_Smarthome", selectedIconName: "Support_Red_Smarthome"),
    ]
    
    // Scenes (adjust if needed)
    private let scenes: [HomeScene] = [
        HomeScene(name: "Soft", iconName: "Scene_Soft"),
        HomeScene(name: "Reading", iconName: "Scene_Reading"),
        HomeScene(name: "Morning", iconName: "Scene_Morning"),
        HomeScene(name: "TV", iconName: "Scene_TV")
    ]
    
    @State private var showSidebarOverlay = false
    @State private var showSettings = false
    
    @State private var lastHandledAgentResponse: String? = nil
    @State private var dynamicRooms: [Room] = []

    @State private var isSpeaking = false
    @State private var isAgentResponding = false
    @State private var speakingTimer: Timer? = nil
    @State private var isVADActive = false

    var allLeftRooms: [Room] { leftColumnRooms + dynamicRooms.filter { $0.name != "Support" } }
    var allRightRooms: [Room] { rightColumnRooms + dynamicRooms.filter { $0.name == "Support" } }

    private var shouldShowVoiceAnimation: Bool {
        isSpeaking || isAgentResponding
    }

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color(red: 172/255, green: 32/255, blue: 41/255)
                    HStack {
                        Button(action: {
                            showSidebarOverlay = true
                        }) {
                            Image("SidebarIcon_Smarthome")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding(.leading, 8)
                        }
                        Spacer()
                        // Centered logo
                        Image("tetradapt-main-logo-transparent")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 28)
                        Spacer()
                        // Settings gear button
                        Button(action: { showSettings = true }) {
                            if let _ = UIImage(named: "Settings_Smarthome") {
                                Image("Settings_Smarthome")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "gearshape")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }
                .frame(height: 88)
                // Main content switch based on selectedRoom
                switch selectedRoom.name {
                case "Favorites":
                    HomeControlsView(showSidebarOverlay: $showSidebarOverlay)
                        .environmentObject(deviceStore)
                        .environmentObject(callManager)
                case "Support":
                    CreateTicketView()
                default:
                    RoomView(roomName: selectedRoom.name)
                        .environmentObject(deviceStore)
                        .environmentObject(callManager)
                }
            }
            .disabled(showSidebarOverlay)
            // Sidebar overlay
            if showSidebarOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showSidebarOverlay = false }
                    .zIndex(1)
                SidebarView(
                    selectedRoom: $selectedRoom,
                    leftColumnRooms: allLeftRooms,
                    rightColumnRooms: allRightRooms,
                    showSidebarOverlay: $showSidebarOverlay,
                    onAddRoom: { newRoom in
                        dynamicRooms.append(newRoom)
                        selectedRoom = newRoom
                        showSidebarOverlay = false
                    }
                )
                .frame(width: 220)
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
            if let msg = appState.agentMessage {
                AgentPromptView(message: msg) {
                    appState.agentMessage = nil
                }
                .transition(.move(edge: .top))
                .zIndex(3)
            }
            GlobalMicrophoneOverlay()
        }
        .onChange(of: callManager.isCalling) { newValue in
            isSpeaking = newValue
        }
        .onChange(of: callManager.latestAgentResponse) { newValue in
            if let response = newValue, !response.isEmpty {
                print("[DEBUG] Setting isAgentResponding = true (agent response received)")
                isAgentResponding = true
                // Simulate agent response duration (e.g., 4.0 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    print("[DEBUG] Setting isAgentResponding = false (timeout elapsed)")
                    isAgentResponding = false
                }
            }
        }
        .onChange(of: appState.currentPage) { newPage in
            print("appState.currentPage changed to: \(newPage.rawValue)")
            let allRooms = leftColumnRooms + rightColumnRooms + dynamicRooms
            if let match = allRooms.first(where: { $0.name.caseInsensitiveCompare(newPage.rawValue) == .orderedSame }) {
                print("Setting selectedRoom to: \(match.name)")
                selectedRoom = match
            } else {
                print("No matching room found for page: \(newPage.rawValue)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToRoom)) { notif in
            if let room = notif.object as? String {
                let normalizedRoom = normalizeRoomName(room)
                print("STT navigation: Setting appState.currentPage to: \(normalizedRoom)")
                appState.currentPage = AppState.AppPage(rawValue: normalizedRoom) ?? appState.currentPage
            }
        }
        .onChange(of: isSpeaking) { newValue in
            if newValue {
                speakingTimer?.invalidate()
                speakingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    isSpeaking = false
                }
            } else {
                speakingTimer?.invalidate()
            }
        }
        .onChange(of: callManager.userSpeaking) { newValue in
            isVADActive = newValue
        }
        .onAppear {
            // Start the agent/call automatically on app launch
            let vapiConfig = VAPIConfig.load()
            callManager.startCall(
                publicKey: vapiConfig.publicKey,
                assistantId: vapiConfig.assistantId
            )
            // VAD is now wired to VAPI events
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // Placeholder: Simulate VAD event for demo
    func simulateVADEvent() {
        isVADActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isVADActive = false
        }
    }

    // Call this when you get a VAPI agent response
    func handleAgentResponse(_ response: String) {
        print("\n====================\n[DEBUG] handleAgentResponse called with: \(response)")
        let (action, message) = parseAgentResponse(response)
        print("[DEBUG] parseAgentResponse returned action: \(String(describing: action)), message: \(message)")
        if let action = action {
            print("[DEBUG] Entered action handling block with action: \(action)")
            if let (room, reduction) = extractTempReductionAction(action) {
                print("[DEBUG] Matched extractTempReductionAction: room=\(room), reduction=\(reduction)")
                if room.lowercased() == "home" || room.lowercased() == "favorites" {
                    print("[DEBUG] Reducing Home temp by \(reduction)")
                    HomeControlsView.homeTempVM?.animateTemperatureChange(by: reduction)
                } else if let roomViewModel = RoomView.roomViewModels[room.lowercased()] {
                    print("[DEBUG] Reducing temp for roomViewModel[\(room.lowercased())] by \(reduction)")
                    roomViewModel.animateTemperatureChange(by: reduction)
                }
                let normalizedRoom = normalizeRoomName(room)
                print("[DEBUG] Setting appState.currentPage to: \(normalizedRoom)")
                appState.currentPage = AppState.AppPage(rawValue: normalizedRoom) ?? appState.currentPage
            } else if let showPageRoom = extractShowPageAction(action) {
                print("[DEBUG] Matched extractShowPageAction: showPageRoom=\(showPageRoom)")
                let normalizedRoom = normalizeRoomName(showPageRoom)
                print("[DEBUG] Setting appState.currentPage to: \(normalizedRoom)")
                appState.currentPage = AppState.AppPage(rawValue: normalizedRoom) ?? appState.currentPage
            } else if action.localizedCaseInsensitiveContains("kitchen") {
                print("[DEBUG] Fallback: Navigating to kitchen page")
                appState.currentPage = AppState.AppPage.kitchen
            } else if action.localizedCaseInsensitiveContains("living room") {
                print("[DEBUG] Fallback: Navigating to living room page")
                appState.currentPage = AppState.AppPage.livingRoom
            } else if action.localizedCaseInsensitiveContains("bedroom") {
                print("[DEBUG] Fallback: Navigating to bedroom page")
                appState.currentPage = AppState.AppPage.bedroom
            } else if action.localizedCaseInsensitiveContains("garage") {
                print("[DEBUG] Fallback: Navigating to garage page")
                appState.currentPage = AppState.AppPage.garage
            } else if action.localizedCaseInsensitiveContains("laundry") {
                print("[DEBUG] Fallback: Navigating to laundry page")
                appState.currentPage = AppState.AppPage.laundry
            } else if action.localizedCaseInsensitiveContains("nursery") {
                print("[DEBUG] Fallback: Navigating to nursery page")
                appState.currentPage = AppState.AppPage.nursery
            } else if action.localizedCaseInsensitiveContains("outside") {
                print("[DEBUG] Fallback: Navigating to outside page")
                appState.currentPage = AppState.AppPage.outside
            } else if action.localizedCaseInsensitiveContains("backyard") {
                print("[DEBUG] Fallback: Navigating to backyard page")
                appState.currentPage = AppState.AppPage.backyard
            } else if action.localizedCaseInsensitiveContains("master") {
                print("[DEBUG] Fallback: Navigating to master page")
                appState.currentPage = AppState.AppPage.master
            } else if action.localizedCaseInsensitiveContains("home") {
                print("[DEBUG] Fallback: Navigating to home page")
                appState.currentPage = AppState.AppPage.home
            } else {
                print("[DEBUG] No navigation match for action: \(action)")
            }
        } else {
            print("[DEBUG] No action parsed from agent response.")
        }
        appState.agentMessage = message
        print("[DEBUG] handleAgentResponse finished.\n====================\n")
    }

    /// Helper to extract (room, reduction) from agent action string like '(Lowers the kitchen temperature by 4 degrees)'
    func extractTempReductionAction(_ action: String) -> (room: String, reduction: Int)? {
        let pattern = #"Lowers the ([a-zA-Z ]+) temperature by (\\d+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: action, options: [], range: NSRange(location: 0, length: action.utf16.count)),
           let roomRange = Range(match.range(at: 1), in: action),
           let reductionRange = Range(match.range(at: 2), in: action) {
            let room = String(action[roomRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let reduction = Int(action[reductionRange]) ?? 0
            return (room, reduction)
        }
        return nil
    }

    /// Extracts the room name from (Shows the <Room> page)
    func extractShowPageAction(_ action: String) -> String? {
        let pattern = #"Shows the ([a-zA-Z ]+) page"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: action, options: [], range: NSRange(location: 0, length: action.utf16.count)),
           let roomRange = Range(match.range(at: 1), in: action) {
            return String(action[roomRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    /// Normalize agent room name to match AppPage raw values
    func normalizeRoomName(_ room: String) -> String {
        let mapping: [String: String] = [
            "kitchen": "Kitchen",
            "living room": "Living Room", 
            "living": "Living Room",  // Handle just "living" 
            "bedroom": "Bedroom",
            "garage": "Garage",
            "laundry": "Laundry",
            "nursery": "Nursery",
            "outside": "Outside",
            "backyard": "Backyard",
            "master": "Master",
            "master bedroom": "Master",  // Handle variations
            "entrance": "Entrance",
            "playroom": "Playroom",
            "elevator": "Elevator",
            "support": "Support",
            "home": "Home",
            "homepage": "Home",  // Handle "homepage" variation
            "favorites": "Home"  // Map "favorites" to "Home" since that's the Favorites page
        ]
        let key = room.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return mapping[key] ?? (room.prefix(1).capitalized + room.dropFirst().lowercased())
    }
}

func parseAgentResponse(_ response: String) -> (action: String?, message: String) {
    print("[DEBUG] parseAgentResponse called with: \(response)")
    let pattern = "^\\((.*?)\\)\\s*(.*)"
    if let regex = try? NSRegularExpression(pattern: pattern, options: []),
       let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.utf16.count)),
       let actionRange = Range(match.range(at: 1), in: response),
       let messageRange = Range(match.range(at: 2), in: response) {
        let action = String(response[actionRange])
        let message = String(response[messageRange])
        print("[DEBUG] parseAgentResponse: action=\(action), message=\(message)")
        return (action, message)
    }
    print("[DEBUG] parseAgentResponse: no action, message=\(response)")
    return (nil, response)
}

struct AgentPromptView: View {
    let message: String
    let onDismiss: () -> Void
    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
        .background(Color.blue.opacity(0.95))
        .cornerRadius(12)
        .padding(.top, 40)
        .padding(.horizontal, 16)
        .shadow(radius: 8)
    }
}

struct FloatingMicButtonWithVAD: View {
    var isVADActive: Bool
    var isAgentResponding: Bool
    @State private var player: AVPlayer? = nil

    private var shouldShowAnimation: Bool { isVADActive || isAgentResponding }

    var body: some View {
        ZStack {
            if shouldShowAnimation {
                // White background mask (slightly larger)
                Circle()
                    .fill(Color.white)
                    .frame(width: 88, height: 88)
                // Video animation
                VideoPlayer(player: player)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(radius: 8)
                    .onAppear {
                        if player == nil, let url = Bundle.main.url(forResource: "voice_animation_MP4_WhiteVersion", withExtension: "mp4") {
                            player = AVPlayer(url: url)
                        }
                        player?.seek(to: .zero)
                        player?.play()
                        player?.actionAtItemEnd = .none
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player?.currentItem, queue: .main
                        ) { _ in
                            player?.seek(to: .zero)
                            player?.play()
                        }
                    }
                    .onDisappear {
                        player?.pause()
                    }
                // Wider inner white circle with thicker border to mask black corners
                Circle()
                    .stroke(Color.white, lineWidth: 12)
                    .background(Circle().fill(Color.clear))
                    .frame(width: 78, height: 78)
                    .allowsHitTesting(false)
            } else {
                Image(systemName: "mic.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.red)
            }
        }
        .padding(.bottom, 32)
        .padding(.trailing, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DeviceStore())
            .environmentObject(CallManager())
            .environmentObject(AppState())
    }
}
