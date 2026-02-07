import SwiftUI
import UIKit
import SwiftData
import CloudKit

struct ChecklistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChecklistDetailViewModel
    @State private var showingShareSheet = false
    @State private var showingCloudKitShare = false
    @State private var cloudKitShare: CKShare?
    @State private var showingCloudKitError = false
    @State private var cloudKitErrorMessage = ""

    let checklist: Checklist
    private let sharingService = CloudKitSharingService.shared

    init(checklist: Checklist) {
        self.checklist = checklist
        self._viewModel = StateObject(wrappedValue: ChecklistDetailViewModel(checklist: checklist))
    }

    var body: some View {
        ZStack {
            // Neumorphic background
            Color.neumorphicBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: NeumorphicSpacing.md) {
                    // Progress Card
                    progressCard

                    // Live Activity Card
                    liveActivityCard

                    // Items Card
                    itemsCard

                    // Info Card
                    infoCard
                }
                .padding(.horizontal, NeumorphicSpacing.md)
                .padding(.top, NeumorphicSpacing.md)
                .padding(.bottom, NeumorphicSpacing.xl)
            }
        }
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
                        Label("テキストで共有", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        Task {
                            await shareWithCloudKit()
                        }
                    } label: {
                        Label(
                            checklist.isShared ? "共有中" : "CloudKitで共有",
                            systemImage: checklist.isShared ? "person.2.fill" : "person.badge.plus"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        modelContext.delete(checklist)
                        dismiss()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.neumorphicTextSecondary)
                }
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
        .sheet(isPresented: $showingCloudKitShare) {
            if let share = cloudKitShare {
                ShareLinkView(checklist: checklist, share: share)
            }
        }
        .alert("エラー", isPresented: $showingCloudKitError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cloudKitErrorMessage)
        }
        .onAppear {
            viewModel.refreshLiveActivityState()
        }
    }

    // MARK: - CloudKit Sharing

    private func shareWithCloudKit() async {
        do {
            let share = try await sharingService.createShare(for: checklist, in: modelContext)
            cloudKitShare = share
            showingCloudKitShare = true
        } catch {
            cloudKitErrorMessage = error.localizedDescription
            showingCloudKitError = true
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(spacing: NeumorphicSpacing.md) {
            HStack {
                Text("進捗")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Spacer()
            }

            HStack(spacing: NeumorphicSpacing.lg) {
                // Circular progress
                NeumorphicCircularProgress(
                    progress: checklist.progress,
                    size: 100,
                    lineWidth: 10
                )

                VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
                    // Count
                    HStack(spacing: NeumorphicSpacing.xs) {
                        Text("\(checklist.completedCount)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.orangeGradient)

                        Text("/ \(checklist.totalCount)")
                            .font(.title2)
                            .foregroundStyle(Color.neumorphicTextSecondary)
                    }
                    .monospacedDigit()

                    Text("項目完了")
                        .font(.subheadline)
                        .foregroundStyle(Color.neumorphicTextTertiary)

                    if checklist.isCompleted {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("すべて完了!")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.statusSuccess)
                    }
                }

                Spacer()
            }
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    // MARK: - Live Activity Card

    private var liveActivityCard: some View {
        Button {
            viewModel.toggleLiveActivity()
        } label: {
            HStack(spacing: NeumorphicSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(viewModel.isLiveActivityActive ? Color.statusSuccess.opacity(0.15) : Color.neumorphicBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: viewModel.isLiveActivityActive ? "bell.badge.fill" : "bell")
                        .font(.title3)
                        .foregroundStyle(viewModel.isLiveActivityActive ? Color.statusSuccess : Color.neumorphicTextSecondary)
                }

                Text("ロック画面に表示")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Spacer()

                // Toggle indicator
                ZStack {
                    Capsule()
                        .fill(viewModel.isLiveActivityActive ? Color.statusSuccess : Color.neumorphicBackground)
                        .frame(width: 50, height: 28)
                        .shadow(
                            color: Color.neumorphicDarkShadow,
                            radius: 2,
                            x: 1,
                            y: 1
                        )
                        .shadow(
                            color: Color.neumorphicLightShadow,
                            radius: 2,
                            x: -1,
                            y: -1
                        )

                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: viewModel.isLiveActivityActive ? 10 : -10)
                        .animation(.spring(response: 0.3), value: viewModel.isLiveActivityActive)
                }
            }
            .padding(NeumorphicSpacing.md)
            .background(Color.neumorphicSurface)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
            .neumorphicShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Items Card

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            HStack {
                Text("項目")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Spacer()

                Text("\(checklist.sortedItems.count)件")
                    .font(.subheadline)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }
            .padding(.horizontal, NeumorphicSpacing.md)
            .padding(.top, NeumorphicSpacing.md)

            Divider()
                .padding(.horizontal, NeumorphicSpacing.md)

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
                    },
                    onDelete: {
                        viewModel.deleteItem(item)
                    }
                )
                .padding(.horizontal, NeumorphicSpacing.md)

                if item.id != checklist.sortedItems.last?.id {
                    Divider()
                        .padding(.horizontal, NeumorphicSpacing.lg)
                }
            }

            // Add item button
            Button {
                viewModel.showingAddItem = true
            } label: {
                HStack(spacing: NeumorphicSpacing.sm) {
                    ZStack {
                        Circle()
                            .stroke(Color.accentOrangeStart.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentOrangeStart)
                    }

                    Text("項目を追加")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentOrangeStart)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(NeumorphicSpacing.md)
            }
            .buttonStyle(.plain)
        }
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            Text("情報")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neumorphicTextPrimary)
                .padding(.horizontal, NeumorphicSpacing.md)
                .padding(.top, NeumorphicSpacing.md)

            Divider()
                .padding(.horizontal, NeumorphicSpacing.md)

            VStack(spacing: NeumorphicSpacing.sm) {
                infoRow(label: "カテゴリ", value: checklist.category.description, icon: checklist.category.icon)
                infoRow(label: "作成方法", value: checklist.inputSource.description, icon: checklist.inputSource.icon)
                infoRow(label: "作成日", value: checklist.createdAt.formatted(.dateTime.year().month(.defaultDigits).day()), icon: "calendar")
                infoRow(label: "更新日", value: checklist.updatedAt.formatted(.dateTime.year().month(.defaultDigits).day()), icon: "clock")
                if checklist.isShared {
                    infoRow(label: "共有状態", value: "共有中", icon: "person.2.fill")
                }
            }
            .padding(.horizontal, NeumorphicSpacing.md)
            .padding(.bottom, NeumorphicSpacing.md)
        }
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack {
            HStack(spacing: NeumorphicSpacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.neumorphicTextTertiary)
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.neumorphicTextSecondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.neumorphicTextPrimary)
        }
        .padding(.vertical, NeumorphicSpacing.xs)
    }
}

// MARK: - Add Item Sheet

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChecklistDetailViewModel

    var body: some View {
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
                            placeholder: "項目を入力...",
                            text: $viewModel.newItemName,
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
                            placeholder: "メモを入力...",
                            text: $viewModel.itemNote,
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
                                isSelected: viewModel.selectedPriority == nil
                            ) {
                                viewModel.selectedPriority = nil
                            }

                            ForEach(Priority.allCases, id: \.self) { priority in
                                NeumorphicPriorityButton(
                                    priority: priority,
                                    isSelected: viewModel.selectedPriority == priority
                                ) {
                                    viewModel.selectedPriority = priority
                                }
                            }
                        }
                    }

                    Spacer()

                    // Add button
                    NeumorphicButton_Unified(
                        title: "追加",
                        style: .accent,
                        isEnabled: !viewModel.newItemName.isEmpty
                    ) {
                        viewModel.addItem()
                        dismiss()
                    }
                    .padding(.bottom, NeumorphicSpacing.md)
                }
                .padding(NeumorphicSpacing.lg)
            }
            .navigationTitle("項目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundStyle(Color.neumorphicTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Priority Button

struct NeumorphicNoPriorityButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .stroke(Color.neumorphicTextTertiary, lineWidth: 1.5)
                    .frame(width: 10, height: 10)

                Text("なし")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .foregroundStyle(isSelected ? Color.neumorphicTextPrimary : Color.neumorphicTextSecondary)
            .padding(.horizontal, NeumorphicSpacing.md)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: NeumorphicRadius.sm)
                    .fill(isSelected ? Color.neumorphicSurface : Color.neumorphicBackground)
            )
        }
        .buttonStyle(.plain)
        .neumorphicShadow(isPressed: !isSelected, subtle: true)
    }
}

struct NeumorphicPriorityButton: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.priority(priority))
                    .frame(width: 10, height: 10)

                Text(priority.description)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .foregroundStyle(isSelected ? Color.neumorphicTextPrimary : Color.neumorphicTextSecondary)
            .padding(.horizontal, NeumorphicSpacing.md)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: NeumorphicRadius.sm)
                    .fill(isSelected ? Color.neumorphicSurface : Color.neumorphicBackground)
            )
        }
        .buttonStyle(.plain)
        .neumorphicShadow(isPressed: !isSelected, subtle: true)
    }
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
