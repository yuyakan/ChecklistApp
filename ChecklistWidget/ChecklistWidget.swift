import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - App Group Container

enum WidgetAppGroupContainer {
    static let appGroupIdentifier = "group.com.checklistapp.shared"
    private static let currentIndexKey = "widget_current_checklist_index"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static var currentIndex: Int {
        get { userDefaults?.integer(forKey: currentIndexKey) ?? 0 }
        set { userDefaults?.set(newValue, forKey: currentIndexKey) }
    }

    static var modelContainer: ModelContainer? {
        guard let containerURL = containerURL else {
            print("Widget: App Groups not configured")
            return nil
        }

        let schema = Schema([
            Checklist.self,
            ChecklistItemModel.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: containerURL.appendingPathComponent("ChecklistApp.store"),
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Widget could not create ModelContainer: \(error)")
            return nil
        }
    }
}

// MARK: - Widget Data Models

struct ChecklistItemWidgetData: Identifiable {
    let id: UUID
    let name: String
    let isCompleted: Bool
    let order: Int
}

struct ChecklistWidgetData {
    let id: UUID
    let title: String
    let completedCount: Int
    let totalCount: Int
    let categoryIcon: String
    let items: [ChecklistItemWidgetData]

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var isCompleted: Bool {
        totalCount > 0 && completedCount == totalCount
    }
}

// MARK: - Widget Entry

struct ChecklistEntry: TimelineEntry {
    let date: Date
    let checklist: ChecklistWidgetData?
    let index: Int
    let totalCount: Int
}

// MARK: - App Intent for Toggle

struct ToggleItemIntent: AppIntent {
    static var title: LocalizedStringResource = "チェック切り替え"
    static var description = IntentDescription("チェックリストアイテムの完了状態を切り替えます")

    @Parameter(title: "Item ID")
    var itemId: String

    @Parameter(title: "Checklist ID")
    var checklistId: String

    init() {}

    init(itemId: UUID, checklistId: UUID) {
        self.itemId = itemId.uuidString
        self.checklistId = checklistId.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let container = WidgetAppGroupContainer.modelContainer else {
            return .result()
        }

        let context = ModelContext(container)
        guard let itemUUID = UUID(uuidString: itemId) else {
            return .result()
        }

        let descriptor = FetchDescriptor<ChecklistItemModel>()

        do {
            let items = try context.fetch(descriptor)
            if let item = items.first(where: { $0.id == itemUUID }) {
                item.isCompleted.toggle()
                item.checklist?.updatedAt = Date()
                try context.save()
            }
        } catch {
            print("Toggle error: \(error)")
        }

        return .result()
    }
}

struct NextChecklistIntent: AppIntent {
    static var title: LocalizedStringResource = "次のチェックリスト"
    static var description = IntentDescription("次のチェックリストを表示します")

    @Parameter(title: "Total Count")
    var totalCount: Int

    init() {
        self.totalCount = 1
    }

    init(totalCount: Int) {
        self.totalCount = totalCount
    }

    func perform() async throws -> some IntentResult {
        guard totalCount > 1 else { return .result() }

        let currentIndex = WidgetAppGroupContainer.currentIndex
        let nextIndex = (currentIndex + 1) % totalCount
        WidgetAppGroupContainer.currentIndex = nextIndex

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct PreviousChecklistIntent: AppIntent {
    static var title: LocalizedStringResource = "前のチェックリスト"
    static var description = IntentDescription("前のチェックリストを表示します")

    @Parameter(title: "Total Count")
    var totalCount: Int

    init() {
        self.totalCount = 1
    }

    init(totalCount: Int) {
        self.totalCount = totalCount
    }

    func perform() async throws -> some IntentResult {
        guard totalCount > 1 else { return .result() }

        let currentIndex = WidgetAppGroupContainer.currentIndex
        let prevIndex = (currentIndex - 1 + totalCount) % totalCount
        WidgetAppGroupContainer.currentIndex = prevIndex

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
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
                categoryIcon: "cart.fill",
                items: [
                    ChecklistItemWidgetData(id: UUID(), name: "牛乳", isCompleted: true, order: 0),
                    ChecklistItemWidgetData(id: UUID(), name: "パン", isCompleted: true, order: 1),
                    ChecklistItemWidgetData(id: UUID(), name: "卵", isCompleted: true, order: 2),
                    ChecklistItemWidgetData(id: UUID(), name: "野菜", isCompleted: false, order: 3),
                    ChecklistItemWidgetData(id: UUID(), name: "果物", isCompleted: false, order: 4),
                ]
            ),
            index: 0,
            totalCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChecklistEntry) -> Void) {
        let checklists = fetchIncompleteChecklists()
        if let first = checklists.first {
            let entry = ChecklistEntry(
                date: Date(),
                checklist: first,
                index: 0,
                totalCount: checklists.count
            )
            completion(entry)
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChecklistEntry>) -> Void) {
        let checklists = fetchIncompleteChecklists()
        let currentDate = Date()

        let entry: ChecklistEntry
        if checklists.isEmpty {
            entry = ChecklistEntry(
                date: currentDate,
                checklist: nil,
                index: 0,
                totalCount: 0
            )
        } else {
            // 保存されたインデックスを取得（範囲外なら0にリセット）
            var currentIndex = WidgetAppGroupContainer.currentIndex
            if currentIndex >= checklists.count {
                currentIndex = 0
                WidgetAppGroupContainer.currentIndex = 0
            }

            entry = ChecklistEntry(
                date: currentDate,
                checklist: checklists[currentIndex],
                index: currentIndex,
                totalCount: checklists.count
            )
        }

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchIncompleteChecklists() -> [ChecklistWidgetData] {
        guard let container = WidgetAppGroupContainer.modelContainer else {
            return []
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Checklist>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            let checklists = try context.fetch(descriptor)
            // アイテムが0個、または未完了のアイテムがあるチェックリストを表示
            return checklists
                .filter { $0.totalCount == 0 || !$0.isCompleted }
                .map { checklist in
                    let items = checklist.sortedItems.map { item in
                        ChecklistItemWidgetData(
                            id: item.id,
                            name: item.name,
                            isCompleted: item.isCompleted,
                            order: item.order
                        )
                    }
                    return ChecklistWidgetData(
                        id: checklist.id,
                        title: checklist.title,
                        completedCount: checklist.completedCount,
                        totalCount: checklist.totalCount,
                        categoryIcon: checklist.category.icon,
                        items: items
                    )
                }
        } catch {
            print("Widget fetch error: \(error)")
            return []
        }
    }
}

// MARK: - Widget Views

struct ChecklistWidgetEntryView: View {
    var entry: ChecklistEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: ChecklistEntry

    var body: some View {
        if let checklist = entry.checklist {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: checklist.categoryIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    NavigationButtons(current: entry.index, total: entry.totalCount, compact: true)
                }

                Text(checklist.title)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()

                ProgressView(value: checklist.progress)
                    .tint(progressColor(for: checklist.progress))

                Text("\(checklist.completedCount)/\(checklist.totalCount) 完了")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            EmptyStateView()
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: ChecklistEntry

    var body: some View {
        if let checklist = entry.checklist {
            HStack(spacing: 16) {
                // 左側: 進捗円グラフ（固定サイズ）
                ProgressCircleView(progress: checklist.progress)
                    .frame(width: 80, height: 80)
                    .fixedSize()

                // 右側: 情報とアイテム
                VStack(alignment: .leading, spacing: 0) {
                    // ヘッダー（固定高さ）
                    HStack {
                        Image(systemName: checklist.categoryIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(checklist.title)
                            .font(.headline)
                            .lineLimit(1)

                        Spacer()

                        NavigationButtons(current: entry.index, total: entry.totalCount, compact: true)
                    }
                    .frame(height: 24)
                    .padding(.bottom, 4)

                    // アイテムリスト
                    ForEach(checklist.items.prefix(3)) { item in
                        ChecklistItemRow(item: item, checklistId: checklist.id, compact: true)
                    }

                    if checklist.items.count > 3 {
                        Text("他 \(checklist.items.count - 3) 件...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }

                Spacer()
            }
            .padding()
        } else {
            EmptyStateView()
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: ChecklistEntry

    private let headerHeight: CGFloat = 70
    private let maxVisibleItems = 7

    var body: some View {
        if let checklist = entry.checklist {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    // ヘッダー（固定高さ）
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: checklist.categoryIcon)
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            Text(checklist.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            Spacer()

                            NavigationButtons(current: entry.index, total: entry.totalCount, compact: false)
                        }

                        HStack {
                            ProgressView(value: checklist.progress)
                                .tint(progressColor(for: checklist.progress))

                            Text("\(checklist.completedCount)/\(checklist.totalCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 40)
                        }

                        Divider()
                    }
                    .frame(height: headerHeight)

                    // アイテムリスト（残りのスペース）
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(checklist.items.prefix(maxVisibleItems)) { item in
                            ChecklistItemRow(item: item, checklistId: checklist.id, compact: false)
                        }

                        if checklist.items.count > maxVisibleItems {
                            HStack {
                                Spacer()
                                Text("他 \(checklist.items.count - maxVisibleItems) 件")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .frame(height: geometry.size.height - headerHeight, alignment: .top)
                }
            }
            .padding()
        } else {
            EmptyStateView()
        }
    }
}

// MARK: - Reusable Components

struct ChecklistItemRow: View {
    let item: ChecklistItemWidgetData
    let checklistId: UUID
    let compact: Bool

    var body: some View {
        Button(intent: ToggleItemIntent(itemId: item.id, checklistId: checklistId)) {
            HStack(spacing: 8) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(compact ? .caption : .body)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)

                Text(item.name)
                    .font(compact ? .caption : .subheadline)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.vertical, compact ? 2 : 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ProgressCircleView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor(for: progress), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("完了")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.primary : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

struct NavigationButtons: View {
    let current: Int
    let total: Int
    let compact: Bool

    var body: some View {
        if total > 1 {
            HStack(spacing: compact ? 4 : 8) {
                Button(intent: PreviousChecklistIntent(totalCount: total)) {
                    Image(systemName: "chevron.left")
                        .font(compact ? .caption2 : .caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: compact ? 20 : 24, height: compact ? 20 : 24)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(current + 1)/\(total)")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Button(intent: NextChecklistIntent(totalCount: total)) {
                    Image(systemName: "chevron.right")
                        .font(compact ? .caption2 : .caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: compact ? 20 : 24, height: compact ? 20 : 24)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.green)

            Text("すべて完了！")
                .font(.headline)

            Text("未完了のリストはありません")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Helper Functions

func progressColor(for progress: Double) -> Color {
    if progress > 0.7 {
        return .green
    } else if progress > 0.3 {
        return .blue
    } else {
        return .orange
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
        .description("未完了のチェックリストの進捗を表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
            categoryIcon: "cart.fill",
            items: []
        ),
        index: 0,
        totalCount: 3
    )
}

#Preview("Medium", as: .systemMedium) {
    ChecklistWidget()
} timeline: {
    ChecklistEntry(
        date: Date(),
        checklist: ChecklistWidgetData(
            id: UUID(),
            title: "買い物リスト",
            completedCount: 2,
            totalCount: 5,
            categoryIcon: "cart.fill",
            items: [
                ChecklistItemWidgetData(id: UUID(), name: "牛乳", isCompleted: true, order: 0),
                ChecklistItemWidgetData(id: UUID(), name: "パン", isCompleted: true, order: 1),
                ChecklistItemWidgetData(id: UUID(), name: "卵", isCompleted: false, order: 2),
                ChecklistItemWidgetData(id: UUID(), name: "野菜", isCompleted: false, order: 3),
                ChecklistItemWidgetData(id: UUID(), name: "果物", isCompleted: false, order: 4),
            ]
        ),
        index: 0,
        totalCount: 2
    )
}

#Preview("Large", as: .systemLarge) {
    ChecklistWidget()
} timeline: {
    ChecklistEntry(
        date: Date(),
        checklist: ChecklistWidgetData(
            id: UUID(),
            title: "引っ越し準備リスト",
            completedCount: 3,
            totalCount: 10,
            categoryIcon: "doc.text.fill",
            items: [
                ChecklistItemWidgetData(id: UUID(), name: "不動産会社に連絡", isCompleted: true, order: 0),
                ChecklistItemWidgetData(id: UUID(), name: "引っ越し業者の手配", isCompleted: true, order: 1),
                ChecklistItemWidgetData(id: UUID(), name: "電気・ガス・水道の手続き", isCompleted: true, order: 2),
                ChecklistItemWidgetData(id: UUID(), name: "郵便局に転居届", isCompleted: false, order: 3),
                ChecklistItemWidgetData(id: UUID(), name: "インターネット回線の移転", isCompleted: false, order: 4),
                ChecklistItemWidgetData(id: UUID(), name: "住民票の移動", isCompleted: false, order: 5),
                ChecklistItemWidgetData(id: UUID(), name: "荷造り", isCompleted: false, order: 6),
                ChecklistItemWidgetData(id: UUID(), name: "不用品の処分", isCompleted: false, order: 7),
                ChecklistItemWidgetData(id: UUID(), name: "新居の掃除", isCompleted: false, order: 8),
                ChecklistItemWidgetData(id: UUID(), name: "近所への挨拶", isCompleted: false, order: 9),
            ]
        ),
        index: 0,
        totalCount: 1
    )
}

#Preview("Empty", as: .systemLarge) {
    ChecklistWidget()
} timeline: {
    ChecklistEntry(
        date: Date(),
        checklist: nil,
        index: 0,
        totalCount: 0
    )
}
