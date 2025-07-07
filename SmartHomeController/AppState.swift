import Foundation
import SwiftUI

class AppState: ObservableObject {
    enum AppPage: String {
        case home = "Home"
        case kitchen = "Kitchen"
        case livingRoom = "Living Room"
        case bedroom = "Bedroom"
        case garage = "Garage"
        case laundry = "Laundry"
        case nursery = "Nursery"
        case outside = "Outside"
        case backyard = "Backyard"
        case master = "Master"
        case entrance = "Entrance"
        case playroom = "Playroom"
        case elevator = "Elevator"
        case support = "Support"
    }
    @Published var currentPage: AppPage = .home
    @Published var agentMessage: String? = nil
} 