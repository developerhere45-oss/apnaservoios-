import Foundation

enum APIError: LocalizedError {
    case missingToken
    case badURL
    case invalidResponse
    case server(status: Int, message: String)
    case decoding
    case transport

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Please sign in before continuing."
        case .badURL:
            return "Backend URL invalid."
        case .invalidResponse: return "The server returned an invalid response. Please try again."
        case .server(let status, let message):
            if status == 401 { return "Your session has expired. Please sign in again." }
            if status == 403 { return message.isEmpty ? "You are not allowed to perform this action." : message }
            if status == 409 { return message.isEmpty ? "This item changed. Refresh and try again." : message }
            if status == 429 { return "Too many attempts. Please wait a moment and try again." }
            if status >= 500 { return "ApnaServo is temporarily unavailable. Please try again." }
            return message.isEmpty ? "The request could not be completed." : message
        case .decoding: return "The server response could not be read. Please update the app or try again."
        case .transport: return "Check your internet connection and try again."
        }
    }
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session { self.session = session } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 45
            configuration.waitsForConnectivity = true
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
    }

    func userBookings(token: String) async throws -> [Booking] {
        let envelope: BookingEnvelope = try await request(path: "/bookings/user", token: token)
        return (envelope.bookings ?? []).map { $0.toBooking() }
    }

    func partnerBookings(token: String) async throws -> [Booking] {
        let envelope: BookingEnvelope = try await request(path: "/bookings/partner", token: token)
        return (envelope.bookings ?? []).map { $0.toBooking() }
    }

    func createBooking(draft: BookingDraft, requestID: String, token: String) async throws -> Booking {
        let body: [String: Any] = [
            "bookingCode": requestID,
            "serviceCategory": draft.service.id,
            "serviceName": draft.service.name,
            "issue": draft.issue,
            "address": draft.address,
            "city": draft.city,
            "slot": draft.slot,
            "userName": draft.customerName,
            "userPhone": draft.customerPhone
        ]
        let envelope: BookingEnvelope = try await request(path: "/bookings", method: "POST", token: token, body: body)
        guard let booking = envelope.booking else { throw APIError.invalidResponse }
        return booking.toBooking()
    }

    func acceptBooking(_ booking: Booking, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(path: "/bookings/\(booking.id)/accept", method: "POST", token: token, body: [:])
        guard let updated = envelope.booking else { throw APIError.invalidResponse }
        return updated.toBooking()
    }

    func rejectBooking(_ booking: Booking, token: String) async throws {
        let _: ActionEnvelope = try await request(path: "/bookings/\(booking.id)/reject", method: "POST", token: token, body: [:])
    }

    func updateStatus(_ booking: Booking, status: String, token: String) async throws -> Booking {
        let envelope: BookingEnvelope = try await request(
            path: "/bookings/\(booking.id)/status",
            method: "PATCH",
            token: token,
            body: ["status": status]
        )
        guard let updated = envelope.booking else { throw APIError.invalidResponse }
        return updated.toBooking()
    }

    func chatMessages(for booking: Booking, token: String) async throws -> [ChatMessage] {
        let envelope: ChatEnvelope = try await request(path: "/bookings/\(booking.id)/chat/messages", token: token)
        return envelope.messages
    }

    func sendChat(_ text: String, clientMessageID: String, booking: Booking, token: String) async throws -> ChatMessage {
        let envelope: SendChatEnvelope = try await request(
            path: "/bookings/\(booking.id)/chat/messages",
            method: "POST",
            token: token,
            body: [
                "message": text,
                "clientMessageId": clientMessageID
            ]
        )
        return envelope.message
    }

    func markChatSeen(booking: Booking, token: String) async {
        do {
            let _: EmptyResponse = try await request(path: "/bookings/\(booking.id)/chat/seen", method: "PATCH", token: token, body: [:])
        } catch {
        }
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
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !cleanPath.isEmpty else {
            throw APIError.badURL
        }
        let url = cleanPath
            .split(separator: "/")
            .reduce(baseURL) { partialURL, component in
                partialURL.appendingPathComponent(String(component))
            }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw APIError.transport }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerError.self, from: data).message) ?? ""
            throw APIError.server(status: http.statusCode, message: message)
        }
        if T.self == EmptyResponse.self, data.isEmpty {
            guard let empty = EmptyResponse() as? T else { throw APIError.invalidResponse }
            return empty
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decoding }
    }
}

struct EmptyResponse: Decodable {}
private struct ServerError: Decodable { let message: String }
