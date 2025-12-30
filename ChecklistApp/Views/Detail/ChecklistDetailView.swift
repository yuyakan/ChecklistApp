 import SwiftUI
import UIKit
import SwiftData

struct ChecklistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ChecklistDetailViewModel
    @State private var showingShareSheet = false

    let checklist: Checklist

    init(checklist: Checklist) {
        self.checklist = checklist
        self._viewModel = StateObject(wrappedValue: ChecklistDetailViewModel(checklist: checklist))
    }

    var body: some View {
        List {
            // 進捗セクション
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Text("進捗")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(checklist.completedCount)/\(checklist.totalCount)")
                            .font(.headline)
                            .monospacedDigit()
                    }

                    ProgressView(value: checklist.progress)
                        .tint(progressColor)

                    if checklist.isCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("完了!")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // チェックリスト項目
            Section {
                ForEach(checklist.sortedItems) { item in
                    ChecklistItemRowView(
                        item: item,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleItem(item)
                            }
                        },
                        onUpdate: { name, note, priority in
                            viewModel.updateItem(item, name: name, note: note, priority: priority)
                        }
                    )
                }
                .onDelete(perform: viewModel.deleteItems)
                .onMove(perform: viewModel.moveItems)

                // 新規項目追加
                Button {
                    viewModel.showingAddItem = true
                } label: {
                    Label("項目を追加", systemImage: "plus.circle")
                }
            } header: {
                Text("項目")
            }

            // 情報セクション
            Section {
                LabeledContent("カテゴリ") {
                    Label(checklist.category.description, systemImage: checklist.category.icon)
                }

                LabeledContent("作成方法") {
                    Label(checklist.inputSource.description, systemImage: checklist.inputSource.icon)
                }

                LabeledContent("作成日") {
                    Text(checklist.createdAt.formatted(date: .abbreviated, time: .shortened))
                }

                LabeledContent("更新日") {
                    Text(checklist.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
            } header: {
                Text("情報")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(checklist.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.isEditing.toggle()
                    } label: {
                        Label("タイトルを編集", systemImage: "pencil")
                    }

                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        modelContext.delete(checklist)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .alert("タイトルを編集", isPresented: $viewModel.isEditing) {
            TextField("タイトル", text: $viewModel.editingTitle)
            Button("キャンセル", role: .cancel) {
                viewModel.editingTitle = checklist.title
            }
            Button("保存") {
                viewModel.updateTitle()
            }
        }
        .sheet(isPresented: $viewModel.showingAddItem) {
            AddItemSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(text: viewModel.shareText())
        }
    }

    private var progressColor: Color {
        if checklist.isCompleted {
            return .green
        } else if checklist.progress > 0.5 {
            return .blue
        } else if checklist.progress > 0 {
            return .orange
        } else {
            return .gray
        }
    }
}

// MARK: - Add Item Sheet

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChecklistDetailViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("項目名", text: $viewModel.newItemName)
                    TextField("メモ（任意）", text: $viewModel.itemNote)
                }

                Section {
                    Picker("優先度", selection: $viewModel.selectedPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.description).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("項目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        viewModel.addItem()
                        dismiss()
                    }
                    .disabled(viewModel.newItemName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let checklist = Checklist(
        title: "買い物リスト",
        category: .shopping,
        items: [
            ChecklistItemModel(name: "牛乳", isCompleted: true, priority: .high, order: 0),
            ChecklistItemModel(name: "卵", isCompleted: true, priority: .medium, order: 1),
            ChecklistItemModel(name: "パン", isCompleted: false, priority: .low, order: 2),
            ChecklistItemModel(name: "バター", note: "無塩のもの", isCompleted: false, priority: .medium, order: 3)
        ],
        inputSource: .aiGenerated
    )

    return NavigationStack {
        ChecklistDetailView(checklist: checklist)
    }
}
