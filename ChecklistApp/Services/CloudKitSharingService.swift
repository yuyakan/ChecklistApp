import Foundation
import SwiftUI
import CoreData
import CloudKit
import Combine

enum CloudKitError: LocalizedError {
    case sharingFailed(String)
    case fetchFailed(String)
    case notAuthenticated
    case containerNotFound

    var errorDescription: String? {
        switch self {
        case .sharingFailed:
            return "共有に失敗しました"
        case .fetchFailed:
            return "データの取得に失敗しました"
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

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    private let ckContainer: CKContainer

    private init() {
        ckContainer = CKContainer(identifier: "iCloud.com.kanbe1365.ChecklistApp")
        Task {
            await checkAccountStatus()
        }
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            let status = try await ckContainer.accountStatus()
            accountStatus = status
        } catch {
            accountStatus = .couldNotDetermine
        }
    }

    var isAvailable: Bool {
        accountStatus == .available
    }
}

// MARK: - CloudKit Sharing Controller

class CloudKitSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    let checklist: CDChecklist
    var onStopSharing: (() -> Void)?
    var onDismiss: (() -> Void)?

    init(checklist: CDChecklist, onStopSharing: (() -> Void)?, onDismiss: (() -> Void)?) {
        self.checklist = checklist
        self.onStopSharing = onStopSharing
        self.onDismiss = onDismiss
    }

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("Failed to save share: \(error)")
    }

    func itemTitle(for csc: UICloudSharingController) -> String? {
        return checklist.wrappedTitle
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("共有が停止されました")
        Task { @MainActor in
            onStopSharing?()
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
        checklist: CDChecklist,
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
