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
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(viewModel.temp) °F")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(viewModel.isReducing ? .red : .black)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.temp)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isReducing)
                    Text("Current")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                VStack(spacing: 4) {
                    Button(action: { onDown?() ?? { if viewModel.temp > 40 { viewModel.temp -= 2; viewModel.updateTemp(viewModel.temp) } }() }) {
                        Image("Down_Smarthome")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
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
                Button(action: { onUp?() ?? { if viewModel.temp < 100 { viewModel.temp += 2; viewModel.updateTemp(viewModel.temp) } }() }) {
                    Image("Up_Smarthome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
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
                await callManager.speakTemperature(room: roomName, temp: temp)
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