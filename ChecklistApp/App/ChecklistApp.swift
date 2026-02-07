import SwiftUI
import SwiftData
import WidgetKit
import Combine
import CloudKit

// MARK: - Navigation State

@MainActor
class NavigationState: ObservableObject {
    @Published var selectedChecklistId: UUID?
    @Published var showingSharedChecklists: Bool = false
    @Published var pendingShareMetadata: CKShare.Metadata?
}

@main
struct ChecklistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var navigationState = NavigationState()
    var sharedModelContainer: ModelContainer = AppGroupContainer.modelContainer

    init() {
        // Darwin Notificationをリッスン
        setupDarwinNotificationObserver()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationState)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
                .task {
                    // CloudKit共有の受け入れを監視
                    await setupCloudKitShareHandler()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let context = ModelContext(sharedModelContainer)
                LiveActivityService.shared.checkPendingUpdates(with: context)
            }
        }
    }

    private func setupCloudKitShareHandler() async {
        // CKShareメタデータの処理をセットアップ
        let container = CKContainer(identifier: "iCloud.com.kanbe1365.ChecklistApp")

        // 共有招待の通知を監視
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CKShareAccepted"),
            object: nil,
            queue: .main
        ) { notification in
            if let metadata = notification.userInfo?["metadata"] as? CKShare.Metadata {
                Task { @MainActor in
                    await acceptShare(metadata: metadata)
                }
            }
        }
    }

    private func acceptShare(metadata: CKShare.Metadata) async {
        let service = CloudKitSharingService.shared

        do {
            try await service.acceptShare(metadata: metadata)
            print("共有を受け入れました")

            // 共有されたリスト画面を表示
            await MainActor.run {
                navigationState.showingSharedChecklists = true
            }
        } catch {
            print("共有の受け入れに失敗: \(error)")
        }
    }

    private func setupDarwinNotificationObserver() {
        DarwinNotificationCenter.shared.observe(.liveActivityUpdateRequested) { [self] in
            Task { @MainActor in
                let context = ModelContext(sharedModelContainer)
                LiveActivityService.shared.checkPendingUpdates(with: context)
            }
        }
    }

    private func handleDeepLink(url: URL) {
        guard url.scheme == "checklistapp" else { return }

        switch url.host {
        case "toggle":
            // URLスキーム: checklistapp://toggle/{itemId}
            guard let itemIdString = url.pathComponents.last,
                  let itemId = UUID(uuidString: itemIdString) else {
                return
            }
            Task { @MainActor in
                let context = ModelContext(sharedModelContainer)
                toggleItem(itemId: itemId, context: context)
            }

        case "checklist":
            // URLスキーム: checklistapp://checklist/{checklistId}
            guard let checklistIdString = url.pathComponents.last,
                  let checklistId = UUID(uuidString: checklistIdString) else {
                return
            }
            Task { @MainActor in
                navigationState.selectedChecklistId = checklistId
            }

        default:
            break
        }
    }

    private func toggleItem(itemId: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<ChecklistItemModel>()

        do {
            let items = try context.fetch(descriptor)
            guard let item = items.first(where: { $0.id == itemId }),
                  let checklist = item.checklist else {
                return
            }

            item.isCompleted.toggle()
            checklist.updatedAt = Date()
            try context.save()

            // Live Activityを更新
            LiveActivityService.shared.updateActivity(for: checklist)

            // ウィジェットも更新
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to toggle item: \(error)")
        }
    }
}
