import Foundation

enum AppLanguage: String, CaseIterable {
    case japanese = "ja"
    case english = "en"
    case spanish = "es"
    case korean = "ko"
    case traditionalChinese = "zh-Hant"
    case french = "fr"
    case german = "de"
    case brazilianPortuguese = "pt-BR"

    static var current: AppLanguage {
        preferredLanguage(from: Locale.preferredLanguages) ?? .english
    }

    static func preferredLanguage(from identifiers: [String]) -> AppLanguage? {
        for identifier in identifiers {
            let locale = Locale(identifier: identifier)
            let languageCode = locale.language.languageCode?.identifier ?? ""
            let regionCode = locale.region?.identifier ?? ""
            let scriptCode = locale.language.script?.identifier ?? ""

            switch languageCode {
            case "ja":
                return .japanese
            case "en":
                return .english
            case "es":
                return .spanish
            case "ko":
                return .korean
            case "fr":
                return .french
            case "de":
                return .german
            case "pt":
                return regionCode == "BR" ? .brazilianPortuguese : .english
            case "zh":
                if scriptCode == "Hant" || regionCode == "TW" || regionCode == "HK" || regionCode == "MO" {
                    return .traditionalChinese
                }
                return .english
            default:
                continue
            }
        }

        return nil
    }

    var localeIdentifier: String {
        switch self {
        case .japanese:
            return "ja"
        case .english:
            return "en"
        case .spanish:
            return "es"
        case .korean:
            return "ko"
        case .traditionalChinese:
            return "zh-Hant"
        case .french:
            return "fr"
        case .german:
            return "de"
        case .brazilianPortuguese:
            return "pt-BR"
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .japanese:
            return "ja-JP"
        case .english:
            return "en-US"
        case .spanish:
            return "es-ES"
        case .korean:
            return "ko-KR"
        case .traditionalChinese:
            return "zh-TW"
        case .french:
            return "fr-FR"
        case .german:
            return "de-DE"
        case .brazilianPortuguese:
            return "pt-BR"
        }
    }

    var visionRecognitionLanguages: [String] {
        switch self {
        case .japanese:
            return ["ja-JP", "en-US"]
        case .english:
            return ["en-US"]
        case .spanish:
            return ["es-ES", "en-US"]
        case .korean:
            return ["ko-KR", "en-US"]
        case .traditionalChinese:
            return ["zh-Hant", "en-US"]
        case .french:
            return ["fr-FR", "en-US"]
        case .german:
            return ["de-DE", "en-US"]
        case .brazilianPortuguese:
            return ["pt-BR", "en-US"]
        }
    }

    var localizedResponseLanguageName: String {
        switch self {
        case .japanese:
            return "Japanese"
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        case .korean:
            return "Korean"
        case .traditionalChinese:
            return "Traditional Chinese"
        case .french:
            return "French"
        case .german:
            return "German"
        case .brazilianPortuguese:
            return "Brazilian Portuguese"
        }
    }
}

enum L10n {
    static func tr(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: Locale.current, arguments: arguments)
    }

    static func checklistCount(_ count: Int) -> String {
        format("%lld件", count)
    }

    static func selectedCount(_ count: Int) -> String {
        format("%lld件選択中", count)
    }

    static func deleteItemsConfirmation(_ count: Int) -> String {
        format("%lld件のアイテムを削除しますか？", count)
    }

    static func deleteChecklistsConfirmation(_ count: Int) -> String {
        format("%lld件のチェックリストを削除しますか？この操作は取り消せません。", count)
    }

    static func deleteItemsButtonTitle(_ count: Int) -> String {
        format("削除（%lld件）", count)
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

    static func generatedChecklistTitle(_ condition: String, suffixKey: String) -> String {
        format("%1$@の%2$@", condition, tr(suffixKey))
    }

    static func todayPrefix(time: String) -> String {
        format("今日 %@", time)
    }

    static func yesterdayPrefix(time: String) -> String {
        format("昨日 %@", time)
    }
}
