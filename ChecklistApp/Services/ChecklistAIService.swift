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
    case preparing(message: String)
    case temporarilyUnavailable(message: String)
    case blocked(message: String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    var blocksInteraction: Bool {
        return false
    }

    var message: String? {
        switch self {
        case .available:
            return nil
        case .preparing(let message), .temporarilyUnavailable(let message), .blocked(let message):
            return message
        }
    }
}

@MainActor
class ChecklistAIService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published private(set) var availabilityState: AIAvailabilityState = .temporarilyUnavailable(message: "AI機能の利用状態を確認しています")

    private var session: LanguageModelSession?
    private let model = SystemLanguageModel.default

    init() {
        refreshAvailability()
    }

    private func setupSession() {
        session = LanguageModelSession()
    }

    private func canUseFoundationModels() -> Bool {
        if case .available = model.availability {
            return true
        }
        return false
    }

    var isAvailable: Bool {
        availabilityState.isAvailable
    }

    var blocksInteraction: Bool {
        availabilityState.blocksInteraction
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
            availabilityState = .temporarilyUnavailable(message: "Apple Intelligenceを利用できないため、標準モードでリストを作成します")
            session = nil
        case .unavailable(.appleIntelligenceNotEnabled):
            availabilityState = .temporarilyUnavailable(message: "Apple Intelligenceがオフのため、標準モードでリストを作成します")
            session = nil
        case .unavailable(.modelNotReady):
            availabilityState = .preparing(message: "AIモデルを準備中のため、標準モードでリストを作成します")
            session = nil
        case .unavailable:
            availabilityState = .temporarilyUnavailable(message: "AI機能は一時的に利用できないため、標準モードでリストを作成します")
            session = nil
        @unknown default:
            availabilityState = .temporarilyUnavailable(message: "AI機能は一時的に利用できないため、標準モードでリストを作成します")
            session = nil
        }
    }

    private func availableSession() throws -> LanguageModelSession {
        refreshAvailability()

        switch model.availability {
        case .available:
            if session == nil {
                setupSession()
            }
        case .unavailable(.appleIntelligenceNotEnabled):
            throw AIServiceError.appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            throw AIServiceError.modelNotReady
        case .unavailable(.deviceNotEligible):
            throw AIServiceError.unsupportedDevice
        case .unavailable:
            throw AIServiceError.sessionCreationFailed
        @unknown default:
            throw AIServiceError.sessionCreationFailed
        }

        guard let session else {
            throw AIServiceError.sessionCreationFailed
        }

        return session
    }

    // MARK: - 入力テキストからチェックリスト抽出

    func extractChecklist(from text: String, source: InputSource) async throws -> ChecklistExtraction {
        isProcessing = true
        defer { isProcessing = false }

        let sourceDescription: String
        switch source {
        case .manual:
            sourceDescription = "手動で入力された"
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

        guard canUseFoundationModels() else {
            return fallbackExtraction(from: text, source: source)
        }

        do {
            let session = try availableSession()
            let response = try await session.respond(to: prompt, generating: ChecklistExtraction.self)
            return response.content
        } catch {
            return fallbackExtraction(from: text, source: source)
        }
    }

    // MARK: - 条件からチェックリスト生成

    func generateChecklist(for condition: String) async throws -> ChecklistGeneration {
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

        guard canUseFoundationModels() else {
            return fallbackGeneration(for: condition)
        }

        do {
            let session = try availableSession()
            let response = try await session.respond(to: prompt, generating: ChecklistGeneration.self)
            return response.content
        } catch {
            return fallbackGeneration(for: condition)
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

    // MARK: - Fallback generation

    private func fallbackExtraction(from text: String, source: InputSource) -> ChecklistExtraction {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = extractCandidateItems(from: cleanedText)
        let items = Array(candidates.prefix(20))

        return ChecklistExtraction(
            items: items.isEmpty ? [cleanedText] : items,
            suggestedTitle: fallbackTitle(from: cleanedText, source: source),
            category: inferCategory(from: cleanedText).rawValue
        )
    }

    private func fallbackGeneration(for condition: String) -> ChecklistGeneration {
        let trimmedCondition = condition.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = inferCategory(from: trimmedCondition)
        let items = fallbackTemplateItems(for: trimmedCondition, category: category)

        return ChecklistGeneration(
            items: items.enumerated().map { index, name in
                GeneratedChecklistItem(
                    name: name,
                    note: fallbackNote(for: name, category: category, index: index),
                    priority: "none"
                )
            },
            title: fallbackGenerationTitle(for: trimmedCondition, category: category),
            tips: fallbackTips(for: category),
            category: category.rawValue
        )
    }

    private func extractCandidateItems(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: "\n、,，・;；")
        let rawParts = text.components(separatedBy: separators)

        var items: [String] = []
        var seen = Set<String>()

        for rawPart in rawParts {
            let normalized = normalizeCandidate(rawPart)
            guard !normalized.isEmpty else { continue }
            guard seen.insert(normalized).inserted else { continue }
            items.append(normalized)
        }

        return items
    }

    private func normalizeCandidate(_ text: String) -> String {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let prefixes = ["- ", "• ", "・", "✓ ", "☑︎ ", "☑ ", "1. ", "2. ", "3. ", "4. ", "5. "]
        for prefix in prefixes where candidate.hasPrefix(prefix) {
            candidate.removeFirst(prefix.count)
        }

        return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func inferCategory(from text: String) -> Category {
        let normalized = text.lowercased()

        if normalized.contains("旅行") || normalized.contains("travel") || normalized.contains("出張") || normalized.contains("持ち物") {
            return .travel
        }
        if normalized.contains("料理") || normalized.contains("レシピ") || normalized.contains("カレー") || normalized.contains("材料") {
            return .cooking
        }
        if normalized.contains("買い物") || normalized.contains("購入") || normalized.contains("shopping") {
            return .shopping
        }
        if normalized.contains("手続き") || normalized.contains("申請") || normalized.contains("届け") {
            return .procedure
        }
        if normalized.contains("掃除") || normalized.contains("準備") || normalized.contains("確認") || normalized.contains("todo") || normalized.contains("タスク") {
            return .task
        }

        return .other
    }

    private func fallbackTitle(from text: String, source: InputSource) -> String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !firstLine.isEmpty && firstLine.count <= 24 {
            return firstLine
        }

        switch inferCategory(from: text) {
        case .shopping:
            return "買い物リスト"
        case .task:
            return "タスクリスト"
        case .procedure:
            return "手続きリスト"
        case .travel:
            return "持ち物リスト"
        case .cooking:
            return "材料リスト"
        case .other:
            switch source {
            case .photo:
                return "写真から作成したリスト"
            case .voice:
                return "音声から作成したリスト"
            case .text:
                return "テキストから作成したリスト"
            case .aiGenerated:
                return "自動作成リスト"
            case .manual:
                return "チェックリスト"
            }
        }
    }

    private func fallbackGenerationTitle(for condition: String, category: Category) -> String {
        if condition.hasSuffix("リスト") || condition.hasSuffix("チェックリスト") {
            return condition
        }

        switch category {
        case .shopping:
            return "\(condition)の買い物リスト"
        case .task:
            return "\(condition)のチェックリスト"
        case .procedure:
            return "\(condition)の手続きリスト"
        case .travel:
            return "\(condition)の持ち物リスト"
        case .cooking:
            return "\(condition)の材料リスト"
        case .other:
            return "\(condition)のチェックリスト"
        }
    }

    private func fallbackTemplateItems(for condition: String, category: Category) -> [String] {
        let normalized = condition.lowercased()

        if normalized.contains("カレー") {
            return ["玉ねぎ", "にんじん", "じゃがいも", "肉", "カレールー", "油", "水"]
        }
        if normalized.contains("引っ越し") {
            return ["転出届", "転入届", "電気の開始・停止手続き", "ガスの開始・停止手続き", "水道の開始・停止手続き", "住所変更", "荷造り", "不用品の処分"]
        }
        if normalized.contains("旅行") || normalized.contains("出張") {
            return ["身分証", "現金・カード", "スマートフォン", "充電器", "着替え", "洗面用具", "交通・宿泊予約の確認", "常備薬"]
        }
        if normalized.contains("キャンプ") {
            return ["テント", "寝袋", "マット", "ランタン", "調理器具", "食材", "飲み物", "救急用品"]
        }
        if normalized.contains("大掃除") || normalized.contains("掃除") {
            return ["掃除場所を決める", "洗剤を準備する", "不要品を分別する", "高い場所から掃除する", "水回りを掃除する", "ゴミを回収する"]
        }
        if normalized.contains("新生活") {
            return ["寝具", "カーテン", "冷蔵庫", "洗濯用品", "調理器具", "日用品", "住所変更手続き", "インターネット契約"]
        }

        switch category {
        case .shopping:
            return ["必要な物を洗い出す", "在庫を確認する", "優先度の高い物から購入する", "予算を確認する", "買い忘れを見直す"]
        case .task:
            return ["やることを整理する", "期限を確認する", "優先順位を決める", "必要な準備をする", "完了後に見直す"]
        case .procedure:
            return ["必要書類を確認する", "提出先を確認する", "申請期限を確認する", "申請を行う", "受付結果を確認する"]
        case .travel:
            return ["移動手段を確認する", "宿泊先を確認する", "必要な持ち物を準備する", "天気を確認する", "当日の連絡手段を確認する"]
        case .cooking:
            return ["材料を確認する", "不足している材料をそろえる", "調味料を確認する", "調理手順を確認する", "保存容器を準備する"]
        case .other:
            return ["必要事項を整理する", "優先度を決める", "準備物を確認する", "実施する", "完了後に見直す"]
        }
    }

    private func fallbackNote(for item: String, category: Category, index: Int) -> String? {
        if index > 2 {
            return nil
        }

        switch category {
        case .procedure:
            return "事前に受付時間や必要書類を確認しておくとスムーズです。"
        case .travel:
            return "出発前日に不足がないか見直してください。"
        case .cooking:
            return "分量や代用品を事前に確認しておくと調理しやすくなります。"
        default:
            return "必要に応じて詳細を追記してください。"
        }
    }

    private func fallbackTips(for category: Category) -> String {
        switch category {
        case .shopping:
            return "買い物前に在庫確認をすると無駄な購入を減らせます。"
        case .task:
            return "先に期限と優先度を決めると進めやすくなります。"
        case .procedure:
            return "提出先、必要書類、期限の3点を最初に確認してください。"
        case .travel:
            return "天気と移動手段を確認してから荷物を最終調整してください。"
        case .cooking:
            return "材料と調味料を先に並べると作業が安定します。"
        case .other:
            return "まず必要事項を洗い出し、終わった項目から順にチェックしてください。"
        }
    }
}
