 import SwiftUI

struct TextInputView: View {
    @ObservedObject var viewModel: CreateChecklistViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // 説明
            VStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("テキストからチェックリストを作成")
                    .font(.headline)

                Text("箇条書き、段落、カンマ区切りなど\n様々な形式のテキストに対応")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            // テキスト入力フィールド
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("入力テキスト")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !viewModel.inputText.isEmpty {
                        Button("クリア") {
                            viewModel.inputText = ""
                        }
                        .font(.caption)
                    }
                }

                TextEditor(text: $viewModel.inputText)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if viewModel.inputText.isEmpty {
                            Text("例：\n・牛乳\n・卵\n・パン\n\nまたは\n\n牛乳、卵、パン、バター")
                                .foregroundStyle(.tertiary)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
            }

            // サンプル入力ボタン
            HStack {
                Text("サンプル:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("買い物リスト") {
                    viewModel.inputText = """
                    今日買うもの
                    - 牛乳 1本
                    - 卵 1パック
                    - 食パン
                    - バター
                    - ヨーグルト
                    """
                }
                .font(.caption)
                .buttonStyle(.bordered)

                Button("レシピ") {
                    viewModel.inputText = """
                    カレーの材料（4人分）
                    玉ねぎ 2個、にんじん 1本、じゃがいも 3個、
                    豚肉 300g、カレールー 1箱、水 800ml
                    """
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }

            // 変換ボタン
            Button {
                isTextFieldFocused = false
                Task {
                    await viewModel.processTextInput()
                }
            } label: {
                Label("チェックリストに変換", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)

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
}

#Preview {
    TextInputView(viewModel: CreateChecklistViewModel())
}
