import Foundation

struct CallRecord: Identifiable, Codable {
    var id: UUID
    let timestamp: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), timestamp: Date, duration: TimeInterval) {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
    }

    func timestampString() -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: timestamp)
    }

    func durationString() -> String {
        let sec = Int(duration.rounded())
        let m = sec / 60, s = sec % 60
        if m > 0 {
            return String(format: "%d:%02d min", m, s)
        } else {
            return "\(s) sec"
        }
    }
} 