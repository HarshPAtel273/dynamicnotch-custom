import SwiftUI

struct CalendarNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.HomePage.calendar.id
    let calendarViewModel: CalendarViewModel
    let notchViewModel: NotchViewModel
    
    var priority: Int { NotchContentRegistry.HomePage.calendar.priority }
    var isExpandable: Bool { true }
    
    var windowLink: (@MainActor () -> Void)? {
        return {
            calendarViewModel.openCalendarEvent()
        }
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 110, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 200, height: baseHeight + 120)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 40)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(CalendarMinimalNotchView(calendarViewModel: calendarViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(CalendarExpandedNotchView(notchViewModel: notchViewModel, calendarViewModel: calendarViewModel))
    }
}
