import Foundation
import CoreData
import CloudKit
import Combine
import os.log

private let logger = Logger(subsystem: "com.kanbe1365.ChecklistApp", category: "CoreDataStack")

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()

    let container: NSPersistentCloudKitContainer
    let ckContainer: CKContainer

    private static let appGroupIdentifier = "group.com.checklistapp.shared"
    private static let cloudKitContainerIdentifier = "iCloud.com.kanbe1365.ChecklistApp"
    private static let privateStoreName = "ChecklistApp-private.sqlite"
    private static let sharedStoreName = "ChecklistApp-shared.sqlite"

    private init() {
        ckContainer = CKContainer(identifier: Self.cloudKitContainerIdentifier)
        container = NSPersistentCloudKitContainer(name: "ChecklistApp")

        // Use default app container (not App Group) for CloudKit sync reliability
        let storeDirectory = NSPersistentContainer.defaultDirectoryURL()
        logger.info("Store directory: \(storeDirectory.path)")

        // Private store description (must be first = default store for new objects)
        let privateStoreURL = storeDirectory.appendingPathComponent(Self.privateStoreName)
        let privateDescription = NSPersistentStoreDescription(url: privateStoreURL)
        privateDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: Self.cloudKitContainerIdentifier
        )
        privateDescription.cloudKitContainerOptions?.databaseScope = .private
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Shared store description
        let sharedStoreURL = storeDirectory.appendingPathComponent(Self.sharedStoreName)
        let sharedDescription = NSPersistentStoreDescription(url: sharedStoreURL)
        sharedDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: Self.cloudKitContainerIdentifier
        )
        sharedDescription.cloudKitContainerOptions?.databaseScope = .shared
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]

        container.loadPersistentStores { description, error in
            if let error = error {
                logger.error("Failed to load persistent store '\(description.url?.lastPathComponent ?? "unknown")': \(error.localizedDescription)")
                fatalError("Failed to load persistent store: \(error)")
            }
            logger.info("Loaded persistent store: \(description.url?.lastPathComponent ?? "unknown"), CloudKit scope: \(String(describing: description.cloudKitContainerOptions?.databaseScope.rawValue))")
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "viewContext"
        container.viewContext.transactionAuthor = "app"

        // Initialize CloudKit schema (required to push schema to CloudKit Dashboard)
        do {
            try container.initializeCloudKitSchema(options: [])
            logger.info("CloudKit schema initialized successfully")
        } catch {
            logger.error("CloudKit schema initialization error: \(error.localizedDescription)")
        }

        // Observe remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )

        // Monitor CloudKit sync events (log ALL events including in-progress)
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: nil
        ) { notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }

            let storeId = event.storeIdentifier
            let typeName: String
            switch event.type {
            case .setup: typeName = "setup"
            case .import: typeName = "import"
            case .export: typeName = "export"
            @unknown default: typeName = "unknown(\(event.type.rawValue))"
            }

            if event.endDate == nil {
                logger.info("CloudKit sync STARTED [\(typeName)] store=\(storeId)")
            } else if let error = event.error {
                logger.error("CloudKit sync FAILED [\(typeName)] store=\(storeId): \(error.localizedDescription)")
            } else {
                logger.info("CloudKit sync OK [\(typeName)] store=\(storeId)")
            }
        }

        // Check iCloud account status
        Task {
            do {
                let status = try await ckContainer.accountStatus()
                switch status {
                case .available:
                    logger.info("iCloud account status: available")
                case .noAccount:
                    logger.warning("iCloud account status: noAccount - CloudKit sync will not work")
                case .restricted:
                    logger.warning("iCloud account status: restricted")
                case .couldNotDetermine:
                    logger.warning("iCloud account status: couldNotDetermine")
                case .temporarilyUnavailable:
                    logger.warning("iCloud account status: temporarilyUnavailable")
                @unknown default:
                    logger.warning("iCloud account status: unknown(\(status.rawValue))")
                }
            } catch {
                logger.error("Failed to check iCloud account status: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Store Accessors

    var privatePersistentStore: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores.first { store in
            guard let url = store.url else { return false }
            return url.lastPathComponent == Self.privateStoreName
        }
    }

    var sharedPersistentStore: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores.first { store in
            guard let url = store.url else { return false }
            return url.lastPathComponent == Self.sharedStoreName
        }
    }

    // MARK: - Helpers

    func isShared(object: NSManagedObject) -> Bool {
        guard let persistentStore = object.objectID.persistentStore else { return false }
        return persistentStore == sharedPersistentStore
    }

    func isOwner(object: NSManagedObject) -> Bool {
        !isShared(object: object)
    }

    // MARK: - Save

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.error("CoreData save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Remote Change Notification

    @objc private func handleRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
