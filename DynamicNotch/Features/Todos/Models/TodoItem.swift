import Foundation

struct TodoItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    var category: TodoCategory

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        category: TodoCategory = .general
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        category = try container.decodeIfPresent(TodoCategory.self, forKey: .category) ?? .general
    }
}
