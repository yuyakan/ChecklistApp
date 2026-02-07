import Foundation
import SwiftData

@Model
class ChecklistItemModel {
    var id: UUID = UUID()
    var name: String = ""
    var note: String? = nil
    var isCompleted: Bool = false
    var priorityRaw: String = ""
    var order: Int = 0

    var checklist: Checklist?

    var priority: Priority? {
        get {
            priorityRaw.isEmpty ? nil : Priority(rawValue: priorityRaw)
        }
        set {
            priorityRaw = newValue?.rawValue ?? ""
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        note: String? = nil,
        isCompleted: Bool = false,
        priority: Priority? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.isCompleted = isCompleted
        self.priorityRaw = priority?.rawValue ?? ""
        self.order = order
    }
}
