import SwiftUI

struct ChecklistPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ChecklistDraft
    let onSave: (ChecklistDraft) -> Void

    @State private var editingTitle: String
    @State private var selectedCategory: Category
    @State private var editingItemIndex: Int?
    @State private var editingItemName: String = ""
    @State private var editingItemNote: String = ""
    @State private var editingItemPriority: Priority? = .medium

    init(draft: ChecklistDraft, onSave: @escaping (ChecklistDraft) -> Void) {
        self._draft = State(initialValue: draft)
        self.onSave = onSave
        self._editingTitle = State(initialValue: draft.title)
        self._selectedCategory = State(initialValue: draft.category)
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
                        Text("タップで編集・長押しで削除")
                            .font(.caption)
                            .foregroundStyle(Color.neumorphicTextTertiary)
                    }
                    .padding(NeumorphicSpacing.md)
                }
            }
            .navigationTitle("プレビュー")
            .sheet(item: $editingItemIndex) { index in
                itemEditSheet(index)
            }
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
                        var finalDraft = draft
                        finalDraft.title = editingTitle
                        finalDraft.category = selectedCategory
                        onSave(finalDraft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        (editingTitle.isEmpty || draft.items.isEmpty)
                            ? Color.neumorphicTextTertiary
                            : Color.accentOrangeStart
                    )
                    .disabled(editingTitle.isEmpty || draft.items.isEmpty)
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

                Text("\(draft.items.count)件")
                    .font(.subheadline)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }
            .padding(.horizontal, NeumorphicSpacing.md)
            .padding(.top, NeumorphicSpacing.md)

            Divider()
                .padding(.horizontal, NeumorphicSpacing.md)

            ForEach(Array(draft.items.enumerated()), id: \.element.id) { index, item in
                previewItemRow(item)
                    .padding(.horizontal, NeumorphicSpacing.md)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingItemName = item.name
                        editingItemNote = item.note ?? ""
                        editingItemPriority = item.priority
                        editingItemIndex = index
                    }
                    .contextMenu {
                        Button {
                            editingItemName = item.name
                            editingItemNote = item.note ?? ""
                            editingItemPriority = item.priority
                            editingItemIndex = index
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            draft.items.remove(at: index)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }

                if index < draft.items.count - 1 {
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

    private func itemEditSheet(_ index: Int) -> some View {
        NavigationStack {
            ZStack {
                Color.neumorphicBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NeumorphicSpacing.md) {
                        // Item name
                        VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                            Text("項目名")
                                .font(.caption)
                                .foregroundStyle(Color.neumorphicTextTertiary)

                            NeumorphicTextField(
                                placeholder: "項目名",
                                text: $editingItemName,
                                icon: "checkmark.circle"
                            )
                        }

                        // Note
                        VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                            Text("メモ（任意）")
                                .font(.caption)
                                .foregroundStyle(Color.neumorphicTextTertiary)

                            NeumorphicTextField(
                                placeholder: "補足説明",
                                text: $editingItemNote,
                                icon: "note.text"
                            )
                        }

                        // Priority
                        VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                            Text("優先度")
                                .font(.caption)
                                .foregroundStyle(Color.neumorphicTextTertiary)

                            HStack(spacing: NeumorphicSpacing.sm) {
                                // Priority none option
                                NoPriorityChipButton(
                                    isSelected: editingItemPriority == nil
                                ) {
                                    editingItemPriority = nil
                                }

                                ForEach([Priority.high, Priority.medium, Priority.low], id: \.self) { priority in
                                    PriorityChipButton(
                                        priority: priority,
                                        isSelected: editingItemPriority == priority
                                    ) {
                                        editingItemPriority = priority
                                    }
                                }
                            }
                        }
                    }
                    .padding(NeumorphicSpacing.md)
                }
            }
            .navigationTitle("項目を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        editingItemIndex = nil
                    }
                    .foregroundStyle(Color.neumorphicTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        if index < draft.items.count {
                            draft.items[index].name = editingItemName
                            draft.items[index].note = editingItemNote.isEmpty ? nil : editingItemNote
                            draft.items[index].priority = editingItemPriority
                        }
                        editingItemIndex = nil
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        editingItemName.isEmpty
                            ? Color.neumorphicTextTertiary
                            : Color.accentOrangeStart
                    )
                    .disabled(editingItemName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func previewItemRow(_ item: ChecklistDraft.ItemDraft) -> some View {
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

            // Priority badge (only show if priority is set)
            if let priority = item.priority {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.priority(priority))
                        .frame(width: 6, height: 6)

                    Text(priority.description)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.priority(priority))
                .padding(.horizontal, NeumorphicSpacing.sm)
                .padding(.vertical, NeumorphicSpacing.xxs)
                .background(
                    Capsule()
                        .fill(Color.priority(priority).opacity(0.12))
                )
            }
        }
        .padding(.vertical, NeumorphicSpacing.xs)
    }
}

// Make Int conform to Identifiable for sheet(item:)
extension Int: @retroactive Identifiable {
    public var id: Int { self }
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

struct NoPriorityChipButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "minus.circle")
                    .font(.caption)

                Text("なし")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : Color.neumorphicTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(
                isSelected ? Color.neumorphicTextSecondary : Color.neumorphicBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.sm))
        }
        .buttonStyle(.plain)
    }
}

struct PriorityChipButton: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.priority(priority))
                    .frame(width: 8, height: 8)

                Text(priority.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : Color.neumorphicTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(priorityBackground)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.sm))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var priorityBackground: some View {
        if isSelected {
            Color.priority(priority)
        } else {
            Color.neumorphicBackground
        }
    }
}
