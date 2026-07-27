import Foundation
import SwiftUI
import UIKit

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
    @Published var savedAddresses: [SavedAddress] = [
        SavedAddress(title: "Home", detail: "House 12, Ganeshguri, Guwahati, Assam 781006"),
        SavedAddress(title: "Work", detail: "Dispur, Guwahati, Assam")
    ]
    @Published var toastMessage = ""
    @Published var showLoginSheet = false
    @Published var loginMode = "Phone"
    @Published var showDateSheet = false
    @Published var showTimeSheet = false
    @Published var showSettingsSheet = false
    @Published var showEditProfileSheet = false
    @Published var showLegalSheet = false
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
    @Published var shouldFocusServiceSearch = false
    @Published var selectedCommercialServiceTitle = "Commercial AC Service"
    @Published var selectedCommercialServiceId = "ac"
    @Published var selectedCleaningType = "Home Cleaning"
    @Published var selectedLaundryServiceType = "Wash & Fold"
    @Published var selectedLaundryItems: [String: Int] = [:]

    let services = ServiceCatalog.services
    let categories = ServiceCatalog.categories
    let cleaningTypes = ["Home Cleaning", "Deep Cleaning", "Bathroom Cleaning", "Room Cleaning"]
    let laundryServiceTypes = ["Wash & Fold", "Dry Cleaning", "Ironing", "Wash & Iron"]
    let laundryItems = [
        "T-Shirts", "Shirts", "Lowers / Track Pants", "Jeans", "Bed Sheet",
        "Blanket", "Pillow Cover", "Curtain", "Towel", "Saree",
        "Suit / Kurta", "Jacket", "Shoes", "Others"
    ]
    private let api = APIClient()
    private let notificationService = AppNotificationService()
    private lazy var locationService = LocationService()
    private let secureStore = SecureStore()
    private let tokenKey = "firebase_id_token"
    private var bookingSyncTask: Task<Void, Never>?

    init() {
        notificationService.configure()
        authToken = secureStore.string(for: tokenKey)
    }

    var isLoggedIn: Bool {
        !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredServices: [ServiceItem] {
        services.filter { $0.category == activeCategory }
    }

    var activeBookings: [Booking] {
        bookings.filter { !["completed", "cancelled", "rejected"].contains($0.progressStatus) }
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
            _ = await notificationService.requestPermission()
            await syncUserProfile()
            await loadLiveBookings()
        }
        startLiveBookingSync()
    }

    func finishLocationGate() {
        profile.lat = AppConfig.defaultLatitude
        profile.lng = AppConfig.defaultLongitude
        navigate(.home, remember: false)
        Task {
            await syncUserProfile()
            await loadLiveBookings()
        }
        startLiveBookingSync()
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

    func openServiceSearch() {
        shouldFocusServiceSearch = true
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
        selectedCleaningType = "Home Cleaning"
        selectedLaundryServiceType = "Wash & Fold"
        selectedLaundryItems = [:]
        navigate(.booking)
    }

    func useCurrentLocation() {
        addressMode = .current
        draft.address = "Ganeshguri, Guwahati, Assam 781006"
        draft.hasLocation = true
        toastMessage = "Current location detected."
        Task {
            let coordinate = await locationService.currentCoordinate()
            draft.lat = coordinate.latitude
            draft.lng = coordinate.longitude
            profile.lat = coordinate.latitude
            profile.lng = coordinate.longitude
        }
    }

    func useManualAddress() {
        addressMode = .manual
        draft.address = ""
        draft.hasLocation = false
    }

    func chooseDate(_ value: String) {
        draft.date = value
        if !draft.time.isEmpty && !isTimeSlotAvailable(draft.time) {
            draft.time = ""
            toastMessage = "Past time slots are closed for today."
        }
        showDateSheet = false
    }

    func chooseTime(_ value: String) {
        guard isTimeSlotAvailable(value) else {
            toastMessage = "This time slot is no longer available."
            return
        }
        draft.time = value
        showTimeSheet = false
    }

    func isTimeSlotAvailable(_ slot: String) -> Bool {
        guard draft.date.hasPrefix("Today") else { return true }
        guard let slotStart = Self.slotStartMinutes(slot) else { return true }
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return slotStart > nowMinutes
    }

    func continueToConfirm() {
        if selectedService.id == "laundry" && selectedLaundryItems.isEmpty {
            toastMessage = "Please select at least one laundry item."
            return
        }
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
        if selectedService.id == "cleaning" {
            return instructions.isEmpty
                ? selectedCleaningType
                : "\(selectedCleaningType) | Instructions: \(instructions)"
        }
        if selectedService.id == "laundry" {
            let items = laundryItems.compactMap { item -> String? in
                guard let quantity = selectedLaundryItems[item], quantity > 0 else { return nil }
                return "\(item) x\(quantity)"
            }.joined(separator: ", ")
            let base = "\(selectedLaundryServiceType) | Items: \(items)"
            return instructions.isEmpty ? base : "\(base) | Instructions: \(instructions)"
        }
        return instructions
    }

    func confirmBooking() {
        let bookingCode = makeBookingCode()
        let requestDetails = bookingRequestDetails()
        var backendDraft = draft
        backendDraft.problem = requestDetails
        backendDraft.address = bookingAddressPreview()
        let issue = requestDetails.isEmpty
            ? "Service request - \(selectedService.name)"
            : "Service request - \(requestDetails)"
        let booking = Booking(
            id: bookingCode,
            bookingCode: bookingCode,
            serviceCategory: selectedService.id,
            serviceName: selectedService.name,
            issue: issue,
            address: bookingAddressPreview(),
            slot: "\(draft.date), \(draft.time)",
            status: "pending",
            partnerName: "",
            partnerPhone: "",
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
            await submitBookingToBackend(service: selectedService, draft: backendDraft, profile: profile, bookingCode: bookingCode, fallbackId: booking.id)
            startLiveBookingSync()
        }
    }

    func openTrack(_ booking: Booking? = nil) {
        if let booking {
            latestBooking = booking
        }
        navigate(.track)
    }

    func approveAmount() {
        guard let booking = latestBooking else { return }
        guard booking.amount > 0 else {
            toastMessage = "Final amount has not been shared yet."
            return
        }
        Task {
            do {
                let updated = try await api.submitDirectPayment(
                    booking.id,
                    finalAmount: booking.amount,
                    token: authToken
                )
                latestBooking = updated
                upsertBooking(updated)
                toastMessage = updated.progressStatus == "completed"
                    ? "Payment confirmed and booking completed."
                    : "Payment submitted. Waiting for partner verification."
                await refreshLiveBookings()
            } catch {
                toastMessage = "Payment could not be submitted. Please try again."
            }
        }
    }

    func requestCancellation(_ booking: Booking) {
        guard ["pending", "accepted", "on_the_way", "arrived"].contains(booking.progressStatus) else {
            toastMessage = "Booking cannot be cancelled after work starts."
            return
        }
        latestBooking = booking
        cancelReason = ""
        showCancelSheet = true
    }

    func cancelLatestBooking() {
        guard let booking = latestBooking else { return }
        let reason = cancelReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard reason.count >= 3 else {
            toastMessage = "Please enter a cancellation reason."
            return
        }
        showCancelSheet = false
        Task {
            do {
                let updated = try await api.updateBookingStatus(
                    booking.id,
                    status: "cancelled",
                    finalAmount: booking.amount,
                    token: authToken
                )
                latestBooking = updated
                upsertBooking(updated)
                toastMessage = "Booking cancelled."
                await refreshLiveBookings()
            } catch {
                toastMessage = error.localizedDescription
            }
        }
    }

    func requestCounterOffer(_ booking: Booking) {
        guard booking.progressStatus == "amount_pending", booking.quoteStatus == "pending" else {
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
                    token: authToken
                )
                latestBooking = updated
                upsertBooking(updated)
                toastMessage = "Counter offer sent to the partner."
                await refreshLiveBookings()
            } catch {
                toastMessage = error.localizedDescription
            }
        }
    }

    func requestReview(_ booking: Booking) {
        guard booking.progressStatus == "completed" else {
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
                    token: authToken
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
        Task { await refreshBookingChat() }
    }

    func callPartner(_ booking: Booking) {
        let digits = booking.partnerPhone.filter(\.isNumber)
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else {
            toastMessage = "Partner phone is not available yet."
            return
        }
        Task {
            await api.createCallLog(bookingId: booking.id, action: "start", token: authToken)
        }
        UIApplication.shared.open(url)
    }

    func sendBookingChat(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let booking = latestBooking, !clean.isEmpty else { return }
        let local = ChatMessage.local(text: clean, booking: booking)
        bookingChatMessages.append(local)
        Task {
            do {
                let sent = try await api.sendBookingChatMessage(bookingId: booking.id, message: clean, token: authToken)
                if let index = bookingChatMessages.firstIndex(where: { $0.id == local.id }) {
                    bookingChatMessages[index] = sent
                } else {
                    bookingChatMessages.append(sent)
                }
                await api.monitorBookingChat(bookingId: booking.id, message: clean, clientMessageId: sent.clientMessageId, token: authToken)
            } catch {
                if let index = bookingChatMessages.firstIndex(where: { $0.id == local.id }) {
                    bookingChatMessages[index].deliveryStatus = "retry"
                }
            }
        }
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
        Task {
            await api.markNotificationRead(item.id, token: authToken)
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
            await api.markAllNotificationsRead(unreadIds, token: authToken)
        }
    }

    func openCommercialService(_ title: String, serviceId: String) {
        selectedCommercialServiceTitle = title
        selectedCommercialServiceId = serviceId
        navigate(.commercialFormOne)
    }

    func logout() {
        stopLiveBookingSync()
        profile = UserProfile()
        latestBooking = nil
        bookings = []
        previousScreens = []
        authToken = ""
        secureStore.set("", for: tokenKey)
        screen = .login
    }

    func setFirebaseIDToken(_ token: String) {
        authToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        secureStore.set(authToken, for: tokenKey)
    }

    func addSavedAddressFromCurrentProfile() {
        addSavedAddress(title: savedAddresses.isEmpty ? "Home" : "Address \(savedAddresses.count + 1)", detail: currentAddressForSaving())
    }

    func addSavedAddress(title: String, detail: String) {
        guard savedAddresses.count < 3 else {
            toastMessage = "You can save up to 3 addresses."
            return
        }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanDetail.count >= 8 else {
            toastMessage = "Add a complete address before saving."
            return
        }
        savedAddresses.append(SavedAddress(title: cleanTitle.isEmpty ? "Address \(savedAddresses.count + 1)" : cleanTitle, detail: cleanDetail))
        toastMessage = "Address saved."
    }

    func deleteSavedAddress(_ address: SavedAddress) {
        savedAddresses.removeAll { $0.id == address.id }
        toastMessage = "Address deleted."
    }

    func useSavedAddress(_ address: SavedAddress) {
        addressMode = .manual
        draft.address = address.detail
        draft.hasLocation = true
        toastMessage = "\(address.title) selected."
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

    private func currentAddressForSaving() -> String {
        let draftAddress = bookingAddressPreview()
        if draftAddress.count >= 8 && !draftAddress.lowercased().contains("location will") {
            return draftAddress
        }
        if !profile.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return profile.address.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Guwahati, Assam"
    }

    func startLiveBookingSync() {
        guard isLoggedIn else { return }
        bookingSyncTask?.cancel()
        bookingSyncTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshLiveBookings()
                try? await Task.sleep(nanoseconds: AppConfig.bookingStatusRefreshSeconds)
            }
        }
    }

    func stopLiveBookingSync() {
        bookingSyncTask?.cancel()
        bookingSyncTask = nil
    }

    func refreshLiveBookings() async {
        await loadLiveBookings()
        await loadNotifications()
    }

    func refreshBookingChat() async {
        guard let booking = latestBooking else { return }
        do {
            let messages = try await api.fetchBookingChatMessages(bookingId: booking.id, token: authToken)
            let pendingLocalMessages = bookingChatMessages.filter { message in
                message.bookingId == booking.id && ["queued", "retry"].contains(message.deliveryStatus)
            }
            let backendClientIds = Set(messages.map(\.clientMessageId).filter { !$0.isEmpty })
            let mergedPending = pendingLocalMessages.filter { message in
                message.clientMessageId.isEmpty || !backendClientIds.contains(message.clientMessageId)
            }
            bookingChatMessages = (messages + mergedPending).sorted { $0.createdAtMillis < $1.createdAtMillis }
            await api.markBookingChatSeen(bookingId: booking.id, token: authToken)
        } catch {
            // Keep queued/local messages visible if the network is temporarily unavailable.
        }
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

    private func makeBookingCode() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
        return "AS\(timestamp)\(random)"
    }

    private func syncUserProfile() async {
        do {
            try await api.upsertUserProfile(profile, fcmToken: notificationService.fcmToken, token: authToken)
        } catch {
            await MainActor.run {
                toastMessage = "Profile will sync when connection is restored."
            }
        }
    }

    private func loadLiveBookings() async {
        do {
            let liveBookings = try await api.fetchUserBookings(token: authToken)
            if !liveBookings.isEmpty {
                await MainActor.run {
                    let selected = latestBooking
                    bookings = liveBookings
                    if let selected,
                       let updated = liveBookings.first(where: { $0.id == selected.id || (!selected.bookingCode.isEmpty && $0.bookingCode == selected.bookingCode) }) {
                        latestBooking = updated
                    } else {
                        latestBooking = liveBookings.first(where: { !["completed", "cancelled", "rejected"].contains($0.progressStatus) }) ?? liveBookings.first
                    }
                }
            }
        } catch {
            // Keep local bookings visible if the backend is temporarily unavailable.
        }
    }

    private func loadNotifications() async {
        do {
            notifications = try await api.fetchNotifications(token: authToken)
        } catch {
            // Keep the last notification snapshot while offline.
        }
    }

    private func submitBookingToBackend(service: ServiceItem, draft: BookingDraft, profile: UserProfile, bookingCode: String, fallbackId: String) async {
        do {
            let liveBooking = try await api.createBooking(
                service: service,
                draft: draft,
                profile: profile,
                bookingCode: bookingCode,
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
            }
            await refreshLiveBookings()
        } catch {
            await MainActor.run {
                bookings.removeAll { $0.id == fallbackId || $0.bookingCode == bookingCode }
                if latestBooking?.id == fallbackId || latestBooking?.bookingCode == bookingCode {
                    latestBooking = bookings.first
                }
                navigate(.confirm)
                toastMessage = "Booking could not be created. Please check network and try again."
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

    private static func slotStartMinutes(_ slot: String) -> Int? {
        let startText = slot.components(separatedBy: " - ").first ?? slot
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"
        guard let date = formatter.date(from: startText) else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
