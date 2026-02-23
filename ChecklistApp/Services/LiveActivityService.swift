import ActivityKit
import Foundation
import CoreData
import Combine

@MainActor
class LiveActivityService: ObservableObject {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<ChecklistActivityAttributes>?
    private var stateMonitoringTask: Task<Void, Never>?

    /// Live Activityが終了したチェックリストIDを通知
    @Published var dismissedChecklistId: UUID?

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    }

    private init() {}

    // MARK: - Public Methods

    /// チェックリストのLive Activityを開始
    func startActivity(for checklist: CDChecklist) {
        // すでに実行中のアクティビティがあれば終了
        endCurrentActivity()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let attributes = ChecklistActivityAttributes(
            checklistId: checklist.wrappedId.uuidString,
            title: checklist.wrappedTitle,
            categoryIcon: checklist.category.icon
        )

        let state = createContentState(for: checklist)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("Live Activity started: \(activity.id)")

            // 状態監視を開始
            startMonitoringActivityState(activity, checklistId: checklist.wrappedId)
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Live Activityを更新
    func updateActivity(for checklist: CDChecklist, lastCompletedItem: String? = nil) {
        guard let activity = findActivity(for: checklist.wrappedId.uuidString) else { return }

        let state = createContentState(for: checklist)
        Task { @MainActor in
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    /// 現在のLive Activityを終了
    func endCurrentActivity() {
        // 状態監視をキャンセル
        stateMonitoringTask?.cancel()
        stateMonitoringTask = nil

        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    /// 特定のチェックリストのLive Activityを終了
    func endActivity(for checklistId: UUID) {
        guard let activity = findActivity(for: checklistId.uuidString) else { return }

        if currentActivity?.id == activity.id {
            // 状態監視をキャンセル
            stateMonitoringTask?.cancel()
            stateMonitoringTask = nil
            currentActivity = nil
        }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// 完了時にLive Activityを終了（完了メッセージ付き）
    func completeActivity(for checklist: CDChecklist) {
        guard let activity = findActivity(for: checklist.wrappedId.uuidString) else { return }

        if currentActivity?.id == activity.id {
            // 状態監視をキャンセル
            stateMonitoringTask?.cancel()
            stateMonitoringTask = nil
            currentActivity = nil
        }

        let finalState = createContentState(for: checklist)
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
        }
    }

    /// 現在アクティブなチェックリストIDを取得
    var activeChecklistId: UUID? {
        guard let activity = currentActivity else { return nil }
        return UUID(uuidString: activity.attributes.checklistId)
    }

    /// 特定のチェックリストのLive Activityがアクティブかどうか
    func isActivityActive(for checklistId: UUID) -> Bool {
        findActivity(for: checklistId.uuidString) != nil
    }

    /// Live Activityが有効かどうか
    var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// ペンディングのLive Activity更新をチェックして処理
    func checkPendingUpdates(with context: NSManagedObjectContext) {
        guard let idString = userDefaults?.string(forKey: AppConstants.liveActivityUpdateKey),
              let checklistId = UUID(uuidString: idString) else {
            // ペンディングがなくても、アクティブなLive Activityを同期
            syncAllActiveActivities(with: context)
            return
        }

        // ペンディングをクリア
        userDefaults?.removeObject(forKey: AppConstants.liveActivityUpdateKey)
        userDefaults?.removeObject(forKey: AppConstants.liveActivityUpdateTimestampKey)

        // チェックリストを取得して更新
        let request: NSFetchRequest<CDChecklist> = CDChecklist.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", checklistId as CVarArg)
        request.fetchLimit = 1

        guard let checklist = try? context.fetch(request).first else {
            return
        }

        updateActivity(for: checklist)
    }

    /// 全てのアクティブなLive Activityを同期
    func syncAllActiveActivities(with context: NSManagedObjectContext) {
        let request: NSFetchRequest<CDChecklist> = CDChecklist.fetchRequest()
        guard let checklists = try? context.fetch(request) else { return }

        for activity in Activity<ChecklistActivityAttributes>.activities {
            if let checklist = checklists.first(where: { $0.wrappedId.uuidString == activity.attributes.checklistId }) {
                let state = createContentState(for: checklist)
                Task {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                }
            }
        }
    }

    // MARK: - Private Methods

    /// 指定されたチェックリストIDに対応するアクティビティを検索
    private func findActivity(for checklistIdString: String) -> Activity<ChecklistActivityAttributes>? {
        // キャッシュされたアクティビティを優先
        if let activity = currentActivity,
           activity.attributes.checklistId == checklistIdString {
            return activity
        }

        // すべてのアクティビティから検索
        for activity in Activity<ChecklistActivityAttributes>.activities {
            if activity.attributes.checklistId == checklistIdString {
                currentActivity = activity
                return activity
            }
        }

        return nil
    }

    private func createContentState(for checklist: CDChecklist) -> ChecklistActivityAttributes.ContentState {
        let items = checklist.sortedItems.prefix(AppConstants.maxDisplayItems).map { item in
            ChecklistActivityItem(
                id: item.wrappedId.uuidString,
                name: item.wrappedName,
                isCompleted: item.isCompleted
            )
        }

        return ChecklistActivityAttributes.ContentState(
            completedCount: checklist.completedCount,
            totalCount: checklist.totalCount,
            items: Array(items)
        )
    }

    /// Live Activityの状態を監視
    private func startMonitoringActivityState(_ activity: Activity<ChecklistActivityAttributes>, checklistId: UUID) {
        // 既存の監視タスクをキャンセル
        stateMonitoringTask?.cancel()

        stateMonitoringTask = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard !Task.isCancelled else { break }

                switch state {
                case .dismissed:
                    // ユーザーがロック画面から消去した場合
                    await MainActor.run {
                        self?.currentActivity = nil
                        self?.stateMonitoringTask = nil
                        self?.dismissedChecklistId = checklistId
                    }
                    return

                case .ended:
                    // システムまたはアプリによって終了された場合
                    await MainActor.run {
                        self?.currentActivity = nil
                        self?.stateMonitoringTask = nil
                    }
                    return

                case .stale:
                    break

                case .active:
                    break

                @unknown default:
                    break
                }
            }
        }
    }
}
