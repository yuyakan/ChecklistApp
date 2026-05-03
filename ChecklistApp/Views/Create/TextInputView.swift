import SwiftUI

struct TextInputView: View {
    @ObservedObject var viewModel: CreateChecklistViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: NeumorphicSpacing.lg) {
            // Header card
            headerCard

            // Text input card
            textInputCard

            // Sample chips
            sampleChips

            AIOptimizationHintCard()

            // Convert button
            NeumorphicAccentButton(
                title: L10n.tr("チェックリストに変換"),
                icon: "sparkles",
                action: {
                    isTextFieldFocused = false
                    Task {
                        await viewModel.processTextInput()
                    }
                },
                isDisabled: viewModel.inputText.isEmpty || viewModel.isProcessing || viewModel.aiService.blocksInteraction
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isTextFieldFocused = false
                }
                .foregroundStyle(Color.accentOrangeStart)
            }
        }
        .onAppear {
            viewModel.aiService.refreshAvailability()
        }
    }

    private var headerCard: some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            Image(systemName: "text.alignleft")
                .font(.title3)
                .foregroundStyle(Color.accentOrangeStart)

            VStack(alignment: .leading, spacing: 2) {
                Text("テキストから作成")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Text("箇条書き、カンマ区切りなど様々な形式に対応")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }

            Spacer()
        }
        .padding(.vertical, NeumorphicSpacing.xs)
    }

    private var textInputCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            HStack {
                Text("入力テキスト")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextSecondary)

                Spacer()

                if !viewModel.inputText.isEmpty {
                    Button {
                        viewModel.inputText = ""
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("クリア")
                        }
                        .font(.caption)
                        .foregroundStyle(Color.neumorphicTextTertiary)
                    }
                }
            }

            NeumorphicTextEditor(
                text: $viewModel.inputText,
                placeholder: L10n.tr("例：\n・牛乳\n・卵\n・パン\n\nまたは\n\n牛乳、卵、パン、バター")
            )
            .focused($isTextFieldFocused)
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private var sampleChips: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
            Text("サンプル")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextTertiary)

            HStack(spacing: NeumorphicSpacing.sm) {
                SampleChipButton(title: L10n.tr("買い物リスト"), icon: "cart") {
                    viewModel.inputText = L10n.tr("""
                    今日買うもの
                    - 牛乳 1本
                    - 卵 1パック
                    - 食パン
                    - バター
                    - ヨーグルト
                    """)
                }

                SampleChipButton(title: L10n.tr("レシピ"), icon: "frying.pan") {
                    viewModel.inputText = L10n.tr("""
                    カレーの材料（4人分）
                    玉ねぎ 2個、にんじん 1本、じゃがいも 3個、
                    豚肉 300g、カレールー 1箱、水 800ml
                    """)
                }
            }
        }
    }
}

struct SampleChipButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.accentOrangeStart)
            .padding(.horizontal, NeumorphicSpacing.sm)
            .padding(.vertical, NeumorphicSpacing.xs)
            .background(Color.neumorphicSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.accentOrangeStart.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#if false
#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()
        ScrollView {
            TextInputView(viewModel: CreateChecklistViewModel())
                .padding()
        }
    }
}
#endif
