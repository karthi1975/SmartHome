import SwiftUI
import Combine

class AnimatedTempCardViewModel: ObservableObject {
    @Published var temp: Int
    @Published var isReducing: Bool = false
    @Published var lastVoiceAction: TempVoiceAction? = nil
    @Published var lastButtonPressed: TempVoiceAction? = nil

    private var reductionCancellable: AnyCancellable?
    private var voiceActionCancellable: AnyCancellable?
    private var buttonActionCancellable: AnyCancellable?
    var updateTemp: (Int) -> Void

    init(initialTemp: Int, updateTemp: @escaping (Int) -> Void) {
        self.temp = initialTemp
        self.updateTemp = updateTemp
    }
    
    deinit {
        // CRITICAL FIX: Clean up all timers to prevent memory leaks
        reductionCancellable?.cancel()
        voiceActionCancellable?.cancel()
        buttonActionCancellable?.cancel()
    }

    func animateTemperatureChange(by amount: Int) {
        print("[DEBUG] AnimatedTempCardViewModel.animateTemperatureChange called with amount: \(amount)")
        guard amount != 0 else { 
            print("[DEBUG] Amount is 0, returning early")
            return 
        }
        
        // CRITICAL FIX: Cancel any existing animation first to prevent conflicts
        reductionCancellable?.cancel()
        reductionCancellable = nil
        
        DispatchQueue.main.async {
            // Prevent concurrent animations
            guard !self.isReducing else {
                print("[DEBUG] Animation already in progress, ignoring new request")
                return
            }
            
            print("[DEBUG] Starting temperature animation from \(self.temp) by \(amount)")
            self.isReducing = true
            print("[DEBUG] isReducing set to true")
            let target = self.temp + amount // positive amount = increase, negative = decrease
            print("[DEBUG] Target temperature: \(target)")
            
            self.reductionCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        if (amount > 0 && self.temp < target) || (amount < 0 && self.temp > target) {
                            self.temp += (amount > 0 ? 1 : -1)
                            print("[DEBUG] Temperature updated to: \(self.temp)")
                            // Don't send to VAPI during animation - only when complete
                        } else {
                            print("[DEBUG] Temperature animation completed at: \(self.temp)")
                            self.isReducing = false
                            print("[DEBUG] isReducing set to false")
                            // Only send final temperature to VAPI when animation completes
                            self.updateTemp(self.temp)
                            self.reductionCancellable?.cancel()
                            self.reductionCancellable = nil
                        }
                    }
                }
        }
    }

    func setTemp(_ newTemp: Int) {
        // CRITICAL FIX: Cancel ongoing animations when temp is set externally
        // This prevents conflicts when multiple sources update temperature
        if isReducing {
            print("[DEBUG] External setTemp called while animation in progress - cancelling animation")
            reductionCancellable?.cancel()
            reductionCancellable = nil
            isReducing = false
        }
        temp = newTemp
    }
    
    func setUpdateTempClosure(_ newClosure: @escaping (Int) -> Void) {
        updateTemp = newClosure
    }
    
    // CRITICAL FIX: Centralized state management to prevent conflicts
    func setVoiceAction(_ action: TempVoiceAction?, duration: TimeInterval = 1.0) {
        // Cancel any existing voice action timer
        voiceActionCancellable?.cancel()
        voiceActionCancellable = nil
        
        DispatchQueue.main.async {
            self.lastVoiceAction = action
            
            if action != nil {
                print("[DEBUG] Setting lastVoiceAction to \(action!) for \(duration)s")
                self.voiceActionCancellable = Timer.publish(every: duration, on: .main, in: .common)
                    .autoconnect()
                    .first()
                    .sink { [weak self] _ in
                        DispatchQueue.main.async {
                            print("[DEBUG] Clearing lastVoiceAction after timer")
                            self?.lastVoiceAction = nil
                            self?.voiceActionCancellable?.cancel()
                            self?.voiceActionCancellable = nil
                        }
                    }
            }
        }
    }
    
    func setButtonAction(_ action: TempVoiceAction?, duration: TimeInterval = 1.0) {
        // Cancel any existing button action timer
        buttonActionCancellable?.cancel()
        buttonActionCancellable = nil
        
        DispatchQueue.main.async {
            self.lastButtonPressed = action
            
            if action != nil {
                print("[DEBUG] Setting lastButtonPressed to \(action!) for \(duration)s")
                self.buttonActionCancellable = Timer.publish(every: duration, on: .main, in: .common)
                    .autoconnect()
                    .first()
                    .sink { [weak self] _ in
                        DispatchQueue.main.async {
                            print("[DEBUG] Clearing lastButtonPressed after timer")
                            self?.lastButtonPressed = nil
                            self?.buttonActionCancellable?.cancel()
                            self?.buttonActionCancellable = nil
                        }
                    }
            }
        }
    }
} 

enum TempVoiceAction {
    case increase
    case decrease
} 