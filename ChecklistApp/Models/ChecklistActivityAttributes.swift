import ActivityKit
import Foundation

struct ChecklistActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var completedCount: Int
        var totalCount: Int
        var items: [ChecklistActivityItem]

        var progress: Double {
            guard totalCount > 0 else { return 0 }
            return Double(completedCount) / Double(totalCount)
        }

        var isCompleted: Bool {
            totalCount > 0 && completedCount == totalCount
        }
    }

    var checklistId: String
    var title: String
    var categoryIcon: String
}

struct ChecklistActivityItem: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var isCompleted: Bool
}
