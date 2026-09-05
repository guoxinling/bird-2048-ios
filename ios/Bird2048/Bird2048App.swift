import GoogleMobileAds
import SwiftUI

@main
struct Bird2048App: App {
    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
