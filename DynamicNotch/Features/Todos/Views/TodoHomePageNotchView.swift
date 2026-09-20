import SwiftUI

struct TodoHomePageNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @StateObject private var viewModel = TodoHomePageViewModel()
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            listToolbar

            if viewModel.hasVisibleItems {
                todoList
            } else {
                emptyState
            }

            composer
        }
        .padding(.top, 36)
        .padding(.horizontal, isDynamicIsland ? 2 : 4)
    }

    @ViewBuilder
    private var listToolbar: some View {
        HStack(spacing: 8) {
            sortByButton

            Spacer(minLength: 8)

            if !viewModel.completedItems.isEmpty {
                Button(action: viewModel.clearCompleted) {
                    Text(verbatim: "Clear")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private var sortByButton: some View {
        Menu {
            Picker("Sort by", selection: $viewModel.categoryFilter) {
                ForEach(TodoCategoryFilter.allCases) { filter in
                    Label(filter.title, systemImage: filter.systemImage)
                        .tag(filter)
                }
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 10, weight: .bold))

                Text(verbatim: "Sort by")
                    .font(.system(size: 11, weight: .semibold))

                Text(viewModel.categoryFilter.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.12))
            )
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .help("Sort to-dos by what they are for")
    }

    @ViewBuilder
    private var todoList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.displayedSections, id: \.category) { section in
                    if viewModel.categoryFilter == .all {
                        HStack(spacing: 6) {
                            Image(systemName: section.category.systemImage)
                                .font(.system(size: 9, weight: .bold))
                            Text(verbatim: section.category.title)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.horizontal, 8)
                    }

                    ForEach(section.items) { item in
                        todoRow(item)
                    }
                }
            }
        }
        .frame(maxHeight: 72)
    }

    @ViewBuilder
    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.categoryFilter.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.39, green: 0.66, blue: 0.96))

            Text(verbatim: emptyStateTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private var emptyStateTitle: String {
        if viewModel.hasItems {
            return "No \(viewModel.categoryFilter.title.lowercased()) to-dos"
        }
        return "No to-dos yet"
    }

    @ViewBuilder
    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 8) {
            Button {
                viewModel.toggle(item)
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        item.isCompleted
                            ? Color(red: 0.39, green: 0.66, blue: 0.96)
                            : .white.opacity(0.55)
                    )
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(item.isCompleted ? 0.4 : 0.9))
                .strikethrough(item.isCompleted, color: .white.opacity(0.35))
                .lineLimit(1)

            Spacer(minLength: 8)

            Menu {
                Picker("Category", selection: categoryBinding(for: item)) {
                    ForEach(TodoCategory.allCases) { category in
                        Label(category.title, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: item.category.systemImage)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .help(item.category.title)

            Button {
                viewModel.delete(item)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }

    @ViewBuilder
    private var composer: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("Category", selection: $viewModel.draftCategory) {
                    ForEach(TodoCategory.allCases) { category in
                        Label(category.title, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: viewModel.draftCategory.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.1))
                    )
            }
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .help("What this to-do is for")

            TextField("Add a to-do", text: $viewModel.draftTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .focused($isComposerFocused)
                .onSubmit {
                    addTodo()
                }

            Button(action: addTodo) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(
                PrimaryButtonStyle(
                    width: 32,
                    height: 32,
                    backgroundColor: Color(red: 0.39, green: 0.66, blue: 0.96).opacity(0.9)
                )
            )
            .disabled(viewModel.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(viewModel.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.1))
        )
    }

    private func categoryBinding(for item: TodoItem) -> Binding<TodoCategory> {
        Binding(
            get: {
                viewModel.items.first(where: { $0.id == item.id })?.category ?? item.category
            },
            set: { category in
                viewModel.setCategory(category, for: item)
            }
        )
    }

    private func addTodo() {
        if viewModel.addTodo() {
            isComposerFocused = true
        }
    }
}
