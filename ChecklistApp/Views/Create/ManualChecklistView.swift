import SwiftUI

struct ManualChecklistView: View {
    @ObservedObject var viewModel: CreateChecklistViewModel
    @State private var title = ""
    @State private var selectedCategory: Category = .task
    @State private var newItemName = ""
    @State private var newItemNote = ""
    @State private var newItemPriority: Priority?
    @State private var items: [ChecklistDraft.ItemDraft] = []
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case itemName
        case itemNote
    }

    var body: some View {
        VStack(spacing: NeumorphicSpacing.lg) {
            headerCard
            basicInfoCard
            itemComposerCard
            itemsCard

            NeumorphicAccentButton(
                title: "プレビュー",
                icon: "checklist",
                action: createChecklist,
                isDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || items.isEmpty
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
                .foregroundStyle(Color.accentOrangeStart)
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            Image(systemName: "square.and.pencil")
                .font(.title3)
                .foregroundStyle(Color.accentOrangeStart)

            VStack(alignment: .leading, spacing: 2) {
                Text("手動で作成")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Text("タイトルと項目を直接入力してリストを作成")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }

            Spacer()
        }
        .padding(.vertical, NeumorphicSpacing.xs)
    }

    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.md) {
            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                Text("タイトル")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)

                NeumorphicTextField(
                    placeholder: "例: 出張の持ち物",
                    text: $title,
                    icon: "text.alignleft"
                )
                .focused($focusedField, equals: .title)
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

    private var itemComposerCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.md) {
            Text("項目を追加")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.neumorphicTextPrimary)

            NeumorphicTextField(
                placeholder: "項目名",
                text: $newItemName,
                icon: "checkmark.circle"
            )
            .focused($focusedField, equals: .itemName)

            NeumorphicTextField(
                placeholder: "メモ（任意）",
                text: $newItemNote,
                icon: "note.text"
            )
            .focused($focusedField, equals: .itemNote)

            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                Text("優先度")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)

                HStack(spacing: NeumorphicSpacing.sm) {
                    NoPriorityChipButton(isSelected: newItemPriority == nil) {
                        newItemPriority = nil
                    }

                    ForEach(Priority.allCases, id: \.self) { priority in
                        PriorityChipButton(
                            priority: priority,
                            isSelected: newItemPriority == priority
                        ) {
                            newItemPriority = priority
                        }
                    }
                }
            }

            NeumorphicAccentButton(
                title: "項目を追加",
                icon: "plus",
                action: addItem,
                isDisabled: newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            HStack {
                Text("追加済みの項目")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Spacer()

                Text("\(items.count)件")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }

            if items.isEmpty {
                Text("項目を追加するとここに表示されます")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(NeumorphicSpacing.md)
                    .background(Color.neumorphicBackground)
                    .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
            } else {
                VStack(spacing: NeumorphicSpacing.sm) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        manualItemRow(index: index, item: item)
                    }
                }
            }
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private func manualItemRow(index: Int, item: ChecklistDraft.ItemDraft) -> some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.neumorphicTextTertiary)
                }
            }

            Spacer()

            if let priority = item.priority {
                Text(priority.description)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, NeumorphicSpacing.xs)
                    .padding(.vertical, 4)
                    .background(Color.priority(priority))
                    .clipShape(Capsule())
            }

            Button {
                items.remove(at: index)
                reindexItems()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Color.statusError)
                    .padding(NeumorphicSpacing.xs)
            }
            .buttonStyle(.plain)
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicBackground)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
    }

    private func addItem() {
        let trimmedName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let trimmedNote = newItemNote.trimmingCharacters(in: .whitespacesAndNewlines)
        items.append(
            ChecklistDraft.ItemDraft(
                name: trimmedName,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                priority: newItemPriority,
                order: items.count
            )
        )

        newItemName = ""
        newItemNote = ""
        newItemPriority = nil
        focusedField = .itemName
    }

    private func reindexItems() {
        items = items.enumerated().map { index, item in
            ChecklistDraft.ItemDraft(
                name: item.name,
                note: item.note,
                priority: item.priority,
                order: index
            )
        }
    }

    private func createChecklist() {
        focusedField = nil
        viewModel.createManualChecklist(
            title: title,
            category: selectedCategory,
            items: items
        )
    }
}

#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()
        ScrollView {
            ManualChecklistView(viewModel: CreateChecklistViewModel())
                .padding()
        }
    }
}
