import SwiftUI
import UIKit

#if canImport(FirebaseCore)
import FirebaseCore
#endif

final class UserFirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // AsyncImage and URLSession share this cache. A bounded cache avoids
        // repeatedly downloading offer/banner artwork while keeping memory
        // predictable on older iPhones.
        URLCache.shared = URLCache(memoryCapacity: 24 * 1024 * 1024, diskCapacity: 96 * 1024 * 1024)
        let inputColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 245 / 255, green: 242 / 255, blue: 244 / 255, alpha: 1)
                : UIColor(red: 22 / 255, green: 22 / 255, blue: 22 / 255, alpha: 1)
        }
        UITextField.appearance().textColor = inputColor
        UITextView.appearance().textColor = inputColor
        UITextField.appearance().tintColor = UIColor(red: 225 / 255, green: 42 / 255, blue: 83 / 255, alpha: 1)
        UITextView.appearance().tintColor = UIColor(red: 225 / 255, green: 42 / 255, blue: 83 / 255, alpha: 1)
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        #endif
        AppNotificationService.shared.configure()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppNotificationService.shared.setAPNSToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        NSLog("APNs registration failed: %@", error.localizedDescription)
        #endif
    }
}

@main
struct ApnaServoUserIOSApp: App {
    @UIApplicationDelegateAdaptor(UserFirebaseAppDelegate.self) private var appDelegate
    @StateObject private var store = UserAppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
