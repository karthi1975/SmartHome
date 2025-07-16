import SwiftUI
import AVFoundation

struct TempCard: View {
    @ObservedObject var viewModel: AnimatedTempCardViewModel
    @EnvironmentObject var callManager: CallManager
    var roomName: String = "Room"
    var onDown: (() -> Void)? = nil
    var onUp: (() -> Void)? = nil
    
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var lastAnnouncedTemp: Int = 0
    @State private var animateTemp = false
    @State private var animateUp = false
    @State private var animateDown = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(viewModel.temp) °F")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(viewModel.isReducing ? .red : .black)
                        .scaleEffect(animateTemp ? 1.2 : 1.0)
                        .animation(.spring(), value: animateTemp)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.temp)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isReducing)
                    Text("Current")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                VStack(spacing: 4) {
                    Button(action: { 
                        onDown?() ?? { 
                            if viewModel.temp > 40 { 
                                viewModel.animateTemperatureChange(by: -2)
                                viewModel.setButtonAction(.decrease, duration: 1.0)
                            } 
                        }() 
                    }) {
                        Image("Down_Smarthome")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .scaleEffect(animateDown ? 1.2 : 1.0)
                            .animation(.spring(), value: animateDown)
                            .background(
                                Image("ButtonBase_Smarthome")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                VStack(spacing: 4) {
                    Text("\(viewModel.temp + 2) °F")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                    Text("Up")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Button(action: { 
                    onUp?() ?? { 
                        if viewModel.temp < 100 { 
                            viewModel.animateTemperatureChange(by: 2)
                            viewModel.setButtonAction(.increase, duration: 1.0)
                        } 
                    }() 
                }) {
                    Image("Up_Smarthome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .scaleEffect(animateUp ? 1.2 : 1.0)
                        .animation(.spring(), value: animateUp)
                        .background(
                            Image("ButtonBase_Smarthome")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            Divider()
            if viewModel.isReducing {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        .scaleEffect(1.2)
                    Text("Adjusting Temperature...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4), lineWidth: 1)
                .background(Color(.systemGray6).cornerRadius(18))
        )
        .padding(.horizontal, 8)
        .onChange(of: viewModel.temp) { newTemp in
            // Automatically announce temperature changes
            if newTemp != lastAnnouncedTemp {
                announceTemperature(newTemp)
                lastAnnouncedTemp = newTemp
            }
        }
        .onChange(of: viewModel.lastVoiceAction) { action in
            if let action = action {
                // Voice commands should trigger both temp and button animations for consistency
                animateTemp = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { animateTemp = false }
                
                // Also trigger appropriate button animation for voice commands
                if action == .increase {
                    animateUp = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { animateUp = false }
                } else if action == .decrease {
                    animateDown = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { animateDown = false }
                }
            }
        }
        .onChange(of: viewModel.lastButtonPressed) { action in
            if action == .increase {
                animateUp = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { animateUp = false }
            } else if action == .decrease {
                animateDown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { animateDown = false }
            }
        }
        .onAppear {
            // Set initial temp but don't announce on startup
            lastAnnouncedTemp = viewModel.temp
            // Only announce if VAPI is already connected (not on startup)
            if callManager.isCalling {
                announceTemperature(viewModel.temp)
            }
        }
    }
    
    private func announceTemperature(_ temp: Int) {
        let message = "\(roomName) temperature is now \(temp) degrees Fahrenheit"
        print("[DEBUG] Announcing: \(message)")
        
        // Only use VAPI for voice announcements - no fallback to native TTS
        if callManager.isCalling {
            Task {
                await callManager.announceRoomTemperature(room: roomName, temp: temp)
            }
        } else {
            print("[DEBUG] VAPI not connected, skipping voice announcement")
        }
    }
}

#if DEBUG
struct TempCard_Previews: PreviewProvider {
    static var previews: some View {
        TempCard(viewModel: AnimatedTempCardViewModel(initialTemp: 70, updateTemp: { _ in }))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 