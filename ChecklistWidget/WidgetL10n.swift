import Foundation

enum L10n {
    static func tr(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: Locale.current, arguments: arguments)
    }

    static func completedSummary(completed: Int, total: Int) -> String {
        format("%1$lld/%2$lld 完了", completed, total)
    }

    static func progressFraction(completed: Int, total: Int) -> String {
        format("%1$lld/%2$lld", completed, total)
    }

    static func moreItems(_ count: Int) -> String {
        format("他 %lld 件", count)
    }

    static func moreItemsEllipsis(_ count: Int) -> String {
        format("他 %lld 件...", count)
    }

    static func pageIndicator(current: Int, total: Int) -> String {
        format("%1$lld/%2$lld", current, total)
    }
}
