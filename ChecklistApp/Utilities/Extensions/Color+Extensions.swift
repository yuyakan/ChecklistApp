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
}
