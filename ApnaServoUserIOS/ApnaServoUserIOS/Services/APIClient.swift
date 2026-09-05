import Foundation
import CoreLocation
import Security
import UIKit
import UserNotifications

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum APIError: LocalizedError {
    case missingToken
    case invalidURL
    case unauthorized(String)
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Your session is unavailable. Please sign in again."
        case .invalidURL:
            return "Backend URL invalid."
        case .unauthorized(let message):
            return message
        case .badResponse(let message):
            return message
        }
    }
}

final class APIClient {
    private var activeBaseURL: URL
    private let baseURLs: [URL]
    private let session: URLSession

    init(baseURLs: [URL] = [AppConfig.apiBaseURL], session: URLSession = .shared) {
        let resolvedBaseURLs = baseURLs.isEmpty ? [AppConfig.apiBaseURL] : baseURLs
        self.baseURLs = resolvedBaseURLs
        self.activeBaseURL = resolvedBaseURLs[0]
        self.session = session
    }

    var socketURL: URL {
        AppConfig.socketURL
    }

    /// Published configuration is intentionally public: it contains display and
    /// availability rules only, never an admin credential or customer data.
    func fetchPublishedAppConfiguration() async throws -> RemoteAppControlEnvelope {
        try await publicRequest(path: "/app-control/config?app=customer", method: "GET")
    }

    func sendLoginOTP(phone: String) async throws -> OTPSendResponse {
        try await publicRequest(
            path: "/otp/send",
            method: "POST",
            body: ["phone": phone, "role": "user"]
        )
    }

    func verifyLoginOTP(phone: String, requestId: String, otp: String) async throws -> OTPVerifyResponse {
        try await publicRequest(
            path: "/otp/verify",
            method: "POST",
            body: ["phone": phone, "requestId": requestId, "otp": otp, "role": "user"]
        )
    }

    func upsertUserProfile(_ profile: UserProfile, fcmToken: String, token: String) async throws {
        let body: [String: Any] = [
            "name": profile.name,
            "phone": profile.phone,
            "email": profile.email,
            "address": profile.address,
            "city": AppConfig.defaultCity,
            "lat": profile.lat,
            "lng": profile.lng,
            "fcmToken": fcmToken
        ]
        let _: EmptyResponse = try await request(path: "/users/profile", method: "POST", token: token, body: body)
    }

    func saveFCMToken(_ fcmToken: String, token: String) async throws {
        let deviceID = await MainActor.run {
            UIDevice.current.identifierForVendor?.uuidString ?? "ios-user-device"
        }
        let _: EmptyResponse = try await request(
            path: "/users/fcm-token",
            method: "POST",
            token: token,
            body: [
                "fcmToken": fcmToken,
                "platform": "ios",
                "deviceId": deviceID,
                "appType": "user"
            ]
        )
    }

    func trackUserActivity(
        event: String,
        screen: String,
        serviceId: String = "",
        serviceName: String = "",
        category: String = "",
        token: String
    ) async {
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let _: EmptyResponse? = try? await request(
            path: "/users/activity",
            method: "POST",
            token: token,
            body: [
                "event": event,
                "platform": "ios",
                "screen": screen,
                "serviceId": serviceId,
                "serviceName": serviceName,
                "category": category
            ]
        )
    }

    func requestAccountDeletion(reason: String, token: String) async throws {
        let _: EmptyResponse = try await request(
            path: "/users/delete-account-request",
            method: "POST",
            token: token,
            body: ["reason": reason]
        )
    }

    func fetchCurrentUser(token: String) async throws -> UserAccountRecord {
        let envelope: UserAccountEnvelope = try await request(path: "/users/me", token: token)
        guard let user = envelope.user else {
            throw APIError.badResponse("Your account could not be restored. Please sign in again.")
        }
        return user
    }

    func sendSupportTicketMessage(ticketId: String, clientMessageId: String, message: String, booking: Booking?, token: String) async throws -> SupportTicketSyncResponse {
        var body: [String: Any] = [
            "clientMessageId": clientMessageId,
            "senderRole": "user",
            "senderName": "Customer",
            "message": message,
            "source": "ios_user_app",
            "platform": "ios",
            "serverBot": true
        ]
        if !ticketId.isEmpty { body["ticketId"] = ticketId }
        if let booking {
            body["bookingId"] = booking.id
            body["bookingCode"] = booking.bookingCode
        }
        return try await request(path: "/users/support-tickets/sync", method: "POST", token: token, body: body)
    }

    func fetchSupportTicket(ticketId: String, token: String) async throws -> SupportTicketEnvelope {
        guard let encodedTicketId = ticketId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.badResponse("Support ticket is invalid.")
        }
        return try await request(path: "/users/support-tickets/\(encodedTicketId)", token: token)
    }

    func fetchLatestSupportTicket(token: String) async throws -> SupportTicketEnvelope? {
        let envelope: LatestSupportTicketEnvelope = try await request(
            path: "/users/support-tickets/latest",
            token: token
        )
        return envelope.ticket
    }

    func fetchNotifications(token: String) async throws -> [AppNotificationItem] {
        let envelope: NotificationsEnvelope = try await request(path: "/notifications?role=user", token: token)
        return envelope.notifications ?? []
    }

    func fetchUserBookings(token: String) async throws -> [Booking] {
        let envelope: BookingEnvelope = try await request(path: "/bookings/user", token: token)
        return envelope.bookings ?? []
    }

    func markNotificationRead(_ notificationId: String, token: String) async {
        guard !notificationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let path = "/notifications/\(notificationId)/read?role=user"
        let _: EmptyResponse? = try? await request(path: path, method: "PATCH", token: token, body: [:])
    }

    func markAllNotificationsRead(token: String) async {
        let _: EmptyResponse? = try? await request(
            path: "/notifications/read-all?role=user",
            method: "PATCH",
            token: token,
            body: [:]
        )
    }

    func createBooking(service: ServiceItem, draft: BookingDraft, profile: UserProfile, city: String, fcmToken: String, requestID: String, commercial: Bool, token: String) async throws -> Booking {
        let amount = service.price
        let body: [String: Any] = [
            "bookingCode": requestID,
            "serviceCategory": service.id,
            "serviceName": service.name,
            "serviceTier": draft.tier.rawValue,
            "issue": draft.problem,
            "problem": draft.problem,
            "address": draft.address,
            "location": draft.address,
            "city": city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppConfig.defaultCity : city,
            "lat": draft.lat,
            "lng": draft.lng,
            "defaultAmount": amount,
            "price": amount,
            "userName": profile.name,
            "customerName": profile.name,
            "userPhone": profile.phone,
            "phone": profile.phone,
            "userEmail": profile.email,
            "userFcmToken": fcmToken,
            "commercial": commercial
        ]
        let envelope: BookingEnvelope = try await request(path: "/bookings", method: "POST", token: token, body: body)
        guard let booking = envelope.booking else {
            throw APIError.badResponse("Booking confirmation was missing. Please retry safely.")
        }
        return booking
    }

    func getBooking(_ bookingId: String, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(path: "/bookings/\(bookingId)", token: token)
        if let booking = envelope.booking {
            return booking
        }
        throw APIError.badResponse("Booking not found.")
    }

    func updateBookingStatus(_ bookingId: String, status: String, finalAmount: Int, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(
            path: "/bookings/\(bookingId)/status",
            method: "PATCH",
            token: token,
            body: ["status": status, "finalAmount": finalAmount]
        )
        if let booking = envelope.booking {
            return booking
        }
        return try await getBooking(bookingId, token: token)
    }

    func cancelBooking(_ bookingId: String, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(
            path: "/bookings/\(bookingId)/cancel",
            method: "POST",
            token: token,
            body: [:]
        )
        if let booking = envelope.booking {
            return booking
        }
        return try await getBooking(bookingId, token: token)
    }

    func submitDirectPayment(bookingId: String, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(
            path: "/bookings/\(bookingId)/payment-submitted",
            method: "POST",
            token: token,
            body: [:]
        )
        if let booking = envelope.booking {
            return booking
        }
        return try await getBooking(bookingId, token: token)
    }

    func counterOfferQuote(_ bookingId: String, amount: Int, message: String, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(
            path: "/bookings/\(bookingId)/quote/counter",
            method: "POST",
            token: token,
            body: ["amount": amount, "message": message]
        )
        if let booking = envelope.booking {
            return booking
        }
        return try await getBooking(bookingId, token: token)
    }

    func submitReview(bookingId: String, rating: Int, comment: String, token: String) async throws {
        let body: [String: Any] = ["rating": rating, "comment": comment]
        let _: EmptyResponse = try await request(path: "/reviews/bookings/\(bookingId)", method: "POST", token: token, body: body)
    }

    func createCallLog(bookingId: String, action: String, token: String) async {
        let _: EmptyResponse? = try? await request(
            path: "/bookings/\(bookingId)/calls",
            method: "POST",
            token: token,
            body: ["action": action, "reason": ""]
        )
    }

    func monitorBookingChat(bookingId: String, message: String, clientMessageId: String, token: String) async {
        guard !bookingId.isEmpty, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let body: [String: Any] = [
            "message": message,
            "clientMessageId": clientMessageId,
            "source": "customer_support_chat"
        ]
        let _: EmptyResponse? = try? await request(path: "/bookings/\(bookingId)/chat/monitor", method: "POST", token: token, body: body)
    }

    func fetchBookingChatMessages(bookingId: String, token: String) async throws -> [ChatMessage] {
        let envelope: ChatEnvelope = try await request(path: "/bookings/\(bookingId)/chat/messages", token: token)
        return envelope.messages
    }

    func sendBookingChatMessage(bookingId: String, message: String, clientMessageId: String, token: String) async throws -> ChatMessage {
        let envelope: SendChatEnvelope = try await request(
            path: "/bookings/\(bookingId)/chat/messages",
            method: "POST",
            token: token,
            body: ["message": message, "clientMessageId": clientMessageId]
        )
        return envelope.message ?? ChatMessage(
            id: clientMessageId,
            bookingId: bookingId,
            bookingCode: "",
            senderRole: "user",
            senderName: "You",
            message: message,
            clientMessageId: clientMessageId,
            deliveryStatus: "sent",
            createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    func markBookingChatSeen(bookingId: String, token: String) async {
        let _: EmptyResponse? = try? await request(path: "/bookings/\(bookingId)/chat/seen", method: "PATCH", token: token, body: [:])
    }

    func fetchCustomerAppControl() async throws -> CustomerAppControlEnvelope {
        try await publicRequest(
            path: "/app-control/config?app=customer&platform=ios&audience=users",
            method: "GET"
        )
    }

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        token: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        let resolvedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedToken.isEmpty else { throw APIError.missingToken }

        var lastError: Error?
        var requestToken = resolvedToken
        var refreshedExpiredToken = false
        let ordered = [activeBaseURL] + baseURLs.filter { $0 != activeBaseURL }
        for baseURL in ordered {
            do {
                let value: T = try await execute(baseURL: baseURL, path: path, method: method, token: requestToken, body: body)
                activeBaseURL = baseURL
                return value
            } catch APIError.unauthorized(_) where !refreshedExpiredToken {
                refreshedExpiredToken = true
                #if canImport(FirebaseAuth)
                if let firebaseUser = Auth.auth().currentUser {
                    do {
                        requestToken = try await firebaseUser.getIDToken(forcingRefresh: true)
                        SecureStore().set(requestToken, for: "user_api_token")
                        let value: T = try await execute(baseURL: baseURL, path: path, method: method, token: requestToken, body: body)
                        activeBaseURL = baseURL
                        return value
                    } catch {
                        lastError = error
                    }
                } else {
                    lastError = APIError.unauthorized("Your session has expired. Please sign in again.")
                }
                #else
                lastError = APIError.unauthorized("Your session has expired. Please sign in again.")
                #endif
            } catch {
                lastError = error
            }
        }
        throw lastError ?? APIError.badResponse("Backend not reachable.")
    }

    private func publicRequest<T: Decodable>(
        path: String,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        var lastError: Error?
        let ordered = [activeBaseURL] + baseURLs.filter { $0 != activeBaseURL }
        for baseURL in ordered {
            do {
                let value: T = try await execute(baseURL: baseURL, path: path, method: method, token: "", body: body)
                activeBaseURL = baseURL
                return value
            } catch {
                lastError = error
            }
        }
        throw lastError ?? APIError.badResponse("Backend not reachable.")
    }

    private func execute<T: Decodable>(
        baseURL: URL,
        path: String,
        method: String,
        token: String,
        body: [String: Any]?
    ) async throws -> T {
        let url = try makeURL(baseURL: baseURL, path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 14
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw networkErrorMessage(for: error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse("Backend response invalid.")
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw APIError.unauthorized("Your session has expired. Please sign in again.")
            }
            throw APIError.badResponse(httpError(code: http.statusCode, data: data))
        }
        if data.isEmpty {
            if let empty = EmptyResponse() as? T {
                return empty
            }
            throw APIError.badResponse("Backend returned empty response.")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func networkErrorMessage(for error: Error) -> APIError {
        let code = (error as? URLError)?.code
        switch code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .badResponse("No internet connection. Check your network and try again.")
        case .timedOut:
            return .badResponse("The server is taking too long to respond. Please try again.")
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .badResponse("Sign-in service is unavailable right now. Please try again shortly.")
        default:
            return .badResponse("Could not reach the service. Check your connection and try again.")
        }
    }

    private func makeURL(baseURL: URL, path: String) throws -> URL {
        let parts = path.split(separator: "?", maxSplits: 1).map(String.init)
        let cleanPath = parts[0].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = baseURL
        for component in cleanPath.split(separator: "/") {
            url.appendPathComponent(String(component))
        }
        if parts.count > 1 {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.percentEncodedQuery = parts[1]
            guard let finalURL = components?.url else { throw APIError.invalidURL }
            return finalURL
        }
        return url
    }

    private func httpError(code: Int, data: Data) -> String {
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let message = object?["message"] as? String
        let requestID = object?["requestId"] as? String
        if (500...599).contains(code) {
            let reference = requestID?.isEmpty == false ? " Reference: \(requestID!)." : ""
            return "Booking service had a temporary problem. Please retry safely.\(reference)"
        }
        if let message, !message.isEmpty {
            return message
        }
        switch code {
        case 401, 403: return "Authentication expired. Please login again."
        case 404: return "Requested booking was not found."
        case 408, 425, 429: return "Server is busy. Please retry in a moment."
        case 500...599: return "Booking service had a temporary problem. Please retry safely."
        default: return "Request failed. Please check details and try again."
        }
    }
}

final class SecureStore {
    private let service = "com.apnaservo.userios.secure"

    func string(for key: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func set(_ value: String, for key: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        guard let data = value.data(using: .utf8) else { return }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}

extension Notification.Name {
    static let apnaServoUserFCMTokenUpdated = Notification.Name("apnaServoUserFCMTokenUpdated")
    static let apnaServoUserNotificationOpened = Notification.Name("apnaServoUserNotificationOpened")
}

struct AppNotificationDeepLink: Equatable {
    let actionType: String
    let type: String
    let bookingId: String
    let bookingCode: String
    let targetApp: String

    init(actionType: String, type: String, bookingId: String, bookingCode: String, targetApp: String) {
        self.actionType = actionType.uppercased()
        self.type = type.lowercased()
        self.bookingId = bookingId
        self.bookingCode = bookingCode
        self.targetApp = targetApp.uppercased()
    }

    init(userInfo: [AnyHashable: Any]) {
        func value(_ key: String) -> String {
            if let text = userInfo[key] as? String { return text }
            if let number = userInfo[key] as? NSNumber { return number.stringValue }
            if let nested = userInfo["data"] as? [String: Any] {
                if let text = nested[key] as? String { return text }
                if let number = nested[key] as? NSNumber { return number.stringValue }
            }
            return ""
        }

        actionType = value("actionType").uppercased()
        type = value("type").lowercased()
        bookingId = value("bookingId")
        bookingCode = value("bookingCode")
        targetApp = value("targetApp").uppercased()
    }

    var isChat: Bool {
        actionType == "OPEN_BOOKING_CHAT" || type.contains("chat")
    }
}

final class AppNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationService()
    private(set) var fcmToken = ""
    private var pendingDeepLink: AppNotificationDeepLink?

    private override init() {
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        #if canImport(FirebaseMessaging)
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().delegate = self
        fcmToken = Messaging.messaging().fcmToken ?? ""
        #endif
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    func requestPermissionIfNeeded() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return await requestPermission()
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func setAPNSToken(_ deviceToken: Data) {
        #if canImport(FirebaseMessaging)
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }

    func refreshFCMToken() async -> String {
        #if canImport(FirebaseMessaging)
        guard FirebaseApp.app() != nil else { return fcmToken }
        let refreshedToken: String? = await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, _ in
                continuation.resume(returning: token)
            }
        }
        if let refreshedToken {
            updateFCMToken(refreshedToken)
        }
        return fcmToken
        #else
        return fcmToken
        #endif
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let deepLink = AppNotificationDeepLink(userInfo: response.notification.request.content.userInfo)
        pendingDeepLink = deepLink
        NotificationCenter.default.post(name: .apnaServoUserNotificationOpened, object: deepLink)
        completionHandler()
    }

    private func updateFCMToken(_ token: String) {
        fcmToken = token
        NotificationCenter.default.post(name: .apnaServoUserFCMTokenUpdated, object: token)
    }

    func consumePendingDeepLink() -> AppNotificationDeepLink? {
        defer { pendingDeepLink = nil }
        return pendingDeepLink
    }

    func presentBookingStatus(title: String, body: String, bookingId: String, status: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "BOOKING_UPDATE"
        content.userInfo = [
            "type": "booking:status_update",
            "status": status,
            "bookingId": bookingId,
            "actionType": "OPEN_BOOKING"
        ]
        let identifier = "booking-status-\(bookingId)-\(status)"
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        )
    }
}

#if canImport(FirebaseMessaging)
extension AppNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        updateFCMToken(fcmToken ?? "")
    }
}
#endif

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<LocationDetectionResult, Never>?
    private var timeoutWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        manager.delegate = self
        // Service availability only needs an area-level position. Requiring a
        // ten-metre GPS lock keeps users indoors on the loading screen too long.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .other
    }

    func currentLocation() async -> LocationDetectionResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.startRequest(continuation)
            }
        }
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        switch await currentLocation() {
        case .detected(let coordinate):
            return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        case .permissionDenied:
            throw LocationServiceError.permissionDenied
        case .restricted:
            throw LocationServiceError.restricted
        case .unavailable:
            throw LocationServiceError.unavailable
        case .failure(let message):
            throw LocationServiceError.failure(message)
        }
    }

    func cancelCurrentRequest() {
        if Thread.isMainThread {
            finish(.failure("Location detection was cancelled."))
        } else {
            DispatchQueue.main.async {
                self.finish(.failure("Location detection was cancelled."))
            }
        }
    }

    func address(for coordinate: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
              let placemark = placemarks.first else {
            return "Current location"
        }
        let parts = [
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        return parts.isEmpty ? "Current location" : parts.joined(separator: ", ")
    }

    func coordinate(for address: String) async -> LocationCoordinate? {
        guard let placemarks = try? await CLGeocoder().geocodeAddressString(address),
              let coordinate = placemarks.first?.location?.coordinate else {
            return nil
        }
        return LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        handleAuthorization(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            finish(.failure("Location data was unavailable. Please retry."))
            return
        }
        finish(.detected(LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .denied {
            switch manager.authorizationStatus {
            case .denied:
                finish(.permissionDenied)
            case .restricted:
                finish(.restricted)
            default:
                finish(.unavailable)
            }
            return
        }
        finish(.failure("Location could not be detected. Please retry."))
    }

    private func startRequest(_ continuation: CheckedContinuation<LocationDetectionResult, Never>) {
        guard self.continuation == nil else {
            continuation.resume(returning: .failure("Location detection is already in progress."))
            return
        }
        self.continuation = continuation

        guard CLLocationManager.locationServicesEnabled() else {
            finish(.unavailable)
            return
        }
        handleAuthorization(manager.authorizationStatus)
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if let cachedLocation = manager.location,
               cachedLocation.horizontalAccuracy >= 0,
               abs(cachedLocation.timestamp.timeIntervalSinceNow) < 300 {
                finish(.detected(LocationCoordinate(
                    latitude: cachedLocation.coordinate.latitude,
                    longitude: cachedLocation.coordinate.longitude
                )))
                return
            }
            scheduleTimeout()
            // `requestLocation()` can wait indefinitely for a high-accuracy GPS
            // sample on some devices. Continuous updates also deliver a usable
            // Wi-Fi/cellular location while GPS is still acquiring a fix.
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied:
            finish(.permissionDenied)
        case .restricted:
            finish(.restricted)
        @unknown default:
            finish(.failure("Location authorization could not be determined."))
        }
    }

    private func scheduleTimeout() {
        timeoutWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.finish(.failure("Location is taking longer than expected. Please retry."))
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: workItem)
    }

    private func finish(_ result: LocationDetectionResult) {
        guard let continuation else { return }
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        self.continuation = nil
        manager.stopUpdatingLocation()
        continuation.resume(returning: result)
    }
}

enum LocationServiceError: LocalizedError {
    case permissionDenied
    case restricted
    case unavailable
    case failure(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return StartupLocationPhase.permissionDenied.message
        case .restricted:
            return StartupLocationPhase.restricted.message
        case .unavailable:
            return StartupLocationPhase.unavailable.message
        case .failure(let message):
            return message
        }
    }
}
