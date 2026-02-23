import Foundation
import SwiftUI
import CoreData
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
    @Published var selectedPriority: Priority? = nil
    @Published var itemNote = ""
    @Published var isLiveActivityActive = false

    let checklist: CDChecklist
    private var cancellables = Set<AnyCancellable>()

    init(checklist: CDChecklist) {
        self.checklist = checklist
        self.editingTitle = checklist.wrappedTitle
        self.isLiveActivityActive = LiveActivityService.shared.isActivityActive(for: checklist.wrappedId)

        // Live Activityの状態変化を監視
        observeLiveActivityDismissal()
    }

    /// Live Activityの状態を更新
    func refreshLiveActivityState() {
        isLiveActivityActive = LiveActivityService.shared.isActivityActive(for: checklist.wrappedId)
    }

    /// Live Activityがロック画面から消去された場合の監視
    private func observeLiveActivityDismissal() {
        LiveActivityService.shared.$dismissedChecklistId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dismissedId in
                guard let self = self,
                      let dismissedId = dismissedId,
                      dismissedId == self.checklist.wrappedId else { return }

                // トグルをオフにする
                self.isLiveActivityActive = false
            }
            .store(in: &cancellables)
    }

    /// Live Activityの表示を切り替え
    func toggleLiveActivity() {
        if isLiveActivityActive {
            LiveActivityService.shared.endActivity(for: checklist.wrappedId)
            isLiveActivityActive = false
        } else {
            LiveActivityService.shared.startActivity(for: checklist)
            isLiveActivityActive = true
        }
    }

    func toggleItem(_ item: CDChecklistItem) {
        item.isCompleted.toggle()
        checklist.updatedAt = Date()
        try? checklist.managedObjectContext?.save()
        reloadWidget()

        // Live Activityがアクティブなら更新
        if isLiveActivityActive {
            if checklist.isCompleted {
                // チェックリスト完了時はLive Activityを終了
                LiveActivityService.shared.completeActivity(for: checklist)
                isLiveActivityActive = false
            } else {
                // 通常の更新
                LiveActivityService.shared.updateActivity(for: checklist)
            }
        }
    }

    func addItem() {
        guard !newItemName.isEmpty else { return }
        guard let context = checklist.managedObjectContext else { return }

        let item = CDChecklistItem.create(
            in: context,
            name: newItemName,
            note: itemNote.isEmpty ? nil : itemNote,
            isCompleted: false,
            priority: selectedPriority,
            order: Int32(checklist.totalCount)
        )

        checklist.addToItems(item)
        checklist.updatedAt = Date()
        try? context.save()

        resetNewItemFields()
        reloadWidget()

        // Live Activityがアクティブなら更新
        if isLiveActivityActive {
            LiveActivityService.shared.updateActivity(for: checklist)
        }
    }

    func deleteItem(_ item: CDChecklistItem) {
        checklist.removeItem(item)
        try? checklist.managedObjectContext?.save()
        reloadWidget()

        // Live Activityがアクティブなら更新
        if isLiveActivityActive {
            LiveActivityService.shared.updateActivity(for: checklist)
        }
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        checklist.moveItem(from: source, to: destination)
        try? checklist.managedObjectContext?.save()
    }

    func updateTitle() {
        guard !editingTitle.isEmpty else {
            editingTitle = checklist.wrappedTitle
            return
        }
        checklist.title = editingTitle
        checklist.updatedAt = Date()
        try? checklist.managedObjectContext?.save()
    }

    func updateItem(_ item: CDChecklistItem, name: String, note: String?, priority: Priority?) {
        item.name = name
        item.note = note
        item.priority = priority
        checklist.updatedAt = Date()
        try? checklist.managedObjectContext?.save()
    }

    func shareText() -> String {
        var text = "[\(checklist.wrappedTitle)]\n\n"

        for item in checklist.sortedItems {
            let checkMark = item.isCompleted ? "✓" : "○"
            text += "\(checkMark) \(item.wrappedName)"
            if let note = item.note, !note.isEmpty {
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
        selectedPriority = nil
        showingAddItem = false
    }

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
