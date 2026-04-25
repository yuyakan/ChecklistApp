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
        VStack(spacing: NeumorphicSpacing.lg) {
            // Header card
            headerCard

            // Input card
            inputCard

            // Suggestions
            suggestionsSection

            AIOptimizationHintCard()

            // Generate button
            NeumorphicAccentButton(
                title: "リストを生成",
                icon: "sparkles",
                action: generateChecklist,
                isDisabled: viewModel.conditionText.isEmpty || viewModel.isProcessing || viewModel.aiService.blocksInteraction
            )

            // Hint card
            hintCard
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
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.accentOrangeStart)

            VStack(alignment: .leading, spacing: 2) {
                Text("自動で作成")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Text("やりたいことを入力するだけでリストを自動作成")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }

            Spacer()
        }
        .padding(.vertical, NeumorphicSpacing.xs)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            Text("何のリストを作成しますか？")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.neumorphicTextSecondary)

            NeumorphicTextField(
                placeholder: "例: カレーの材料、引っ越しの手続き...",
                text: $viewModel.conditionText,
                icon: "sparkles"
            )
            .focused($isTextFieldFocused)
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .neumorphicShadow()
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
            Text("よく使われる例")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextTertiary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: NeumorphicSpacing.xs) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionChipButton(title: suggestion) {
                        viewModel.conditionText = suggestion
                    }
                }
            }
        }
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
            Label("ヒント", systemImage: "lightbulb.fill")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentOrangeStart)

            Text("具体的な条件を入力すると、より適切なリストが生成されます。")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextSecondary)

            Text("例: 「2泊3日の北海道旅行の持ち物」「4人家族のBBQで必要なもの」")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextTertiary)
        }
        .padding(NeumorphicSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentOrangeStart.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
    }

    private func generateChecklist() {
        isTextFieldFocused = false
        Task {
            await viewModel.generateChecklistFromCondition()
        }
    }
}

struct SuggestionChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(Color.neumorphicTextPrimary)
                .padding(.horizontal, NeumorphicSpacing.sm)
                .padding(.vertical, NeumorphicSpacing.xs)
                .frame(maxWidth: .infinity)
                .background(Color.neumorphicSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .neumorphicShadow(subtle: true)
    }
}

struct AIOptimizationHintCard: View {
    var body: some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundStyle(Color.accentOrangeStart)

            Text("利用可能な場合はApple Intelligenceを使用して結果を最適化します。")
                .font(.caption)
                .foregroundStyle(Color.neumorphicTextTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(NeumorphicSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
        .neumorphicShadow(subtle: true)
    }
}

#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()
        ScrollView {
            AIGenerateView(viewModel: CreateChecklistViewModel())
                .padding()
        }
    }
}
