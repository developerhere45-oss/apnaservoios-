import Foundation

enum UserScreen: String, CaseIterable {
    case splash
    case login
    case startupLocation
    case home
    case services
    case detail
    case booking
    case confirm
    case bookingConfirmed
    case track
    case bookings
    case notifications
    case profile
    case support
    case bookingChat
    case commercial
    case commercialFormOne
    case commercialFormTwo
    case commercialSubmitted
    case commercialInspection
    case commercialQuote
    case commercialApproved
    case commercialTeam
    case commercialPlan
    case commercialProgress
    case commercialCompleted
}

enum BookingAddressMode: String, CaseIterable, Identifiable {
    case current = "current"
    case manual = "manual"

    var id: String { rawValue }
}

enum ServiceTier: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case premier = "Premier"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .normal: return "Standard partner assignment"
        case .premier: return "Priority slot with top-rated partner"
        }
    }
}

struct ServiceItem: Identifiable, Hashable, Codable {
    let id: String
    let shortCode: String
    let name: String
    let category: String
    let description: String
    let price: Int
    let arrival: String
    let rating: String

    var priceLabel: String {
        price > 0 ? "Rs \(price)" : "Quote"
    }
}

enum ServiceCatalog {
    static let categories = ["Home Repair", "Roadside Help", "Cleaning & Care", "Appliances", "Others"]

    static let services: [ServiceItem] = [
        ServiceItem(id: "ac", shortCode: "AC", name: "AC Repair & Service", category: "Home Repair", description: "AC inspection, cleaning, gas refilling, performance check, and repair replacement.", price: 499, arrival: "Same day", rating: "4.7"),
        ServiceItem(id: "electrician", shortCode: "EL", name: "Electrician", category: "Home Repair", description: "Switchboard, wiring, fan, MCB, socket, inverter, and urgent electrical repair.", price: 299, arrival: "45 min", rating: "4.8"),
        ServiceItem(id: "plumbing", shortCode: "PL", name: "Plumber", category: "Home Repair", description: "Tap, sink, flush tank, blocked drain, water motor, leakage, and pipe repair.", price: 299, arrival: "45 min", rating: "4.7"),
        ServiceItem(id: "carpenter", shortCode: "CR", name: "Carpenter", category: "Home Repair", description: "Door, lock, curtain rod, furniture assembly, wall shelf, and cabinet fixes.", price: 299, arrival: "Same day", rating: "4.8"),
        ServiceItem(id: "painting", shortCode: "PT", name: "Painting", category: "Home Repair", description: "Wall painting, touch-ups, damp patch repair, rental move-out paint, and finish work.", price: 399, arrival: "Scheduled", rating: "4.6"),
        ServiceItem(id: "interior", shortCode: "IN", name: "Interior Design", category: "Others", description: "Consultation for room planning, furniture placement, lighting, and home styling.", price: 0, arrival: "Consultation", rating: "4.9"),
        ServiceItem(id: "roadside", shortCode: "RS", name: "Roadside Assistance", category: "Roadside Help", description: "Emergency roadside help, jump-start support, towing coordination, and tyre help.", price: 0, arrival: "24/7", rating: "4.6"),
        ServiceItem(id: "cleaning", shortCode: "CL", name: "Cleaning Services", category: "Cleaning & Care", description: "Home and office cleaning, bathroom cleaning, sofa cleaning, and deep cleaning.", price: 599, arrival: "Scheduled", rating: "4.7"),
        ServiceItem(id: "laundry", shortCode: "LD", name: "Laundry", category: "Cleaning & Care", description: "Clothes washing, ironing, dry cleaning pickup, stain care, and doorstep laundry service.", price: 199, arrival: "Scheduled", rating: "4.6"),
        ServiceItem(id: "pest", shortCode: "PC", name: "Pest Control", category: "Cleaning & Care", description: "Safe pest treatment for home, kitchen, bathroom, and office spaces.", price: 499, arrival: "Safe", rating: "4.6"),
        ServiceItem(id: "appliances", shortCode: "AP", name: "Appliances", category: "Appliances", description: "Washing machine, refrigerator, microwave, RO, chimney, and geyser inspection.", price: 399, arrival: "Same day", rating: "4.7"),
        ServiceItem(id: "ro", shortCode: "RO", name: "RO Service", category: "Appliances", description: "RO water purifier inspection, filter change, leakage repair, servicing, and installation.", price: 299, arrival: "Same day", rating: "4.7")
    ]

    static func service(id: String) -> ServiceItem {
        services.first { $0.id == id } ?? services[0]
    }
}

struct UserProfile: Codable, Hashable {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    var lat: Double = AppConfig.defaultLatitude
    var lng: Double = AppConfig.defaultLongitude

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phone.filter(\.isNumber).count == 10
    }
}

struct BookingDraft: Hashable {
    var problem = ""
    var address = ""
    var date = "Today"
    var time = "06:00 PM - 08:00 PM"
    var tier: ServiceTier = .normal
    var lat = AppConfig.defaultLatitude
    var lng = AppConfig.defaultLongitude
    var hasLocation = false

    var slot: String { "\(date), \(time)" }
}

struct Booking: Identifiable, Codable, Hashable {
    var id: String
    var bookingCode: String
    var serviceCategory: String
    var serviceName: String
    var issue: String
    var address: String
    var city: String
    var slot: String
    var status: String
    var partnerId: String
    var partnerName: String
    var partnerPhone: String
    var customerName: String
    var userPhone: String
    var defaultAmount: Int
    var finalAmount: Int
    var quoteStatus: String
    var quoteCounterAmount: Int
    var quoteCounterMessage: String
    var quoteExpiresAtMillis: Int64
    var lat: Double
    var lng: Double
    var createdAtMillis: Int64

    var displayId: String { bookingCode.isEmpty ? id : bookingCode }
    var amount: Int { finalAmount > 0 ? finalAmount : defaultAmount }

    var isAssigned: Bool {
        ["accepted", "on_the_way", "arrived", "started", "amount_pending", "completed"].contains(status)
    }

    var isAmountApprovalPending: Bool {
        status == "amount_pending" || quoteStatus == "pending_customer"
    }

    var statusTitle: String {
        switch status {
        case "pending": return "Finding Partner"
        case "accepted": return "Partner Assigned"
        case "on_the_way": return "Partner On The Way"
        case "arrived": return "Partner Arrived"
        case "started": return "Work in Progress"
        case "amount_pending": return quoteStatus == "payment_submitted" ? "Payment Verification" : "Service Completed"
        case "completed": return "Service Completed"
        case "cancelled": return "Cancelled"
        case "rejected": return "Rejected"
        default: return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var timeline: [String] {
        ["pending", "accepted", "on_the_way", "arrived", "started", "completed"]
    }

    var canCustomerCancel: Bool {
        ["pending", "accepted"].contains(status)
    }

    var isWaitingForPaymentVerification: Bool {
        status == "amount_pending" && quoteStatus == "payment_submitted"
    }

    init(
        id: String,
        bookingCode: String = "",
        serviceCategory: String,
        serviceName: String,
        issue: String,
        address: String,
        city: String = AppConfig.defaultCity,
        slot: String,
        status: String = "pending",
        partnerId: String = "",
        partnerName: String = "ApnaServo Partner",
        partnerPhone: String = "",
        customerName: String,
        userPhone: String,
        defaultAmount: Int = 0,
        finalAmount: Int = 0,
        quoteStatus: String = "none",
        quoteCounterAmount: Int = 0,
        quoteCounterMessage: String = "",
        quoteExpiresAtMillis: Int64 = 0,
        lat: Double = AppConfig.defaultLatitude,
        lng: Double = AppConfig.defaultLongitude,
        createdAtMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.bookingCode = bookingCode
        self.serviceCategory = serviceCategory
        self.serviceName = serviceName
        self.issue = issue
        self.address = address
        self.city = city
        self.slot = slot
        self.status = Self.normalizedStatus(status)
        self.partnerId = partnerId
        self.partnerName = partnerName
        self.partnerPhone = partnerPhone
        self.customerName = customerName
        self.userPhone = userPhone
        self.defaultAmount = defaultAmount
        self.finalAmount = finalAmount
        self.quoteStatus = quoteStatus
        self.quoteCounterAmount = quoteCounterAmount
        self.quoteCounterMessage = quoteCounterMessage
        self.quoteExpiresAtMillis = quoteExpiresAtMillis
        self.lat = lat
        self.lng = lng
        self.createdAtMillis = createdAtMillis
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicCodingKey.self)
        id = c.string("_id", "bookingId", "id", fallback: UUID().uuidString)
        bookingCode = c.string("bookingCode", "code")
        serviceCategory = c.string("serviceCategory", "serviceType", "category", fallback: "service")
        serviceName = c.string("serviceName", "service", fallback: ServiceCatalog.service(id: serviceCategory).name)
        issue = c.string("issue", "problem", "description", fallback: "Service request")
        address = c.string("address", "location", fallback: "Address pending")
        city = c.string("city", fallback: AppConfig.defaultCity)
        slot = c.string("slot", "time", fallback: "Slot pending")
        status = Self.normalizedStatus(c.string("status", fallback: "pending"))
        partnerId = c.string("partnerId", "assignedPartnerId")
        partnerName = c.string("partnerName", "assignedPartnerName", fallback: "ApnaServo Partner")
        partnerPhone = c.string("partnerPhone")
        customerName = c.string("customerName", "userName", "name", fallback: "Customer")
        userPhone = c.string("userPhone", "phone")
        defaultAmount = c.int("defaultAmount", "price")
        finalAmount = c.int("finalAmount")
        quoteStatus = c.string("quoteStatus", fallback: "none")
        quoteCounterAmount = c.int("quoteCounterAmount")
        quoteCounterMessage = c.string("quoteCounterMessage")
        quoteExpiresAtMillis = c.int64("quoteExpiresAtMillis")
        lat = c.double("lat", fallback: AppConfig.defaultLatitude)
        lng = c.double("lng", fallback: AppConfig.defaultLongitude)
        createdAtMillis = c.int64("createdAtMillis", "createdAt", fallback: Int64(Date().timeIntervalSince1970 * 1000))
    }

    private static func normalizedStatus(_ value: String) -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "searching", "sent_to_partner", "requested": return "pending"
        case "assigned", "partner_assigned": return "accepted"
        case "travelling", "partner_on_way": return "on_the_way"
        case "reached", "partner_arrived": return "arrived"
        case "in_progress", "work_started", "service_started": return "started"
        case "work_completed", "payment_pending", "quoted", "negotiating": return "amount_pending"
        case "paid", "payment_verified", "service_completed": return "completed"
        default:
            let clean = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return clean.isEmpty ? "pending" : clean
        }
    }
}

struct ChatMessage: Identifiable, Codable, Hashable {
    var id: String
    var bookingId: String
    var bookingCode: String
    var senderRole: String
    var senderName: String
    var message: String
    var clientMessageId: String
    var deliveryStatus: String
    var createdAtMillis: Int64

    static func local(text: String, booking: Booking, senderRole: String = "user") -> ChatMessage {
        ChatMessage(
            id: "local-\(UUID().uuidString)",
            bookingId: booking.id,
            bookingCode: booking.bookingCode,
            senderRole: senderRole,
            senderName: senderRole == "user" ? "You" : booking.partnerName,
            message: text,
            clientMessageId: "IOSUSER\(Int(Date().timeIntervalSince1970 * 1000))",
            deliveryStatus: "queued",
            createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
}

struct AppNotificationItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var body: String
    var type: String
    var bookingId: String
    var bookingCode: String
    var actionType: String
    var isRead: Bool
    var createdAtMillis: Int64

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicCodingKey.self)
        id = c.string("_id", "id", fallback: UUID().uuidString)
        title = c.string("title", fallback: "ApnaServo")
        body = c.string("body", "message", fallback: "Booking update received")
        type = c.string("type")
        bookingId = c.string("bookingId")
        bookingCode = c.string("bookingCode")
        actionType = c.string("actionType")
        isRead = c.bool("read", "isRead")
        createdAtMillis = c.int64("createdAtMillis", "createdAt")
    }

    init(id: String, title: String, body: String, type: String, bookingId: String, bookingCode: String = "", actionType: String = "", isRead: Bool, createdAtMillis: Int64) {
        self.id = id
        self.title = title
        self.body = body
        self.type = type
        self.bookingId = bookingId
        self.bookingCode = bookingCode
        self.actionType = actionType
        self.isRead = isRead
        self.createdAtMillis = createdAtMillis
    }
}

struct BookingEnvelope: Decodable {
    let booking: Booking?
    let bookings: [Booking]?
}

struct NotificationsEnvelope: Decodable {
    let notifications: [AppNotificationItem]?
}

struct ChatEnvelope: Decodable {
    let messages: [ChatMessage]
}

struct SendChatEnvelope: Decodable {
    let message: ChatMessage?
}

struct EmptyResponse: Decodable {}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where Key == DynamicCodingKey {
    func string(_ keys: String..., fallback: String = "") -> String {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            if let value = try? decodeIfPresent(String.self, forKey: codingKey), !value.isEmpty {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return String(value)
            }
        }
        return fallback
    }

    func int(_ keys: String..., fallback: Int = 0) -> Int {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            if let value = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return value
            }
            if let value = try? decodeIfPresent(Double.self, forKey: codingKey) {
                return Int(value)
            }
            if let value = try? decodeIfPresent(String.self, forKey: codingKey), let parsed = Int(value) {
                return parsed
            }
        }
        return fallback
    }

    func int64(_ keys: String..., fallback: Int64 = 0) -> Int64 {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            if let value = try? decodeIfPresent(Int64.self, forKey: codingKey) {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return Int64(value)
            }
            if let value = try? decodeIfPresent(String.self, forKey: codingKey), let parsed = Int64(value) {
                return parsed
            }
        }
        return fallback
    }

    func double(_ keys: String..., fallback: Double = 0) -> Double {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            if let value = try? decodeIfPresent(Double.self, forKey: codingKey) {
                return value
            }
            if let value = try? decodeIfPresent(String.self, forKey: codingKey), let parsed = Double(value) {
                return parsed
            }
        }
        return fallback
    }

    func bool(_ keys: String..., fallback: Bool = false) -> Bool {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            if let value = try? decodeIfPresent(Bool.self, forKey: codingKey) {
                return value
            }
        }
        return fallback
    }
}
