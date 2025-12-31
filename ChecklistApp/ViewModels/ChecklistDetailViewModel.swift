import Foundation
import SwiftUI
import Combine
import WidgetKit
import ActivityKit

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
        reloadWidget()
        updateLiveActivity(completedItem: item.isCompleted ? item.name : nil)
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
        reloadWidget()
        updateLiveActivity(completedItem: nil)
    }

    func deleteItems(at offsets: IndexSet) {
        let sortedItems = checklist.sortedItems
        for index in offsets {
            checklist.removeItem(sortedItems[index])
        }
        reloadWidget()
        updateLiveActivity(completedItem: nil)
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

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func updateLiveActivity(completedItem: String?) {
        if checklist.isCompleted {
            // すべて完了したらLive Activityを終了
            LiveActivityService.shared.completeActivity(for: checklist)
        } else {
            // 進捗を更新
            LiveActivityService.shared.updateActivity(for: checklist, lastCompletedItem: completedItem)
        }
    }

    /// Live Activityを開始
    func startLiveActivity() {
        LiveActivityService.shared.startActivity(for: checklist)
    }

    /// Live Activityを終了
    func endLiveActivity() {
        LiveActivityService.shared.endActivity(for: checklist.id)
    }
}
