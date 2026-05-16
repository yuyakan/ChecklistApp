import GoogleMobileAds
import UIKit

class AdMobService: NSObject {
    static let shared = AdMobService()

    // テスト時は testAdUnitID に切り替えてください。
    // private let adUnitID = "ca-app-pub-3155724310732667/5449902297" // 本番用
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910" // テスト用

    private var interstitialAd: GADInterstitialAd?
    private var dismissContinuation: CheckedContinuation<Void, Never>?

    private var retryCount = 0
    private let maxRetryCount = 3
    private var retryWorkItem: DispatchWorkItem?

    override private init() {
        super.init()
    }

    func initialize() {
        GADMobileAds.sharedInstance().start()
        preloadAd()
    }

    // アプリがフォアグラウンドに戻ったときに呼ぶ。広告がなければ再取得する。
    func reloadIfNeeded() {
        guard interstitialAd == nil else { return }
        retryCount = 0
        retryWorkItem?.cancel()
        preloadAd()
    }

    private func preloadAd() {
        GADInterstitialAd.load(
            withAdUnitID: adUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    print("AdMob: 広告読み込み失敗(\(self.retryCount + 1)回目) - \(error.localizedDescription)")
                    self.scheduleRetry()
                    return
                }
                self.retryCount = 0
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                print("AdMob: 広告の読み込み成功")
            }
        }
    }

    private func scheduleRetry() {
        guard retryCount < maxRetryCount else {
            print("AdMob: リトライ上限(\(maxRetryCount)回)に達しました")
            return
        }
        // 指数バックオフ: 2, 4, 8, 16, 32 秒
        let delay = pow(2.0, Double(retryCount + 1))
        retryCount += 1
        print("AdMob: \(Int(delay))秒後にリトライします(\(retryCount)/\(maxRetryCount))")

        let work = DispatchWorkItem { [weak self] in
            self?.preloadAd()
        }
        retryWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // 広告を表示して閉じるまで await する。
    // 広告が未ロードの場合は即座に返る（スキップ）。
    func showAdAndWait() async {
        guard let ad = interstitialAd,
              let rootVC = topViewController() else {
            return
        }
        await withCheckedContinuation { continuation in
            self.dismissContinuation = continuation
            ad.present(fromRootViewController: rootVC)
        }
    }

    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}

extension AdMobService: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitialAd = nil
        preloadAd()
        dismissContinuation?.resume()
        dismissContinuation = nil
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialAd = nil
        preloadAd()
        dismissContinuation?.resume()
        dismissContinuation = nil
    }
}
