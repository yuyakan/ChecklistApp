import Foundation
import SwiftData
 import SwiftUI
 import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: Category?
    @Published var showingCreateSheet = false
    @Published var showingSettings = false

    func filteredChecklists(_ checklists: [Checklist]) -> [Checklist] {
        var result = checklists

        // カテゴリフィルタ
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // 検索フィルタ
        if !searchText.isEmpty {
            result = result.filter { checklist in
                checklist.title.localizedCaseInsensitiveContains(searchText) ||
                checklist.items.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // 更新日時でソート（新しい順）
        return result.sorted { $0.updatedAt > $1.updatedAt }
    }

    func deleteChecklists(at offsets: IndexSet, from checklists: [Checklist], modelContext: ModelContext) {
        let filteredList = filteredChecklists(checklists)
        for index in offsets {
            let checklist = filteredList[index]
            modelContext.delete(checklist)
        }
    }
}
