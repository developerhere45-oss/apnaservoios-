import Foundation

enum AppConfig {
    static let apiBaseURL = URL(string: "https://apnaservobk-1.onrender.com/api")!
    static let socketURL = URL(string: "https://apnaservobk-1.onrender.com")!
    static let privacyPolicyURL = URL(string: "https://apnaservo.com/privacy-policy")!
    static let termsURL = URL(string: "https://apnaservo.com/terms-and-conditions")!
    static let supportURL = URL(string: "https://apnaservobk-1.onrender.com/support")!
    static let defaultCity = "Guwahati"
    static let defaultLatitude = 26.1445
    static let defaultLongitude = 91.7362
    // Push notifications are primary. This foreground poll is only a bounded
    // recovery path for delayed/missed pushes and must stay gentle at scale.
    static let bookingStatusRefreshSeconds: UInt64 = 8_000_000_000
    static let supportUploadMaxBytes = 2_500_000
}
