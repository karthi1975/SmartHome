import SwiftUI
import Combine

class AnimatedTempCardViewModel: ObservableObject {
    @Published var temp: Int
    @Published var isReducing: Bool = false

    private var reductionCancellable: AnyCancellable?
    var updateTemp: (Int) -> Void

    init(initialTemp: Int, updateTemp: @escaping (Int) -> Void) {
        self.temp = initialTemp
        self.updateTemp = updateTemp
    }

    func animateTemperatureChange(by amount: Int) {
        print("[DEBUG] AnimatedTempCardViewModel.animateTemperatureChange called with amount: \(amount)")
        guard amount != 0 else { 
            print("[DEBUG] Amount is 0, returning early")
            return 
        }
        
        DispatchQueue.main.async {
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
                            self.updateTemp(self.temp)
                        } else {
                            print("[DEBUG] Temperature animation completed at: \(self.temp)")
                            self.isReducing = false
                            print("[DEBUG] isReducing set to false")
                            self.reductionCancellable?.cancel()
                        }
                    }
                }
        }
    }

    func setTemp(_ newTemp: Int) {
        temp = newTemp
    }
} 