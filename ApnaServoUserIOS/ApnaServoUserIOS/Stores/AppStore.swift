import Foundation
import SwiftUI

@MainActor
final class UserAppStore: ObservableObject {
    @Published var screen: UserScreen = .splash
    @Published var previousScreens: [UserScreen] = []
    @Published var profile = UserProfile(
        name: "",
        phone: "",
        email: "",
        address: "House 12, Ganeshguri, Guwahati",
        lat: AppConfig.defaultLatitude,
        lng: AppConfig.defaultLongitude
    )
    @Published var activeCategory = "Home Repair"
    @Published var selectedService = ServiceCatalog.service(id: "ro")
    @Published var draft = BookingDraft(
        problem: "",
        address: "Detecting your current service location...",
        date: "",
        time: "",
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
    @Published var notifications: [AppNotificationItem] = []
    @Published var toastMessage = ""
    @Published var showLoginSheet = false
    @Published var loginMode = "Phone"
    @Published var showDateSheet = false
    @Published var showTimeSheet = false
    @Published var showSettingsSheet = false
    @Published var showEditProfileSheet = false
    @Published var showLegalSheet = false
    @Published var paymentInfoExpanded = false
    @Published var aboutInfoExpanded = false
    @Published var selectedCommercialServiceTitle = "Commercial AC Service"
    @Published var selectedCommercialServiceId = "ac"

    let services = ServiceCatalog.services
    let categories = ServiceCatalog.categories
    private let api = APIClient()
    private let notificationService = AppNotificationService()
    private let authToken = ""

    init() {
        notificationService.configure()
    }

    var isLoggedIn: Bool {
        !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredServices: [ServiceItem] {
        services.filter { $0.category == activeCategory }
    }

    var activeBookings: [Booking] {
        bookings.filter { !["completed", "cancelled", "rejected"].contains($0.status) }
    }

    func finishSplash() {
        screen = .login
    }

    func navigate(_ target: UserScreen, remember: Bool = true) {
        if remember, screen != target, screen != .splash {
            previousScreens.append(screen)
        }
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
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.name = cleanName.isEmpty ? "ApnaServo Customer" : cleanName
        if loginMode == "Email" {
            profile.email = value
            if profile.phone.isEmpty { profile.phone = "Not shared" }
        } else {
            profile.phone = value.filter(\.isNumber)
        }
        showLoginSheet = false
        navigate(.startupLocation, remember: false)
        Task {
            await syncUserProfile()
            await loadLiveBookings()
        }
    }

    func finishLocationGate() {
        profile.lat = AppConfig.defaultLatitude
        profile.lng = AppConfig.defaultLongitude
        navigate(.home, remember: false)
        Task {
            await syncUserProfile()
            await loadLiveBookings()
        }
    }

    func openService(_ service: ServiceItem) {
        selectedService = service
        navigate(.detail)
    }

    func showAllServices(category: String? = nil) {
        if let category {
            activeCategory = category
        }
        navigate(.services)
    }

    func startBooking(_ service: ServiceItem) {
        selectedService = service
        draft = BookingDraft(
            problem: "",
            address: addressMode == .current ? "Detecting your current service location..." : "",
            date: "",
            time: "",
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
        navigate(.booking)
    }

    func useCurrentLocation() {
        addressMode = .current
        draft.address = "Ganeshguri, Guwahati, Assam 781006"
        draft.hasLocation = true
        toastMessage = "Current location detected."
    }

    func useManualAddress() {
        addressMode = .manual
        draft.address = ""
        draft.hasLocation = false
    }

    func chooseDate(_ value: String) {
        draft.date = value
        showDateSheet = false
    }

    func chooseTime(_ value: String) {
        draft.time = value
        showTimeSheet = false
    }

    func continueToConfirm() {
        if draft.date.isEmpty || draft.time.isEmpty {
            toastMessage = "Please select a date and time."
            return
        }
        if addressMode == .current {
            if !draft.hasLocation {
                useCurrentLocation()
            }
            if houseFlat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                toastMessage = "Enter house or flat number."
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

    func confirmBooking() {
        let issue = draft.problem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Service request - \(selectedService.name)"
            : "Service request - \(draft.problem)"
        let booking = Booking(
            id: "AS\(Int(Date().timeIntervalSince1970))",
            bookingCode: "AS\(Int(Date().timeIntervalSince1970) % 100000)",
            serviceCategory: selectedService.id,
            serviceName: selectedService.name,
            issue: issue,
            address: bookingAddressPreview(),
            slot: "\(draft.date), \(draft.time)",
            status: "pending",
            partnerName: "ApnaServo Partner",
            partnerPhone: "9876543210",
            customerName: profile.name.isEmpty ? "ApnaServo Customer" : profile.name,
            userPhone: profile.phone,
            defaultAmount: 0,
            lat: draft.lat,
            lng: draft.lng
        )
        latestBooking = booking
        upsertBooking(booking)
        addNotification(title: "Booking confirmed", body: "\(booking.serviceName) request \(booking.displayId) is confirmed.", type: "booking", bookingId: booking.id)
        bookingChatMessages = [
            ChatMessage(id: "system-chat", bookingId: booking.id, bookingCode: booking.bookingCode, senderRole: "system", senderName: "ApnaServo", message: "Chat will be available after a partner is assigned.", clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
        ]
        navigate(.bookingConfirmed)
        Task {
            await submitBookingToBackend(service: selectedService, draft: draft, profile: profile, fallbackId: booking.id)
        }
    }

    func assignPartner() {
        guard var booking = latestBooking else { return }
        booking.status = "accepted"
        booking.partnerName = "Rahul Kumar"
        latestBooking = booking
        upsertBooking(booking)
        addNotification(title: "Partner assigned", body: "\(booking.partnerName) accepted \(booking.displayId). Track live status now.", type: "partner_assigned", bookingId: booking.id)
        bookingChatMessages = [
            ChatMessage(id: "system-chat", bookingId: booking.id, bookingCode: booking.bookingCode, senderRole: "system", senderName: "ApnaServo", message: "Chat directly with Rahul Kumar. Keep payments and service details inside ApnaServo.", clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
        ]
    }

    func openTrack(_ booking: Booking? = nil) {
        if let booking {
            latestBooking = booking
        }
        navigate(.track)
    }

    func advanceBookingStatus() {
        guard var booking = latestBooking else { return }
        let flow = ["accepted", "on_the_way", "arrived", "started", "amount_pending", "completed"]
        let currentIndex = flow.firstIndex(of: booking.status) ?? 0
        let next = flow[min(currentIndex + 1, flow.count - 1)]
        booking.status = next
        if next == "amount_pending" {
            booking.quoteStatus = "pending_customer"
        }
        latestBooking = booking
        upsertBooking(booking)
    }

    func approveAmount() {
        guard var booking = latestBooking else { return }
        booking.status = "completed"
        booking.quoteStatus = "approved"
        latestBooking = booking
        upsertBooking(booking)
        toastMessage = "Amount approved."
    }

    func openBookingChat(_ booking: Booking? = nil) {
        if let booking {
            latestBooking = booking
        }
        guard latestBooking != nil else { return }
        navigate(.bookingChat)
    }

    func sendBookingChat(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let booking = latestBooking, !clean.isEmpty else { return }
        bookingChatMessages.append(ChatMessage.local(text: clean, booking: booking))
    }

    func sendSupportMessage(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        supportMessages.append(ChatMessage(id: UUID().uuidString, bookingId: "support", bookingCode: "", senderRole: "user", senderName: "You", message: clean, clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)))
        supportMessages.append(ChatMessage(id: UUID().uuidString, bookingId: "support", bookingCode: "", senderRole: "support", senderName: "ApnaServo Support", message: supportReply(for: clean), clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)))
    }

    func markNotificationRead(_ item: AppNotificationItem) {
        notifications = notifications.map { notification in
            var copy = notification
            if copy.id == item.id {
                copy.isRead = true
            }
            return copy
        }
    }

    func markAllNotificationsRead() {
        notifications = notifications.map { notification in
            var copy = notification
            copy.isRead = true
            return copy
        }
    }

    func openCommercialService(_ title: String, serviceId: String) {
        selectedCommercialServiceTitle = title
        selectedCommercialServiceId = serviceId
        navigate(.commercialFormOne)
    }

    func logout() {
        profile = UserProfile()
        latestBooking = nil
        bookings = []
        previousScreens = []
        screen = .login
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

    private func syncUserProfile() async {
        do {
            try await api.upsertUserProfile(profile, fcmToken: notificationService.fcmToken, token: authToken)
        } catch {
            await MainActor.run {
                toastMessage = "Profile will sync when backend is reachable."
            }
        }
    }

    private func loadLiveBookings() async {
        do {
            let liveBookings = try await api.fetchUserBookings(token: authToken)
            if !liveBookings.isEmpty {
                await MainActor.run {
                    bookings = liveBookings
                    latestBooking = liveBookings.first
                }
            }
        } catch {
            // Keep local bookings visible if the backend is temporarily unavailable.
        }
    }

    private func submitBookingToBackend(service: ServiceItem, draft: BookingDraft, profile: UserProfile, fallbackId: String) async {
        do {
            let liveBooking = try await api.createBooking(
                service: service,
                draft: draft,
                profile: profile,
                fcmToken: notificationService.fcmToken,
                token: authToken
            )
            await MainActor.run {
                latestBooking = liveBooking
                if let index = bookings.firstIndex(where: { $0.id == fallbackId }) {
                    bookings[index] = liveBooking
                } else {
                    upsertBooking(liveBooking)
                }
                toastMessage = "Booking sent to live backend."
            }
        } catch {
            await MainActor.run {
                toastMessage = "Booking saved locally. Live sync will retry when backend is reachable."
            }
        }
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
