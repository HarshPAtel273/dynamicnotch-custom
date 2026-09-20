import Foundation

enum TodoCategory: String, CaseIterable, Identifiable, Codable {
    case general
    case work
    case personal
    case school
    case shopping
    case health
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .work: return "Work"
        case .personal: return "Personal"
        case .school: return "School"
        case .shopping: return "Shopping"
        case .health: return "Health"
        case .home: return "Home"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "tray"
        case .work: return "briefcase"
        case .personal: return "person"
        case .school: return "graduationcap"
        case .shopping: return "cart"
        case .health: return "heart"
        case .home: return "house"
        }
    }

    var sortRank: Int {
        switch self {
        case .work: return 0
        case .school: return 1
        case .personal: return 2
        case .home: return 3
        case .shopping: return 4
        case .health: return 5
        case .general: return 6
        }
    }
}

enum TodoCategoryFilter: String, CaseIterable, Identifiable, Codable {
    case all
    case general
    case work
    case personal
    case school
    case shopping
    case health
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .general: return TodoCategory.general.title
        case .work: return TodoCategory.work.title
        case .personal: return TodoCategory.personal.title
        case .school: return TodoCategory.school.title
        case .shopping: return TodoCategory.shopping.title
        case .health: return TodoCategory.health.title
        case .home: return TodoCategory.home.title
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .general: return TodoCategory.general.systemImage
        case .work: return TodoCategory.work.systemImage
        case .personal: return TodoCategory.personal.systemImage
        case .school: return TodoCategory.school.systemImage
        case .shopping: return TodoCategory.shopping.systemImage
        case .health: return TodoCategory.health.systemImage
        case .home: return TodoCategory.home.systemImage
        }
    }

    var category: TodoCategory? {
        TodoCategory(rawValue: rawValue)
    }
}
