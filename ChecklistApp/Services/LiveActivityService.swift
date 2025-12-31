import ActivityKit
import Foundation

@MainActor
class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<ChecklistActivityAttributes>?
    private let maxDisplayItems = 5

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
        guard let activity = currentActivity,
              activity.attributes.checklistId == checklist.id.uuidString else {
            return
        }

        let state = createContentState(for: checklist)

        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
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
        guard let activity = currentActivity,
              activity.attributes.checklistId == checklistId.uuidString else {
            return
        }

        endCurrentActivity()
    }

    /// 完了時にLive Activityを終了（完了メッセージ付き）
    func completeActivity(for checklist: Checklist) {
        guard let activity = currentActivity,
              activity.attributes.checklistId == checklist.id.uuidString else {
            return
        }

        let finalState = createContentState(for: checklist)

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
            currentActivity = nil
        }
    }

    /// 現在アクティブなチェックリストIDを取得
    var activeChecklistId: UUID? {
        guard let activity = currentActivity else { return nil }
        return UUID(uuidString: activity.attributes.checklistId)
    }

    /// Live Activityが有効かどうか
    var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
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
