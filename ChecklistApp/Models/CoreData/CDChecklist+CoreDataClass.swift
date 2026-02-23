import Foundation
import CoreData

@objc(CDChecklist)
public class CDChecklist: NSManagedObject {

    // MARK: - Convenience Properties

    var wrappedTitle: String {
        get { title ?? "" }
        set { title = newValue }
    }

    var wrappedId: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }

    var category: Category {
        get { Category(rawValue: categoryRaw ?? "other") ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var inputSource: InputSource {
        get { InputSource(rawValue: inputSourceRaw ?? "text") ?? .text }
        set { inputSourceRaw = newValue.rawValue }
    }

    var wrappedCreatedAt: Date {
        get { createdAt ?? Date() }
        set { createdAt = newValue }
    }

    var wrappedUpdatedAt: Date {
        get { updatedAt ?? Date() }
        set { updatedAt = newValue }
    }

    var wrappedOwnerName: String {
        get { ownerName ?? "" }
        set { ownerName = newValue }
    }

    var itemsArray: [CDChecklistItem] {
        let set = items as? Set<CDChecklistItem> ?? []
        return Array(set)
    }

    var sortedItems: [CDChecklistItem] {
        itemsArray.sorted { $0.order < $1.order }
    }

    var completedCount: Int {
        itemsArray.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        itemsArray.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var isCompleted: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    // MARK: - Mutating Helpers

    func addItem(_ item: CDChecklistItem) {
        item.order = Int32(totalCount)
        addToItems(item)
        updatedAt = Date()
    }

    func removeItem(_ item: CDChecklistItem) {
        removeFromItems(item)
        item.managedObjectContext?.delete(item)
        reorderItems()
        updatedAt = Date()
    }

    func reorderItems() {
        for (index, item) in sortedItems.enumerated() {
            item.order = Int32(index)
        }
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        var sorted = sortedItems
        // Manual move implementation to avoid SwiftUI dependency
        let items = source.sorted().reversed().map { sorted.remove(at: $0) }.reversed()
        let insertionIndex = min(destination, sorted.count)
        sorted.insert(contentsOf: items, at: insertionIndex)
        for (index, item) in sorted.enumerated() {
            item.order = Int32(index)
        }
        updatedAt = Date()
    }

    // MARK: - Factory

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        id: UUID = UUID(),
        title: String,
        category: Category = .other,
        inputSource: InputSource = .text,
        isShared: Bool = false,
        ownerName: String = ""
    ) -> CDChecklist {
        let checklist = CDChecklist(context: context)
        checklist.id = id
        checklist.title = title
        checklist.categoryRaw = category.rawValue
        checklist.inputSourceRaw = inputSource.rawValue
        checklist.createdAt = Date()
        checklist.updatedAt = Date()
        checklist.isShared = isShared
        checklist.ownerName = ownerName
        return checklist
    }
}
