import SwiftUI
import Combine

class AnimatedToasterViewModel: ObservableObject {
    @Published var isOn: Bool = false
    @Published var isToasting: Bool = false
    @Published var toastProgress: Double = 0.0
    @Published var toastLevel: Int = 3 // 1-5 toast level
    @Published var showVoiceAnimation: Bool = false
    @Published var voiceCommandText: String = ""
    
    private var toastTimer: Timer?
    
    func toggle() {
        if isOn {
            stopToasting()
        } else {
            startToasting()
        }
    }
    
    func startToasting() {
        isOn = true
        isToasting = true
        toastProgress = 0.0
        
        // Animate toasting progress (duration based on toast level)
        let duration = Double(toastLevel + 2) // 3-7 seconds based on level
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.toastProgress += (0.1 / duration)
            if self.toastProgress >= 1.0 {
                self.toastProgress = 1.0
                self.finishToasting()
                timer.invalidate()
            }
        }
    }
    
    func stopToasting() {
        isOn = false
        isToasting = false
        toastProgress = 0.0
        toastTimer?.invalidate()
    }
    
    private func finishToasting() {
        isToasting = false
        // Keep isOn true to show it's done but still on
        
        // Auto turn off after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isOn = false
            self.toastProgress = 0.0
        }
    }
    
    func setToastLevel(_ level: Int) {
        toastLevel = max(1, min(5, level))
    }
    
    func handleVoiceCommand(_ command: String) {
        voiceCommandText = command
        showVoiceAnimation = true
        
        // Hide voice animation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showVoiceAnimation = false
            self.voiceCommandText = ""
        }
        
        // Process voice commands
        let lowercased = command.lowercased()
        if lowercased.contains("start") || lowercased.contains("toast") || lowercased.contains("on") {
            startToasting()
        } else if lowercased.contains("stop") || lowercased.contains("cancel") || lowercased.contains("off") {
            stopToasting()
        } else if lowercased.contains("level") {
            if let number = extractNumber(from: command) {
                setToastLevel(number)
            }
        }
    }
    
    private func extractNumber(from text: String) -> Int? {
        let pattern = "\\d+"
        if let match = text.range(of: pattern, options: .regularExpression) {
            return Int(text[match])
        }
        return nil
    }
}

struct AnimatedToasterCard: View {
    @ObservedObject var viewModel: AnimatedToasterViewModel
    var onToggle: (() -> Void)?
    
    @State private var glowAnimation: Bool = false
    @State private var heatWaveAnimation: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    ZStack {
                        // Toaster icon
                        Image("Toaster_Smarthome")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .overlay(
                                // Heat glow effect when toasting
                                viewModel.isToasting ?
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.orange, .red]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: glowAnimation ? 3 : 1
                                    )
                                    .opacity(glowAnimation ? 0.8 : 0.3)
                                    .animation(
                                        Animation.easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true),
                                        value: glowAnimation
                                    )
                                : nil
                            )
                        
                        // Toast progress indicator
                        if viewModel.isToasting {
                            Circle()
                                .trim(from: 0, to: CGFloat(viewModel.toastProgress))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .red]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: viewModel.toastProgress)
                        }
                        
                        // Heat waves animation
                        if viewModel.isToasting {
                            ForEach(0..<3) { index in
                                Image(systemName: "heat.waves")
                                    .foregroundColor(.orange)
                                    .offset(y: -20 - CGFloat(index * 10))
                                    .opacity(heatWaveAnimation ? 0.0 : 0.8)
                                    .animation(
                                        Animation.easeOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.3),
                                        value: heatWaveAnimation
                                    )
                            }
                        }
                    }
                    
                    Text(statusText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(viewModel.isOn ? .orange : .black)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isOn)
                    
                    Text("Level \(viewModel.toastLevel)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    // Power button
                    Button(action: {
                        viewModel.toggle()
                        onToggle?()
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isOn ? Color.orange.opacity(0.2) : Color.clear)
                                .frame(width: 44, height: 44)
                            
                            Image("Power_Smarthome")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(viewModel.isOn ? .orange : .primary)
                        }
                    }
                    .scaleEffect(viewModel.isOn ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: viewModel.isOn)
                    
                    Text(viewModel.isOn ? "On" : "Off")
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.isOn ? .orange : .gray)
                    
                    // Toast level control
                    if viewModel.isOn && !viewModel.isToasting {
                        HStack(spacing: 4) {
                            Button(action: {
                                viewModel.setToastLevel(viewModel.toastLevel - 1)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.blue)
                            }
                            .disabled(viewModel.toastLevel <= 1)
                            
                            Text("\(viewModel.toastLevel)")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 20)
                            
                            Button(action: {
                                viewModel.setToastLevel(viewModel.toastLevel + 1)
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                            .disabled(viewModel.toastLevel >= 5)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            
            // Progress bar
            if viewModel.isToasting {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.yellow, .orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(viewModel.toastProgress), height: 4)
                            .animation(.linear(duration: 0.1), value: viewModel.toastProgress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            // Voice command feedback
            if viewModel.showVoiceAnimation {
                Text(viewModel.voiceCommandText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
                    .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(viewModel.isOn ? Color.orange.opacity(0.5) : Color(.systemGray4), lineWidth: viewModel.isOn ? 2 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(viewModel.isOn ? Color.orange.opacity(0.05) : Color(.systemGray6))
                )
        )
        .padding(.horizontal, 8)
        .onAppear {
            glowAnimation = true
            heatWaveAnimation = true
        }
    }
    
    private var statusText: String {
        if !viewModel.isOn {
            return "Ready"
        } else if viewModel.isToasting {
            let progress = Int(viewModel.toastProgress * 100)
            return "Toasting \(progress)%"
        } else if viewModel.toastProgress >= 1.0 {
            return "Done!"
        } else {
            return "On"
        }
    }
}

#if DEBUG
struct AnimatedToasterCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnimatedToasterCard(viewModel: AnimatedToasterViewModel())
            
            AnimatedToasterCard(viewModel: {
                let vm = AnimatedToasterViewModel()
                vm.isOn = true
                vm.isToasting = true
                vm.toastProgress = 0.5
                return vm
            }())
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif