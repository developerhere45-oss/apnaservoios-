import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct ApnaServoUserIOSApp: App {
    @StateObject private var store: UserAppStore

    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
        _store = StateObject(wrappedValue: UserAppStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
