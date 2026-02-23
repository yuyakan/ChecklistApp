import Foundation
import CoreData
import SwiftUI
import Combine
import WidgetKit

@MainActor
class HomeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: Category?
    @Published var showingCreateSheet = false
    @Published var showingSettings = false
    @Published var isSelecting = false
    @Published var selectedChecklistIDs: Set<NSManagedObjectID> = []
    @Published var showingDeleteConfirmation = false

    func toggleSelection(_ checklist: CDChecklist) {
        if selectedChecklistIDs.contains(checklist.objectID) {
            selectedChecklistIDs.remove(checklist.objectID)
        } else {
            selectedChecklistIDs.insert(checklist.objectID)
        }
    }

    func exitSelectionMode() {
        isSelecting = false
        selectedChecklistIDs.removeAll()
    }

    func deleteSelectedChecklists(from checklists: [CDChecklist], context: NSManagedObjectContext) {
        let toDelete = checklists.filter { selectedChecklistIDs.contains($0.objectID) }
        for checklist in toDelete {
            context.delete(checklist)
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        exitSelectionMode()
    }

    func filteredChecklists(_ checklists: [CDChecklist]) -> [CDChecklist] {
        var result = checklists

        // カテゴリフィルタ
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // 検索フィルタ
        if !searchText.isEmpty {
            result = result.filter { checklist in
                checklist.wrappedTitle.localizedCaseInsensitiveContains(searchText) ||
                checklist.itemsArray.contains { $0.wrappedName.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // 更新日時でソート（新しい順）
        return result.sorted { $0.wrappedUpdatedAt > $1.wrappedUpdatedAt }
    }

    func deleteChecklist(_ checklist: CDChecklist, context: NSManagedObjectContext) {
        context.delete(checklist)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
