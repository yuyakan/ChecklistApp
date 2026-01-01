import SwiftUI

extension Color {
    // MARK: - Priority Colors (Neumorphic)
    static let priorityHigh = Color.priorityHighNeu
    static let priorityMedium = Color.priorityMediumNeu
    static let priorityLow = Color.priorityLowNeu

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

    /// 進捗率に応じた色を返す（オレンジアクセント対応）
    static func progress(_ progress: Double, isCompleted: Bool) -> Color {
        if isCompleted {
            return .statusSuccess
        } else if progress > 0.5 {
            return .statusInfo
        } else if progress > 0 {
            return .accentOrangeStart
        } else {
            return .neumorphicTextTertiary
        }
    }
}
