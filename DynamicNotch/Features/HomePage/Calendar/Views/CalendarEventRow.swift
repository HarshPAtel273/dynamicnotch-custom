import SwiftUI
internal import EventKit

struct CalendarEventRow: View {
    let event: EKEvent
    
    var body: some View {
        Button(action: {
            openEventInCalendar()
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        if event.isAllDay {
                            Text("All Day")
                        } else {
                            Text(timeString(from: event.startDate) + " - " + timeString(from: event.endDate))
                        }
                        
                        Text("•")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(event.calendar.title)
                            .lineLimit(1)
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    
                    if let location = event.location, !location.isEmpty {
                        Text(location)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .foregroundColor(.gray.opacity(0.8))
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
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(cgColor: event.calendar.cgColor).opacity(0.2))
            .cornerRadius(30)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func openEventInCalendar() {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        } else if let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        }
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
