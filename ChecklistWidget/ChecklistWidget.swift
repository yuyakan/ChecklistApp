import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct ChecklistEntry: TimelineEntry {
    let date: Date
    let checklist: ChecklistWidgetData?
}

struct ChecklistWidgetData {
    let id: UUID
    let title: String
    let completedCount: Int
    let totalCount: Int
    let categoryIcon: String

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var isCompleted: Bool {
        totalCount > 0 && completedCount == totalCount
    }
}

// MARK: - Timeline Provider

struct ChecklistTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChecklistEntry {
        ChecklistEntry(
            date: Date(),
            checklist: ChecklistWidgetData(
                id: UUID(),
                title: "サンプルリスト",
                completedCount: 3,
                totalCount: 5,
                categoryIcon: "cart.fill"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChecklistEntry) -> Void) {
        let entry = ChecklistEntry(
            date: Date(),
            checklist: placeholder(in: context).checklist
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChecklistEntry>) -> Void) {
        // プレースホルダーデータを使用
        // 実際の実装ではApp Groupsを使用してメインアプリとデータを共有
        let entry = ChecklistEntry(
            date: Date(),
            checklist: placeholder(in: context).checklist
        )

        // 15分ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct ChecklistWidgetEntryView: View {
    var entry: ChecklistEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(checklist: entry.checklist)
        case .systemMedium:
            MediumWidgetView(checklist: entry.checklist)
        default:
            SmallWidgetView(checklist: entry.checklist)
        }
    }
}

struct SmallWidgetView: View {
    let checklist: ChecklistWidgetData?

    var body: some View {
        if let checklist = checklist {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: checklist.categoryIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if checklist.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Text(checklist.title)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()

                ProgressView(value: checklist.progress)
                    .tint(progressColor(for: checklist))

                Text("\(checklist.completedCount)/\(checklist.totalCount) 完了")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("チェックリストがありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func progressColor(for checklist: ChecklistWidgetData) -> Color {
        if checklist.isCompleted {
            return .green
        } else if checklist.progress > 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
}

struct MediumWidgetView: View {
    let checklist: ChecklistWidgetData?

    var body: some View {
        if let checklist = checklist {
            HStack(spacing: 16) {
                // 左側: 進捗円グラフ
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: checklist.progress)
                        .stroke(progressColor(for: checklist), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(checklist.progress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("完了")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                // 右側: 情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: checklist.categoryIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if checklist.isCompleted {
                            Label("完了", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Text(checklist.title)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    Text("\(checklist.completedCount)/\(checklist.totalCount) 項目完了")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
        } else {
            HStack {
                Image(systemName: "checklist")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading) {
                    Text("チェックリストがありません")
                        .font(.headline)

                    Text("アプリで新しいリストを作成してください")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
        }
    }

    private func progressColor(for checklist: ChecklistWidgetData) -> Color {
        if checklist.isCompleted {
            return .green
        } else if checklist.progress > 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Widget Definition

@main
struct ChecklistWidget: Widget {
    let kind: String = "ChecklistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChecklistTimelineProvider()) { entry in
            ChecklistWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("チェックリスト")
        .description("進行中のチェックリストの進捗を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    ChecklistWidget()
} timeline: {
    ChecklistEntry(
        date: Date(),
        checklist: ChecklistWidgetData(
            id: UUID(),
            title: "買い物リスト",
            completedCount: 3,
            totalCount: 5,
            categoryIcon: "cart.fill"
        )
    )

    ChecklistEntry(
        date: Date(),
        checklist: nil
    )
}

#Preview("Medium", as: .systemMedium) {
    ChecklistWidget()
} timeline: {
    ChecklistEntry(
        date: Date(),
        checklist: ChecklistWidgetData(
            id: UUID(),
            title: "引っ越し準備リスト",
            completedCount: 7,
            totalCount: 10,
            categoryIcon: "doc.text.fill"
        )
    )
}
