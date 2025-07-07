//
//  Room.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 6/2/25.
//
import Foundation

struct Room: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
    let selectedIconName: String
}
