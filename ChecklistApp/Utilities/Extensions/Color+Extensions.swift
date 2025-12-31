import SwiftUI

extension Color {
    static let priorityHigh = Color.red
    static let priorityMedium = Color.orange
    static let priorityLow = Color.green

    static func priority(_ priority: Priority) -> Color {
        switch priority {
        case .high:
            return .priorityHigh
        case .medium:
            return .priorityMedium
        case .low:
            return .priorityLow
        }
    }

    /// 進捗率に応じた色を返す
    static func progress(_ progress: Double, isCompleted: Bool) -> Color {
        if isCompleted {
            return .green
        } else if progress > 0.5 {
            return .blue
        } else if progress > 0 {
            return .orange
        } else {
            return .gray
        }
    }
}
