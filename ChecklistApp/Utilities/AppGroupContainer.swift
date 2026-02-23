import Foundation
import SwiftData

enum AppConstants {
    static let appGroupIdentifier = "group.com.checklistapp.shared"
    static let maxDisplayItems = 12
    static let liveActivityUpdateKey = "live_activity_update_checklist_id"
    static let liveActivityUpdateTimestampKey = "live_activity_update_timestamp"
}

enum AppGroupContainer {
    static let appGroupIdentifier = AppConstants.appGroupIdentifier
    static let cloudKitContainerIdentifier = "iCloud.com.kanbe1365.ChecklistApp"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    static var modelContainer: ModelContainer {
        let schema = Schema([
            Checklist.self,
            ChecklistItemModel.self,
        ])

        let modelConfiguration: ModelConfiguration
        if let containerURL = containerURL {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: containerURL.appendingPathComponent("ChecklistApp.store"),
                allowsSave: true,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        } else {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
