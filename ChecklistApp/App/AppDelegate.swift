import UIKit
import CloudKit
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // アプリ起動時に共有URLがある場合
        if let cloudKitShareMetadata = connectionOptions.cloudKitShareMetadata {
            acceptCloudKitShare(metadata: cloudKitShareMetadata)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        // アプリ実行中に共有を受け入れた場合
        acceptCloudKitShare(metadata: cloudKitShareMetadata)
    }

    private func acceptCloudKitShare(metadata: CKShare.Metadata) {
        print("CloudKit共有を受け入れ中: \(metadata.share.recordID)")

        let stack = CoreDataStack.shared
        guard let sharedStore = stack.sharedPersistentStore else {
            print("Shared store not found")
            return
        }

        Task {
            do {
                try await stack.container.acceptShareInvitations(
                    from: [metadata],
                    into: sharedStore
                )
                print("共有の受け入れに成功しました")

                // 通知を送信して共有リスト画面を表示
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CloudKitShareAccepted"),
                        object: nil
                    )
                }
            } catch {
                print("共有の受け入れに失敗: \(error)")
            }
        }
    }
}
