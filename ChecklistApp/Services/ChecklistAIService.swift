import Foundation
import FoundationModels
 import Combine

enum AIServiceError: LocalizedError {
    case sessionCreationFailed
    case generationFailed(String)
    case unsupportedDevice

    var errorDescription: String? {
        switch self {
        case .sessionCreationFailed:
            return "AIセッションの作成に失敗しました"
        case .generationFailed(let message):
            return "生成に失敗しました: \(message)"
        case .unsupportedDevice:
            return "このデバイスではAI機能がサポートされていません"
        }
    }
}

@MainActor
class ChecklistAIService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private var session: LanguageModelSession?

    init() {
        setupSession()
    }

    private func setupSession() {
        session = LanguageModelSession()
    }

    var isAvailable: Bool {
        return session != nil
    }

    // MARK: - 入力テキストからチェックリスト抽出

    func extractChecklist(from text: String, source: InputSource) async throws -> ChecklistExtraction {
        guard let session = session else {
            throw AIServiceError.sessionCreationFailed
        }

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

        - 各項目は具体的で実行可能な形式にしてください
        - 重複を避け、整理してください
        - 適切なタイトルとカテゴリを推測してください

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
        guard let session = session else {
            throw AIServiceError.sessionCreationFailed
        }

        isProcessing = true
        defer { isProcessing = false }

        let prompt = """
        「\(condition)」に関する実用的なチェックリストを作成してください。

        要件:
        - 一般的に必要とされる項目を網羅的にリストアップしてください
        - 各項目には適切な優先度（high, medium, low）を設定してください
        - 重要な項目には補足説明を追加してください
        - 実践的で役立つアドバイスをtipsとして提供してください
        - 適切なカテゴリを選択してください（shopping, task, procedure, travel, cooking, other）
        """

        do {
            let response = try await session.respond(to: prompt, generating: ChecklistGeneration.self)
            return response.content
        } catch {
            throw AIServiceError.generationFailed(error.localizedDescription)
        }
    }

    // MARK: - チェックリストモデルへの変換

    func createChecklist(from extraction: ChecklistExtraction, source: InputSource) -> Checklist {
        let items = extraction.items.enumerated().map { index, itemName in
            ChecklistItemModel(
                name: itemName,
                note: nil,
                isCompleted: false,
                priority: .medium,
                order: index
            )
        }

        return Checklist(
            title: extraction.suggestedTitle,
            category: extraction.toCategory(),
            items: items,
            inputSource: source
        )
    }

    func createChecklist(from generation: ChecklistGeneration) -> Checklist {
        let items = generation.items.enumerated().map { index, item in
            item.toChecklistItemModel(order: index)
        }

        return Checklist(
            title: generation.title,
            category: generation.toCategory(),
            items: items,
            inputSource: .aiGenerated
        )
    }
}
