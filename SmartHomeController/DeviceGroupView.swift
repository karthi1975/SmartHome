import SwiftUI

struct DeviceGroupView: View {
    @StateObject private var groupManager = DeviceGroupManager()
    @State private var showingAddGroup = false
    @State private var selectedGroup: DeviceGroup?
    @State private var showingGroupDetail = false
    
    var body: some View {
        List {
            ForEach(groupManager.groups) { group in
                Button(action: {
                    selectedGroup = group
                    showingGroupDetail = true
                }) {
                    HStack {
                        Image(group.icon)
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.headline)
                            Text("\(group.devices.count) devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    groupManager.removeGroup(groupManager.groups[index])
                }
            }
        }
        .navigationTitle("Device Groups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddGroup = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGroup) {
            AddGroupView(groupManager: groupManager)
        }
        .sheet(isPresented: $showingGroupDetail) {
            if let group = selectedGroup {
                GroupDetailView(group: group, groupManager: groupManager)
            }
        }
    }
}

struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var groupManager: DeviceGroupManager
    @State private var name = ""
    @State private var selectedType: DeviceGroup.GroupType = .room
    @State private var selectedIcon = "folder"
    @State private var description = ""
    
    let icons = ["folder", "house", "star", "gear", "bell", "lock", "camera", "tv", "speaker.wave.2", "lightbulb", "thermometer", "fan", "humidity", "vacuum", "dishwasher", "washer", "dryer", "oven", "refrigerator", "garage"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    TextField("Name", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Room").tag(DeviceGroup.GroupType.room)
                        Text("Scene").tag(DeviceGroup.GroupType.scene)
                        Text("Automation").tag(DeviceGroup.GroupType.automation)
                        Text("Custom").tag(DeviceGroup.GroupType.custom)
                    }
                    
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(icons, id: \.self) { icon in
                            Image(icon)
                                .tag(icon)
                        }
                    }
                    
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        groupManager.addGroup(
                            name: name,
                            devices: [],
                            type: selectedType,
                            icon: selectedIcon,
                            description: description
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct GroupDetailView: View {
    let group: DeviceGroup
    @ObservedObject var groupManager: DeviceGroupManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddDevice = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Group Info")) {
                    HStack {
                        Image(group.icon)
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.headline)
                            Text(group.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Devices")) {
                    ForEach(group.devices, id: \.self) { deviceId in
                        Text(deviceId)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            groupManager.removeDeviceFromGroup(group.devices[index], groupId: group.id)
                        }
                    }
                }
            }
            .navigationTitle("Group Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddDevice = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDevice) {
                AddDeviceToGroupView(group: group, groupManager: groupManager)
            }
        }
    }
}

struct AddDeviceToGroupView: View {
    let group: DeviceGroup
    @ObservedObject var groupManager: DeviceGroupManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDeviceId: String?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupManager.groups.flatMap { $0.devices }, id: \.self) { deviceId in
                    Button(action: {
                        selectedDeviceId = deviceId
                    }) {
                        HStack {
                            Text(deviceId)
                            Spacer()
                            if selectedDeviceId == deviceId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let deviceId = selectedDeviceId {
                            groupManager.addDeviceToGroup(deviceId, groupId: group.id)
                        }
                        dismiss()
                    }
                    .disabled(selectedDeviceId == nil)
                }
            }
        }
    }
} 