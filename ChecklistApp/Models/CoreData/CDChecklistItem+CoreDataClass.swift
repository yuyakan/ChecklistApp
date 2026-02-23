import Foundation
import CoreData

@objc(CDChecklistItem)
public class CDChecklistItem: NSManagedObject {

    var wrappedId: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }

    var wrappedName: String {
        get { name ?? "" }
        set { name = newValue }
    }

    var priority: Priority? {
        get {
            guard let raw = priorityRaw, !raw.isEmpty else { return nil }
            return Priority(rawValue: raw)
        }
        set {
            priorityRaw = newValue?.rawValue ?? ""
        }
    }

    // MARK: - Factory

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        id: UUID = UUID(),
        name: String,
        note: String? = nil,
        isCompleted: Bool = false,
        priority: Priority? = nil,
        order: Int32 = 0
    ) -> CDChecklistItem {
        let item = CDChecklistItem(context: context)
        item.id = id
        item.name = name
        item.note = note
        item.isCompleted = isCompleted
        item.priorityRaw = priority?.rawValue ?? ""
        item.order = order
        return item
    }
}
