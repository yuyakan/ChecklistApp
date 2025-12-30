 import SwiftUI

struct ChecklistPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let checklist: Checklist
    let onSave: () -> Void

    @State private var editingTitle: String
    @State private var selectedCategory: Category

    init(checklist: Checklist, onSave: @escaping () -> Void) {
        self.checklist = checklist
        self.onSave = onSave
        self._editingTitle = State(initialValue: checklist.title)
        self._selectedCategory = State(initialValue: checklist.category)
    }

    var body: some View {
        NavigationStack {
            List {
                // タイトルセクション
                Section {
                    TextField("タイトル", text: $editingTitle)

                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.description, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                // 項目プレビュー
                Section {
                    ForEach(checklist.sortedItems) { item in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.body)

                                if let note = item.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            // 優先度表示
                            priorityBadge(item.priority)
                        }
                    }
                    .onDelete { offsets in
                        let sortedItems = checklist.sortedItems
                        for index in offsets {
                            checklist.removeItem(sortedItems[index])
                        }
                    }
                    .onMove { source, destination in
                        checklist.moveItem(from: source, to: destination)
                    }
                } header: {
                    Text("項目 (\(checklist.items.count)件)")
                } footer: {
                    Text("スワイプで削除、長押しで並び替えができます")
                }
            }
            .navigationTitle("プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        checklist.title = editingTitle
                        checklist.category = selectedCategory
                        onSave()
                    }
                    .disabled(editingTitle.isEmpty || checklist.items.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    @ViewBuilder
    private func priorityBadge(_ priority: Priority) -> some View {
        Text(priority.description)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor(priority).opacity(0.2))
            .foregroundStyle(priorityColor(priority))
            .clipShape(Capsule())
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
}

#Preview {
    let checklist = Checklist(
        title: "買い物リスト",
        category: .shopping,
        items: [
            ChecklistItemModel(name: "牛乳", note: "低脂肪のもの", priority: .high, order: 0),
            ChecklistItemModel(name: "卵", priority: .medium, order: 1),
            ChecklistItemModel(name: "パン", priority: .low, order: 2)
        ]
    )

    return ChecklistPreviewView(checklist: checklist) {
        print("Saved")
    }
}
