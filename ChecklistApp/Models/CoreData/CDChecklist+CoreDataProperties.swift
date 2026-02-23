import Foundation
import CoreData

extension CDChecklist {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDChecklist> {
        return NSFetchRequest<CDChecklist>(entityName: "CDChecklist")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var categoryRaw: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var inputSourceRaw: String?
    @NSManaged public var isShared: Bool
    @NSManaged public var ownerName: String?
    @NSManaged public var items: NSSet?
}

// MARK: Generated accessors for items
extension CDChecklist {
    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: CDChecklistItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: CDChecklistItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}

extension CDChecklist: Identifiable {}
