import Foundation
import SwiftData
 import SwiftUI

@Model
class Checklist {
    var id: UUID
    var title: String
    var categoryRaw: String
    @Relationship(deleteRule: .cascade, inverse: \ChecklistItemModel.checklist)
    var items: [ChecklistItemModel]
    var createdAt: Date
    var updatedAt: Date
    var inputSourceRaw: String

    var category: Category {
        get {
            Category(rawValue: categoryRaw) ?? .other
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }

    var inputSource: InputSource {
        get {
            InputSource(rawValue: inputSourceRaw) ?? .text
        }
        set {
            inputSourceRaw = newValue.rawValue
        }
    }

    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        items.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var isCompleted: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    var sortedItems: [ChecklistItemModel] {
        items.sorted { $0.order < $1.order }
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: Category = .other,
        items: [ChecklistItemModel] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        inputSource: InputSource = .text
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.inputSourceRaw = inputSource.rawValue
    }

    func addItem(_ item: ChecklistItemModel) {
        item.order = items.count
        items.append(item)
        updatedAt = Date()
    }

    func removeItem(_ item: ChecklistItemModel) {
        items.removeAll { $0.id == item.id }
        reorderItems()
        updatedAt = Date()
    }

    func reorderItems() {
        for (index, item) in sortedItems.enumerated() {
            item.order = index
        }
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        var sortedItems = self.sortedItems
        sortedItems.move(fromOffsets: source, toOffset: destination)
        for (index, item) in sortedItems.enumerated() {
            item.order = index
        }
        updatedAt = Date()
    }
}
