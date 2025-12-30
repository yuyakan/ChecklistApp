import Foundation
import SwiftData

enum AppGroupContainer {
    static let appGroupIdentifier = "group.com.checklistapp.shared"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    static var modelContainer: ModelContainer {
        let schema = Schema([
            Checklist.self,
            ChecklistItemModel.self,
        ])

        // App Groupsが設定されている場合は共有コンテナを使用
        // 設定されていない場合はデフォルトの場所を使用
        let modelConfiguration: ModelConfiguration
        if let containerURL = containerURL {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: containerURL.appendingPathComponent("ChecklistApp.store"),
                allowsSave: true
            )
        } else {
            // App Groupsが未設定の場合はデフォルト設定
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
