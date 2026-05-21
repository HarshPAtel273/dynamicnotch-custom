import SwiftUI
internal import EventKit

struct CalendarExpandedNotchView: View {
    let notchViewModel: NotchViewModel
    
    @ObservedObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            if let event = calendarViewModel.nextEvent {
                HStack {
                    Circle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 12, height: 12)
                    
                    Text("Next Event")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                    
                    Button {
                        notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.calendar.id))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if event.isAllDay {
                        Text("All Day")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    } else {
                        Text(timeString(from: event.startDate) + " - " + timeString(from: event.endDate))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                if let url = event.url, isVideoCall(url: url) {
                    Button {
                        NSWorkspace.shared.open(url)
                        notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.calendar.id))
                    } label: {
                        HStack {
                            Image(systemName: "video.fill")
                            Text("Join Meeting")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                Text("No upcoming events")
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
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
