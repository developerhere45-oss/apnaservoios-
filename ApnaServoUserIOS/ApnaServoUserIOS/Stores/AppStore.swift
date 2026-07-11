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
    @Published var isBookingSubmitting = false
    @Published var selectedCommercialServiceTitle = "Commercial AC Service"
    @Published var selectedCommercialServiceId = "ac"

    let services = ServiceCatalog.services
    let categories = ServiceCatalog.categories
    private let api = APIClient()
    private let secureStore = SecureStore()
    private let notificationService = AppNotificationService()
    private var bookingPollingTask: Task<Void, Never>?

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
            await refreshBookings()
        }
    }

    func finishLocationGate() {
        profile.lat = AppConfig.defaultLatitude
        profile.lng = AppConfig.defaultLongitude
        navigate(.home, remember: false)
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
        guard !isBookingSubmitting else { return }
        isBookingSubmitting = true
        let issue = draft.problem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Service request - \(selectedService.name)"
            : "Service request - \(draft.problem)"
        var networkDraft = draft
        networkDraft.problem = issue
        networkDraft.address = bookingAddressPreview()
        let booking = Booking(
            id: "AS\(Int(Date().timeIntervalSince1970))",
            bookingCode: "AS\(Int(Date().timeIntervalSince1970) % 100000)",
            serviceCategory: selectedService.id,
            serviceName: selectedService.name,
            issue: issue,
            address: networkDraft.address,
            slot: networkDraft.slot,
            status: "pending",
            partnerName: "",
            partnerPhone: "",
            customerName: profile.name.isEmpty ? "ApnaServo Customer" : profile.name,
            userPhone: profile.phone,
            defaultAmount: selectedService.price,
            lat: networkDraft.lat,
            lng: networkDraft.lng
        )
        latestBooking = booking
        upsertBooking(booking)
        addNotification(title: "Booking confirmed", body: "\(booking.serviceName) request \(booking.displayId) is confirmed.", type: "booking", bookingId: booking.id)
        bookingChatMessages = [
            ChatMessage(id: "system-chat", bookingId: booking.id, bookingCode: booking.bookingCode, senderRole: "system", senderName: "ApnaServo", message: "Chat will be available after a partner is assigned.", clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
        ]
        navigate(.bookingConfirmed)
        let service = selectedService
        let customer = profile
        Task {
            do {
                let liveBooking = try await api.createBooking(
                    service: service,
                    draft: networkDraft,
                    profile: customer,
                    fcmToken: notificationService.fcmToken,
                    token: apiToken
                )
                latestBooking = liveBooking
                upsertBooking(liveBooking)
                addNotification(title: "Booking sent", body: "\(liveBooking.displayId) is now live for nearby partners.", type: "booking", bookingId: liveBooking.id)
                startBookingPolling()
            } catch {
                toastMessage = "Booking could not reach the live backend. Please retry from booking status."
            }
            isBookingSubmitting = false
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
        startBookingPolling()
        navigate(.track)
    }

    func advanceBookingStatus() {
        guard var booking = latestBooking else { return }
        let flow = ["accepted", "on_the_way", "arrived", "started", "amount_pending", "completed"]
        let currentIndex = flow.firstIndex(of: booking.status) ?? 0
        let next = flow[min(currentIndex + 1, flow.count - 1)]
        booking.status = next
        if next == "amount_pending" {
            booking.finalAmount = max(booking.defaultAmount, 699)
            booking.quoteStatus = "pending_customer"
        }
        latestBooking = booking
        upsertBooking(booking)
    }

    func approveAmount() {
        guard var booking = latestBooking else { return }
        booking.quoteStatus = "payment_submitted"
        latestBooking = booking
        upsertBooking(booking)
        toastMessage = "Payment sent for partner verification."
        Task {
            do {
                let live = try await api.submitDirectPayment(bookingId: booking.id, token: apiToken)
                latestBooking = live
                upsertBooking(live)
            } catch {
                toastMessage = "Payment update could not be sent. Please try again."
            }
        }
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
        stopBookingPolling()
        profile = UserProfile()
        latestBooking = nil
        bookings = []
        previousScreens = []
        screen = .login
    }

    func configureAppServices() {
        notificationService.configure()
        Task {
            _ = await notificationService.requestPermission()
        }
    }

    func refreshBookings() async {
        do {
            let liveBookings = try await api.fetchUserBookings(token: apiToken)
            bookings = liveBookings
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
        guard let booking = latestBooking else { return }
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
                try? await Task.sleep(nanoseconds: AppConfig.bookingStatusRefreshSeconds)
            }
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

    private var apiToken: String {
        let saved = secureStore.string(for: "user_api_token")
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
