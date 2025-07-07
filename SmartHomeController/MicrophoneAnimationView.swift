import SwiftUI
import AVKit

struct MicrophoneAnimationView: View {
    @EnvironmentObject var callManager: CallManager
    @State private var player: AVPlayer?
    @State private var isAnimating = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var animationTimer: Timer?
    
    private var shouldShowAnimation: Bool {
        callManager.userSpeaking || callManager.agentSpeaking
    }
    
    var body: some View {
        ZStack {
            // Enhanced pulse effect with multiple expanding rings
            if shouldShowAnimation {
                // Outer ring - largest expansion
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(scaleEffect * 1.8)
                    .opacity(pulseOpacity * 0.6)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: scaleEffect)
                
                // Middle ring - medium expansion  
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 120, height: 120)
                    .scaleEffect(scaleEffect * 1.4)
                    .opacity(pulseOpacity * 0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scaleEffect)
                
                // Inner ring - original expansion
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .scaleEffect(scaleEffect)
                    .opacity(pulseOpacity)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scaleEffect)
            }
            
            // Main microphone animation
            if shouldShowAnimation {
                // White background circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 88, height: 88)
                
                // Video animation
                VideoPlayer(player: player)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(radius: 8)
                    .onAppear {
                        setupVideoPlayer()
                        startAnimation()
                    }
                    .onDisappear {
                        stopAnimation()
                    }
                
                // Inner white circle border to mask corners (original working version)
                Circle()
                    .stroke(Color.white, lineWidth: 12)
                    .frame(width: 78, height: 78)
                    .allowsHitTesting(false)
            } else {
                // Static microphone icon (this shouldn't show in GlobalMicrophoneOverlay)
                StaticMicrophoneButton()
            }
        }
        .onChange(of: shouldShowAnimation) { newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    private func setupVideoPlayer() {
        guard player == nil else { return }
        
        if let url = Bundle.main.url(forResource: "voice_animation_MP4_WhiteVersion", withExtension: "mp4") {
            player = AVPlayer(url: url)
            player?.actionAtItemEnd = .none
            
            // Loop the video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Start video player
        player?.seek(to: .zero)
        player?.play()
        
        // Start pulse animation
        withAnimation {
            scaleEffect = 1.2
            pulseOpacity = 1.0
        }
        
        // Set a safety timer to stop animation after 10 seconds if no state change
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            if !self.callManager.userSpeaking && !self.callManager.agentSpeaking {
                self.stopAnimation()
            }
        }
    }
    
    private func stopAnimation() {
        isAnimating = false
        player?.pause()
        
        // Reset pulse animation
        withAnimation {
            scaleEffect = 1.0
            pulseOpacity = 0.0
        }
        
        // Clear the safety timer
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Global Microphone Overlay
struct GlobalMicrophoneOverlay: View {
    @EnvironmentObject var callManager: CallManager
    @State private var showAnimation = false
    
    private var shouldShowAnimation: Bool {
        callManager.userSpeaking || callManager.agentSpeaking
    }
    
    var body: some View {
        // Only show the microphone overlay when actually calling
        if callManager.isCalling {
            // Use overlay modifier to position without affecting layout
            Color.clear
                .overlay(alignment: .bottomTrailing) {
                    ZStack {
                        // Static microphone - fade out when animation starts
                        if !showAnimation {
                            StaticMicrophoneButton()
                                .transition(.opacity)
                        }
                        
                        // Animation microphone - fade in when speaking starts
                        if showAnimation {
                            MicrophoneAnimationView()
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 32)
                    .padding(.trailing, 24)
                }
                .allowsHitTesting(false) // Container passes through touches
                .overlay(alignment: .bottomTrailing) {
                    // Make only the actual button area interactive
                    if callManager.isCalling {
                        Button(action: {
                            if callManager.isCalling {
                                callManager.endCall()
                            } else {
                                let vapiConfig = VAPIConfig.load()
                                callManager.startCall(
                                    publicKey: vapiConfig.publicKey,
                                    assistantId: vapiConfig.assistantId
                                )
                            }
                        }) {
                            Color.clear
                                .frame(width: 88, height: 88) // Match microphone button size
                        }
                        .padding(.bottom, 32)
                        .padding(.trailing, 24)
                        .allowsHitTesting(true)
                    }
                }
                .onChange(of: shouldShowAnimation) { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAnimation = newValue
                    }
                }
                .onAppear {
                    showAnimation = shouldShowAnimation
                }
        }
    }
}

// MARK: - Static Microphone Button
struct StaticMicrophoneButton: View {
    @EnvironmentObject var callManager: CallManager
    
    var body: some View {
        ZStack {
            // Match the animation size (88px background circle)
            Circle()
                .fill(Color.red)
                .frame(width: 88, height: 88)
                .shadow(radius: 8)
            
            Image(systemName: callManager.isCalling ? "mic.fill" : "mic.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundColor(.white)
        }
        .allowsHitTesting(false) // Visual only - interaction handled by overlay
    }
}

// MARK: - Floating Microphone Button (Enhanced)
struct FloatingMicrophoneButton: View {
    @EnvironmentObject var callManager: CallManager
    @State private var isPressed = false
    @State private var showingAnimation = false
    
    var body: some View {
        Button(action: {
            // Handle microphone button press
            if callManager.isCalling {
                callManager.endCall()
            } else {
                let vapiConfig = VAPIConfig.load()
                callManager.startCall(
                    publicKey: vapiConfig.publicKey,
                    assistantId: vapiConfig.assistantId
                )
            }
        }) {
            ZStack {
                // Button background
                Circle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 8)
                
                // Microphone icon or animation
                if showingAnimation {
                    MicrophoneAnimationView()
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: callManager.isCalling ? "mic.fill" : "mic.slash.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) {
            // Handle long press
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onChange(of: callManager.userSpeaking) { newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                showingAnimation = newValue || callManager.agentSpeaking
            }
        }
        .onChange(of: callManager.agentSpeaking) { newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                showingAnimation = newValue || callManager.userSpeaking
            }
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        MicrophoneAnimationView()
        FloatingMicrophoneButton()
    }
    .environmentObject(CallManager())
}