import Foundation
import CoreLocation
import SwiftUI
import UIKit
import AuthenticationServices
import CryptoKit
import Security

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
final class UserAppStore: ObservableObject {
    @Published var screen: UserScreen = .splash
    @Published var previousScreens: [UserScreen] = []
    @Published var profile = UserProfile(
        name: "",
        phone: "",
        email: "",
        address: "",
        lat: AppConfig.defaultLatitude,
        lng: AppConfig.defaultLongitude
    )
    @Published var startupLocationPhase: StartupLocationPhase = .idle
    @Published var startupManualAddress = ""
    @Published var isStartupManualEntry = false
    @Published var activeCategory = "Home Repair"
    @Published var selectedService = ServiceCatalog.service(id: "ro")
    @Published var draft = BookingDraft(
        problem: "",
        address: "Detecting your current service location...",
        tier: .normal,
        lat: AppConfig.defaultLatitude,
        lng: AppConfig.defaultLongitude,
        hasLocation: false
    )
    @Published var addressMode: BookingAddressMode = .current
    @Published var houseFlat = ""
    @Published var building = ""
    @Published var floor = ""
    @Published var room = ""
    @Published var landmark = ""
    @Published var city = AppConfig.defaultCity
    @Published var state = "Assam"
    @Published var pinCode = ""
    @Published var latestBooking: Booking?
    @Published var bookings: [Booking] = []
    @Published var bookingChatMessages: [ChatMessage] = []
    @Published var supportMessages: [ChatMessage] = [
        ChatMessage(id: "support-welcome", bookingId: "support", bookingCode: "", senderRole: "support", senderName: "ApnaServo Support", message: "Hi, how can we help?", clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
    ]
    @Published private(set) var supportTicketId = ""
    @Published private(set) var supportTicketStatus = ""
    @Published private(set) var supportAssignedAgent = ""
    @Published private(set) var supportBookingCode = ""
    @Published private(set) var isSupportMessageSending = false
    @Published var notifications: [AppNotificationItem] = []
    @Published var toastMessage = ""
    @Published var showLoginSheet = false
    @Published var loginMode = "Phone"
    @Published var loginName = ""
    @Published var loginPhone = ""
    @Published var loginOTPRequestID = ""
    @Published var loginOTPExpiresInSeconds = 300
    @Published private(set) var loginOTPExpiresAt: Date?
    @Published var showDateSheet = false
    @Published var showTimeSheet = false
    @Published var showSettingsSheet = false
    @Published var showEditProfileSheet = false
    @Published var showLegalSheet = false
    @Published var isAuthenticating = false
    @Published var isDeletingAccount = false
    @Published private(set) var appleDeletionAuthorizationRevoked = false
    @Published var showCancelSheet = false
    @Published var showCounterOfferSheet = false
    @Published var showReviewSheet = false
    @Published var cancelReason = ""
    @Published var counterOfferAmount = ""
    @Published var counterOfferMessage = ""
    @Published var reviewRating = 5
    @Published var reviewComment = ""
    @Published var reviewedBookingIDs: Set<String> = []
    @Published var authToken = ""
    @Published var paymentInfoExpanded = false
    @Published var aboutInfoExpanded = false
    @Published var isBookingSubmitting = false
    @Published var bookingActionInFlight = false
    @Published var submittedRatings: [String: Int] = [:]
    @Published var selectedCommercialServiceTitle = "Commercial AC Service"
    @Published var selectedCommercialServiceId = "ac"
    @Published private(set) var isCommercialBooking = false
    private var bookingRequestID = ""
    @Published var selectedCleaningType = "Home Cleaning"
    @Published var selectedLaundryServiceType = "Wash & Fold"
    @Published var selectedLaundryItems: [String: Int] = [:]
    @Published private(set) var appControlMode: RemoteAppMode = .live
    @Published private(set) var serviceRules: [String: RemoteServiceRule] = [:]
    @Published private(set) var selectedServiceStatusMessage = ""
    @Published private(set) var remoteAppControl: RemoteAppControlEnvelope?

    var services: [ServiceItem] {
        ServiceCatalog.services.filter { remoteServiceStatus(for: $0) != "DISABLED" }
    }
    var categories: [String] {
        let available = Set(services.map(\.category))
        return ServiceCatalog.categories.filter { available.contains($0) }
    }
    let cleaningTypes = ["Home Cleaning", "Deep Cleaning", "Bathroom Cleaning", "Room Cleaning"]
    let laundryServiceTypes = ["Wash & Fold", "Dry Cleaning", "Ironing", "Wash & Iron"]
    let laundryItems = [
        "T-Shirts", "Shirts", "Lowers / Track Pants", "Jeans", "Bed Sheet",
        "Blanket", "Pillow Cover", "Curtain", "Towel", "Saree",
        "Suit / Kurta", "Jacket", "Shoes", "Others"
    ]
    private let api = APIClient()
    private lazy var locationService = LocationService()
    private let secureStore = SecureStore()
    private let defaults = UserDefaults.standard
    private let notificationService = AppNotificationService.shared
    private var bookingPollingTask: Task<Void, Never>?
    private var bookingLocationTask: Task<Void, Never>?
    private var startupLocationTask: Task<Void, Never>?
    private var fcmTokenObserver: NSObjectProtocol?
    private var notificationOpenObserver: NSObjectProtocol?
    private var pendingNotificationDeepLink: AppNotificationDeepLink?
    private let tokenKey = "user_api_token"
    private let appleUserIDKey = "apple_user_identifier"
    private let submittedRatingsKey = "apnaservo_user_submitted_ratings"
    private let supportTicketKey = "apnaservo_user_support_ticket_id"
    private var currentAppleNonce: String?
    private var isRefreshingBookings = false
    private var isRefreshingLatestBooking = false
    private var isLoadingBookingChat = false
    private var isRefreshingNotifications = false

    var requiresAppleDeletionAuthorization: Bool {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "apple.com" }) == true
            && !appleDeletionAuthorizationRevoked
        #else
        return false
        #endif
    }

    init() {
        if let data = defaults.data(forKey: submittedRatingsKey),
           let saved = try? JSONDecoder().decode([String: Int].self, from: data) {
            submittedRatings = saved
        }
        fcmTokenObserver = NotificationCenter.default.addObserver(forName: .apnaServoUserFCMTokenUpdated, object: nil, queue: .main) { [weak self] notification in
            guard let token = notification.object as? String, !token.isEmpty else { return }
            Task { @MainActor in
                guard let self, self.isLoggedIn else { return }
                try? await self.api.saveFCMToken(token, token: self.apiToken)
            }
        }
        notificationOpenObserver = NotificationCenter.default.addObserver(forName: .apnaServoUserNotificationOpened, object: nil, queue: .main) { [weak self] notification in
            guard let deepLink = notification.object as? AppNotificationDeepLink else { return }
            Task { @MainActor in
                _ = self?.notificationService.consumePendingDeepLink()
                await self?.openNotificationDeepLink(deepLink)
            }
        }
        if let deepLink = notificationService.consumePendingDeepLink() {
            Task { @MainActor in
                await self.openNotificationDeepLink(deepLink)
            }
        }
    }

    deinit {
        if let fcmTokenObserver {
            NotificationCenter.default.removeObserver(fcmTokenObserver)
        }
        if let notificationOpenObserver {
            NotificationCenter.default.removeObserver(notificationOpenObserver)
        }
    }

    var isLoggedIn: Bool {
        !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredServices: [ServiceItem] {
        services.filter { $0.category == activeCategory }
    }

    var remotePrimaryColor: Color {
        Color(hexString: remoteAppControl?.config.theme.primaryColor ?? remoteAppControl?.config.ui.primaryColor ?? "#f32368")
    }

    var remoteHomeTitle: String { remoteAppControl?.config.ui.homeTitle.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
    var remoteHomeSubtitle: String { remoteAppControl?.config.ui.homeSubtitle.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
    var remoteAnnouncements: [RemoteAppContent] { remoteAppControl?.announcements ?? [] }
    var remoteBanners: [RemoteAppContent] { remoteAppControl?.banners ?? [] }

    func isHomeSectionVisible(_ id: String) -> Bool {
        guard let config = remoteAppControl?.config else { return true }
        if config.ui.hiddenSections.contains(id) { return false }
        if let section = config.home.sections.first(where: { $0.id == id }) { return section.enabled }
        return true
    }

    func homeSectionTitle(_ id: String, fallback: String) -> String {
        let title = remoteAppControl?.config.home.sections.first(where: { $0.id == id })?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? fallback : title
    }

    func remoteServiceStatus(for service: ServiceItem) -> String {
        remoteAppControl?.config.services[service.id]?.status.uppercased() ?? "AVAILABLE"
    }

    func serviceIsBookable(_ service: ServiceItem) -> Bool {
        let status = remoteServiceStatus(for: service)
        let appMode = remoteAppControl?.config.appStatus.mode.uppercased() ?? "LIVE"
        return (remoteAppControl?.config.booking.enabled ?? true)
            && !["MAINTENANCE", "HIGH_DEMAND"].contains(appMode)
            && !["DISABLED", "TEMPORARILY_UNAVAILABLE", "HIGH_DEMAND"].contains(status)
    }

    func serviceUnavailableMessage(for service: ServiceItem) -> String {
        switch remoteAppControl?.config.appStatus.mode.uppercased() {
        case "MAINTENANCE": return "ApnaServo is under maintenance. Please try again after some time."
        case "HIGH_DEMAND": return "We are receiving a high number of service requests. Please try again shortly."
        default: break
        }
        let configured = remoteAppControl?.config.services[service.id]?.message.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !configured.isEmpty { return configured }
        switch remoteServiceStatus(for: service) {
        case "HIGH_DEMAND": return "This service is receiving high demand. Please try again shortly."
        case "TEMPORARILY_UNAVAILABLE", "DISABLED": return "This service is temporarily unavailable."
        default: return "New bookings are temporarily paused."
        }
    }

    func refreshRemoteAppControl() async {
        do {
            remoteAppControl = try await api.fetchPublishedAppConfiguration()
            if !categories.contains(activeCategory) { activeCategory = categories.first ?? ServiceCatalog.categories[0] }
        } catch {
            // Keep the signed app's complete offline catalogue and design usable.
        }
    }

    var activeBookings: [Booking] {
        bookings.filter { !["completed", "cancelled", "rejected"].contains($0.status) }
    }

    var isOutsideGuwahatiServiceArea: Bool {
        guard startupLocationPhase == .detected else { return false }
        let current = CLLocation(latitude: profile.lat, longitude: profile.lng)
        let guwahatiCenter = CLLocation(
            latitude: AppConfig.defaultLatitude,
            longitude: AppConfig.defaultLongitude
        )
        return current.distance(from: guwahatiCenter) / 1_000 > 35
    }

    func finishSplash() {
        screen = .login
    }

    func restoreAuthenticatedSession() async -> Bool {
        #if canImport(FirebaseAuth)
        guard let firebaseUser = Auth.auth().currentUser else {
            secureStore.set("", for: tokenKey)
            return false
        }
        do {
            let token = try await firebaseUser.getIDToken(forcingRefresh: true)
            let account = try await api.fetchCurrentUser(token: token)
            guard account.accountStatus != "deleted", account.accountStatus != "blocked" else {
                logout()
                return false
            }
            secureStore.set(token, for: tokenKey)
            authToken = token
            profile.name = account.name ?? ""
            profile.phone = String((account.phone ?? "").filter(\.isNumber).suffix(10))
            profile.email = account.email ?? ""
            profile.address = account.address ?? ""
            guard profile.isValid else {
                logout()
                return false
            }
            startupLocationPhase = .idle
            startupManualAddress = ""
            isStartupManualEntry = false
            previousScreens.removeAll()
            screen = .startupLocation
            Task { await refreshBookings(); await refreshNotifications() }
            return true
        } catch {
            // A temporary backend outage must not destroy an existing Firebase
            // login. Restore the identity Firebase already has and retry data
            // refreshes in the background once the UI is available.
            let fallbackPhone = String((firebaseUser.phoneNumber ?? "").filter(\.isNumber).suffix(10))
            guard !fallbackPhone.isEmpty else { return false }
            profile.name = firebaseUser.displayName ?? "ApnaServo Customer"
            profile.phone = fallbackPhone
            profile.email = firebaseUser.email ?? ""
            previousScreens.removeAll()
            screen = .home
            Task { await refreshBookings(); await refreshNotifications() }
            return true
        }
        #else
        return false
        #endif
    }

    func navigate(_ target: UserScreen, remember: Bool = true) {
        if remember, screen != target, screen != .splash {
            previousScreens.append(screen)
        }
        screen = target
    }

    func selectTab(_ target: UserScreen) {
        guard [.home, .bookings, .profile].contains(target) else { return }
        previousScreens.removeAll()
        screen = target
    }

    func back() {
        while let previous = previousScreens.popLast() {
            if previous != screen {
                screen = previous
                return
            }
        }
        screen = isLoggedIn ? .home : .login
    }

    func beginLogin(_ mode: String) {
        loginMode = mode
        showLoginSheet = true
    }

    func completeLogin(name: String, value: String) {
        toastMessage = "Please sign in securely with your mobile number and OTP."
    }

    func showOTPLogin() {
        let cleanName = loginName.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = loginPhone.filter(\.isNumber)
        guard digits.count == 10 else {
            toastMessage = "Enter a valid 10-digit mobile number."
            return
        }
        guard !isAuthenticating else { return }
        // A review/demo phone flow must be usable with the supplied phone
        // number alone. The user can personalise this default in Profile.
        loginName = cleanName.isEmpty ? "ApnaServo Customer" : cleanName
        loginPhone = String(digits.suffix(10))
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            do {
                let response = try await api.sendLoginOTP(phone: loginPhone)
                loginOTPRequestID = response.requestId
                loginOTPExpiresInSeconds = max(1, response.expiresInSeconds)
                loginOTPExpiresAt = Date().addingTimeInterval(TimeInterval(loginOTPExpiresInSeconds))
                navigate(.otp)
            } catch {
                toastMessage = error.localizedDescription
            }
        }
    }

    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func completeAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        guard !isAuthenticating else { return }
        switch result {
        case .failure(let error):
            currentAppleNonce = nil
            if (error as? ASAuthorizationError)?.code != .canceled {
                toastMessage = "Sign in with Apple could not be completed. Please try again."
            }
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentAppleNonce,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                currentAppleNonce = nil
                toastMessage = "Apple sign-in credential was incomplete. Please try again."
                return
            }
            currentAppleNonce = nil
            isAuthenticating = true
            Task {
                defer { isAuthenticating = false }
                do {
                    #if canImport(FirebaseAuth)
                    let firebaseCredential = OAuthProvider.appleCredential(
                        withIDToken: identityToken,
                        rawNonce: nonce,
                        fullName: credential.fullName
                    )
                    let result = try await Auth.auth().signIn(with: firebaseCredential)
                    let token = try await result.user.getIDToken(forcingRefresh: true)
                    // Apple sends this stable identifier on every authorization,
                    // whereas name/email are commonly supplied only the first time.
                    secureStore.set(credential.user, for: appleUserIDKey)
                    let appleName = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    profile.name = appleName.isEmpty ? (result.user.displayName ?? "ApnaServo Customer") : appleName
                    profile.email = result.user.email ?? credential.email ?? ""
                    profile.phone = String((result.user.phoneNumber ?? "").filter(\.isNumber).suffix(10))
                    guard profile.isValid else {
                        throw APIError.badResponse("Apple did not provide an email for this account. Please sign in again and choose Share My Email.")
                    }
                    secureStore.set(token, for: tokenKey)
                    authToken = token
                    try await api.upsertUserProfile(profile, fcmToken: notificationService.fcmToken, token: token)
                    startupLocationPhase = .idle
                    startupManualAddress = ""
                    isStartupManualEntry = false
                    navigate(.startupLocation, remember: false)
                    await refreshBookings()
                    #else
                    throw APIError.badResponse("Sign in with Apple is unavailable in this build.")
                    #endif
                } catch {
                    secureStore.set("", for: tokenKey)
                    authToken = ""
                    #if canImport(FirebaseAuth)
                    try? Auth.auth().signOut()
                    #endif
                    toastMessage = appleSignInErrorMessage(for: error)
                }
            }
        }
    }

    private func appleSignInErrorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "Could not complete Apple sign-in. Please try again."
        }
        #if canImport(FirebaseAuth)
        let authError = AuthErrorCode(rawValue: (error as NSError).code)
        switch authError {
        case .operationNotAllowed:
            return "Apple sign-in is not enabled yet. Please contact support."
        case .invalidCredential:
            return "Apple sign-in configuration is invalid. Please update the app and try again."
        case .networkError:
            return "Could not reach the sign-in service. Check your connection and try again."
        case .accountExistsWithDifferentCredential:
            return "An account already exists with this email. Sign in using its original method."
        case .userDisabled:
            return "This account has been disabled. Please contact support."
        default:
            #if DEBUG
            NSLog("Sign in with Apple Firebase error: %@", error.localizedDescription)
            #endif
            return "Sign in with Apple failed. Please try again."
        }
        #else
        return "Sign in with Apple is unavailable in this build."
        #endif
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            guard status == errSecSuccess else { continue }
            if Int(random) < characters.count {
                result.append(characters[Int(random)])
                remainingLength -= 1
            }
        }
        return result
    }

    func prepareAppleAccountDeletion(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = []
    }

    func completeAppleAccountDeletionAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                toastMessage = "Apple account confirmation failed. Please try again."
            }
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let codeData = credential.authorizationCode,
                  let authorizationCode = String(data: codeData, encoding: .utf8),
                  !authorizationCode.isEmpty else {
                toastMessage = "Apple account confirmation was incomplete. Please try again."
                return
            }
            Task {
                do {
                    #if canImport(FirebaseAuth)
                    try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
                    appleDeletionAuthorizationRevoked = true
                    toastMessage = "Apple account confirmed. You can now permanently delete your account."
                    #else
                    throw APIError.badResponse("Apple account confirmation is unavailable in this build.")
                    #endif
                } catch {
                    toastMessage = "Apple account confirmation failed. Please check your connection and try again."
                }
            }
        }
    }

    func requestAccountDeletion(reason: String) async -> Bool {
        guard !isDeletingAccount else { return false }
        guard !requiresAppleDeletionAuthorization else {
            toastMessage = "Confirm your Apple account before deleting it."
            return false
        }
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await api.requestAccountDeletion(
                reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
                token: apiToken
            )
            secureStore.set("", for: appleUserIDKey)
            logout()
            toastMessage = "Account deletion request submitted successfully."
            return true
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }

    func saveProfileChanges() async {
        profile.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.phone = String(profile.phone.filter(\.isNumber).suffix(10))
        profile.email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard profile.isValid else {
            toastMessage = "Enter a valid name and either a mobile number or email address."
            return
        }
        if !profile.email.isEmpty, (!profile.email.contains("@") || !profile.email.contains(".")) {
            toastMessage = "Enter a valid email address."
            return
        }
        do {
            try await api.upsertUserProfile(profile, fcmToken: notificationService.fcmToken, token: apiToken)
            showEditProfileSheet = false
            toastMessage = "Profile updated successfully."
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    func resendLoginOTP() async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            let response = try await api.sendLoginOTP(phone: loginPhone)
            loginOTPRequestID = response.requestId
            loginOTPExpiresInSeconds = max(1, response.expiresInSeconds)
            loginOTPExpiresAt = Date().addingTimeInterval(TimeInterval(loginOTPExpiresInSeconds))
            return true
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }

    func verifyLoginOTP(_ otp: String) async -> Bool {
        guard !isAuthenticating else { return false }
        guard !loginOTPRequestID.isEmpty else {
            toastMessage = "OTP session expired. Please request a new OTP."
            return false
        }
        if let expiresAt = loginOTPExpiresAt, expiresAt <= Date() {
            loginOTPRequestID = ""
            loginOTPExpiresAt = nil
            toastMessage = "This OTP has expired. Please request a new one."
            return false
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            let verification = try await api.verifyLoginOTP(
                phone: loginPhone,
                requestId: loginOTPRequestID,
                otp: otp
            )
            let token = try await firebaseSessionToken(customToken: verification.customToken)
            secureStore.set(token, for: tokenKey)
            authToken = token
            profile.name = loginName
            profile.phone = verification.phone.filter(\.isNumber).suffix(10).description
            loginOTPRequestID = ""
            loginOTPExpiresAt = nil
            startupLocationPhase = .idle
            startupManualAddress = ""
            isStartupManualEntry = false
            navigate(.startupLocation, remember: false)
            await syncUserProfile()
            Task { await refreshBookings(); await refreshNotifications() }
            await openPendingNotificationDeepLinkIfNeeded()
            return true
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }

    private func firebaseSessionToken(customToken: String) async throws -> String {
        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        return try await result.user.getIDToken()
        #else
        throw APIError.badResponse("Authentication is unavailable in this build.")
        #endif
    }

    func detectStartupLocation() {
        guard startupLocationTask == nil, startupLocationPhase != .detecting else { return }
        isStartupManualEntry = false
        startupLocationPhase = .detecting
        let service = locationService
        startupLocationTask = Task { [weak self] in
            let result = await service.currentLocation()
            guard let self, !Task.isCancelled else { return }
            await self.handleStartupLocationResult(result)
            self.startupLocationTask = nil
        }
    }

    func showStartupManualEntry() {
        startupLocationTask?.cancel()
        startupLocationTask = nil
        locationService.cancelCurrentRequest()
        isStartupManualEntry = true
        startupLocationPhase = .idle
    }

    func openLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            toastMessage = "Location settings are unavailable on this device."
            return
        }
        UIApplication.shared.open(url)
    }

    func submitStartupManualLocation() {
        let address = startupManualAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard address.count >= 5 else {
            toastMessage = "Enter a complete service location."
            return
        }
        guard startupLocationTask == nil else { return }
        isStartupManualEntry = false
        startupLocationPhase = .detecting
        let service = locationService
        startupLocationTask = Task { [weak self] in
            let point = await service.coordinate(for: address)
            guard let self, !Task.isCancelled else { return }
            defer { self.startupLocationTask = nil }
            guard let point else {
                self.startupLocationPhase = .idle
                self.isStartupManualEntry = true
                self.toastMessage = "We could not find that location. Enter a more complete address."
                return
            }
            self.profile.address = address
            self.profile.lat = point.latitude
            self.profile.lng = point.longitude
            self.startupLocationPhase = .detected
            Task { await self.syncUserProfile() }
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled,
                  self.screen == .startupLocation,
                  self.startupLocationPhase == .detected else { return }
            self.completeStartupLocationGate()
        }
    }

    func continueWithoutStartupLocation() {
        startupLocationTask?.cancel()
        startupLocationTask = nil
        locationService.cancelCurrentRequest()
        startupManualAddress = ""
        isStartupManualEntry = false
        startupLocationPhase = .idle
        profile.address = AppConfig.defaultCity
        profile.lat = AppConfig.defaultLatitude
        profile.lng = AppConfig.defaultLongitude
        completeStartupLocationGate()
    }

    // Compatibility for the existing location view until it adopts the typed startup API.
    func finishLocationGate() {
        detectStartupLocation()
    }

    private func handleStartupLocationResult(_ result: LocationDetectionResult) async {
        switch result {
        case .detected(let point):
            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            // A reverse-geocoding request needs network access and may take much
            // longer than the GPS fix. Do not keep the user on the location gate
            // while that request is pending.
            profile.address = "Current location"
            profile.lat = point.latitude
            profile.lng = point.longitude
            startupLocationPhase = .detected
            Task { await syncUserProfile() }
            Task { [weak self] in
                guard let self else { return }
                let address = await self.locationService.address(for: coordinate)
                guard self.profile.lat == point.latitude,
                      self.profile.lng == point.longitude else { return }
                self.profile.address = address
                await self.syncUserProfile()
            }
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled,
                  screen == .startupLocation,
                  startupLocationPhase == .detected else { return }
            completeStartupLocationGate()
        case .permissionDenied:
            startupLocationPhase = .permissionDenied
        case .restricted:
            startupLocationPhase = .restricted
        case .unavailable:
            startupLocationPhase = .unavailable
        case .failure:
            startupLocationPhase = .failure
            // The location screen already presents the retry/manual choices.
            // Avoid a second alert that hides those actions.
        }
    }

    private func completeStartupLocationGate() {
        navigate(.home, remember: false)
        Task {
            // Ask for booking notifications only after the location prompt has
            // completed so iOS never has two permission dialogs competing.
            await requestRequiredNotificationPermission()
            await openPendingNotificationDeepLinkIfNeeded()
        }
    }

    private func requestRequiredNotificationPermission() async {
        let granted = await notificationService.requestPermissionIfNeeded()
        guard granted else { return }
        let token = await notificationService.refreshFCMToken()
        guard !token.isEmpty, isLoggedIn else { return }
        try? await api.saveFCMToken(token, token: apiToken)
    }

    func openService(_ service: ServiceItem) {
        selectedService = service
        Task {
            await refreshAppControl()
            guard selectedService.id == service.id else { return }
            openServiceUsingCurrentControl(service)
        }
    }

    func refreshAppControl() async {
        do {
            let response = try await api.fetchCustomerAppControl()
            appControlMode = response.config.appStatus.mode
            serviceRules = Dictionary(uniqueKeysWithValues: response.config.services.map { key, value in
                (Self.normalizedServiceKey(key), value)
            })
        } catch {
            // Keep the last known safe config when a refresh temporarily fails.
        }
    }

    private func openServiceUsingCurrentControl(_ service: ServiceItem, commercial: Bool = false) {
        selectedService = service
        selectedServiceStatusMessage = ""
        if appControlMode == .highDemand {
            selectedServiceStatusMessage = "We are currently receiving a high number of service requests. Please try again after some time."
            navigate(.serviceHighDemand)
            return
        }
        if appControlMode == .maintenance {
            selectedServiceStatusMessage = "ApnaServo is currently under maintenance. Please try again after some time."
            navigate(.servicePreparing)
            return
        }

        let rule = serviceRules[Self.normalizedServiceKey(service.id)] ?? RemoteServiceRule()
        if rule.isActiveNow {
            selectedServiceStatusMessage = rule.message.trimmingCharacters(in: .whitespacesAndNewlines)
            switch rule.status {
            case .highDemand:
                navigate(.serviceHighDemand)
                return
            case .preparing, .temporarilyUnavailable, .disabled:
                navigate(.servicePreparing)
                return
            case .available:
                break
            }
        }
        startBooking(service, commercial: commercial)
    }

    func showAllServices(category: String? = nil) {
        if let category {
            activeCategory = category
        }
        navigate(.services)
    }

    func startBooking(_ service: ServiceItem, commercial: Bool = false) {
        guard serviceIsBookable(service) else {
            toastMessage = serviceUnavailableMessage(for: service)
            return
        }
        guard activeBookings.count < (remoteAppControl?.config.booking.maxActiveBookings ?? 10) else {
            toastMessage = "You already have the maximum number of active bookings allowed."
            return
        }
        selectedService = service
        isCommercialBooking = commercial
        bookingLocationTask?.cancel()
        bookingLocationTask = nil
        locationService.cancelCurrentRequest()
        draft = BookingDraft(
            problem: "",
            address: addressMode == .current ? "Detecting your current service location..." : "",
            tier: .normal,
            lat: profile.lat,
            lng: profile.lng,
            hasLocation: false
        )
        addressMode = .current
        houseFlat = ""
        building = ""
        floor = ""
        room = ""
        landmark = ""
        city = AppConfig.defaultCity
        state = "Assam"
        pinCode = ""
        selectedCleaningType = "Home Cleaning"
        selectedLaundryServiceType = "Wash & Fold"
        selectedLaundryItems = [:]
        navigate(.booking)
    }


    func useCurrentLocation() {
        guard bookingLocationTask == nil else { return }
        addressMode = .current
        draft.address = "Detecting your current service location..."
        draft.hasLocation = false
        toastMessage = "Detecting current location..."
        bookingLocationTask = Task { [weak self] in
            guard let self else { return }
            let result = await locationService.currentLocation()
            guard !Task.isCancelled else { return }
            switch result {
            case .detected(let point):
                let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                let address = await locationService.address(for: coordinate)
                guard !Task.isCancelled, addressMode == .current else { return }
                draft.lat = point.latitude
                draft.lng = point.longitude
                draft.address = address
                draft.hasLocation = true
                profile.address = address
                profile.lat = point.latitude
                profile.lng = point.longitude
                toastMessage = "Current location detected. Add the required house or flat number."
            case .permissionDenied, .restricted, .unavailable, .failure:
                draft.address = "Current location not detected"
                draft.hasLocation = false
                toastMessage = result.userMessage
            }
            bookingLocationTask = nil
        }
    }

    func useManualAddress() {
        bookingLocationTask?.cancel()
        bookingLocationTask = nil
        locationService.cancelCurrentRequest()
        addressMode = .manual
        draft.address = ""
        draft.hasLocation = false
    }

    func continueToConfirm() {
        if selectedService.id == "laundry" && selectedLaundryItems.isEmpty {
            toastMessage = "Please select at least one laundry item."
            return
        }
        profile.phone = String(profile.phone.filter(\.isNumber).suffix(10))
        guard profile.phone.count == 10 else {
            toastMessage = "Enter a valid 10-digit contact mobile number for this booking."
            return
        }
        if houseFlat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            toastMessage = "Enter house or flat number. This is required so the service partner can find your exact entrance."
            return
        }
        if addressMode == .current {
            if !draft.hasLocation {
                useCurrentLocation()
                toastMessage = "Wait for current location detection, then confirm again."
                return
            }
        } else {
            if draft.address.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
                toastMessage = "Enter the complete service address."
                return
            }
            if city.isEmpty || state.isEmpty || pinCode.count != 6 {
                toastMessage = "Enter city, state, and a valid 6-digit PIN code."
                return
            }
        }
        navigate(.confirm)
    }

    func updateLaundryItem(_ item: String, delta: Int) {
        let next = max(0, (selectedLaundryItems[item] ?? 0) + delta)
        if next == 0 {
            selectedLaundryItems.removeValue(forKey: item)
        } else {
            selectedLaundryItems[item] = next
        }
    }

    func selectAllLaundryItems() {
        selectedLaundryItems = Dictionary(uniqueKeysWithValues: laundryItems.map { ($0, 1) })
    }

    func bookingRequestDetails() -> String {
        let instructions = draft.problem.trimmingCharacters(in: .whitespacesAndNewlines)
        let tier = "Tier: \(draft.tier.rawValue)"
        if selectedService.id == "cleaning" {
            let detail = instructions.isEmpty
                ? selectedCleaningType
                : "\(selectedCleaningType) | Instructions: \(instructions)"
            return limitedBookingDetail("Type: \(detail) | \(tier)")
        }
        if selectedService.id == "laundry" {
            let items = laundryItems.compactMap { item -> String? in
                guard let quantity = selectedLaundryItems[item], quantity > 0 else { return nil }
                return "\(item) x\(quantity)"
            }.joined(separator: ", ")
            let base = "\(selectedLaundryServiceType) | Items: \(items)"
            let detail = instructions.isEmpty ? base : "\(base) | Instructions: \(instructions)"
            return limitedBookingDetail("Type: \(detail) | \(tier)")
        }
        let detail = instructions.isEmpty ? "Customer requested \(selectedService.name)" : instructions
        return limitedBookingDetail("Issue: \(detail) | \(tier)")
    }

    func confirmBooking() {
        guard !isBookingSubmitting else { return }
        guard isLoggedIn, !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            previousScreens.removeAll()
            screen = .login
            toastMessage = "Sign in with your mobile number to confirm this booking."
            return
        }
        let address = bookingAddressPreview()
        guard address.count >= 10 else {
            toastMessage = "Add a complete service address before confirming."
            return
        }
        isBookingSubmitting = true
        let issue = bookingRequestDetails()
        var networkDraft = draft
        networkDraft.problem = issue
        networkDraft.address = address
        let service = selectedService
        let customer = profile
        let requestID = bookingRequestID.isEmpty ? "IOS-\(UUID().uuidString)" : bookingRequestID
        bookingRequestID = requestID
        Task {
            do {
                let liveBooking = try await api.createBooking(
                    service: service,
                    draft: networkDraft,
                    profile: customer,
                    city: city,
                    fcmToken: notificationService.fcmToken,
                    requestID: requestID,
                    commercial: isCommercialBooking,
                    token: apiToken
                )
                latestBooking = liveBooking
                upsertBooking(liveBooking)
                bookingChatMessages = [
                    ChatMessage(id: "system-chat", bookingId: liveBooking.id, bookingCode: liveBooking.bookingCode, senderRole: "system", senderName: "ApnaServo", message: "Chat will be available after a partner is assigned.", clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
                ]
                addNotification(title: "Booking confirmed", body: "\(liveBooking.displayId) is now live for nearby partners.", type: "booking", bookingId: liveBooking.id)
                bookingRequestID = ""
                navigate(.bookingConfirmed)
                startBookingPolling()
                Task { await refreshBookings() }
            } catch {
                toastMessage = error.localizedDescription
            }
            isBookingSubmitting = false
        }
    }

    private func limitedBookingDetail(_ value: String) -> String {
        String(value.prefix(500))
    }

    func openTrack(_ booking: Booking? = nil) {
        if let booking {
            latestBooking = booking
        }
        startBookingPolling()
        navigate(.track)
    }

    func approveAmount() {
        guard let booking = latestBooking, !bookingActionInFlight else { return }
        guard booking.status == "amount_pending", booking.amount > 0 else {
            toastMessage = "Partner final amount is not ready yet."
            return
        }
        if booking.quoteExpiresAtMillis > 0,
           booking.quoteExpiresAtMillis <= Int64(Date().timeIntervalSince1970 * 1000) {
            toastMessage = "This quote expired. Ask the partner for a fresh amount."
            return
        }
        guard ["pending", "pending_customer"].contains(booking.quoteStatus) else {
            if booking.quoteStatus == "payment_submitted" {
                toastMessage = "Payment is already waiting for partner verification."
            } else {
                toastMessage = "This payment request is not active."
            }
            return
        }
        bookingActionInFlight = true
        Task {
            do {
                let live = try await api.submitDirectPayment(bookingId: booking.id, token: apiToken)
                latestBooking = live
                upsertBooking(live)
                toastMessage = "Payment submitted. Waiting for partner verification."
            } catch {
                toastMessage = "Payment update could not be sent. Please try again."
            }
            bookingActionInFlight = false
        }
    }

    func sendCounterOffer(amount: Int, message: String) {
        guard let booking = latestBooking, !bookingActionInFlight else { return }
        guard booking.status == "amount_pending", amount > 0 else {
            toastMessage = "Enter a valid counter amount."
            return
        }
        bookingActionInFlight = true
        Task {
            do {
                let live = try await api.counterOfferQuote(booking.id, amount: amount, message: message, token: apiToken)
                latestBooking = live
                upsertBooking(live)
                toastMessage = "Counter offer sent to \(booking.partnerName)."
            } catch {
                toastMessage = "Counter offer could not be sent. Please retry."
            }
            bookingActionInFlight = false
        }
    }

    func cancelLatestBooking() {
        guard let booking = latestBooking, booking.canCustomerCancel, !bookingActionInFlight else {
            toastMessage = "This booking can no longer be cancelled from the app."
            return
        }
        bookingActionInFlight = true
        Task {
            do {
                let live = try await api.cancelBooking(booking.id, token: apiToken)
                latestBooking = live
                upsertBooking(live)
                stopBookingPolling()
                navigate(.bookings, remember: false)
                toastMessage = "Booking cancelled successfully."
            } catch {
                toastMessage = error.localizedDescription
            }
            bookingActionInFlight = false
        }
    }

    func callPartner(_ booking: Booking) {
        let digits = booking.partnerPhone.filter(\.isNumber)
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else {
            toastMessage = "Partner phone number is not available yet."
            return
        }
        Task {
            await api.createCallLog(bookingId: booking.id, action: "start", token: apiToken)
        }
        UIApplication.shared.open(url)
    }

    func submitServiceRating(_ rating: Int, comment: String = "") {
        guard let booking = latestBooking, booking.status == "completed", (1...5).contains(rating), !bookingActionInFlight else { return }
        bookingActionInFlight = true
        Task {
            do {
                try await api.submitReview(bookingId: booking.id, rating: rating, comment: comment, token: apiToken)
                submittedRatings[booking.id] = rating
                persistSubmittedRatings()
                toastMessage = "Thank you. Your rating was submitted."
            } catch {
                toastMessage = "Rating could not be submitted. Please retry."
            }
            bookingActionInFlight = false
        }
    }

    func requestCancellation(_ booking: Booking) {
        guard ["pending", "sent_to_partner", "accepted", "on_the_way", "arrived"].contains(booking.status) else {
            toastMessage = "Booking cannot be cancelled after work starts."
            return
        }
        latestBooking = booking
        cancelReason = ""
        showCancelSheet = true
    }

    func requestCounterOffer(_ booking: Booking) {
        guard booking.status == "amount_pending", booking.quoteStatus == "pending" else {
            toastMessage = "A counter offer is not available for this booking."
            return
        }
        latestBooking = booking
        counterOfferAmount = booking.amount > 0 ? String(max(1, booking.amount - 100)) : ""
        counterOfferMessage = ""
        showCounterOfferSheet = true
    }

    func submitCounterOffer() {
        guard let booking = latestBooking,
              let amount = Int(counterOfferAmount),
              amount > 0 else {
            toastMessage = "Enter a valid offer amount."
            return
        }
        showCounterOfferSheet = false
        Task {
            do {
                let updated = try await api.counterOfferQuote(
                    booking.id,
                    amount: amount,
                    message: counterOfferMessage.trimmingCharacters(in: .whitespacesAndNewlines),
                    token: apiToken
                )
                latestBooking = updated
                upsertBooking(updated)
                toastMessage = "Counter offer sent to the partner."
                await refreshBookings()
            } catch {
                toastMessage = error.localizedDescription
            }
        }
    }

    func requestReview(_ booking: Booking) {
        guard booking.status == "completed" else {
            toastMessage = "Only completed bookings can be reviewed."
            return
        }
        guard !reviewedBookingIDs.contains(booking.id) else {
            toastMessage = "This booking is already reviewed."
            return
        }
        latestBooking = booking
        reviewRating = 5
        reviewComment = ""
        showReviewSheet = true
    }

    func submitReview() {
        guard let booking = latestBooking else { return }
        let rating = min(max(reviewRating, 1), 5)
        showReviewSheet = false
        Task {
            do {
                try await api.submitReview(
                    bookingId: booking.id,
                    rating: rating,
                    comment: reviewComment.trimmingCharacters(in: .whitespacesAndNewlines),
                    token: apiToken
                )
                reviewedBookingIDs.insert(booking.id)
                toastMessage = "Thank you for your review."
            } catch {
                toastMessage = error.localizedDescription
            }
        }
    }

    func openBookingChat(_ booking: Booking? = nil) {
        if let booking {
            latestBooking = booking
        }
        guard latestBooking != nil else { return }
        navigate(.bookingChat)
        Task { await loadBookingChat() }
    }

    func sendBookingChat(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let booking = latestBooking, !clean.isEmpty else { return }
        let local = ChatMessage.local(text: clean, booking: booking)
        bookingChatMessages.append(local)
        Task {
            do {
                let sent = try await api.sendBookingChatMessage(bookingId: booking.id, message: clean, token: apiToken)
                if let index = bookingChatMessages.firstIndex(where: { $0.id == local.id }) {
                    bookingChatMessages[index] = sent
                }
                await api.monitorBookingChat(bookingId: booking.id, message: clean, clientMessageId: sent.clientMessageId, token: apiToken)
            } catch {
                if let index = bookingChatMessages.firstIndex(where: { $0.id == local.id }) {
                    bookingChatMessages[index].deliveryStatus = "failed"
                }
                toastMessage = "Message could not be sent. Please retry."
            }
        }
    }

    func loadBookingChat() async {
        guard let booking = latestBooking, !isLoadingBookingChat else { return }
        isLoadingBookingChat = true
        defer { isLoadingBookingChat = false }
        do {
            bookingChatMessages = try await api.fetchBookingChatMessages(bookingId: booking.id, token: apiToken)
            await api.markBookingChatSeen(bookingId: booking.id, token: apiToken)
        } catch {
            toastMessage = "Chat could not be refreshed."
        }
    }

    func sendSupportMessage(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, isLoggedIn, !isSupportMessageSending else {
            toastMessage = "Please sign in to contact support."
            return
        }
        let clientMessageId = UUID().uuidString
        let ticketId: String
        if let saved = defaults.string(forKey: supportTicketKey), !saved.isEmpty {
            ticketId = saved
        } else {
            ticketId = ""
        }
        isSupportMessageSending = true
        supportMessages.append(ChatMessage(id: clientMessageId, bookingId: "support", bookingCode: "", senderRole: "user", senderName: "You", message: clean, clientMessageId: clientMessageId, deliveryStatus: "sending", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)))
        Task {
            do {
                let ticket = try await api.sendSupportTicketMessage(
                    ticketId: ticketId,
                    clientMessageId: clientMessageId,
                    message: clean,
                    booking: latestBooking,
                    token: apiToken
                )
                defaults.set(ticket.ticketId, forKey: supportTicketKey)
                supportTicketId = ticket.ticketId
                supportTicketStatus = ticket.status
                if let index = supportMessages.firstIndex(where: { $0.id == clientMessageId }) {
                    supportMessages[index].deliveryStatus = "sent"
                }
                await loadSupportChat(showError: false)
                toastMessage = "Message sent to ApnaServo Support."
            } catch {
                if let index = supportMessages.firstIndex(where: { $0.id == clientMessageId }) {
                    supportMessages[index].deliveryStatus = "failed"
                }
                toastMessage = error.localizedDescription
            }
            isSupportMessageSending = false
        }
    }

    func markNotificationRead(_ item: AppNotificationItem) {
        notifications = notifications.map { notification in
            var copy = notification
            if copy.id == item.id {
                copy.isRead = true
            }
            return copy
        }
        Task { await api.markNotificationRead(item.id, token: apiToken) }
    }

    func refreshNotifications() async {
        guard isLoggedIn, !isRefreshingNotifications else { return }
        isRefreshingNotifications = true
        defer { isRefreshingNotifications = false }
        do {
            notifications = try await api.fetchNotifications(token: apiToken)
        } catch {
            // Keep visible notification state on a temporary network failure.
        }
    }

    func openNotification(_ item: AppNotificationItem) {
        markNotificationRead(item)
        let inferredAction: String
        if !item.actionType.isEmpty {
            inferredAction = item.actionType
        } else if item.type.lowercased().contains("chat") {
            inferredAction = "OPEN_BOOKING_CHAT"
        } else {
            inferredAction = "OPEN_BOOKING"
        }
        let deepLink = AppNotificationDeepLink(
            actionType: inferredAction,
            type: item.type,
            bookingId: item.bookingId,
            bookingCode: item.bookingCode,
            targetApp: "USER"
        )
        Task { await openNotificationDeepLink(deepLink) }
    }

    func openNotificationDeepLink(_ deepLink: AppNotificationDeepLink) async {
        guard deepLink.targetApp.isEmpty || deepLink.targetApp == "USER" else { return }
        guard isLoggedIn else {
            pendingNotificationDeepLink = deepLink
            return
        }

        if deepLink.actionType == "OPEN_SUPPORT" || deepLink.type.contains("support") {
            navigate(.support, remember: false)
            return
        }
        if deepLink.actionType == "OPEN_HOME" {
            navigate(.home, remember: false)
            return
        }

        var booking = bookingMatching(deepLink)
        if booking == nil, !deepLink.bookingId.isEmpty {
            booking = try? await api.getBooking(deepLink.bookingId, token: apiToken)
            if let booking { upsertBooking(booking) }
        }
        if booking == nil {
            await refreshBookings()
            booking = bookingMatching(deepLink)
        }

        guard let booking else {
            navigate(.bookings, remember: false)
            toastMessage = "Booking update received. Open the matching booking from My Bookings."
            return
        }

        latestBooking = booking
        if deepLink.isChat {
            navigate(.bookingChat, remember: false)
            await loadBookingChat()
        } else {
            openTrack(booking)
        }
    }

    private func openPendingNotificationDeepLinkIfNeeded() async {
        guard let deepLink = pendingNotificationDeepLink else { return }
        pendingNotificationDeepLink = nil
        await openNotificationDeepLink(deepLink)
    }

    private func bookingMatching(_ deepLink: AppNotificationDeepLink) -> Booking? {
        bookings.first { booking in
            (!deepLink.bookingId.isEmpty && booking.id == deepLink.bookingId)
                || (!deepLink.bookingCode.isEmpty && booking.bookingCode == deepLink.bookingCode)
        }
    }

    func markAllNotificationsRead() {
        let unreadIds = notifications.filter { !$0.isRead }.map(\.id)
        notifications = notifications.map { notification in
            var copy = notification
            copy.isRead = true
            return copy
        }
        Task {
            await api.markAllNotificationsRead(unreadIds, token: apiToken)
        }
    }

    func openCommercialService(_ title: String, serviceId: String) {
        selectedCommercialServiceTitle = title
        selectedCommercialServiceId = serviceId
        Task {
            await refreshAppControl()
            guard commercialControlAllowsBooking() else { return }
            openServiceUsingCurrentControl(ServiceCatalog.service(id: serviceId), commercial: true)
        }
    }

    func openCommercialServices() {
        Task {
            await refreshAppControl()
            guard commercialControlAllowsBooking() else { return }
            navigate(.commercial)
        }
    }

    private func commercialControlAllowsBooking() -> Bool {
        if appControlMode == .maintenance {
            selectedServiceStatusMessage = "ApnaServo is currently under maintenance. Please try again after some time."
            navigate(.servicePreparing)
            return false
        }
        if appControlMode == .highDemand {
            selectedServiceStatusMessage = "We are currently receiving a high number of commercial requests. Please try again after some time."
            navigate(.serviceHighDemand)
            return false
        }
        let rule = serviceRules["commercial"] ?? RemoteServiceRule()
        guard rule.isActiveNow else { return true }
        selectedServiceStatusMessage = rule.message.trimmingCharacters(in: .whitespacesAndNewlines)
        switch rule.status {
        case .available:
            return true
        case .highDemand:
            navigate(.serviceHighDemand)
        case .preparing, .temporarilyUnavailable, .disabled:
            navigate(.servicePreparing)
        }
        return false
    }

    private static func normalizedServiceKey(_ value: String) -> String {
        let key = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        switch key {
        case "plumber": return "plumbing"
        case "pest_control": return "pest"
        case "roadside_assistance": return "roadside"
        case "interior_design": return "interior"
        default: return key
        }
    }

    func loadSupportChat(showError: Bool = true) async {
        guard isLoggedIn,
              let ticketId = defaults.string(forKey: supportTicketKey),
              !ticketId.isEmpty else { return }
        do {
            let ticket = try await api.fetchSupportTicket(ticketId: ticketId, token: apiToken)
            defaults.set(ticket.ticketId, forKey: supportTicketKey)
            supportTicketId = ticket.ticketId
            supportTicketStatus = ticket.status
            supportAssignedAgent = ticket.assignedTo ?? ""
            supportBookingCode = ticket.bookingCode ?? ""
            let pending = supportMessages.filter { $0.senderRole == "user" && ["sending", "failed"].contains($0.deliveryStatus) }
            var merged = ticket.messages
            for local in pending where !merged.contains(where: {
                (!$0.clientMessageId.isEmpty && $0.clientMessageId == local.clientMessageId) || $0.id == local.id
            }) {
                merged.append(local)
            }
            merged.sort { $0.createdAtMillis < $1.createdAtMillis }
            supportMessages = merged.isEmpty ? supportMessages : merged
        } catch {
            if showError { toastMessage = "Support chat could not be refreshed." }
        }
    }

    func retrySupportMessage(_ message: ChatMessage) {
        guard message.senderRole == "user", message.deliveryStatus == "failed" else { return }
        supportMessages.removeAll { $0.id == message.id }
        sendSupportMessage(message.message)
    }

    func logout() {
        stopBookingPolling()
        bookingLocationTask?.cancel()
        bookingLocationTask = nil
        startupLocationTask?.cancel()
        startupLocationTask = nil
        locationService.cancelCurrentRequest()
        profile = UserProfile()
        startupLocationPhase = .idle
        startupManualAddress = ""
        isStartupManualEntry = false
        latestBooking = nil
        bookings = []
        supportMessages = [
            ChatMessage(id: "support-welcome", bookingId: "support", bookingCode: "", senderRole: "support", senderName: "ApnaServo Support", message: "Hi, how can we help?", clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
        ]
        supportTicketId = ""
        supportTicketStatus = ""
        supportAssignedAgent = ""
        supportBookingCode = ""
        isSupportMessageSending = false
        submittedRatings = [:]
        defaults.removeObject(forKey: submittedRatingsKey)
        defaults.removeObject(forKey: supportTicketKey)
        appleDeletionAuthorizationRevoked = false
        previousScreens = []
        authToken = ""
        secureStore.set("", for: tokenKey)
#if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
#endif
        screen = .login
    }

    func configureAppServices() {
        notificationService.configure()
        Task {
            let fcmToken = await notificationService.refreshFCMToken()
            if isLoggedIn, !fcmToken.isEmpty {
                try? await api.saveFCMToken(fcmToken, token: apiToken)
            }
        }
    }

    func enableBookingNotifications() async {
        let granted = await notificationService.requestPermission()
        guard granted else {
            toastMessage = "Notifications are off. You can enable them in iPhone Settings."
            return
        }
        let token = await notificationService.refreshFCMToken()
        if isLoggedIn, !token.isEmpty {
            do {
                try await api.saveFCMToken(token, token: apiToken)
                toastMessage = "Booking notifications enabled."
            } catch {
                toastMessage = error.localizedDescription
            }
        } else {
            toastMessage = "Booking notifications enabled."
        }
    }

    func refreshBookings() async {
        guard isLoggedIn, !isRefreshingBookings else { return }
        isRefreshingBookings = true
        defer { isRefreshingBookings = false }
        do {
            let liveBookings = try await api.fetchUserBookings(token: apiToken)
            // Keep a just-created local booking while a read replica catches up.
            var merged = liveBookings
            for cached in bookings where !merged.contains(where: { $0.id == cached.id || $0.bookingCode == cached.bookingCode }) {
                merged.append(cached)
            }
            bookings = merged.sorted { $0.createdAtMillis > $1.createdAtMillis }
            if let current = latestBooking,
               let updated = liveBookings.first(where: { $0.id == current.id || $0.bookingCode == current.bookingCode }) {
                latestBooking = updated
            } else if latestBooking == nil {
                latestBooking = liveBookings.first { !["completed", "cancelled", "rejected"].contains($0.status) }
            }
        } catch {
            // Keep local cached bookings if the network is temporarily unavailable.
        }
    }

    func refreshLatestBooking() async {
        guard let booking = latestBooking, !isRefreshingLatestBooking else { return }
        isRefreshingLatestBooking = true
        defer { isRefreshingLatestBooking = false }
        do {
            let live = try await api.getBooking(booking.id, token: apiToken)
            latestBooking = live
            upsertBooking(live)
        } catch {
            await refreshBookings()
        }
    }

    func startBookingPolling() {
        bookingPollingTask?.cancel()
        guard latestBooking != nil else { return }
        bookingPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshLatestBooking()
                guard let status = self?.latestBooking?.status,
                      !["completed", "cancelled", "rejected"].contains(status) else {
                    break
                }
                try? await Task.sleep(nanoseconds: AppConfig.bookingStatusRefreshSeconds)
            }
            self?.bookingPollingTask = nil
        }
    }

    func stopBookingPolling() {
        bookingPollingTask?.cancel()
        bookingPollingTask = nil
    }

    func bookingAddressPreview() -> String {
        if addressMode == .current {
            let parts = [houseFlat, building, floor, room, landmark, draft.address]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.lowercased().contains("detecting") }
            return parts.isEmpty ? "Location will be detected before booking" : parts.joined(separator: ", ")
        }
        let parts = [houseFlat, building, floor, room, landmark, draft.address, city, state, pinCode]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    private func upsertBooking(_ booking: Booking) {
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[index] = booking
        } else {
            bookings.insert(booking, at: 0)
        }
    }

    private func persistSubmittedRatings() {
        if let data = try? JSONEncoder().encode(submittedRatings) {
            defaults.set(data, forKey: submittedRatingsKey)
        }
    }

    private var apiToken: String {
        let saved = secureStore.string(for: tokenKey)
        return saved.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func syncUserProfile() async {
        do {
            try await api.upsertUserProfile(profile, fcmToken: notificationService.fcmToken, token: apiToken)
        } catch {
            // Login remains usable; the next booking write will also carry user details.
        }
    }

    private func addNotification(title: String, body: String, type: String, bookingId: String) {
        notifications.insert(
            AppNotificationItem(
                id: UUID().uuidString,
                title: title,
                body: body,
                type: type,
                bookingId: bookingId,
                isRead: false,
                createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
            ),
            at: 0
        )
    }

    private func supportReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("payment") || lower.contains("amount") {
            return "Payment and final quote help is available from the track screen after expert inspection."
        }
        if lower.contains("booking") || lower.contains("partner") {
            return "Open My Bookings to track partner assignment, live status, and service details."
        }
        if lower.contains("address") || lower.contains("location") {
            return "You can update address before confirming the booking. Support can help after confirmation."
        }
        return "Request recorded. Our support team will follow up from your booking details."
    }
}
