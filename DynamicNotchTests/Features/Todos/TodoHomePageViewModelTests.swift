import XCTest
@testable import DynamicNotch

@MainActor
final class TodoHomePageViewModelTests: XCTestCase {
    func testAddTodoInsertsTrimmedItemAndClearsDraft() {
        let defaults = makeDefaults()
        let viewModel = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(viewModel)
        viewModel.draftTitle = "  Buy milk  "
        viewModel.draftCategory = .shopping

        XCTAssertTrue(viewModel.addTodo())
        XCTAssertEqual(viewModel.items.map(\.title), ["Buy milk"])
        XCTAssertEqual(viewModel.items.first?.category, .shopping)
        XCTAssertTrue(viewModel.draftTitle.isEmpty)
        XCTAssertEqual(viewModel.incompleteItems.count, 1)
    }

    func testAddTodoIgnoresBlankTitles() {
        let viewModel = TodoHomePageViewModel(defaults: makeDefaults())
        TestLifetime.retain(viewModel)
        viewModel.draftTitle = "   "

        XCTAssertFalse(viewModel.addTodo())
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testToggleCompletesAndClearCompletedRemovesThem() throws {
        let viewModel = TodoHomePageViewModel(defaults: makeDefaults())
        TestLifetime.retain(viewModel)

        viewModel.addTodo(title: "Call dentist")
        let item = try XCTUnwrap(viewModel.items.first)

        viewModel.toggle(item)

        XCTAssertTrue(viewModel.items.first?.isCompleted ?? false)
        XCTAssertTrue(viewModel.incompleteItems.isEmpty)
        XCTAssertEqual(viewModel.completedItems.count, 1)

        viewModel.clearCompleted()

        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testDeleteRemovesItem() throws {
        let viewModel = TodoHomePageViewModel(defaults: makeDefaults())
        TestLifetime.retain(viewModel)
        viewModel.addTodo(title: "Ship feature")
        let item = try XCTUnwrap(viewModel.items.first)

        viewModel.delete(item)

        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testPersistsTodosAcrossViewModelInstances() {
        let defaults = makeDefaults()
        let first = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(first)
        first.addTodo(title: "Write tests", category: .work)

        let second = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(second)

        XCTAssertEqual(second.items.map(\.title), ["Write tests"])
        XCTAssertEqual(second.items.first?.category, .work)
    }

    func testSortsAndFiltersByWhatTheTaskIsFor() throws {
        let viewModel = TodoHomePageViewModel(defaults: makeDefaults())
        TestLifetime.retain(viewModel)

        viewModel.addTodo(title: "Buy milk", category: .shopping)
        viewModel.addTodo(title: "Ship feature", category: .work)
        viewModel.addTodo(title: "Call mom", category: .personal)

        viewModel.categoryFilter = .all
        XCTAssertEqual(viewModel.displayedItems.map(\.title), ["Ship feature", "Call mom", "Buy milk"])
        XCTAssertEqual(viewModel.displayedSections.map(\.category), [.work, .personal, .shopping])

        viewModel.categoryFilter = .work
        XCTAssertEqual(viewModel.displayedItems.map(\.title), ["Ship feature"])

        let shoppingItem = try XCTUnwrap(viewModel.items.first { $0.title == "Buy milk" })
        viewModel.setCategory(.home, for: shoppingItem)
        viewModel.categoryFilter = .home
        XCTAssertEqual(viewModel.displayedItems.map(\.title), ["Buy milk"])
    }

    func testPersistsCategoryFilterAcrossViewModelInstances() {
        let defaults = makeDefaults()
        let first = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(first)
        first.categoryFilter = .school

        let second = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(second)

        XCTAssertEqual(second.categoryFilter, .school)
    }

    func testDecodesTodosWithoutAStoredCategoryAsGeneral() throws {
        let defaults = makeDefaults()
        let legacyItem = """
        [{"id":"A1B2C3D4-E5F6-7890-ABCD-EF1234567890","title":"Legacy task","isCompleted":false,"createdAt":0}]
        """.data(using: .utf8)
        defaults.set(legacyItem, forKey: TodoHomePageViewModel.storageKey)

        let viewModel = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(viewModel)

        XCTAssertEqual(viewModel.items.first?.title, "Legacy task")
        XCTAssertEqual(viewModel.items.first?.category, .general)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "DynamicNotch.TodoHomePageViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
