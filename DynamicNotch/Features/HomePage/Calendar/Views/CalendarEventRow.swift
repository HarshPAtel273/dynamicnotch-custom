import SwiftUI
internal import EventKit

struct CalendarEventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                if event.isAllDay {
                    Text("All Day")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text(timeString(from: event.startDate) + " - " + timeString(from: event.endDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let url = event.url, isVideoCall(url: url) {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Text("Join")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isVideoCall(url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("zoom.us") || 
               host.contains("meet.google.com") || 
               host.contains("teams.microsoft.com") ||
               host.contains("webex.com")
    }
}
