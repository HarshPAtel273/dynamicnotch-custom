import SwiftUI

struct TodoHomePageNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @StateObject private var viewModel = TodoHomePageViewModel()
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                if viewModel.hasItems {
                    todoList
                } else {
                    emptyState
                }

                composer
            }
        }
        .padding(.horizontal, isDynamicIsland ? 2 : 4)
    }

    @ViewBuilder
    private var todoList: some View {
        VStack(spacing: 4) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.incompleteItems) { item in
                        todoRow(item)
                    }

                    ForEach(viewModel.completedItems) { item in
                        todoRow(item)
                    }
                }
            }
            .frame(maxHeight: 72)

            if !viewModel.completedItems.isEmpty {
                Button(action: viewModel.clearCompleted) {
                    Text(verbatim: "Clear Completed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 6)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.39, green: 0.66, blue: 0.96))

            Text(verbatim: "No to-dos yet")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .padding(.horizontal, 8)
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

    private func addTodo() {
        if viewModel.addTodo() {
            isComposerFocused = true
        }
    }
}
