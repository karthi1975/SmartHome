import SwiftUI

struct TicketHistoryView: View {
    let tickets: [Ticket]

    var body: some View {
        List(tickets) { ticket in
            VStack(alignment: .leading, spacing: 6) {
                Text(ticket.title)
                    .font(.headline)
                HStack {
                    Text("Status: \(ticket.state)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(ticket.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return dateString
    }
} 