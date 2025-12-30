import Foundation

enum InputSource: String, Codable, CaseIterable {
    case photo
    case voice
    case text
    case aiGenerated

    var description: String {
        switch self {
        case .photo:
            return "写真"
        case .voice:
            return "音声"
        case .text:
            return "テキスト"
        case .aiGenerated:
            return "AI生成"
        }
    }

    var icon: String {
        switch self {
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
            return "高"
        case .medium:
            return "中"
        case .low:
            return "低"
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
            return "買い物"
        case .task:
            return "タスク"
        case .procedure:
            return "手続き"
        case .travel:
            return "旅行"
        case .cooking:
            return "料理"
        case .other:
            return "その他"
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
