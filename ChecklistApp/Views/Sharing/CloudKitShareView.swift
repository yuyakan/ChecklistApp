import SwiftUI
import SwiftData
import CloudKit

struct CloudKitShareButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingShareSheet = false
    @State private var share: CKShare?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    let checklist: Checklist
    private let sharingService = CloudKitSharingService.shared

    var body: some View {
        Button {
            print("CloudKit共有ボタンがタップされました")
            isLoading = true
            Task {
                await shareChecklist()
                isLoading = false
            }
        } label: {
            Label(
                checklist.isShared ? "共有中" : "CloudKitで共有",
                systemImage: checklist.isShared ? "person.2.fill" : "person.badge.plus"
            )
        }
        .task {
            await sharingService.checkAccountStatus()
            print("iCloudアカウント状態: \(sharingService.accountStatus.rawValue), isAvailable: \(sharingService.isAvailable)")
        }
        .onChange(of: showingShareSheet) { _, newValue in
            if newValue, let share = share {
                CloudKitSharingPresenter.present(
                    share: share,
                    container: CKContainer(identifier: "iCloud.com.kanbe1365.ChecklistApp"),
                    checklist: checklist,
                    onStopSharing: {
                        checklist.isShared = false
                        try? modelContext.save()
                    }
                )
                showingShareSheet = false
            }
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func shareChecklist() async {
        print("shareChecklist開始")

        // アカウント状態を再確認
        await sharingService.checkAccountStatus()

        guard sharingService.isAvailable else {
            print("iCloudが利用できません: \(sharingService.accountStatus.rawValue)")
            errorMessage = "iCloudにサインインしてください"
            showingError = true
            return
        }

        do {
            print("CKShare作成中...")
            let newShare = try await sharingService.createShare(for: checklist, in: modelContext)
            print("CKShare作成成功")
            share = newShare
            showingShareSheet = true
        } catch {
            print("共有エラー: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Shared Checklists View

struct SharedChecklistsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sharingService = CloudKitSharingService.shared
    @State private var sharedRecords: [CKRecord] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.neumorphicBackground.ignoresSafeArea()

            if !sharingService.isAvailable {
                notSignedInView
            } else if isLoading {
                ProgressView("共有リストを読み込み中...")
            } else if sharedRecords.isEmpty {
                emptyView
            } else {
                sharedListView
            }
        }
        .navigationTitle("共有されたリスト")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await fetchSharedChecklists()
        }
        .refreshable {
            await fetchSharedChecklists()
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var notSignedInView: some View {
        VStack(spacing: NeumorphicSpacing.lg) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 60))
                .foregroundStyle(Color.neumorphicTextTertiary)

            Text("iCloudにサインインしてください")
                .font(.headline)
                .foregroundStyle(Color.neumorphicTextSecondary)

            Text("共有機能を使用するには、設定アプリからiCloudにサインインする必要があります。")
                .font(.subheadline)
                .foregroundStyle(Color.neumorphicTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NeumorphicSpacing.xl)
        }
    }

    private var emptyView: some View {
        VStack(spacing: NeumorphicSpacing.lg) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(Color.neumorphicTextTertiary)

            Text("共有されたリストはありません")
                .font(.headline)
                .foregroundStyle(Color.neumorphicTextSecondary)

            Text("他のユーザーがチェックリストを共有すると、ここに表示されます。")
                .font(.subheadline)
                .foregroundStyle(Color.neumorphicTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NeumorphicSpacing.xl)
        }
    }

    private var sharedListView: some View {
        ScrollView {
            LazyVStack(spacing: NeumorphicSpacing.md) {
                ForEach(sharedRecords, id: \.recordID) { record in
                    SharedChecklistRow(record: record) {
                        await importChecklist(from: record)
                    }
                }
            }
            .padding(NeumorphicSpacing.md)
        }
    }

    private func fetchSharedChecklists() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sharedRecords = try await sharingService.fetchSharedChecklists()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func importChecklist(from record: CKRecord) async {
        do {
            let _ = try await sharingService.importSharedChecklist(from: record, modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Shared Checklist Row

struct SharedChecklistRow: View {
    let record: CKRecord
    let onImport: () async -> Void

    @State private var isImporting = false

    private var title: String {
        record["title"] as? String ?? "無題のリスト"
    }

    private var ownerName: String {
        record["ownerName"] as? String ?? "不明"
    }

    var body: some View {
        HStack(spacing: NeumorphicSpacing.md) {
            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                HStack(spacing: NeumorphicSpacing.xs) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text(ownerName)
                        .font(.caption)
                }
                .foregroundStyle(Color.neumorphicTextTertiary)
            }

            Spacer()

            Button {
                Task {
                    isImporting = true
                    await onImport()
                    isImporting = false
                }
            } label: {
                if isImporting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.orangeGradient)
                }
            }
            .disabled(isImporting)
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }
}

// MARK: - Share Status Badge

struct ShareStatusBadge: View {
    let isShared: Bool

    var body: some View {
        if isShared {
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                Text("共有中")
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentOrangeStart.opacity(0.8))
            .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        SharedChecklistsView()
    }
}
