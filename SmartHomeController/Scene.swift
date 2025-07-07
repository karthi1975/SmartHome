//
//  Scene.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 6/3/25.
//

import Foundation

struct Scene: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
}
