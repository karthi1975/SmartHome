import SwiftUI

struct DeviceHistoryView: View {
    let device: SmartDevice
    @StateObject private var historyManager = DeviceHistoryManager()
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedEventType: DeviceEvent.EventType?
    
    enum TimeRange: String, CaseIterable {
        case hour = "Last Hour"
        case day = "Last 24 Hours"
        case week = "Last Week"
        case month = "Last Month"
        case all = "All Time"
        
        var date: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .hour:
                return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
            case .day:
                return calendar.date(byAdding: .day, value: -1, to: now) ?? now
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .all:
                return .distantPast
            }
        }
    }
    
    var filteredEvents: [DeviceEvent] {
        var events = historyManager.eventsForDevice(device.id.uuidString)
        
        // Filter by time range
        events = events.filter { $0.timestamp >= selectedTimeRange.date }
        
        // Filter by event type if selected
        if let eventType = selectedEventType {
            events = events.filter { $0.eventType == eventType }
        }
        
        return events
    }
    
    var body: some View {
        List {
            Section {
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Picker("Event Type", selection: $selectedEventType) {
                    Text("All Events").tag(nil as DeviceEvent.EventType?)
                    ForEach(DeviceEvent.EventType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type as DeviceEvent.EventType?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Section {
                ForEach(filteredEvents) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(event.eventType.rawValue.capitalized)
                                .font(.headline)
                            Spacer()
                            Text(event.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let oldValue = event.oldValue, let newValue = event.newValue {
                            Text("\(oldValue) → \(newValue)")
                                .font(.subheadline)
                        }
                        
                        Text("Source: \(event.source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Device History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Image("tetradapt-main-logo-BLKWHT")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                    Text("TETR")
                        .font(.system(size: 22, weight: .bold, design: .default))
                        .foregroundColor(.black)
                }
                .padding(.leading, 8)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    historyManager.clearHistory()
                }) {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

extension DeviceEvent.EventType: CaseIterable {
    static var allCases: [DeviceEvent.EventType] {
        [.stateChange, .serviceCall, .error, .discovery, .configuration]
    }
} 