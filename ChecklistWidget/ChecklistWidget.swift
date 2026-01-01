import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import ActivityKit

// MARK: - App Group Container

enum WidgetConstants {
    static let appGroupIdentifier = "group.com.checklistapp.shared"
    static let maxDisplayItems = 12
    static let liveActivityUpdateKey = "live_activity_update_checklist_id"
    static let liveActivityUpdateTimestampKey = "live_activity_update_timestamp"
}

enum WidgetAppGroupContainer {
    static let appGroupIdentifier = WidgetConstants.appGroupIdentifier
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

    static func requestLiveActivityUpdate(checklistId: UUID) {
        userDefaults?.set(checklistId.uuidString, forKey: WidgetConstants.liveActivityUpdateKey)
        userDefaults?.set(Date().timeIntervalSince1970, forKey: WidgetConstants.liveActivityUpdateTimestampKey)
    }

    static func getPendingLiveActivityUpdate() -> UUID? {
        guard let idString = userDefaults?.string(forKey: WidgetConstants.liveActivityUpdateKey),
              let uuid = UUID(uuidString: idString) else {
            return nil
        }
        return uuid
    }

    static func clearPendingLiveActivityUpdate() {
        userDefaults?.removeObject(forKey: WidgetConstants.liveActivityUpdateKey)
        userDefaults?.removeObject(forKey: WidgetConstants.liveActivityUpdateTimestampKey)
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
        guard let itemUUID = UUID(uuidString: itemId),
              let checklistUUID = UUID(uuidString: checklistId) else {
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

        // Live Activity更新をリクエスト
        WidgetAppGroupContainer.requestLiveActivityUpdate(checklistId: checklistUUID)

        // Darwin Notificationを送信してメインアプリに通知
        Self.postDarwinNotification()

        // ウィジェットを更新
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }

    private static func postDarwinNotification() {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            notificationCenter,
            CFNotificationName("com.checklistapp.liveactivity.update" as CFString),
            nil,
            nil,
            true
        )
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
        // プレビュー時は即座にプレースホルダーを返す
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

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
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    let entry: ChecklistEntry

    var body: some View {
        if let checklist = entry.checklist {
            Gauge(value: checklist.progress) {
                Image(systemName: "checklist")
            } currentValueLabel: {
                Text("\(checklist.completedCount)")
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: ChecklistEntry

    var body: some View {
        if let checklist = entry.checklist {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: checklist.categoryIcon)
                        .font(.caption2)
                    Text(checklist.title)
                        .font(.headline)
                        .lineLimit(1)
                }

                Gauge(value: checklist.progress) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinear)

                Text("\(checklist.completedCount)/\(checklist.totalCount) 完了")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("すべて完了")
                        .font(.headline)
                }
                Text("未完了のリストはありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AccessoryInlineView: View {
    let entry: ChecklistEntry

    var body: some View {
        if let checklist = entry.checklist {
            Label("\(checklist.title): \(checklist.completedCount)/\(checklist.totalCount)", systemImage: checklist.categoryIcon)
        } else {
            Label("すべて完了", systemImage: "checkmark.circle.fill")
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
                    .foregroundStyle(item.isCompleted ? WidgetColors.statusSuccess : .secondary)

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
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(WidgetColors.statusSuccess)

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

// MARK: - Widget Colors (Neumorphic Design System)

enum WidgetColors {
    // Accent colors - Orange gradient
    static let accentOrangeStart = Color(red: 1.0, green: 0.55, blue: 0.25)  // #FF8C40
    static let accentOrangeEnd = Color(red: 1.0, green: 0.40, blue: 0.40)    // #FF6666

    // Status colors
    static let statusSuccess = Color(red: 0.30, green: 0.75, blue: 0.45)     // #4DC072

    // Orange gradient
    static var orangeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [accentOrangeStart, accentOrangeEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Helper Functions

/// 進捗率に応じた色を返す（Widget共通 - Neumorphicデザイン対応）
func progressColor(for progress: Double, isCompleted: Bool = false) -> Color {
    if isCompleted || progress >= 1.0 {
        return WidgetColors.statusSuccess
    } else if progress > 0.5 {
        return WidgetColors.accentOrangeEnd
    } else if progress > 0 {
        return WidgetColors.accentOrangeStart
    } else {
        return .gray
    }
}

// MARK: - Widget Definition

struct ChecklistWidget: Widget {
    let kind: String = "ChecklistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChecklistTimelineProvider()) { entry in
            ChecklistWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("チェックリスト")
        .description("未完了のチェックリストの進捗を表示します")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Live Activity Widget

struct ChecklistLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChecklistActivityAttributes.self) { context in
            // ロック画面・通知センターのバナー表示
            LiveActivityBannerView(context: context)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            // Dynamic Islandはコンパクト表示のみ（展開しない）
            DynamicIsland {
                // 展開時の領域は最小限に
                DynamicIslandExpandedRegion(.leading) { }
                DynamicIslandExpandedRegion(.trailing) { }
                DynamicIslandExpandedRegion(.center) { }
                DynamicIslandExpandedRegion(.bottom) { }
            } compactLeading: {
                // コンパクト表示: 進捗アイコン
                Image(systemName: "checklist")
                    .font(.caption2)
            } compactTrailing: {
                // コンパクト表示: 進捗
                Text("\(context.state.completedCount)/\(context.state.totalCount)")
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                // 最小表示: チェックマークアイコン
                Image(systemName: "checklist")
                    .font(.caption2)
            }
            .contentMargins(.all, 0, for: .expanded)
        }
    }
}

// MARK: - Live Activity Views

struct LiveActivityBannerView: View {
    let context: ActivityViewContext<ChecklistActivityAttributes>

    // アイテムを左右の列に分割
    private var leftColumnItems: [ChecklistActivityItem] {
        let items = Array(context.state.items.prefix(WidgetConstants.maxDisplayItems))
        return items.enumerated().compactMap { $0.offset % 2 == 0 ? $0.element : nil }
    }

    private var rightColumnItems: [ChecklistActivityItem] {
        let items = Array(context.state.items.prefix(WidgetConstants.maxDisplayItems))
        return items.enumerated().compactMap { $0.offset % 2 == 1 ? $0.element : nil }
    }

    var body: some View {
        // Live Activity全体をタップでアプリを開く
        Link(destination: URL(string: "checklistapp://checklist/\(context.attributes.checklistId)")!) {
            VStack(alignment: .leading, spacing: 4) {
                // ヘッダー
                HStack {
                    // 進捗円グラフ
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)

                        Circle()
                            .trim(from: 0, to: context.state.progress)
                            .stroke(
                                liveActivityProgressColor(for: context.state.progress),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(context.state.progress * 100))%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .frame(width: 32, height: 32)

                    Image(systemName: context.attributes.categoryIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Text(context.attributes.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Spacer()

                    Text("\(context.state.completedCount)/\(context.state.totalCount)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                // 2列のアイテムリスト
                HStack(alignment: .top, spacing: 8) {
                    // 左列
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(leftColumnItems) { item in
                            LiveActivityItemRow(item: item)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 右列
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(rightColumnItems) { item in
                            LiveActivityItemRow(item: item)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if context.state.totalCount > WidgetConstants.maxDisplayItems {
                    Text("他 \(context.state.totalCount - WidgetConstants.maxDisplayItems) 件...")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Live Activity Item Row

struct LiveActivityItemRow: View {
    let item: ChecklistActivityItem

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 9))
                .foregroundStyle(item.isCompleted ? WidgetColors.statusSuccess : .secondary)
            Text(item.name)
                .font(.system(size: 10))
                .strikethrough(item.isCompleted)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .lineLimit(1)
        }
    }
}

/// Live Activity用の進捗色（progressColor関数を使用）
private func liveActivityProgressColor(for progress: Double) -> Color {
    progressColor(for: progress, isCompleted: progress >= 1.0)
}

// MARK: - Widget Bundle

@main
struct ChecklistWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChecklistWidget()
        ChecklistLiveActivity()
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
