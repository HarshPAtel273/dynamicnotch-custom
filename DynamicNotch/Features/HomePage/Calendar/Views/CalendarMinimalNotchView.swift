import SwiftUI
internal import EventKit

struct CalendarMinimalNotchView: View {
    @Environment(\.notchScale) private var notchScale
    @ObservedObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            if calendarViewModel.nextEvent != nil {
                Text(calendarViewModel.formattedNextEventTime)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.red.gradient)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14.scaled(by: notchScale))
    }
}
