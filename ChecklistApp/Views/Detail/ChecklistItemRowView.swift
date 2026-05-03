import SwiftUI

struct ChecklistItemRowView: View {
    @ObservedObject var item: CDChecklistItem
    let onToggle: () -> Void
    let onUpdate: (String, String?, Priority?) -> Void
    let onDelete: () -> Void

    @State private var showingEditSheet = false
    @State private var editingName: String = ""
    @State private var editingNote: String = ""
    @State private var editingPriority: Priority? = nil

    var body: some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            // Neumorphic Checkbox
            NeumorphicCheckbox(isChecked: item.isCompleted) {
                onToggle()
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.wrappedName)
                    .font(.body)
                    .fontWeight(item.isCompleted ? .regular : .medium)
                    .strikethrough(item.isCompleted, color: Color.neumorphicTextTertiary)
                    .foregroundStyle(item.isCompleted ? Color.neumorphicTextTertiary : Color.neumorphicTextPrimary)
                    .animation(nil, value: item.isCompleted)

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.neumorphicTextSecondary)
                }
            }

            Spacer()

            // Priority badge (only show if priority is set)
            if item.priority != nil {
                priorityBadge
            }
        }
        .padding(.vertical, NeumorphicSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            prepareEditValues()
            showingEditSheet = true
        }
        .contextMenu {
            Button {
                prepareEditValues()
                showingEditSheet = true
            } label: {
                Label("編集", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            editSheet
                .iPadExpandedModalLayout()
        }
    }

    @ViewBuilder
    private var priorityBadge: some View {
        if let priority = item.priority {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.priority(priority))
                    .frame(width: 8, height: 8)

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

    private var editSheet: some View {
        NavigationStack {
            ZStack {
                Color.neumorphicBackground.ignoresSafeArea()

                VStack(spacing: NeumorphicSpacing.lg) {
                    // Item name field
                    VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                        Text("項目名")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.neumorphicTextSecondary)

                        NeumorphicTextField(
                            placeholder: L10n.tr("項目を入力..."),
                            text: $editingName,
                            icon: "checklist"
                        )
                    }

                    // Note field
                    VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                        Text("メモ（任意）")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.neumorphicTextSecondary)

                        NeumorphicTextField(
                            placeholder: L10n.tr("メモを入力..."),
                            text: $editingNote,
                            icon: "note.text"
                        )
                    }

                    // Priority picker
                    VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                        Text("優先度")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.neumorphicTextSecondary)

                        HStack(spacing: NeumorphicSpacing.sm) {
                            // None option
                            NeumorphicNoPriorityButton(
                                isSelected: editingPriority == nil
                            ) {
                                editingPriority = nil
                            }

                            ForEach(Priority.allCases, id: \.self) { priority in
                                NeumorphicPriorityButton(
                                    priority: priority,
                                    isSelected: editingPriority == priority
                                ) {
                                    editingPriority = priority
                                }
                            }
                        }
                    }

                    // Completion toggle
                    Button {
                        onToggle()
                    } label: {
                        HStack(spacing: NeumorphicSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(item.isCompleted ? Color.statusSuccess.opacity(0.15) : Color.neumorphicBackground)
                                    .frame(width: 44, height: 44)

                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(item.isCompleted ? Color.statusSuccess : Color.neumorphicTextSecondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("完了状態")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.neumorphicTextPrimary)

                                Text(item.isCompleted ? L10n.tr("完了済み") : L10n.tr("未完了"))
                                    .font(.caption)
                                    .foregroundStyle(Color.neumorphicTextTertiary)
                            }

                            Spacer()
                        }
                        .padding(NeumorphicSpacing.md)
                        .background(Color.neumorphicSurface)
                        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
                    }
                    .buttonStyle(.plain)
                    .neumorphicShadow(subtle: true)

                    Spacer()

                    // Save button
                    NeumorphicButton_Unified(
                        title: L10n.tr("保存"),
                        style: .accent,
                        isEnabled: !editingName.isEmpty
                    ) {
                        onUpdate(
                            editingName,
                            editingNote.isEmpty ? nil : editingNote,
                            editingPriority
                        )
                        showingEditSheet = false
                    }
                    .padding(.bottom, NeumorphicSpacing.md)
                }
                .padding(NeumorphicSpacing.lg)
            }
            .navigationTitle("項目を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingEditSheet = false
                    }
                    .foregroundStyle(Color.neumorphicTextSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .iPadExpandedModalLayout()
    }

    private func prepareEditValues() {
        editingName = item.wrappedName
        editingNote = item.note ?? ""
        editingPriority = item.priority
    }
}
