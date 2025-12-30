 import SwiftUI

struct AIGenerateView: View {
    @ObservedObject var viewModel: CreateChecklistViewModel
    @FocusState private var isTextFieldFocused: Bool

    private let suggestions = [
        "カレーの材料",
        "引っ越しで必要な手続き",
        "キャンプの持ち物",
        "旅行の準備リスト",
        "大掃除のチェックリスト",
        "新生活に必要なもの"
    ]

    var body: some View {
        VStack(spacing: 20) {
            // 説明
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(.purple)

                Text("AIでチェックリストを生成")
                    .font(.headline)

                Text("やりたいことを入力するだけで\nAIが最適なリストを作成します")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            // 条件入力フィールド
            VStack(alignment: .leading, spacing: 8) {
                Text("何のリストを作成しますか？")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("例: カレーの材料、引っ越しの手続き...", text: $viewModel.conditionText)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.go)
                    .onSubmit {
                        generateChecklist()
                    }
            }

            // 提案ボタン
            VStack(alignment: .leading, spacing: 8) {
                Text("よく使われる例")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            viewModel.conditionText = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }

            // AI機能利用可否の確認
            if !viewModel.aiService.isAvailable {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)

                    Text("AI機能は現在利用できません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("このデバイスではFoundation Modelsが\nサポートされていません")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 生成ボタン
            Button {
                generateChecklist()
            } label: {
                Label("リストを生成", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(viewModel.conditionText.isEmpty || viewModel.isProcessing || !viewModel.aiService.isAvailable)

            // ヒント
            VStack(alignment: .leading, spacing: 4) {
                Label("ヒント", systemImage: "lightbulb")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text("具体的な条件を入力すると、より適切なリストが生成されます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("例: 「2泊3日の北海道旅行の持ち物」「4人家族のBBQで必要なもの」")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isTextFieldFocused = false
                }
            }
        }
    }

    private func generateChecklist() {
        isTextFieldFocused = false
        Task {
            await viewModel.generateChecklistFromCondition()
        }
    }
}

#Preview {
    AIGenerateView(viewModel: CreateChecklistViewModel())
}
