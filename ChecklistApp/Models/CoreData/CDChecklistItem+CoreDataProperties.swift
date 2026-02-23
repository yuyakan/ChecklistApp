import Foundation
import CoreData

extension CDChecklistItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDChecklistItem> {
        return NSFetchRequest<CDChecklistItem>(entityName: "CDChecklistItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var note: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var priorityRaw: String?
    @NSManaged public var order: Int32
    @NSManaged public var checklist: CDChecklist?
}

extension CDChecklistItem: Identifiable {}
