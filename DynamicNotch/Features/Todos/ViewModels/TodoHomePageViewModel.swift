import Combine
import Foundation

@MainActor
final class TodoHomePageViewModel: ObservableObject {
    static let storageKey = "settings.homePage.todos"
    static let categoryFilterStorageKey = "settings.homePage.todos.categoryFilter"

    @Published private(set) var items: [TodoItem] = []
    @Published var draftTitle = ""
    @Published var draftCategory: TodoCategory = .general
    @Published var categoryFilter: TodoCategoryFilter {
        didSet {
            guard oldValue != categoryFilter else { return }
            persistCategoryFilter()
        }
    }

    private let defaults: UserDefaults
    private let now: () -> Date

    var displayedItems: [TodoItem] {
        let filtered = items.filter { item in
            guard let category = categoryFilter.category else { return true }
            return item.category == category
        }

        return filtered.sorted { lhs, rhs in
            if lhs.category.sortRank != rhs.category.sortRank {
                return lhs.category.sortRank < rhs.category.sortRank
            }
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }
    }

    var displayedSections: [(category: TodoCategory, items: [TodoItem])] {
        TodoCategory.allCases.compactMap { category in
            let sectionItems = displayedItems.filter { $0.category == category }
            guard !sectionItems.isEmpty else { return nil }
            return (category, sectionItems)
        }
    }

    var incompleteItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }

    var completedItems: [TodoItem] {
        items.filter(\.isCompleted)
    }

    var hasItems: Bool {
        !items.isEmpty
    }

    var hasVisibleItems: Bool {
        !displayedItems.isEmpty
    }

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        items = Self.loadItems(from: defaults)
        categoryFilter = Self.loadCategoryFilter(from: defaults)
    }

    @discardableResult
    func addTodo(title: String? = nil, category: TodoCategory? = nil) -> Bool {
        let resolvedTitle = (title ?? draftTitle)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedTitle.isEmpty else { return false }

        let item = TodoItem(
            title: resolvedTitle,
            createdAt: now(),
            category: category ?? draftCategory
        )
        items.insert(item, at: 0)
        draftTitle = ""
        persist()
        return true
    }

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        items[index].isCompleted.toggle()
        persist()
    }

    func setCategory(_ category: TodoCategory, for item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        guard items[index].category != category else { return }

        items[index].category = category
        persist()
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func clearCompleted() {
        guard items.contains(where: \.isCompleted) else { return }

        items.removeAll(where: \.isCompleted)
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private func persistCategoryFilter() {
        defaults.set(categoryFilter.rawValue, forKey: Self.categoryFilterStorageKey)
    }

    private static func loadItems(from defaults: UserDefaults) -> [TodoItem] {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([TodoItem].self, from: data)
        else {
            return []
        }

        return decoded
    }

    private static func loadCategoryFilter(from defaults: UserDefaults) -> TodoCategoryFilter {
        guard
            let rawValue = defaults.string(forKey: categoryFilterStorageKey),
            let filter = TodoCategoryFilter(rawValue: rawValue)
        else {
            return .all
        }

        return filter
    }
}
