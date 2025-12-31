import SwiftUI
import SwiftData
import WidgetKit

@main
struct ChecklistApp: App {
    @Environment(\.scenePhase) private var scenePhase
    var sharedModelContainer: ModelContainer = AppGroupContainer.modelContainer

    init() {
        // Darwin Notificationをリッスン
        setupDarwinNotificationObserver()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url: url)
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

    private func setupDarwinNotificationObserver() {
        DarwinNotificationCenter.shared.observe(.liveActivityUpdateRequested) { [self] in
            Task { @MainActor in
                let context = ModelContext(sharedModelContainer)
                LiveActivityService.shared.checkPendingUpdates(with: context)
            }
        }
    }

    private func handleDeepLink(url: URL) {
        // URLスキーム: checklistapp://toggle/{itemId}
        guard url.scheme == "checklistapp",
              url.host == "toggle",
              let itemIdString = url.pathComponents.last,
              let itemId = UUID(uuidString: itemIdString) else {
            return
        }

        Task { @MainActor in
            let context = ModelContext(sharedModelContainer)
            toggleItem(itemId: itemId, context: context)
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
