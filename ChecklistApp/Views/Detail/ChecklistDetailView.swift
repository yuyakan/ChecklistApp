import SwiftUI
import UIKit
import CoreData
import CloudKit

struct ChecklistDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coreDataStack: CoreDataStack
    @StateObject private var viewModel: ChecklistDetailViewModel
    @State private var showingShareSheet = false
    @State private var showingCloudKitError = false
    @State private var cloudKitErrorMessage = ""
    @State private var showingDeleteSheet = false

    @ObservedObject var checklist: CDChecklist

    init(checklist: CDChecklist) {
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
        .navigationTitle(checklist.wrappedTitle)
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
                            checklist.isShared ? "共有設定" : "iCloudで共有",
                            systemImage: checklist.isShared ? "person.2.fill" : "person.badge.plus"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewContext.delete(checklist)
                        try? viewContext.save()
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
                viewModel.editingTitle = checklist.wrappedTitle
            }
            Button("保存") {
                viewModel.updateTitle()
            }
        }
        .sheet(isPresented: $viewModel.showingAddItem) {
            AddItemSheet(viewModel: viewModel)
                .iPadExpandedModalLayout()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(text: viewModel.shareText())
        }
        .sheet(isPresented: $showingDeleteSheet) {
            DeleteItemsSheet(viewModel: viewModel)
                .iPadExpandedModalLayout()
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
        let stack = coreDataStack

        do {
            if coreDataStack.isShared(object: checklist) {
                // Already shared - show existing share management
                let shares = try stack.container.fetchShares(matching: [checklist.objectID])
                if let existingShare = shares.values.first {
                    await MainActor.run {
                        CloudKitSharingPresenter.present(
                            share: existingShare,
                            container: stack.ckContainer,
                            checklist: checklist,
                            onStopSharing: {
                                checklist.isShared = false
                                try? viewContext.save()
                            }
                        )
                    }
                }
            } else {
                // New share
                let (_, share, _) = try await stack.container.share(
                    [checklist],
                    to: nil
                )
                share[CKShare.SystemFieldKey.title] = checklist.wrappedTitle as CKRecordValue
                checklist.isShared = true
                try? viewContext.save()

                await MainActor.run {
                    CloudKitSharingPresenter.present(
                        share: share,
                        container: stack.ckContainer,
                        checklist: checklist,
                        onStopSharing: {
                            checklist.isShared = false
                            try? viewContext.save()
                        }
                    )
                }
            }
        } catch {
            cloudKitErrorMessage = UserErrorMessageResolver.message(for: error, context: .cloudShare)
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

                Text(L10n.checklistCount(checklist.sortedItems.count))
                    .font(.subheadline)
                    .foregroundStyle(Color.neumorphicTextTertiary)

                if !checklist.sortedItems.isEmpty {
                    Button {
                        viewModel.deselectAll()
                        showingDeleteSheet = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(Color.red.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, NeumorphicSpacing.md)
            .padding(.top, NeumorphicSpacing.md)

            Divider()
                .padding(.horizontal, NeumorphicSpacing.md)

            ForEach(Array(checklist.sortedItems), id: \.objectID) { (item: CDChecklistItem) in
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

                if item.objectID != checklist.sortedItems.last?.objectID {
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
            Text(L10n.tr("情報"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neumorphicTextPrimary)
                .padding(.horizontal, NeumorphicSpacing.md)
                .padding(.top, NeumorphicSpacing.md)

            Divider()
                .padding(.horizontal, NeumorphicSpacing.md)

            VStack(spacing: NeumorphicSpacing.sm) {
                infoRow(label: L10n.tr("カテゴリ"), value: checklist.category.description, icon: checklist.category.icon)
                infoRow(label: L10n.tr("作成方法"), value: checklist.inputSource.description, icon: checklist.inputSource.icon)
                infoRow(label: L10n.tr("作成日"), value: checklist.wrappedCreatedAt.formatted(.dateTime.year().month(.defaultDigits).day()), icon: "calendar")
                infoRow(label: L10n.tr("更新日"), value: checklist.wrappedUpdatedAt.formatted(.dateTime.year().month(.defaultDigits).day()), icon: "clock")
                if checklist.isShared {
                    infoRow(label: L10n.tr("共有状態"), value: L10n.tr("共有中"), icon: "person.2.fill")
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
                            placeholder: L10n.tr("項目を入力..."),
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
                            placeholder: L10n.tr("メモを入力..."),
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
                        title: L10n.tr("追加"),
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
        .iPadExpandedModalLayout()
    }
}

// MARK: - Delete Items Sheet

struct DeleteItemsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChecklistDetailViewModel
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.neumorphicBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Select all / deselect all
                    HStack {
                        let allSelected = viewModel.selectedItemIDs.count == viewModel.checklist.sortedItems.count
                        Button(allSelected ? L10n.tr("すべて解除") : L10n.tr("すべて選択")) {
                            if allSelected {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }
                        .font(.subheadline)

                        Spacer()

                        if !viewModel.selectedItemIDs.isEmpty {
                            Text(L10n.selectedCount(viewModel.selectedItemIDs.count))
                                .font(.subheadline)
                                .foregroundStyle(Color.neumorphicTextTertiary)
                        }
                    }
                    .padding(.horizontal, NeumorphicSpacing.md)
                    .padding(.vertical, NeumorphicSpacing.sm)

                    Divider()

                    // Item list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.checklist.sortedItems), id: \.objectID) { (item: CDChecklistItem) in
                                Button {
                                    viewModel.toggleSelection(item)
                                } label: {
                                    HStack(spacing: NeumorphicSpacing.sm) {
                                        Image(systemName: viewModel.selectedItemIDs.contains(item.objectID) ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(viewModel.selectedItemIDs.contains(item.objectID) ? Color.red : Color.neumorphicTextTertiary)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.wrappedName)
                                                .foregroundStyle(Color.neumorphicTextPrimary)
                                                .lineLimit(1)

                                            if let note = item.note, !note.isEmpty {
                                                Text(note)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.neumorphicTextTertiary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()

                                        if item.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundStyle(Color.neumorphicTextTertiary)
                                        }
                                    }
                                    .padding(.horizontal, NeumorphicSpacing.md)
                                    .padding(.vertical, NeumorphicSpacing.sm)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading, NeumorphicSpacing.lg + NeumorphicSpacing.md)
                            }
                        }
                    }

                    // Delete button
                    VStack {
                        Divider()
                        Button {
                            showingConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(L10n.deleteItemsButtonTitle(viewModel.selectedItemIDs.count))
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(NeumorphicSpacing.sm)
                            .background(viewModel.selectedItemIDs.isEmpty ? Color.gray : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.selectedItemIDs.isEmpty)
                        .padding(.horizontal, NeumorphicSpacing.md)
                        .padding(.vertical, NeumorphicSpacing.sm)
                    }
                    .background(Color.neumorphicBackground)
                }
            }
            .navigationTitle("項目を削除")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.deselectAll()
                        dismiss()
                    }
                    .foregroundStyle(Color.neumorphicTextSecondary)
                }
            }
            .alert("確認", isPresented: $showingConfirmation) {
                Button("削除", role: .destructive) {
                    viewModel.deleteSelectedItems()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text(L10n.deleteItemsConfirmation(viewModel.selectedItemIDs.count))
            }
        }
        .presentationDetents([.medium, .large])
        .iPadExpandedModalLayout()
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
