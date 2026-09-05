@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

final class RewardedAdManager: NSObject, @unchecked Sendable {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case unavailable(String)
        case presenting
    }

    private static var rewardedAdUnitID: String {
        #if DEBUG
        "ca-app-pub-3940256099942544/1712485313"
        #else
        "ca-app-pub-5003253618778149/5442530338"
        #endif
    }

    private var rewardedAd: RewardedAd?
    private var rewardHandler: (() -> Void)?
    private(set) var state: State = .idle

    override init() {
        super.init()
        load()
    }

    func load() {
        guard state != .loading else {
            return
        }

        state = .loading
        RewardedAd.load(with: Self.rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            guard let self else {
                return
            }

            if let error {
                self.rewardedAd = nil
                self.state = .unavailable(error.localizedDescription)
                return
            }

            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.state = .ready
        }
    }

    @discardableResult
    @MainActor
    func presentRewardedAd(onReward: @escaping () -> Void) -> Bool {
        guard let rewardedAd else {
            load()
            return false
        }

        guard let rootViewController = UIApplication.shared.activeRootViewController else {
            state = .unavailable("Unable to show ad")
            return false
        }

        state = .presenting
        rewardHandler = onReward
        rewardedAd.present(from: rootViewController) { [weak self] in
            Task { @MainActor in
                self?.rewardHandler?()
                self?.rewardHandler = nil
            }
        }
        return true
    }
}

extension RewardedAdManager: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardHandler = nil
        rewardedAd = nil
        state = .unavailable(error.localizedDescription)
        load()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardHandler = nil
        rewardedAd = nil
        state = .idle
        load()
    }
}

private extension UIApplication {
    var activeRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topPresentedViewController
    }
}

private extension UIViewController {
    var topPresentedViewController: UIViewController {
        presentedViewController?.topPresentedViewController ?? self
    }
}
