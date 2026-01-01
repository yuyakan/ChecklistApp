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
            ZStack {
                Color.neumorphicBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NeumorphicSpacing.md) {
                        // Title and category card
                        titleCard

                        // Items preview card
                        itemsCard

                        // Footer hint
                        Text("長押しで削除できます")
                            .font(.caption)
                            .foregroundStyle(Color.neumorphicTextTertiary)
                    }
                    .padding(NeumorphicSpacing.md)
                }
            }
            .navigationTitle("プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundStyle(Color.neumorphicTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        checklist.title = editingTitle
                        checklist.category = selectedCategory
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        (editingTitle.isEmpty || checklist.items.isEmpty)
                            ? Color.neumorphicTextTertiary
                            : Color.accentOrangeStart
                    )
                    .disabled(editingTitle.isEmpty || checklist.items.isEmpty)
                }
            }
        }
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.md) {
            Text("基本情報")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neumorphicTextPrimary)

            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                Text("タイトル")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)

                NeumorphicTextField(
                    placeholder: "タイトル",
                    text: $editingTitle,
                    icon: "text.alignleft"
                )
            }

            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                Text("カテゴリ")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)

                HStack(spacing: NeumorphicSpacing.xs) {
                    ForEach(Category.allCases, id: \.self) { category in
                        CategoryChipButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            HStack {
                Text("項目")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Spacer()

                Text("\(checklist.items.count)件")
                    .font(.subheadline)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }
            .padding(.horizontal, NeumorphicSpacing.md)
            .padding(.top, NeumorphicSpacing.md)

            Divider()
                .padding(.horizontal, NeumorphicSpacing.md)

            ForEach(checklist.sortedItems) { item in
                previewItemRow(item)
                    .padding(.horizontal, NeumorphicSpacing.md)
                    .contextMenu {
                        Button(role: .destructive) {
                            checklist.removeItem(item)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }

                if item.id != checklist.sortedItems.last?.id {
                    Divider()
                        .padding(.horizontal, NeumorphicSpacing.lg)
                }
            }

            Spacer()
                .frame(height: NeumorphicSpacing.md)
        }
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private func previewItemRow(_ item: ChecklistItemModel) -> some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(Color.neumorphicTextTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.neumorphicTextSecondary)
                }
            }

            Spacer()

            // Priority badge
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.priority(item.priority))
                    .frame(width: 6, height: 6)

                Text(item.priority.description)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.priority(item.priority))
            .padding(.horizontal, NeumorphicSpacing.sm)
            .padding(.vertical, NeumorphicSpacing.xxs)
            .background(
                Capsule()
                    .fill(Color.priority(item.priority).opacity(0.12))
            )
        }
        .padding(.vertical, NeumorphicSpacing.xs)
    }
}

struct CategoryChipButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                Text(category.description)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .white : Color.neumorphicTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(categoryBackground)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.sm))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var categoryBackground: some View {
        if isSelected {
            Color.orangeGradient
        } else {
            Color.neumorphicBackground
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
