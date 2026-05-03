import Foundation

enum InputSource: String, Codable, CaseIterable {
    case manual
    case photo
    case voice
    case text
    case aiGenerated

    var description: String {
        switch self {
        case .manual:
            return L10n.tr("手動")
        case .photo:
            return L10n.tr("写真")
        case .voice:
            return L10n.tr("音声")
        case .text:
            return L10n.tr("テキスト")
        case .aiGenerated:
            return L10n.tr("自動")
        }
    }

    var icon: String {
        switch self {
        case .manual:
            return "square.and.pencil"
        case .photo:
            return "camera.fill"
        case .voice:
            return "mic.fill"
        case .text:
            return "text.alignleft"
        case .aiGenerated:
            return "sparkles"
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case high
    case medium
    case low

    var description: String {
        switch self {
        case .high:
            return L10n.tr("高")
        case .medium:
            return L10n.tr("中")
        case .low:
            return L10n.tr("低")
        }
    }

    var color: String {
        switch self {
        case .high:
            return "red"
        case .medium:
            return "orange"
        case .low:
            return "green"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case shopping
    case task
    case procedure
    case travel
    case cooking
    case other

    var description: String {
        switch self {
        case .shopping:
            return L10n.tr("買い物")
        case .task:
            return L10n.tr("タスク")
        case .procedure:
            return L10n.tr("手続き")
        case .travel:
            return L10n.tr("旅行")
        case .cooking:
            return L10n.tr("料理")
        case .other:
            return L10n.tr("その他")
        }
    }

    var icon: String {
        switch self {
        case .shopping:
            return "cart.fill"
        case .task:
            return "checkmark.circle.fill"
        case .procedure:
            return "doc.text.fill"
        case .travel:
            return "airplane"
        case .cooking:
            return "frying.pan.fill"
        case .other:
            return "folder.fill"
        }
    }
}
