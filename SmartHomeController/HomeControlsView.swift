//
//  HomeControlsView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 6/2/25.
//
//
//  HomeControlsView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 6/2/25.
//

import SwiftUI
//import LiveKit
// import Speech // REMOVE
import AVFoundation

enum HomeCardType: Identifiable, Equatable, CaseIterable, RawRepresentable {
    case blinds, oven, temp, dishwasher, fridge
    var id: String {
        switch self {
        case .blinds: return "blinds"
        case .oven: return "oven"
        case .temp: return "temp"
        case .dishwasher: return "dishwasher"
        case .fridge: return "fridge"
        }
    }
    init?(rawValue: String) {
        switch rawValue {
        case "blinds": self = .blinds
        case "oven": self = .oven
        case "temp": self = .temp
        case "dishwasher": self = .dishwasher
        case "fridge": self = .fridge
        default: return nil
        }
    }
    var rawValue: String { id }
    static var defaultSet: [HomeCardType] { [.blinds, .oven, .temp, .dishwasher, .fridge] }
}

class VoiceAgent: ObservableObject {
    @Published var agentResponse: String = ""
    var speakCallback: ((String) -> Void)?
    
    func handle(transcript: String, currentTemp: inout Int) {
        if transcript.lowercased().contains("hot") {
            respond("Can I reduce the temp?")
        } else if transcript.lowercased().contains("reduce") {
            let number = extractNumber(from: transcript) ?? 5
            currentTemp -= number
            respond("Reduced the temperature by \(number) degrees. New temperature is \(currentTemp) degrees Fahrenheit.")
        }
    }

    private func respond(_ text: String) {
        agentResponse = text
        speakCallback?(text)
    }

    private func extractNumber(from text: String) -> Int? {
        let pattern = "\\d+"
        if let match = text.range(of: pattern, options: .regularExpression) {
            return Int(text[match])
        }
        return nil
    }
}

struct HomeControlsView: View {
    @Binding var showSidebarOverlay: Bool
    @EnvironmentObject var callManager: CallManager
    @State private var showingAddDevice = false
    @State private var isEditing: Bool = false
    @State private var cards: [HomeCardType] = HomeCardType.defaultSet
    @State private var editingCard: HomeCardType? = nil
    @State private var navigationSelection: HomeCardType? = nil
    @State private var currentTempF: Int = 70
    // Voice/LiveKit integration
    @StateObject var agent = VoiceAgent()
    @StateObject private var tempVM = AnimatedTempCardViewModel(initialTemp: 70, updateTemp: { _ in })
    static var homeTempVM: AnimatedTempCardViewModel?

    var body: some View {
        ZStack {
            VStack {
                if !agent.agentResponse.isEmpty {
                    Text("Agent: \(agent.agentResponse)")
                        .foregroundColor(.blue)
                }
                NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with Edit/Done button and Add Device button
                        HStack {
                            Button(action: {
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "Done" : "Edit")
                                    .foregroundColor(.blue)
                                    .font(.body)
                                    .padding(.leading)
                            }
                            Spacer()
                            Text("Favorites")
                                .font(.title)
                                .bold()
                                .padding(.top, 8)
                            Spacer()
                            Button(action: { showingAddDevice = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                            .padding(.trailing)
                        }
                        .padding(.horizontal)

                        // Device Cards
                        VStack(spacing: 16) {
                            ForEach(cards) { card in
                                ZStack(alignment: .topTrailing) {
                                    NavigationLink(
                                        destination: EditDeviceView(card: card, onSave: { updatedCard in
                                            navigationSelection = nil
                                        }),
                                        tag: card,
                                        selection: $navigationSelection
                                    ) {
                                        EmptyView()
                                    }.frame(width: 0, height: 0).hidden()
                                    VStack(spacing: 4) {
                                        cardView(for: card)
                                        Text(label(for: card))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                    if isEditing {
                                        HStack(spacing: 0) {
                                            Button(action: {
                                                navigationSelection = card
                                            }) {
                                                Image(systemName: "pencil.circle.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.blue)
                                                    .padding(8)
                                            }
                                            Button(action: {
                                                removeCard(card)
                                            }) {
                                                Image(systemName: "trash.circle.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.red)
                                                    .padding(8)
                                            }
                                        }
                                    }
                                }
                            }
                            // Add Device Card - Always at the bottom
                            Button(action: { showingAddDevice = true }) {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.red)
                                    Text("Add Device")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .sheet(isPresented: $showingAddDevice) {
                    AddHomeDeviceView(
                        availableTypes: HomeCardType.allCases.filter { !cards.contains($0) },
                        onAdd: { type in
                            cards.append(type)
                            saveCards()
                            showingAddDevice = false
                        },
                        onCancel: { showingAddDevice = false }
                    )
                }
                .onAppear {
                    loadCards()
                    // Set the update closure for home temperature
                    let updateClosure: (Int) -> Void = { newTemp in
                        callManager.roomTemps["home"] = newTemp
                    }
                    tempVM.setUpdateTempClosure(updateClosure)
                    HomeControlsView.homeTempVM = tempVM
                }
                .onDisappear {
                    HomeControlsView.homeTempVM = nil
                }
                }
            }
            GlobalMicrophoneOverlay()
        }
    }

    func cardView(for card: HomeCardType) -> some View {
        switch card {
        case .blinds:
            return AnyView(BlindsCard())
        case .oven:
            return AnyView(OvenCard(status: "On", temperature: "375 °F", isOn: true, onPowerToggle: nil))
        case .temp:
            return AnyView(TempCard(viewModel: tempVM, roomName: "Home")
                .environmentObject(callManager))
        case .dishwasher:
            return AnyView(DishwasherCard(status: "Idle"))
        case .fridge:
            return AnyView(FridgeCard(temperature: "40 °F"))
        }
    }

    func label(for card: HomeCardType) -> String {
        switch card {
        case .blinds: return "Blinds"
        case .oven: return "Oven"
        case .temp: return "Temp"
        case .dishwasher: return "Dishwasher"
        case .fridge: return "Fridge"
        }
    }

    func removeCard(_ card: HomeCardType) {
        if let idx = cards.firstIndex(of: card) {
            cards.remove(at: idx)
            saveCards()
        }
    }

    private func saveCards() {
        let rawValues = cards.map { $0.id }
        UserDefaults.standard.set(rawValues, forKey: "homeCards")
    }

    private func loadCards() {
        if let saved = UserDefaults.standard.array(forKey: "homeCards") as? [String] {
            let loaded = saved.compactMap { HomeCardType(rawValue: $0) }
            if !loaded.isEmpty {
                cards = loaded
            }
        }
    }
}

struct AddHomeDeviceView: View {
    let availableTypes: [HomeCardType]
    let onAdd: (HomeCardType) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            List(availableTypes, id: \ .id) { type in
                Button(action: { onAdd(type) }) {
                    Text(label(for: type))
                }
            }
            .navigationTitle("Add Device")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    func label(for type: HomeCardType) -> String {
        switch type {
        case .blinds: return "Blinds"
        case .oven: return "Oven"
        case .temp: return "Temp"
        case .dishwasher: return "Dishwasher"
        case .fridge: return "Fridge"
        }
    }
}

struct EditDeviceView: View {
    var card: HomeCardType
    var onSave: (HomeCardType) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var deviceName: String = ""
    // Blinds
    @State private var defaultPosition: String = "Open"
    let positions = ["Open", "Closed", "Custom"]
    // Oven
    @State private var ovenTemp: Int = 350
    // Temp
    @State private var minTemp: Int = 65
    @State private var maxTemp: Int = 75
    // Dishwasher
    @State private var dishwasherStatus: String = "Idle"
    let dishwasherStatuses = ["Idle", "Running", "Done"]
    // Fridge
    @State private var fridgeTemp: Int = 40

    var body: some View {
        Form {
            Section(header: Text("Device Info")) {
                TextField("Device Name", text: $deviceName)
                HStack {
                    Text("Icon Preview:")
                    Spacer()
                    iconPreview
                }
            }
            dynamicFields
            Section {
                Button("Save") {
                    onSave(card)
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("Edit " + label(for: card))
    }

    @ViewBuilder
    var dynamicFields: some View {
        switch card {
        case .blinds:
            Section(header: Text("Default Position")) {
                Picker("Default Position", selection: $defaultPosition) {
                    ForEach(positions, id: \.self) { pos in
                        Text(pos)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        case .oven:
            Section(header: Text("Default Temperature")) {
                Stepper(value: $ovenTemp, in: 150...500, step: 5) {
                    Text("Default Temp: \(ovenTemp) °F")
                }
            }
        case .temp:
            Section(header: Text("Temperature Range")) {
                Stepper(value: $minTemp, in: 40...maxTemp, step: 1) {
                    Text("Min Temp: \(minTemp) °F")
                }
                Stepper(value: $maxTemp, in: minTemp...100, step: 1) {
                    Text("Max Temp: \(maxTemp) °F")
                }
            }
        case .dishwasher:
            Section(header: Text("Default Status")) {
                Picker("Default Status", selection: $dishwasherStatus) {
                    ForEach(dishwasherStatuses, id: \.self) { status in
                        Text(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        case .fridge:
            Section(header: Text("Default Temperature")) {
                Stepper(value: $fridgeTemp, in: 32...50, step: 1) {
                    Text("Default Temp: \(fridgeTemp) °F")
                }
            }
        }
    }

    @ViewBuilder
    var iconPreview: some View {
        switch card {
        case .blinds:
            Image("BlindsIcon_Smarthome").resizable().frame(width: 40, height: 40)
        case .oven:
            Image("Oven_Smarthome").resizable().frame(width: 40, height: 40)
        case .temp:
            Image("Temp__Smarthome").resizable().frame(width: 40, height: 40)
        case .dishwasher:
            Image("Dishwasher_Smarthome").resizable().frame(width: 40, height: 40)
        case .fridge:
            Image("Fridge_Smarthome").resizable().frame(width: 40, height: 40)
        }
    }

    func label(for card: HomeCardType) -> String {
        switch card {
        case .blinds: return "Blinds"
        case .oven: return "Oven"
        case .temp: return "Temp"
        case .dishwasher: return "Dishwasher"
        case .fridge: return "Fridge"
        }
    }
}

#Preview {
    HomeControlsView(showSidebarOverlay: .constant(false))
}

// --- CardSegment Helper
struct CardSegment<Content: View>: View {
    let width: CGFloat?
    let content: Content
    init(width: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }
    var body: some View {
        VStack {
            content
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: width ?? .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal, 8) // Padding between CardSegments
    }
}

// --- ControlTile Helper
struct ControlTile: View {
    var icon: String
    var label: String
    @State private var isPressed = false
    
    // Helper to determine if this is an arrow or toggle button (including Max variants and Power/Mute)
    private var isArrowOrToggle: Bool {
        icon == "Down_Smarthome" || icon == "Up_Smarthome" || icon == "DownMax_Smarthome" || icon == "UpMax_Smarthome" || icon == "Mute_Smarthome" || icon == "Power_Smarthome"
    }
    // Helper to get the pressed icon for arrows and toggles
    private var pressedIcon: String {
        if icon == "Down_Smarthome" { return "DownArrow_Smarthome" }
        if icon == "Up_Smarthome" { return "UpArrow_Smarthome" }
        if icon == "DownMax_Smarthome" { return "DownMaxArrow_Smarthome" }
        if icon == "UpMax_Smarthome" { return "UpMaxArrow_Smarthome" }
        if icon == "Mute_Smarthome" { return "Mute_Red_Smarthome" }
        if icon == "Power_Smarthome" { return "Power_Red_Smarthome" }
        return icon
    }
    // Helper to determine if background should be shown (Mute/Power only)
    private var showSelectionBackground: Bool {
        (icon == "Mute_Smarthome" || icon == "Power_Smarthome") && isPressed
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if showSelectionBackground {
                    Image("DeviceSelection_Base_Smarthome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                }
                Image(isArrowOrToggle && isPressed ? pressedIcon : icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
            }
            .background(
                // Only show background for non-arrow/toggle buttons (legacy)
                isArrowOrToggle ? nil : (
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isPressed ? Color(.systemGray4) : Color.clear)
                        .frame(width: 40, height: 40)
                )
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.black)
            }
        }
        .frame(width: 48)
    }
}

// --- Custom Toggle Helper
struct CustomOnOffToggle: View {
    @State private var isOn = false
    var body: some View {
        VStack(spacing: 2) {
            Toggle(isOn: $isOn) { EmptyView() }
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 172/255, green: 32/255, blue: 41/255)))
                .labelsHidden()
                .frame(width: 52)
            Text("On/Off")
                .font(.caption2)
                .foregroundColor(.black)
        }
        .frame(width: 52)
    }
}

// --- SceneIconTile Helper
struct SceneIconTile: View {
    let normalIcon: String
    let pressedIcon: String
    let label: String
    @State private var isPressed = false
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                if isPressed {
                    Image("DeviceSelection_Base_Smarthome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                }
                Image(isPressed ? pressedIcon : normalIcon)
                    .resizable()
                    .frame(width: 34, height: 34)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            Text(label)
                .font(.caption2)
                .foregroundColor(isPressed ? Color(red: 172/255, green: 32/255, blue: 41/255) : .black)
        }
    }
}

