import SwiftUI
import CoreData
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
    @StateObject private var coreDataStack = CoreDataStack.shared

    init() {
        // Run migration from SwiftData to CoreData
        DataMigrationService.migrateIfNeeded(to: CoreDataStack.shared.container.viewContext)

        // Darwin Notificationをリッスン
        setupDarwinNotificationObserver()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.container.viewContext)
                .environmentObject(navigationState)
                .environmentObject(coreDataStack)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
                .task {
                    // CloudKit共有の受け入れを監視
                    await setupCloudKitShareHandler()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let context = coreDataStack.container.viewContext
                LiveActivityService.shared.checkPendingUpdates(with: context)
            }
        }
    }

    private func setupCloudKitShareHandler() async {
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
        let stack = CoreDataStack.shared
        guard let sharedStore = stack.sharedPersistentStore else {
            print("Shared store not found")
            return
        }

        do {
            try await stack.container.acceptShareInvitations(
                from: [metadata],
                into: sharedStore
            )
            print("共有を受け入れました")

            await MainActor.run {
                navigationState.showingSharedChecklists = true
            }
        } catch {
            print("共有の受け入れに失敗: \(error)")
        }
    }

    private func setupDarwinNotificationObserver() {
        DarwinNotificationCenter.shared.observe(.liveActivityUpdateRequested) {
            Task { @MainActor in
                let context = CoreDataStack.shared.container.viewContext
                LiveActivityService.shared.checkPendingUpdates(with: context)
            }
        }
    }

    private func handleDeepLink(url: URL) {
        guard url.scheme == "checklistapp" else { return }

        switch url.host {
        case "toggle":
            guard let itemIdString = url.pathComponents.last,
                  let itemId = UUID(uuidString: itemIdString) else {
                return
            }
            Task { @MainActor in
                let context = coreDataStack.container.viewContext
                toggleItem(itemId: itemId, context: context)
            }

        case "checklist":
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

    private func toggleItem(itemId: UUID, context: NSManagedObjectContext) {
        let request: NSFetchRequest<CDChecklistItem> = CDChecklistItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        request.fetchLimit = 1

        do {
            guard let item = try context.fetch(request).first,
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
