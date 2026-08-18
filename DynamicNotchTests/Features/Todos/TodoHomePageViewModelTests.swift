import XCTest
@testable import DynamicNotch

@MainActor
final class TodoHomePageViewModelTests: XCTestCase {
    func testAddTodoInsertsTrimmedItemAndClearsDraft() {
        let defaults = makeDefaults()
        let viewModel = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(viewModel)
        viewModel.draftTitle = "  Buy milk  "

        XCTAssertTrue(viewModel.addTodo())
        XCTAssertEqual(viewModel.items.map(\.title), ["Buy milk"])
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
        first.addTodo(title: "Write tests")

        let second = TodoHomePageViewModel(defaults: defaults)
        TestLifetime.retain(second)

        XCTAssertEqual(second.items.map(\.title), ["Write tests"])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "DynamicNotch.TodoHomePageViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
