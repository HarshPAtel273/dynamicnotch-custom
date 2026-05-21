import SwiftUI

@MainActor
final class NotchCalendarEventsHandler {
    private let notchViewModel: NotchViewModel
    private let calendarViewModel: CalendarViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        calendarViewModel: CalendarViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.calendarViewModel = calendarViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleCalendarEvent(_ hasUpcoming: Bool) {
        if hasUpcoming && settingsViewModel.calendar.isCalendarLiveActivityEnabled {
            notchViewModel.send(
                .showLiveActivity(
                    CalendarNotchContent(
                        calendarViewModel: calendarViewModel,
                        notchViewModel: notchViewModel
                    )
                )
            )
        } else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.calendar.id))
        }
    }
}
