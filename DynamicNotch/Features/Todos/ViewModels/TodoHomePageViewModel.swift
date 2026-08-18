import Combine
import Foundation

@MainActor
final class TodoHomePageViewModel: ObservableObject {
    static let storageKey = "settings.homePage.todos"

    @Published private(set) var items: [TodoItem] = []
    @Published var draftTitle = ""

    private let defaults: UserDefaults
    private let now: () -> Date

    var incompleteItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }

    var completedItems: [TodoItem] {
        items.filter(\.isCompleted)
    }

    var hasItems: Bool {
        !items.isEmpty
    }

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        items = Self.loadItems(from: defaults)
    }

    @discardableResult
    func addTodo(title: String? = nil) -> Bool {
        let resolvedTitle = (title ?? draftTitle)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedTitle.isEmpty else { return false }

        let item = TodoItem(title: resolvedTitle, createdAt: now())
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

    private static func loadItems(from defaults: UserDefaults) -> [TodoItem] {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([TodoItem].self, from: data)
        else {
            return []
        }

        return decoded
    }
}
