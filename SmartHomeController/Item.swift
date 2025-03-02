//
//  Item.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
