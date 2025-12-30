 import SwiftUI

struct ChecklistItemRowView: View {
    let item: ChecklistItemModel
    let onToggle: () -> Void
    let onUpdate: (String, String?, Priority) -> Void

    @State private var showingEditSheet = false
    @State private var editingName: String = ""
    @State private var editingNote: String = ""
    @State private var editingPriority: Priority = .medium

    var body: some View {
        HStack(spacing: 12) {
            // チェックボックス
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // コンテンツ
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 優先度バッジ
            priorityBadge
        }
        .contentShape(Rectangle())
        .onTapGesture {
            prepareEditValues()
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            editSheet
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            Text(item.priority.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var priorityColor: Color {
        switch item.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("項目名", text: $editingName)
                    TextField("メモ（任意）", text: $editingNote)
                }

                Section("優先度") {
                    Picker("優先度", selection: $editingPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(colorForPriority(priority))
                                    .frame(width: 10, height: 10)
                                Text(priority.description)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Toggle("完了", isOn: Binding(
                        get: { item.isCompleted },
                        set: { _ in onToggle() }
                    ))
                }
            }
            .navigationTitle("項目を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingEditSheet = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onUpdate(
                            editingName,
                            editingNote.isEmpty ? nil : editingNote,
                            editingPriority
                        )
                        showingEditSheet = false
                    }
                    .disabled(editingName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func prepareEditValues() {
        editingName = item.name
        editingNote = item.note ?? ""
        editingPriority = item.priority
    }

    private func colorForPriority(_ priority: Priority) -> Color {
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
    List {
        ChecklistItemRowView(
            item: ChecklistItemModel(name: "牛乳を買う", note: "低脂肪のもの", isCompleted: false, priority: .high, order: 0),
            onToggle: {},
            onUpdate: { _, _, _ in }
        )

        ChecklistItemRowView(
            item: ChecklistItemModel(name: "完了した項目", isCompleted: true, priority: .low, order: 1),
            onToggle: {},
            onUpdate: { _, _, _ in }
        )
    }
}
