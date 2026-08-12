import Foundation

enum AppRole: String, CaseIterable, Identifiable, Codable {
    case user = "Customer"
    case partner = "Partner"

    var id: String { rawValue }
}

struct ServiceItem: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let systemImage: String
    let tintName: String
}

struct Booking: Identifiable, Codable, Hashable {
    let id: String
    let bookingCode: String
    let serviceName: String
    let serviceCategory: String
    let issue: String
    let address: String
    let city: String
    let slot: String
    let status: String
    let partnerName: String
    let customerName: String
    let finalAmount: Int

    var displayId: String { bookingCode.isEmpty ? id : bookingCode }
    var isAssigned: Bool {
        ["accepted", "on_the_way", "arrived", "started", "amount_pending", "completed"].contains(status)
    }

    var normalizedStatus: String { status.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
    var canOpenChat: Bool { isAssigned }
    var isPendingPartnerAction: Bool { ["pending", "sent_to_partner"].contains(normalizedStatus) }
    var isTerminal: Bool { ["completed", "cancelled", "rejected", "disputed"].contains(normalizedStatus) }
    var statusLabel: String { normalizedStatus.replacingOccurrences(of: "_", with: " ").capitalized }

}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let bookingId: String
    let bookingCode: String
    let senderRole: String
    let senderName: String
    let message: String
    let clientMessageId: String
    let deliveryStatus: String
    let createdAtMillis: Int64

    static func local(text: String, role: AppRole, booking: Booking) -> ChatMessage {
        ChatMessage(
            id: "local-\(UUID().uuidString)",
            bookingId: booking.id,
            bookingCode: booking.bookingCode,
            senderRole: role == .user ? "user" : "partner",
            senderName: role == .user ? "You" : booking.partnerName,
            message: text,
            clientMessageId: "IOS\(Int(Date().timeIntervalSince1970 * 1000))",
            deliveryStatus: "queued",
            createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
}

struct BookingDraft: Equatable, Identifiable {
    let service: ServiceItem
    var id: String { service.id }
    var issue = ""
    var address = ""
    var city = "Guwahati"
    var slot = ""
    var customerName = ""
    var customerPhone = ""

    var isValid: Bool {
        !issue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && address.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
            && !slot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct BookingEnvelope: Decodable {
    let booking: BookingDTO?
    let bookings: [BookingDTO]?
}

struct ActionEnvelope: Decodable {
    let booking: BookingDTO?
    let ok: Bool?
}

struct BookingDTO: Decodable {
    let id: String?
    let bookingId: String?
    let bookingCode: String?
    let serviceName: String?
    let serviceCategory: String?
    let issue: String?
    let address: String?
    let city: String?
    let slot: String?
    let status: String?
    let partnerName: String?
    let userName: String?
    let customerName: String?
    let finalAmount: Int?
    let price: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bookingId
        case bookingCode
        case serviceName
        case serviceCategory
        case issue
        case address
        case city
        case slot
        case status
        case partnerName
        case userName
        case customerName
        case finalAmount
        case price
    }

    func toBooking() -> Booking {
        Booking(
            id: id ?? bookingId ?? bookingCode ?? UUID().uuidString,
            bookingCode: bookingCode ?? "",
            serviceName: serviceName ?? "Service",
            serviceCategory: serviceCategory ?? "service",
            issue: issue ?? "Service request",
            address: address ?? "Address pending",
            city: city ?? "Guwahati",
            slot: slot ?? "Slot pending",
            status: status ?? "pending",
            partnerName: partnerName ?? "ApnaServo Partner",
            customerName: userName ?? customerName ?? "Customer",
            finalAmount: finalAmount ?? price ?? 0
        )
    }
}

struct ChatEnvelope: Decodable {
    let messages: [ChatMessage]
}

struct SendChatEnvelope: Decodable {
    let message: ChatMessage
}
