import SwiftUI
import CoreData
import CloudKit

struct CloudKitShareButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var coreDataStack: CoreDataStack
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    @ObservedObject var checklist: CDChecklist

    var body: some View {
        Button {
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
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func shareChecklist() async {
        let stack = coreDataStack

        do {
            // Check iCloud availability
            let status = try await stack.ckContainer.accountStatus()
            guard status == .available else {
                errorMessage = "iCloudにサインインしてください"
                showingError = true
                return
            }

            if stack.isShared(object: checklist) {
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
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Shared Checklists View

struct SharedChecklistsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var coreDataStack: CoreDataStack

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDChecklist.updatedAt, ascending: false)],
        animation: .default
    )
    private var allChecklists: FetchedResults<CDChecklist>

    @State private var iCloudAvailable = true

    private var sharedChecklists: [CDChecklist] {
        allChecklists.filter { coreDataStack.isShared(object: $0) }
    }

    var body: some View {
        ZStack {
            Color.neumorphicBackground.ignoresSafeArea()

            if !iCloudAvailable {
                notSignedInView
            } else if sharedChecklists.isEmpty {
                emptyView
            } else {
                sharedListView
            }
        }
        .navigationTitle("共有されたリスト")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await checkiCloudStatus()
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
                ForEach(sharedChecklists, id: \.objectID) { checklist in
                    SharedChecklistRow(checklist: checklist)
                }
            }
            .padding(NeumorphicSpacing.md)
        }
    }

    private func checkiCloudStatus() async {
        do {
            let status = try await coreDataStack.ckContainer.accountStatus()
            iCloudAvailable = (status == .available)
        } catch {
            iCloudAvailable = false
        }
    }
}

// MARK: - Shared Checklist Row

struct SharedChecklistRow: View {
    @ObservedObject var checklist: CDChecklist

    var body: some View {
        NavigationLink(value: checklist.objectID) {
            HStack(spacing: NeumorphicSpacing.md) {
                VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                    Text(checklist.wrappedTitle)
                        .font(.headline)
                        .foregroundStyle(Color.neumorphicTextPrimary)

                    HStack(spacing: NeumorphicSpacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text((checklist.ownerName ?? "").isEmpty ? "不明" : (checklist.ownerName ?? "不明"))
                            .font(.caption)
                    }
                    .foregroundStyle(Color.neumorphicTextTertiary)
                }

                Spacer()

                // Progress indicator
                Text("\(checklist.completedCount)/\(checklist.totalCount)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color.neumorphicTextSecondary)
            }
            .padding(NeumorphicSpacing.md)
            .background(Color.neumorphicSurface)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
            .neumorphicShadow()
        }
        .buttonStyle(.plain)
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
