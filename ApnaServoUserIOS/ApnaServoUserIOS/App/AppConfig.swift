import Foundation

enum AppConfig {
    static let apiBaseURL = URL(string: "https://apnaservobk-1.onrender.com/api")!
    static let socketURL = URL(string: "https://apnaservobk-1.onrender.com")!
    static let privacyPolicyURL = URL(string: "https://apnaservobk-1.onrender.com/privacy-policy")!
    static let termsURL = URL(string: "https://apnaservobk-1.onrender.com/terms")!
    static let supportURL = URL(string: "https://apnaservobk-1.onrender.com/support")!
    static let defaultCity = "Guwahati"
    static let defaultLatitude = 26.1445
    static let defaultLongitude = 91.7362
    static let bookingStatusRefreshSeconds: UInt64 = 2_000_000_000
    static let supportUploadMaxBytes = 2_500_000
}
