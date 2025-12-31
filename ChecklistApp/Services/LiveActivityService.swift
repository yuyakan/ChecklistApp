import ActivityKit
import Foundation
import SwiftData

@MainActor
class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<ChecklistActivityAttributes>?
    private let maxDisplayItems = 12

    private static let appGroupIdentifier = "group.com.checklistapp.shared"
    private static let liveActivityUpdateKey = "live_activity_update_checklist_id"
    private static let liveActivityUpdateTimestampKey = "live_activity_update_timestamp"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    private init() {}

    // MARK: - Public Methods

    /// チェックリストのLive Activityを開始
    func startActivity(for checklist: Checklist) {
        // すでに実行中のアクティビティがあれば終了
        endCurrentActivity()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let attributes = ChecklistActivityAttributes(
            checklistId: checklist.id.uuidString,
            title: checklist.title,
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
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Live Activityを更新
    func updateActivity(for checklist: Checklist, lastCompletedItem: String? = nil) {
        let checklistId = checklist.id.uuidString

        // アクティビティを検索
        var targetActivity: Activity<ChecklistActivityAttributes>?

        if let activity = currentActivity,
           activity.attributes.checklistId == checklistId {
            targetActivity = activity
        } else {
            for activity in Activity<ChecklistActivityAttributes>.activities {
                if activity.attributes.checklistId == checklistId {
                    targetActivity = activity
                    currentActivity = activity
                    break
                }
            }
        }

        guard let activity = targetActivity else { return }

        let state = createContentState(for: checklist)
        Task { @MainActor in
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    /// 現在のLive Activityを終了
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    /// 特定のチェックリストのLive Activityを終了
    func endActivity(for checklistId: UUID) {
        let checklistIdString = checklistId.uuidString

        // currentActivityを確認
        if let activity = currentActivity,
           activity.attributes.checklistId == checklistIdString {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
            return
        }

        // すべてのアクティビティから検索
        for activity in Activity<ChecklistActivityAttributes>.activities {
            if activity.attributes.checklistId == checklistIdString {
                Task {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
                return
            }
        }
    }

    /// 完了時にLive Activityを終了（完了メッセージ付き）
    func completeActivity(for checklist: Checklist) {
        let finalState = createContentState(for: checklist)
        let checklistIdString = checklist.id.uuidString

        // currentActivityを確認
        if let activity = currentActivity,
           activity.attributes.checklistId == checklistIdString {
            Task {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .default
                )
            }
            currentActivity = nil
            return
        }

        // すべてのアクティビティから検索
        for activity in Activity<ChecklistActivityAttributes>.activities {
            if activity.attributes.checklistId == checklistIdString {
                Task {
                    await activity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .default
                    )
                }
                return
            }
        }
    }

    /// 現在アクティブなチェックリストIDを取得
    var activeChecklistId: UUID? {
        guard let activity = currentActivity else { return nil }
        return UUID(uuidString: activity.attributes.checklistId)
    }

    /// 特定のチェックリストのLive Activityがアクティブかどうか
    func isActivityActive(for checklistId: UUID) -> Bool {
        let checklistIdString = checklistId.uuidString

        // currentActivityを確認
        if let activity = currentActivity,
           activity.attributes.checklistId == checklistIdString {
            return true
        }

        // すべてのアクティビティから検索
        for activity in Activity<ChecklistActivityAttributes>.activities {
            if activity.attributes.checklistId == checklistIdString {
                currentActivity = activity
                return true
            }
        }

        return false
    }

    /// Live Activityが有効かどうか
    var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// ペンディングのLive Activity更新をチェックして処理
    func checkPendingUpdates(with modelContext: ModelContext) {
        guard let idString = userDefaults?.string(forKey: Self.liveActivityUpdateKey),
              let checklistId = UUID(uuidString: idString) else {
            // ペンディングがなくても、アクティブなLive Activityを同期
            syncAllActiveActivities(with: modelContext)
            return
        }

        // ペンディングをクリア
        userDefaults?.removeObject(forKey: Self.liveActivityUpdateKey)
        userDefaults?.removeObject(forKey: Self.liveActivityUpdateTimestampKey)

        // チェックリストを取得して更新
        let descriptor = FetchDescriptor<Checklist>()
        guard let checklists = try? modelContext.fetch(descriptor),
              let checklist = checklists.first(where: { $0.id == checklistId }) else {
            return
        }

        updateActivity(for: checklist)
    }

    /// 全てのアクティブなLive Activityを同期
    func syncAllActiveActivities(with modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Checklist>()
        guard let checklists = try? modelContext.fetch(descriptor) else { return }

        for activity in Activity<ChecklistActivityAttributes>.activities {
            if let checklist = checklists.first(where: { $0.id.uuidString == activity.attributes.checklistId }) {
                let state = createContentState(for: checklist)
                Task {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func createContentState(for checklist: Checklist) -> ChecklistActivityAttributes.ContentState {
        let items = checklist.sortedItems.prefix(maxDisplayItems).map { item in
            ChecklistActivityItem(
                id: item.id.uuidString,
                name: item.name,
                isCompleted: item.isCompleted
            )
        }

        return ChecklistActivityAttributes.ContentState(
            completedCount: checklist.completedCount,
            totalCount: checklist.totalCount,
            items: Array(items)
        )
    }
}
