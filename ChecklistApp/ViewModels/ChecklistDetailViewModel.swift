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
    @Published var selectedPriority: Priority? = nil
    @Published var itemNote = ""
    @Published var isLiveActivityActive = false

    let checklist: Checklist
    private var cancellables = Set<AnyCancellable>()

    init(checklist: Checklist) {
        self.checklist = checklist
        self.editingTitle = checklist.title
        self.isLiveActivityActive = LiveActivityService.shared.isActivityActive(for: checklist.id)

        // Live Activityの状態変化を監視
        observeLiveActivityDismissal()
    }

    /// Live Activityの状態を更新
    func refreshLiveActivityState() {
        isLiveActivityActive = LiveActivityService.shared.isActivityActive(for: checklist.id)
    }

    /// Live Activityがロック画面から消去された場合の監視
    private func observeLiveActivityDismissal() {
        LiveActivityService.shared.$dismissedChecklistId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dismissedId in
                guard let self = self,
                      let dismissedId = dismissedId,
                      dismissedId == self.checklist.id else { return }

                // トグルをオフにする
                self.isLiveActivityActive = false
            }
            .store(in: &cancellables)
    }

    /// Live Activityの表示を切り替え
    func toggleLiveActivity() {
        if isLiveActivityActive {
            LiveActivityService.shared.endActivity(for: checklist.id)
            isLiveActivityActive = false
        } else {
            LiveActivityService.shared.startActivity(for: checklist)
            isLiveActivityActive = true
        }
    }

    func toggleItem(_ item: ChecklistItemModel) {
        item.isCompleted.toggle()
        checklist.updatedAt = Date()
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

        // Live Activityがアクティブなら更新
        if isLiveActivityActive {
            LiveActivityService.shared.updateActivity(for: checklist)
        }
    }

    func deleteItems(at offsets: IndexSet) {
        let sortedItems = checklist.sortedItems
        for index in offsets {
            checklist.removeItem(sortedItems[index])
        }
        reloadWidget()

        // Live Activityがアクティブなら更新
        if isLiveActivityActive {
            LiveActivityService.shared.updateActivity(for: checklist)
        }
    }

    func deleteItem(_ item: ChecklistItemModel) {
        checklist.removeItem(item)
        reloadWidget()

        // Live Activityがアクティブなら更新
        if isLiveActivityActive {
            LiveActivityService.shared.updateActivity(for: checklist)
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

    func updateItem(_ item: ChecklistItemModel, name: String, note: String?, priority: Priority?) {
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
        selectedPriority = nil
        showingAddItem = false
    }

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
