import Foundation
import CoreData

/// Lightweight DTO for checklist data before persisting to CoreData.
/// Used by AI service, text recognition, and the create flow.
struct ChecklistDraft {
    var title: String
    var category: Category
    var items: [ItemDraft]
    var inputSource: InputSource

    struct ItemDraft: Identifiable {
        let id = UUID()
        var name: String
        var note: String?
        var priority: Priority?
        var order: Int
    }

    /// Save this draft into CoreData
    @discardableResult
    func save(to context: NSManagedObjectContext) -> CDChecklist {
        let checklist = CDChecklist.create(
            in: context,
            title: title,
            category: category,
            inputSource: inputSource
        )

        if let privateStore = CoreDataStack.shared.privatePersistentStore {
            context.assign(checklist, to: privateStore)
        }

        for itemDraft in items {
            let item = CDChecklistItem.create(
                in: context,
                name: itemDraft.name,
                note: itemDraft.note,
                isCompleted: false,
                priority: itemDraft.priority,
                order: Int32(itemDraft.order)
            )
            item.checklist = checklist
        }

        return checklist
    }
}
