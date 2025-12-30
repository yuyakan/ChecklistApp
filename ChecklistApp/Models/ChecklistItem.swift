import Foundation
import SwiftData

@Model
class ChecklistItemModel {
    var id: UUID
    var name: String
    var note: String?
    var isCompleted: Bool
    var priorityRaw: String
    var order: Int

    var checklist: Checklist?

    var priority: Priority {
        get {
            Priority(rawValue: priorityRaw) ?? .medium
        }
        set {
            priorityRaw = newValue.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        note: String? = nil,
        isCompleted: Bool = false,
        priority: Priority = .medium,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.isCompleted = isCompleted
        self.priorityRaw = priority.rawValue
        self.order = order
    }
}
