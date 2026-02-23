import Foundation
import CoreData
import SwiftData

enum DataMigrationService {

    private static let migrationKey = "coredata_migration_completed_v1"
    private static let appGroupIdentifier = "group.com.checklistapp.shared"

    static var isMigrationNeeded: Bool {
        !UserDefaults.standard.bool(forKey: migrationKey)
    }

    /// Migrate data from old SwiftData store to CoreData.
    /// Call this once at app launch before showing any UI.
    static func migrateIfNeeded(to coreDataContext: NSManagedObjectContext) {
        guard isMigrationNeeded else { return }

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("Migration: App Group container not found, skipping")
            markCompleted()
            return
        }

        let oldStoreURL = containerURL.appendingPathComponent("ChecklistApp.store")

        // Check if old SwiftData store exists
        guard FileManager.default.fileExists(atPath: oldStoreURL.path) else {
            print("Migration: No old SwiftData store found, skipping")
            markCompleted()
            return
        }

        // Lightweight struct to hold migrated data outside of SwiftData context
        struct MigratedChecklist {
            let id: UUID
            let title: String
            let categoryRaw: String
            let createdAt: Date
            let updatedAt: Date
            let inputSourceRaw: String
            let isShared: Bool
            let ownerName: String
            struct Item {
                let id: UUID
                let name: String
                let note: String?
                let isCompleted: Bool
                let priorityRaw: String
                let order: Int
            }
            let items: [Item]
        }

        do {
            // Phase 1: Read from old SwiftData store, then release it
            var migratedData: [MigratedChecklist] = []

            do {
                let schema = Schema([Checklist.self, ChecklistItemModel.self])
                let config = ModelConfiguration(
                    schema: schema,
                    url: oldStoreURL,
                    allowsSave: false,
                    cloudKitDatabase: .none
                )
                let oldContainer = try ModelContainer(for: schema, configurations: [config])
                let oldContext = ModelContext(oldContainer)

                let descriptor = FetchDescriptor<Checklist>(
                    sortBy: [SortDescriptor(\.createdAt)]
                )
                let oldChecklists = try oldContext.fetch(descriptor)

                guard !oldChecklists.isEmpty else {
                    print("Migration: No data to migrate")
                    markCompleted()
                    return
                }

                // Copy data to plain structs before releasing SwiftData
                for old in oldChecklists {
                    migratedData.append(MigratedChecklist(
                        id: old.id,
                        title: old.title,
                        categoryRaw: old.categoryRaw,
                        createdAt: old.createdAt,
                        updatedAt: old.updatedAt,
                        inputSourceRaw: old.inputSourceRaw,
                        isShared: old.isShared,
                        ownerName: old.ownerName,
                        items: old.items.map { item in
                            MigratedChecklist.Item(
                                id: item.id,
                                name: item.name,
                                note: item.note,
                                isCompleted: item.isCompleted,
                                priorityRaw: item.priorityRaw,
                                order: item.order
                            )
                        }
                    ))
                }
            }
            // oldContainer / oldContext are now released

            print("Migration: Found \(migratedData.count) checklists to migrate")

            // Phase 2: Write to CoreData
            for data in migratedData {
                let newChecklist = CDChecklist(context: coreDataContext)
                newChecklist.id = data.id
                newChecklist.title = data.title
                newChecklist.categoryRaw = data.categoryRaw
                newChecklist.createdAt = data.createdAt
                newChecklist.updatedAt = data.updatedAt
                newChecklist.inputSourceRaw = data.inputSourceRaw
                newChecklist.isShared = data.isShared
                newChecklist.ownerName = data.ownerName

                if let privateStore = CoreDataStack.shared.privatePersistentStore {
                    coreDataContext.assign(newChecklist, to: privateStore)
                }

                for itemData in data.items {
                    let newItem = CDChecklistItem(context: coreDataContext)
                    newItem.id = itemData.id
                    newItem.name = itemData.name
                    newItem.note = itemData.note
                    newItem.isCompleted = itemData.isCompleted
                    newItem.priorityRaw = itemData.priorityRaw
                    newItem.order = Int32(itemData.order)
                    newItem.checklist = newChecklist
                }
            }

            try coreDataContext.save()
            print("Migration: Successfully migrated \(migratedData.count) checklists")

            // Phase 3: Archive old store (SwiftData container is already released)
            let archiveURL = containerURL.appendingPathComponent("ChecklistApp.store.migrated")
            if !FileManager.default.fileExists(atPath: archiveURL.path) {
                try? FileManager.default.moveItem(at: oldStoreURL, to: archiveURL)
                let walURL = containerURL.appendingPathComponent("ChecklistApp.store-wal")
                let shmURL = containerURL.appendingPathComponent("ChecklistApp.store-shm")
                if FileManager.default.fileExists(atPath: walURL.path) {
                    try? FileManager.default.moveItem(
                        at: walURL,
                        to: containerURL.appendingPathComponent("ChecklistApp.store.migrated-wal")
                    )
                }
                if FileManager.default.fileExists(atPath: shmURL.path) {
                    try? FileManager.default.moveItem(
                        at: shmURL,
                        to: containerURL.appendingPathComponent("ChecklistApp.store.migrated-shm")
                    )
                }
            }

            markCompleted()

        } catch {
            print("Migration failed: \(error)")
        }
    }

    private static func markCompleted() {
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
