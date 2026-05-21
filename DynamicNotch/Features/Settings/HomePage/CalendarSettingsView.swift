import SwiftUI
internal import EventKit

struct CalendarSettingsView: View {
    @ObservedObject var settings: CalendarSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            calendarActivity
            calendarPreferences
        }
    }

    private var calendarActivity: some View {
        SettingsCard(title: "settings.activities.calendar.title") {
            SettingsToggleRow(
                title: "settings.activities.calendar.liveActivity",
                description: "settings.activities.calendar.liveActivity.desc",
                systemImage: "calendar",
                color: .red,
                isOn: $settings.isCalendarLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.calendar"
            )
        }
    }
    
    private var calendarPreferences: some View {
        SettingsCard(title: "settings.activities.calendar.preferences") {
            SettingsToggleRow(
                title: "settings.activities.calendar.allDay",
                description: "settings.activities.calendar.allDay.desc",
                systemImage: "clock.arrow.2.circlepath",
                color: .blue,
                isOn: $settings.showAllDayEvents,
                accessibilityIdentifier: "settings.activities.calendar.allDay"
            )
            
            Divider().opacity(0.6)
            
            HStack {

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("settings.activities.calendar.daysToShow"))
                        .font(.body)
                    Text(LocalizedStringKey("settings.activities.calendar.daysToShow.desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Stepper(value: $settings.daysToShow, in: 1...14) {
                    Text("\(settings.daysToShow) ") + Text(LocalizedStringKey("settings.activities.calendar.days"))
                        .font(.body)
                }
            }
        }
    }
}
