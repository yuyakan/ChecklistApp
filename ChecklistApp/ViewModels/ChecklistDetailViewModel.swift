import Foundation
 import SwiftUI
 import Combine

@MainActor
class ChecklistDetailViewModel: ObservableObject {
    @Published var isEditing = false
    @Published var editingTitle = ""
    @Published var newItemName = ""
    @Published var showingAddItem = false
    @Published var showingShareSheet = false
    @Published var selectedPriority: Priority = .medium
    @Published var itemNote = ""

    let checklist: Checklist

    init(checklist: Checklist) {
        self.checklist = checklist
        self.editingTitle = checklist.title
    }

    func toggleItem(_ item: ChecklistItemModel) {
        item.isCompleted.toggle()
        checklist.updatedAt = Date()
    }

    func addItem() {
        guard !newItemName.isEmpty else { return }

        let item = ChecklistItemModel(
            name: newItemName,
            note: itemNote.isEmpty ? nil : itemNote,
            isCompleted: false,
            priority: selectedPriority,
            order: checklist.items.count
        )

        checklist.addItem(item)
        resetNewItemFields()
    }

    func deleteItems(at offsets: IndexSet) {
        let sortedItems = checklist.sortedItems
        for index in offsets {
            checklist.removeItem(sortedItems[index])
        }
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        checklist.moveItem(from: source, to: destination)
    }

    func updateTitle() {
        guard !editingTitle.isEmpty else {
            editingTitle = checklist.title
            return
        }
        checklist.title = editingTitle
        checklist.updatedAt = Date()
    }

    func updateItem(_ item: ChecklistItemModel, name: String, note: String?, priority: Priority) {
        item.name = name
        item.note = note
        item.priority = priority
        checklist.updatedAt = Date()
    }

    func shareText() -> String {
        var text = "[\(checklist.title)]\n\n"

        for item in checklist.sortedItems {
            let checkMark = item.isCompleted ? "✓" : "○"
            text += "\(checkMark) \(item.name)"
            if let note = item.note {
                text += " (\(note))"
            }
            text += "\n"
        }

        text += "\n進捗: \(checklist.completedCount)/\(checklist.totalCount)"
        return text
    }

    private func resetNewItemFields() {
        newItemName = ""
        itemNote = ""
        selectedPriority = .medium
        showingAddItem = false
    }
}
