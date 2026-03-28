import Foundation
import FoundationModels
import Combine

enum AIServiceError: LocalizedError {
    case sessionCreationFailed
    case generationFailed(String)
    case unsupportedDevice
    case appleIntelligenceNotEnabled
    case modelNotReady

    var errorDescription: String? {
        switch self {
        case .sessionCreationFailed:
            return "AIセッションの作成に失敗しました"
        case .generationFailed:
            return "生成に失敗しました"
        case .unsupportedDevice:
            return "このデバイスではAI機能がサポートされていません"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligenceがオフになっています"
        case .modelNotReady:
            return "AIモデルの準備が完了していません"
        }
    }
}

enum AIAvailabilityState: Equatable {
    case available
    case unavailable(message: String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    var message: String? {
        switch self {
        case .available:
            return nil
        case .unavailable(let message):
            return message
        }
    }
}

@MainActor
class ChecklistAIService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published private(set) var availabilityState: AIAvailabilityState = .unavailable(message: "AI機能の利用状態を確認しています")

    private var session: LanguageModelSession?
    private let model = SystemLanguageModel.default

    init() {
        refreshAvailability()
    }

    private func setupSession() {
        session = LanguageModelSession()
    }

    var isAvailable: Bool {
        availabilityState.isAvailable
    }

    var availabilityMessage: String? {
        availabilityState.message
    }

    func refreshAvailability() {
        switch model.availability {
        case .available:
            availabilityState = .available
            setupSession()
        case .unavailable(.deviceNotEligible):
            availabilityState = .unavailable(message: "このデバイスではFoundation Modelsを利用できません。Apple Intelligenceの設定もあわせてご確認ください")
            session = nil
        case .unavailable(.appleIntelligenceNotEnabled):
            availabilityState = .unavailable(message: "Apple IntelligenceがオフのためAI機能を利用できません。設定アプリでApple Intelligenceの設定をご確認ください")
            session = nil
        case .unavailable(.modelNotReady):
            availabilityState = .unavailable(message: "AIモデルの準備が完了していないため、現在は利用できません。設定アプリでApple Intelligenceの設定をご確認ください")
            session = nil
        case .unavailable:
            availabilityState = .unavailable(message: "AI機能は現在利用できません。設定アプリでApple Intelligenceの設定と端末状況をご確認ください")
            session = nil
        @unknown default:
            availabilityState = .unavailable(message: "AI機能は現在利用できません。設定アプリでApple Intelligenceの設定と端末状況をご確認ください")
            session = nil
        }
    }

    private func availableSession() throws -> LanguageModelSession {
        refreshAvailability()

        guard availabilityState.isAvailable else {
            switch model.availability {
            case .unavailable(.appleIntelligenceNotEnabled):
                throw AIServiceError.appleIntelligenceNotEnabled
            case .unavailable(.modelNotReady):
                throw AIServiceError.modelNotReady
            case .unavailable(.deviceNotEligible):
                throw AIServiceError.unsupportedDevice
            case .unavailable:
                throw AIServiceError.sessionCreationFailed
            case .available:
                throw AIServiceError.sessionCreationFailed
            @unknown default:
                throw AIServiceError.sessionCreationFailed
            }
        }

        guard let session else {
            throw AIServiceError.sessionCreationFailed
        }

        return session
    }

    // MARK: - 入力テキストからチェックリスト抽出

    func extractChecklist(from text: String, source: InputSource) async throws -> ChecklistExtraction {
        let session = try availableSession()

        isProcessing = true
        defer { isProcessing = false }

        let sourceDescription: String
        switch source {
        case .photo:
            sourceDescription = "写真から抽出された"
        case .voice:
            sourceDescription = "音声から認識された"
        case .text:
            sourceDescription = "入力された"
        case .aiGenerated:
            sourceDescription = "指定された"
        }

        let prompt = """
        以下の\(sourceDescription)テキストを分析し、チェックリストとして適切な項目を抽出してください。

        - 重複を避け、整理してください
        - 適切なタイトルとカテゴリを推測してください

        項目名の形式について（重要）:
        - 買い物リスト・材料リスト・持ち物リストなど「物」を列挙する場合は、名詞・単語のみで記載してください
          例: ○「りんご」「牛乳」「パスポート」 ×「りんごを買う」「牛乳を購入する」
        - 手順・作業・タスクなど「動作」を列挙する場合のみ、動詞を含めた文で記載してください
          例: ○「予約を確認する」「書類を提出する」

        入力テキスト:
        \(text)
        """

        do {
            let response = try await session.respond(to: prompt, generating: ChecklistExtraction.self)
            return response.content
        } catch {
            throw AIServiceError.generationFailed(error.localizedDescription)
        }
    }

    // MARK: - 条件からチェックリスト生成

    func generateChecklist(for condition: String) async throws -> ChecklistGeneration {
        let session = try availableSession()

        isProcessing = true
        defer { isProcessing = false }

        let prompt = """
        「\(condition)」に関する実用的なチェックリストを作成してください。

        要件:
        - 一般的に必要とされる項目を網羅的にリストアップしてください
        - 重要な項目には補足説明を追加してください
        - 実践的で役立つアドバイスをtipsとして提供してください
        - 適切なカテゴリを選択してください（shopping, task, procedure, travel, cooking, other）

        項目名の形式について（重要）:
        - 買い物リスト・材料リスト・持ち物リストなど「物」を列挙する場合は、名詞・単語のみで記載してください
          例: ○「りんご」「牛乳」「パスポート」 ×「りんごを買う」「牛乳を購入する」
        - 手順・作業・タスクなど「動作」を列挙する場合のみ、動詞を含めた文で記載してください
          例: ○「予約を確認する」「書類を提出する」

        優先度について:
        - 全ての項目の priority は必ず "none" にしてください
        """

        do {
            let response = try await session.respond(to: prompt, generating: ChecklistGeneration.self)
            return response.content
        } catch {
            throw AIServiceError.generationFailed(error.localizedDescription)
        }
    }

    // MARK: - チェックリストDTOへの変換

    func createDraft(from extraction: ChecklistExtraction, source: InputSource) -> ChecklistDraft {
        let items = extraction.items.enumerated().map { index, itemName in
            ChecklistDraft.ItemDraft(
                name: itemName,
                note: nil,
                priority: nil,
                order: index
            )
        }

        return ChecklistDraft(
            title: extraction.suggestedTitle,
            category: extraction.toCategory(),
            items: items,
            inputSource: source
        )
    }

    func createDraft(from generation: ChecklistGeneration) -> ChecklistDraft {
        let items = generation.items.enumerated().map { index, item in
            item.toItemDraft(order: index)
        }

        return ChecklistDraft(
            title: generation.title,
            category: generation.toCategory(),
            items: items,
            inputSource: .aiGenerated
        )
    }
}
