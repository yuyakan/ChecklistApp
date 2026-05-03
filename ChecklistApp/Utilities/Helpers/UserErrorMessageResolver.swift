import Foundation
import CloudKit

enum UserErrorContext {
    case checklistCreation
    case cloudShare
    case speechRecognition
    case generic
}

enum UserErrorMessageResolver {
    static func message(for error: Error, context: UserErrorContext = .generic) -> String {
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .sessionCreationFailed, .unsupportedDevice:
                return L10n.tr("このデバイスではAI機能を利用できません。対応デバイス、OSバージョン、言語/地域設定をご確認ください。")
            case .appleIntelligenceNotEnabled:
                return L10n.tr("Apple IntelligenceがオフのためAI機能を利用できません。設定アプリでApple Intelligenceをオンにしてください。")
            case .modelNotReady:
                return L10n.tr("AIモデルを準備中です。ネットワーク接続と空き容量を確認し、しばらくしてから再度お試しください。")
            case .generationFailed(let detail):
                let normalizedDetail = detail.lowercased()
                if normalizedDetail.contains("model assets are unavailable") {
                    return L10n.tr("AIモデルを準備中です。ネットワーク接続と空き容量を確認し、しばらくしてから再度お試しください。")
                }
                if normalizedDetail.contains("not authenticated") {
                    return L10n.tr("Apple Accountへのサインインが必要です。設定アプリからサインイン状態をご確認ください。")
                }
                if normalizedDetail.contains("unsupported")
                    || normalizedDetail.contains("not available in current locale")
                    || normalizedDetail.contains("language") {
                    return L10n.tr("この言語・地域設定ではAI機能を利用できません。設定アプリの言語/地域設定をご確認ください。")
                }
                return L10n.tr("チェックリストの生成に失敗しました。通信環境と端末状況を確認し、再度お試しください。")
            }
        }

        if let textError = error as? TextRecognitionError {
            switch textError {
            case .invalidImage:
                return L10n.tr("画像を読み込めませんでした。別の画像でお試しください。")
            case .noTextFound:
                return L10n.tr("画像内の文字を読み取れませんでした。はっきり写っている画像でお試しください。")
            case .recognitionFailed:
                return L10n.tr("文字の読み取りに失敗しました。時間をおいて再度お試しください。")
            }
        }

        if let cloudKitError = error as? CloudKitError {
            switch cloudKitError {
            case .notAuthenticated:
                return L10n.tr("iCloudにサインインしてください。設定アプリでApple Accountのサインイン状態をご確認ください。")
            case .containerNotFound:
                return L10n.tr("共有機能の初期化に失敗しました。しばらくしてから再度お試しください。")
            case .sharingFailed, .fetchFailed:
                return L10n.tr("iCloud共有に失敗しました。通信環境とiCloud Drive設定をご確認のうえ、再度お試しください。")
            }
        }

        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return L10n.tr("iCloudにサインインしてください。設定アプリでApple Accountのサインイン状態をご確認ください。")
            case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
                return L10n.tr("iCloudに接続できませんでした。通信環境を確認して再度お試しください。")
            case .permissionFailure:
                return L10n.tr("iCloud共有の権限が不足しています。設定アプリでiCloud Driveと本アプリのiCloud利用設定をご確認ください。")
            default:
                return L10n.tr("iCloud共有に失敗しました。しばらくしてから再度お試しください。")
            }
        }

        switch context {
        case .checklistCreation:
            return L10n.tr("チェックリストの作成に失敗しました。しばらくしてから再度お試しください。")
        case .cloudShare:
            return L10n.tr("iCloud共有に失敗しました。しばらくしてから再度お試しください。")
        case .speechRecognition:
            return L10n.tr("音声認識の開始に失敗しました。権限と通信環境をご確認ください。")
        case .generic:
            return L10n.tr("エラーが発生しました。しばらくしてから再度お試しください。")
        }
    }
}
