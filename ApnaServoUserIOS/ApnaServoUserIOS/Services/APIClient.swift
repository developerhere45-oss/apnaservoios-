import CoreLocation
import Foundation
import Security
import UserNotifications

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

enum APIError: LocalizedError {
    case missingToken
    case invalidURL
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Firebase ID token missing. Add Firebase iOS Auth or paste a temporary token in Profile."
        case .invalidURL:
            return "Backend URL invalid."
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
        self.baseURLs = baseURLs
        self.activeBaseURL = baseURLs[0]
        self.session = session
    }

    var socketURL: URL {
        AppConfig.socketURL
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
        let _: EmptyResponse = try await request(path: "/users/fcm-token", method: "POST", token: token, body: ["fcmToken": fcmToken])
    }

    func requestAccountDeletion(reason: String, token: String) async throws {
        let _: EmptyResponse = try await request(path: "/users/delete-account-request", method: "POST", token: token, body: ["reason": reason])
    }

    func fetchNotifications(token: String) async throws -> [AppNotificationItem] {
        let envelope: NotificationsEnvelope = try await request(path: "/notifications?role=user", token: token)
        return envelope.notifications ?? []
    }

    func markNotificationRead(_ notificationId: String, token: String) async {
        guard !notificationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let path = "/notifications/\(notificationId)/read?role=user"
        let _: EmptyResponse? = try? await request(path: path, method: "PATCH", token: token, body: [:])
    }

    func createBooking(service: ServiceItem, draft: BookingDraft, profile: UserProfile, fcmToken: String, token: String) async throws -> Booking {
        let amount = service.price
        let body: [String: Any] = [
            "serviceCategory": service.id,
            "serviceName": service.name,
            "serviceTier": draft.tier.rawValue,
            "issue": draft.problem,
            "problem": draft.problem,
            "address": draft.address,
            "location": draft.address,
            "city": AppConfig.defaultCity,
            "lat": draft.lat,
            "lng": draft.lng,
            "date": draft.date,
            "time": draft.time,
            "slot": draft.slot,
            "defaultAmount": amount,
            "price": amount,
            "userName": profile.name,
            "customerName": profile.name,
            "userPhone": profile.phone,
            "phone": profile.phone,
            "userEmail": profile.email,
            "phoneVerified": true,
            "userFcmToken": fcmToken
        ]
        let envelope: BookingEnvelope = try await request(path: "/bookings", method: "POST", token: token, body: body)
        return envelope.booking ?? Booking(
            id: "local-\(UUID().uuidString)",
            bookingCode: "",
            serviceCategory: service.id,
            serviceName: service.name,
            issue: draft.problem,
            address: draft.address,
            slot: draft.slot,
            customerName: profile.name,
            userPhone: profile.phone,
            defaultAmount: amount,
            lat: draft.lat,
            lng: draft.lng
        )
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
        return envelope.booking ?? try await getBooking(bookingId, token: token)
    }

    func counterOfferQuote(_ bookingId: String, amount: Int, message: String, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(
            path: "/bookings/\(bookingId)/quote/counter",
            method: "POST",
            token: token,
            body: ["amount": amount, "message": message]
        )
        return envelope.booking ?? try await getBooking(bookingId, token: token)
    }

    func submitReview(bookingId: String, rating: Int, comment: String, token: String) async throws {
        let body: [String: Any] = ["rating": rating, "comment": comment]
        let _: EmptyResponse = try await request(path: "/reviews/bookings/\(bookingId)", method: "POST", token: token, body: body)
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

    func sendBookingChatMessage(bookingId: String, message: String, token: String) async throws -> ChatMessage {
        let clientMessageId = "IOSUSER\(Int(Date().timeIntervalSince1970 * 1000))"
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

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        token: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.missingToken
        }

        var lastError: Error?
        let ordered = [activeBaseURL] + baseURLs.filter { $0 != activeBaseURL }
        for baseURL in ordered {
            do {
                let value: T = try await execute(baseURL: baseURL, path: path, method: method, token: token, body: body)
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
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse("Backend response invalid.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse(httpError(code: http.statusCode, data: data))
        }
        if data.isEmpty {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            throw APIError.badResponse("Backend returned empty response.")
        }
        return try JSONDecoder().decode(T.self, from: data)
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
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = object["message"] as? String,
           !message.isEmpty {
            return "HTTP \(code): \(message)"
        }
        switch code {
        case 401, 403: return "Authentication expired. Please login again."
        case 404: return "Requested booking was not found."
        case 408, 425, 429: return "Server is busy. Please retry in a moment."
        case 500...599: return "Server temporarily unavailable."
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
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}

final class AppNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private(set) var fcmToken = ""

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        #if canImport(FirebaseMessaging)
        fcmToken = Messaging.messaging().fcmToken ?? ""
        #endif
    }

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var lastCoordinate = CLLocationCoordinate2D(
        latitude: AppConfig.defaultLatitude,
        longitude: AppConfig.defaultLongitude
    )

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    func currentCoordinate() async -> CLLocationCoordinate2D {
        lastCoordinate
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.last?.coordinate {
            lastCoordinate = coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastCoordinate = CLLocationCoordinate2D(
            latitude: AppConfig.defaultLatitude,
            longitude: AppConfig.defaultLongitude
        )
    }
}
