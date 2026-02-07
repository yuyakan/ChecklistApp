import SwiftUI

struct ChecklistCardView: View {
    let checklist: Checklist

    var body: some View {
        VStack(alignment: .leading, spacing: NeumorphicSpacing.sm) {
            // Header: Category icon + Title + Input source
            HStack(spacing: NeumorphicSpacing.sm) {
                // Neumorphic category icon
                ZStack {
                    Circle()
                        .fill(Color.neumorphicSurface)
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: Color.neumorphicLightShadow,
                            radius: 3,
                            x: -2,
                            y: -2
                        )
                        .shadow(
                            color: Color.neumorphicDarkShadow,
                            radius: 3,
                            x: 2,
                            y: 2
                        )

                    Image(systemName: checklist.category.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.orangeGradient)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(checklist.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.neumorphicTextPrimary)
                        .lineLimit(1)

                    Text(checklist.category.description)
                        .font(.caption)
                        .foregroundStyle(Color.neumorphicTextSecondary)
                }

                Spacer()

                // Share status badge
                if checklist.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentOrangeStart)
                        .padding(NeumorphicSpacing.xs)
                        .background(
                            Circle()
                                .fill(Color.accentOrangeStart.opacity(0.15))
                        )
                }

                // Input source badge
                Image(systemName: checklist.inputSource.icon)
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextTertiary)
                    .padding(NeumorphicSpacing.xs)
                    .background(
                        Circle()
                            .fill(Color.neumorphicBackground)
                    )
            }

            // Progress section
            VStack(alignment: .leading, spacing: NeumorphicSpacing.xs) {
                HStack {
                    Text("進捗")
                        .font(.caption)
                        .foregroundStyle(Color.neumorphicTextSecondary)

                    Spacer()

                    // Progress count badge
                    HStack(spacing: 4) {
                        Text("\(checklist.completedCount)")
                            .fontWeight(.semibold)
                            .foregroundStyle(progressColor)
                        Text("/")
                            .foregroundStyle(Color.neumorphicTextTertiary)
                        Text("\(checklist.totalCount)")
                            .foregroundStyle(Color.neumorphicTextSecondary)
                    }
                    .font(.caption)
                    .monospacedDigit()
                }

                NeumorphicProgressBar(progress: checklist.progress)
            }

            // Footer: Completion badge + Updated date
            HStack {
                // Completion badge
                if checklist.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("完了")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, NeumorphicSpacing.sm)
                    .padding(.vertical, NeumorphicSpacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.statusSuccess)
                    )
                } else if checklist.progress > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("進行中")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.accentOrangeStart)
                    .padding(.horizontal, NeumorphicSpacing.sm)
                    .padding(.vertical, NeumorphicSpacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.accentOrangeStart.opacity(0.15))
                    )
                }

                Spacer()

                // Updated date
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(checklist.updatedAt.formatted(.dateTime.year().month(.defaultDigits).day()))
                        .font(.caption)
                }
                .foregroundStyle(Color.neumorphicTextTertiary)
            }
        }
        .padding(NeumorphicSpacing.md)
        .background(Color.neumorphicSurface)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.lg))
        .shadow(
            color: Color.neumorphicLightShadow,
            radius: 8,
            x: -4,
            y: -4
        )
        .shadow(
            color: Color.neumorphicDarkShadow,
            radius: 8,
            x: 4,
            y: 4
        )
    }

    private var progressColor: Color {
        .progress(checklist.progress, isCompleted: checklist.isCompleted)
    }
}

#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        VStack(spacing: NeumorphicSpacing.md) {
            ChecklistCardView(
                checklist: Checklist(
                    title: "買い物リスト",
                    category: .shopping,
                    items: [
                        ChecklistItemModel(name: "牛乳", isCompleted: true, order: 0),
                        ChecklistItemModel(name: "卵", isCompleted: true, order: 1),
                        ChecklistItemModel(name: "パン", isCompleted: false, order: 2),
                        ChecklistItemModel(name: "バター", isCompleted: false, order: 3)
                    ],
                    inputSource: .aiGenerated
                )
            )

            ChecklistCardView(
                checklist: Checklist(
                    title: "完了済みタスク",
                    category: .task,
                    items: [
                        ChecklistItemModel(name: "Task 1", isCompleted: true, order: 0),
                        ChecklistItemModel(name: "Task 2", isCompleted: true, order: 1)
                    ],
                    inputSource: .text
                )
            )

            ChecklistCardView(
                checklist: Checklist(
                    title: "新規チェックリスト",
                    category: .other,
                    items: [
                        ChecklistItemModel(name: "Item 1", isCompleted: false, order: 0),
                        ChecklistItemModel(name: "Item 2", isCompleted: false, order: 1)
                    ],
                    inputSource: .voice
                )
            )
        }
        .padding()
    }
}
