//
//  SidebarView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 6/2/25.


//import SwiftUI
//
//struct SidebarView: View {
//    @Binding var selectedRoom: Room
//    let leftColumnRooms: [Room]
//    let rightColumnRooms: [Room]
//    @Binding var showSidebarOverlay: Bool
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Hamburger at the top
//            HStack {
//                Button(action: { showSidebarOverlay = true }) {
//                    Image("SidebarIcon_Smarthome")
//                        .resizable()
//                        .frame(width: 34, height: 34)
//                        .foregroundColor(.white)
//                }
//                Spacer()
//            }
//            .padding(.top, 12)
//            .padding(.horizontal, 8)
//
//            HStack(alignment: .top, spacing: 0) {
//                // Left column
//                VStack {
//                    ForEach(leftColumnRooms) { room in
//                        RoomButton(room: room, isSelected: selectedRoom.id == room.id) {
//                            selectedRoom = room
//                        }
//                    }
//                }
//                // Right column with plus after last room
//                VStack(spacing: 0) {
//                    ForEach(Array(rightColumnRooms.enumerated()), id: \.element.id) { index, room in
//                        RoomButton(room: room, isSelected: selectedRoom.id == room.id) {
//                            selectedRoom = room
//                        }
//                        // Insert plus after the last right column room
//                        if index == rightColumnRooms.count - 1 {
//                            Button(action: {}) {
//                                Image(systemName: "plus")
//                                    .resizable()
//                                    .frame(width: 28, height: 28)
//                                    .foregroundColor(.white)
//                                    .padding(.vertical, 10)
//                            }
//                        }
//                    }
//                    Spacer()
//                }
//            }
//            Spacer()
//        }
//        .frame(width: 180)
//        .background(Color(red: 172/255, green: 32/255, blue: 41/255))
//    }
//}
import SwiftUI

struct SidebarView: View {
    @Binding var selectedRoom: Room
    let leftColumnRooms: [Room]
    let rightColumnRooms: [Room]
    @Binding var showSidebarOverlay: Bool
    var onAddRoom: ((Room) -> Void)? = nil

    @State private var showingAddRoom = false
    @State private var newRoomName = ""
    @State private var newRoomIcon = "Home_Smarthome"

    var body: some View {
        VStack(spacing: 0) {
            // Hamburger at the top
            HStack {
                Button(action: { showSidebarOverlay = true }) {
                    Image("SidebarIcon_Smarthome")
                        .resizable()
                        .frame(width: 34, height: 34)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal, 8)

            HStack(alignment: .top, spacing: 0) {
                // Left column
                VStack(spacing: 0) {
                    ForEach(leftColumnRooms) { room in
                        RoomButton(room: room, isSelected: selectedRoom.id == room.id) {
                            selectedRoom = room
                            showSidebarOverlay = false
                        }
                    }
                }
                // Right column, plus after last room
                VStack(spacing: 0) {
                    ForEach(Array(rightColumnRooms.enumerated()), id: \.element.id) { index, room in
                        RoomButton(room: room, isSelected: selectedRoom.id == room.id) {
                            selectedRoom = room
                            showSidebarOverlay = false
                        }
                        // After the last room (Support), show PLUS
                        if index == rightColumnRooms.count - 1 {
                            Button(action: { showingAddRoom = true }) {
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                    Spacer()
                }
            }
            Spacer()
        }
        .padding(.leading, 14)
        .frame(width: 220)
        .background(Color(red: 172/255, green: 32/255, blue: 41/255))
        .sheet(isPresented: $showingAddRoom) {
            VStack(spacing: 20) {
                Text("Add New Room").font(.title2).bold()
                TextField("Room Name", text: $newRoomName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                // For now, just use default icon
                Button("Add Room") {
                    let room = Room(name: newRoomName, iconName: newRoomIcon, selectedIconName: newRoomIcon)
                    onAddRoom?(room)
                    newRoomName = ""
                    showingAddRoom = false
                }
                .disabled(newRoomName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel") {
                    showingAddRoom = false
                }
            }
            .padding()
        }
    }
}

struct RoomButton: View {
    let room: Room
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(isSelected ? room.selectedIconName : room.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
                Text(room.name)
                    .font(.system(size: 16, weight: .heavy))
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? Color(red: 172/255, green: 32/255, blue: 41/255) : .white)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
