import Foundation
import SwiftUI
import SwiftData
import CloudKit
import Combine

enum CloudKitError: LocalizedError {
    case sharingFailed(String)
    case fetchFailed(String)
    case notAuthenticated
    case containerNotFound

    var errorDescription: String? {
        switch self {
        case .sharingFailed(let message):
            return "共有に失敗しました: \(message)"
        case .fetchFailed(let message):
            return "データの取得に失敗しました: \(message)"
        case .notAuthenticated:
            return "iCloudにサインインしてください"
        case .containerNotFound:
            return "CloudKitコンテナが見つかりません"
        }
    }
}

@MainActor
class CloudKitSharingService: ObservableObject {
    static let shared = CloudKitSharingService()

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase

    // 共有用のカスタムゾーン（デフォルトゾーンでは共有できない）
    private let shareZoneID: CKRecordZone.ID

    private init() {
        // 明示的にCloudKitコンテナを指定
        container = CKContainer(identifier: "iCloud.com.kanbe1365.ChecklistApp")
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        shareZoneID = CKRecordZone.ID(zoneName: "SharedChecklists", ownerName: CKCurrentUserDefaultName)
        print("CloudKitSharingService初期化: container=\(container.containerIdentifier ?? "nil")")
        Task {
            await checkAccountStatus()
            await createShareZoneIfNeeded()
        }
    }

    // 共有用ゾーンを作成
    private func createShareZoneIfNeeded() async {
        let zone = CKRecordZone(zoneID: shareZoneID)

        do {
            let _ = try await privateDatabase.save(zone)
            print("共有ゾーンを作成しました: \(shareZoneID.zoneName)")
        } catch let error as CKError where error.code == .serverRecordChanged || error.code == .zoneNotFound {
            // ゾーンが既に存在する場合は無視
            print("共有ゾーンは既に存在します")
        } catch {
            print("共有ゾーンの作成エラー: \(error)")
        }
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            print("CloudKit accountStatus: \(status.rawValue)")
        } catch {
            print("CloudKit accountStatus エラー: \(error)")
            accountStatus = .couldNotDetermine
        }
    }

    var isAvailable: Bool {
        accountStatus == .available
    }

    // MARK: - Share Checklist

    func createShare(for checklist: Checklist, in modelContext: ModelContext) async throws -> CKShare {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // チェックリストをCKRecordに変換
        let checklistRecord = createChecklistRecord(from: checklist)

        // アイテムレコードを作成
        var itemRecords: [CKRecord] = []
        for item in checklist.items {
            let itemRecord = createItemRecord(from: item, parentRecordID: checklistRecord.recordID)
            itemRecords.append(itemRecord)
        }

        // CKShareを作成
        let share = CKShare(rootRecord: checklistRecord)
        share[CKShare.SystemFieldKey.title] = checklist.title as CKRecordValue
        share.publicPermission = .readWrite

        // rootRecord、アイテムレコード、CKShareを同時に保存
        var recordsToSave: [CKRecord] = [checklistRecord]
        recordsToSave.append(contentsOf: itemRecords)
        recordsToSave.append(share)

        return try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(
                recordsToSave: recordsToSave,
                recordIDsToDelete: nil
            )

            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("CKShare保存成功（チェックリスト + \(itemRecords.count)個のアイテム）")
                    Task { @MainActor in
                        checklist.isShared = true
                        try? modelContext.save()
                    }
                    continuation.resume(returning: share)
                case .failure(let error):
                    print("CKShare保存失敗: \(error)")
                    continuation.resume(throwing: CloudKitError.sharingFailed(error.localizedDescription))
                }
            }

            privateDatabase.add(operation)
        }
    }

    // アイテムレコードを別途保存（共有後に呼び出し可能）
    func saveChecklistItems(for checklist: Checklist) async throws {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }

        let checklistRecordID = CKRecord.ID(recordName: checklist.id.uuidString)

        for item in checklist.items {
            let itemRecord = createItemRecord(from: item, parentRecordID: checklistRecordID)
            do {
                let _ = try await privateDatabase.save(itemRecord)
            } catch {
                print("Failed to save item record: \(error)")
            }
        }
    }

    // MARK: - Accept Share

    func acceptShare(metadata: CKShare.Metadata) async throws {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let _ = try await container.accept(metadata)
        } catch {
            throw CloudKitError.sharingFailed(error.localizedDescription)
        }
    }

    // MARK: - Fetch Shared Checklists

    func fetchSharedChecklists() async throws -> [CKRecord] {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Shared Databaseでは、まず共有ゾーンを取得してから各ゾーン内をクエリする必要がある
        var allRecords: [CKRecord] = []

        do {
            // 共有ゾーンを取得
            let zones = try await sharedDatabase.allRecordZones()
            print("共有ゾーン数: \(zones.count)")

            // 各ゾーン内のChecklistレコードを取得
            for zone in zones {
                print("ゾーン検索中: \(zone.zoneID.zoneName)")
                let query = CKQuery(recordType: "Checklist", predicate: NSPredicate(value: true))

                do {
                    let (results, _) = try await sharedDatabase.records(
                        matching: query,
                        inZoneWith: zone.zoneID
                    )
                    let records = results.compactMap { try? $0.1.get() }
                    print("ゾーン \(zone.zoneID.zoneName) で \(records.count) 件のレコードを取得")
                    allRecords.append(contentsOf: records)
                } catch {
                    print("ゾーン \(zone.zoneID.zoneName) のクエリエラー: \(error)")
                }
            }

            return allRecords
        } catch {
            throw CloudKitError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Import Shared Checklist

    func importSharedChecklist(from record: CKRecord, modelContext: ModelContext) async throws -> Checklist {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }

        // CKRecordからChecklistを作成
        let checklist = Checklist(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            title: record["title"] as? String ?? "共有リスト",
            category: Category(rawValue: record["categoryRaw"] as? String ?? "") ?? .other,
            items: [],
            createdAt: record["createdAt"] as? Date ?? Date(),
            updatedAt: record["updatedAt"] as? Date ?? Date(),
            inputSource: InputSource(rawValue: record["inputSourceRaw"] as? String ?? "") ?? .text
        )
        checklist.isShared = true
        checklist.ownerName = record["ownerName"] as? String ?? ""

        // アイテムを取得
        let itemQuery = CKQuery(
            recordType: "ChecklistItem",
            predicate: NSPredicate(format: "parentChecklistID == %@", record.recordID.recordName)
        )

        do {
            let (itemResults, _) = try await sharedDatabase.records(matching: itemQuery)
            for result in itemResults {
                if let itemRecord = try? result.1.get() {
                    let item = ChecklistItemModel(
                        id: UUID(uuidString: itemRecord["id"] as? String ?? "") ?? UUID(),
                        name: itemRecord["name"] as? String ?? "",
                        note: itemRecord["note"] as? String,
                        isCompleted: itemRecord["isCompleted"] as? Bool ?? false,
                        priority: Priority(rawValue: itemRecord["priorityRaw"] as? String ?? ""),
                        order: itemRecord["order"] as? Int ?? 0
                    )
                    checklist.addItem(item)
                }
            }
        } catch {
            print("Failed to fetch items: \(error)")
        }

        modelContext.insert(checklist)
        try? modelContext.save()

        return checklist
    }

    // MARK: - Sync Changes

    func syncChecklist(_ checklist: Checklist) async throws {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }

        let record = createChecklistRecord(from: checklist)

        do {
            let _ = try await privateDatabase.save(record)
        } catch {
            throw CloudKitError.sharingFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete Shared Records

    func deleteSharedRecords(for checklist: Checklist) async throws {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // チェックリストとアイテムのレコードIDを収集
        var recordIDsToDelete: [CKRecord.ID] = []

        // チェックリストレコードID
        let checklistRecordID = CKRecord.ID(recordName: checklist.id.uuidString, zoneID: shareZoneID)
        recordIDsToDelete.append(checklistRecordID)

        // アイテムレコードID
        for item in checklist.items {
            let itemRecordID = CKRecord.ID(recordName: item.id.uuidString, zoneID: shareZoneID)
            recordIDsToDelete.append(itemRecordID)
        }

        print("CloudKitから削除するレコード数: \(recordIDsToDelete.count)")

        return try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(
                recordsToSave: nil,
                recordIDsToDelete: recordIDsToDelete
            )

            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("CloudKitレコード削除成功")
                    continuation.resume()
                case .failure(let error):
                    print("CloudKitレコード削除失敗: \(error)")
                    // レコードが見つからない場合は成功として扱う
                    if let ckError = error as? CKError, ckError.code == .unknownItem {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: CloudKitError.sharingFailed(error.localizedDescription))
                    }
                }
            }

            privateDatabase.add(operation)
        }
    }

    // MARK: - Helper Methods

    private func createChecklistRecord(from checklist: Checklist) -> CKRecord {
        // カスタムゾーンにレコードを作成（共有にはカスタムゾーンが必須）
        let recordID = CKRecord.ID(recordName: checklist.id.uuidString, zoneID: shareZoneID)
        let record = CKRecord(recordType: "Checklist", recordID: recordID)

        record["id"] = checklist.id.uuidString as CKRecordValue
        record["title"] = checklist.title as CKRecordValue
        record["categoryRaw"] = checklist.categoryRaw as CKRecordValue
        record["createdAt"] = checklist.createdAt as CKRecordValue
        record["updatedAt"] = checklist.updatedAt as CKRecordValue
        record["inputSourceRaw"] = checklist.inputSourceRaw as CKRecordValue
        record["isShared"] = checklist.isShared as CKRecordValue
        record["ownerName"] = checklist.ownerName as CKRecordValue

        return record
    }

    private func createItemRecord(from item: ChecklistItemModel, parentRecordID: CKRecord.ID) -> CKRecord {
        // 親レコードと同じゾーンにアイテムを作成
        let recordID = CKRecord.ID(recordName: item.id.uuidString, zoneID: parentRecordID.zoneID)
        let record = CKRecord(recordType: "ChecklistItem", recordID: recordID)

        record["id"] = item.id.uuidString as CKRecordValue
        record["name"] = item.name as CKRecordValue
        record["note"] = (item.note ?? "") as CKRecordValue
        record["isCompleted"] = item.isCompleted as CKRecordValue
        record["priorityRaw"] = item.priorityRaw as CKRecordValue
        record["order"] = item.order as CKRecordValue
        record["parentChecklistID"] = parentRecordID.recordName as CKRecordValue

        return record
    }
}

// MARK: - CloudKit Sharing Controller

class CloudKitSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    let checklist: Checklist
    var onStopSharing: (() -> Void)?
    var onDismiss: (() -> Void)?

    init(checklist: Checklist, onStopSharing: (() -> Void)?, onDismiss: (() -> Void)?) {
        self.checklist = checklist
        self.onStopSharing = onStopSharing
        self.onDismiss = onDismiss
    }

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("Failed to save share: \(error)")
    }

    func itemTitle(for csc: UICloudSharingController) -> String? {
        return checklist.title
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("共有が停止されました")

        // CloudKitからレコードを削除
        Task {
            do {
                try await CloudKitSharingService.shared.deleteSharedRecords(for: checklist)
                print("CloudKitレコードを削除しました")
            } catch {
                print("CloudKitレコード削除エラー: \(error)")
            }

            await MainActor.run {
                onStopSharing?()
            }
        }
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("共有が保存されました")
    }
}

struct CloudKitSharingPresenter {
    static var coordinator: CloudKitSharingCoordinator?

    static func present(
        share: CKShare,
        container: CKContainer,
        checklist: Checklist,
        onStopSharing: (() -> Void)?
    ) {
        // キーボードを閉じる
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }

            // 最前面のViewControllerを取得
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            coordinator = CloudKitSharingCoordinator(
                checklist: checklist,
                onStopSharing: onStopSharing,
                onDismiss: nil
            )

            let sharingController = UICloudSharingController(share: share, container: container)
            sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
            sharingController.delegate = coordinator
            sharingController.modalPresentationStyle = .formSheet

            topController.present(sharingController, animated: true)
        }
    }
}

// SwiftUI用のラッパー（後方互換性のため残す）
struct CloudKitSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let checklist: Checklist
    var onStopSharing: (() -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear

        DispatchQueue.main.async {
            CloudKitSharingPresenter.present(
                share: share,
                container: container,
                checklist: checklist,
                onStopSharing: onStopSharing
            )
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
