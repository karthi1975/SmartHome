import SwiftUI

enum BlindsVoiceAction {
    case open
    case close
    case adjusting
}

class AnimatedBlindsViewModel: ObservableObject {
    @Published var position: Int = 50
    @Published var isAnimating: Bool = false
    @Published var lastCommand: String = ""
    @Published var voiceAction: BlindsVoiceAction? = nil
    @Published var isVoiceActive: Bool = false
    @Published var voiceIndicatorOpacity: Double = 0.0
    @Published var pulseAnimation: Bool = false
    
    private var voiceActionTimer: Timer?
    
    func setPosition(_ newPosition: Int, animated: Bool = true) {
        if animated {
            self.position = newPosition
            self.isAnimating = true
            
            // Reset animation state after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isAnimating = false
            }
        } else {
            self.position = newPosition
        }
    }
    
    func handleVoiceCommand(_ command: String) {
        lastCommand = command
        
        if command.lowercased().contains("open") {
            setPosition(100)
            setVoiceAction(.open, duration: 2.0)
        } else if command.lowercased().contains("close") {
            setPosition(0)
            setVoiceAction(.close, duration: 2.0)
        } else if command.lowercased().contains("half") || command.lowercased().contains("50") {
            setPosition(50)
            setVoiceAction(.adjusting, duration: 2.0)
        } else if let percentage = extractPercentage(from: command) {
            setPosition(percentage)
            setVoiceAction(.adjusting, duration: 2.0)
        }
    }
    
    func setVoiceAction(_ action: BlindsVoiceAction, duration: TimeInterval = 2.0) {
        voiceActionTimer?.invalidate()
        
        self.voiceAction = action
        self.isVoiceActive = true
        
        withAnimation(.easeIn(duration: 0.3)) {
            self.voiceIndicatorOpacity = 1.0
            self.pulseAnimation = true
        }
        
        voiceActionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                self.voiceIndicatorOpacity = 0.0
                self.pulseAnimation = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isVoiceActive = false
                self.voiceAction = nil
            }
        }
    }
    
    func animatePositionChange(by delta: Int) {
        let newPosition = min(max(position + delta, 0), 100)
        setPosition(newPosition)
        
        if delta > 0 {
            setVoiceAction(.open, duration: 1.5)
        } else if delta < 0 {
            setVoiceAction(.close, duration: 1.5)
        }
    }
    
    private func extractPercentage(from text: String) -> Int? {
        let pattern = "\\d+"
        if let match = text.range(of: pattern, options: .regularExpression) {
            if let number = Int(text[match]) {
                return min(max(number, 0), 100)
            }
        }
        return nil
    }
}

struct AnimatedBlindsCard: View {
    @StateObject var viewModel: AnimatedBlindsViewModel
    var onClose: (() -> Void)?
    var onDown: (() -> Void)?
    var onUp: (() -> Void)?
    var onOpen: (() -> Void)?
    
    @State private var pressedButton: String? = nil
    
    private var voiceActionText: String {
        switch viewModel.voiceAction {
        case .open: return "Opening"
        case .close: return "Closing"
        case .adjusting: return "Adjusting"
        case .none: return ""
        }
    }
    
    private var voiceActionIcon: String {
        switch viewModel.voiceAction {
        case .open: return "arrow.up.circle.fill"
        case .close: return "arrow.down.circle.fill"
        case .adjusting: return "slider.horizontal.3"
        case .none: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Position indicator with voice feedback
            HStack {
                Text("Position: \(viewModel.position)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                
                // Voice indicator
                if viewModel.isVoiceActive {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .scaleEffect(viewModel.pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.pulseAnimation)
                        
                        Text(voiceActionText)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .opacity(viewModel.voiceIndicatorOpacity)
                    .transition(.opacity)
                }
                
                if viewModel.isAnimating && !viewModel.isVoiceActive {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Visual representation of blinds with enhanced animation
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 60)
                
                // Blind slats animation with voice feedback color
                VStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Rectangle()
                            .fill(viewModel.isVoiceActive ? Color.blue.opacity(0.7) : Color(.systemGray3))
                            .frame(height: 10)
                            .opacity(Double(100 - viewModel.position) / 100.0)
                            .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.05), value: viewModel.position)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isVoiceActive)
                    }
                }
                .padding(.horizontal, 8)
                
                // Voice action overlay
                if viewModel.isVoiceActive {
                    Image(systemName: voiceActionIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .opacity(viewModel.voiceIndicatorOpacity)
                        .scaleEffect(viewModel.pulseAnimation ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.pulseAnimation)
                }
            }
            .padding(.vertical, 8)
            
            // Control buttons
            HStack(spacing: 0) {
                ForEach([
                    ("Close", "DownMax_Smarthome", { 
                        pressedButton = "Close"
                        onClose?()
                        viewModel.setPosition(0)
                        viewModel.setVoiceAction(.close, duration: 2.0)
                        resetButton()
                    }),
                    ("Down", "Down_Smarthome", { 
                        pressedButton = "Down"
                        onDown?()
                        viewModel.animatePositionChange(by: -10)
                        resetButton()
                    }),
                    ("", "BlindsIcon_Smarthome", nil),
                    ("Up", "Up_Smarthome", { 
                        pressedButton = "Up"
                        onUp?()
                        viewModel.animatePositionChange(by: 10)
                        resetButton()
                    }),
                    ("Open", "UpMax_Smarthome", { 
                        pressedButton = "Open"
                        onOpen?()
                        viewModel.setPosition(100)
                        viewModel.setVoiceAction(.open, duration: 2.0)
                        resetButton()
                    })
                ], id: \.0) { button in
                    if let action = button.2 {
                        VStack(spacing: 4) {
                            Button(action: action) {
                                ZStack {
                                    if pressedButton == button.0 {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 52, height: 52)
                                            .animation(.easeInOut(duration: 0.2), value: pressedButton)
                                    }
                                    
                                    Image(button.1)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Image("ButtonBase_Smarthome")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        )
                                        .scaleEffect(pressedButton == button.0 ? 0.9 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressedButton)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(button.0)
                                .font(.system(size: 13))
                                .foregroundColor(pressedButton == button.0 ? .blue : .gray)
                                .animation(.easeInOut(duration: 0.2), value: pressedButton)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Image(button.1)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                            Spacer().frame(height: 17)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            
            // Voice command indicator
            if !viewModel.lastCommand.isEmpty {
                Text("Voice: \"\(viewModel.lastCommand)\"")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
            
            Divider()
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(viewModel.isVoiceActive ? Color.blue : (viewModel.isAnimating ? Color.blue.opacity(0.5) : Color(.systemGray4)), lineWidth: viewModel.isVoiceActive ? 2 : 1)
                .background(Color(.systemGray6).cornerRadius(18))
                .animation(.easeInOut(duration: 0.3), value: viewModel.isAnimating)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isVoiceActive)
        )
        .padding(.horizontal, 8)
    }
    
    private func resetButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pressedButton = nil
        }
    }
}

#if DEBUG
struct AnimatedBlindsCard_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedBlindsCard(viewModel: AnimatedBlindsViewModel())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif