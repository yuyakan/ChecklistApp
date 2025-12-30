import Foundation
import FoundationModels

// MARK: - Checklist Extraction (入力からチェックリスト抽出)

@Generable
struct ChecklistExtraction {
    @Guide(description: "入力から抽出したチェックリスト項目の配列")
    var items: [String]

    @Guide(description: "チェックリストのタイトル（推測）")
    var suggestedTitle: String

    @Guide(description: "カテゴリ: shopping, task, procedure, travel, cooking, other のいずれか")
    var category: String
}

// MARK: - Checklist Generation (条件からチェックリスト生成)

@Generable
struct ChecklistGeneration {
    @Guide(description: "生成されたチェックリスト項目")
    var items: [GeneratedChecklistItem]

    @Guide(description: "チェックリストのタイトル")
    var title: String

    @Guide(description: "補足説明やアドバイス")
    var tips: String?

    @Guide(description: "カテゴリ: shopping, task, procedure, travel, cooking, other のいずれか")
    var category: String
}

@Generable
struct GeneratedChecklistItem {
    @Guide(description: "項目名")
    var name: String

    @Guide(description: "項目の補足説明（任意）")
    var note: String?

    @Guide(description: "優先度: high, medium, low のいずれか")
    var priority: String
}

// MARK: - Helper Extensions

extension ChecklistExtraction {
    func toCategory() -> Category {
        Category(rawValue: category) ?? .other
    }
}

extension ChecklistGeneration {
    func toCategory() -> Category {
        Category(rawValue: category) ?? .other
    }
}

extension GeneratedChecklistItem {
    func toPriority() -> Priority {
        Priority(rawValue: priority) ?? .medium
    }

    func toChecklistItemModel(order: Int) -> ChecklistItemModel {
        ChecklistItemModel(
            name: name,
            note: note,
            isCompleted: false,
            priority: toPriority(),
            order: order
        )
    }
}
