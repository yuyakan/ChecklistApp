 import SwiftUI

struct ChecklistRowView: View {
    let checklist: Checklist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // カテゴリアイコン
                Image(systemName: checklist.category.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                // タイトル
                Text(checklist.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // 入力ソースアイコン
                Image(systemName: checklist.inputSource.icon)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                // 進捗バー
                ProgressView(value: checklist.progress)
                    .tint(progressColor)

                // 進捗テキスト
                Text("\(checklist.completedCount)/\(checklist.totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            HStack {
                // カテゴリラベル
                Text(checklist.category.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())

                Spacer()

                // 更新日時
                Text(checklist.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var progressColor: Color {
        if checklist.isCompleted {
            return .green
        } else if checklist.progress > 0.5 {
            return .blue
        } else if checklist.progress > 0 {
            return .orange
        } else {
            return .gray
        }
    }
}

#Preview {
    let checklist = Checklist(
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

    return List {
        ChecklistRowView(checklist: checklist)
    }
}
