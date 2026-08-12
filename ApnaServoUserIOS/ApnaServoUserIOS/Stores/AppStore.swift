import Foundation
import CoreLocation
import SwiftUI
import UIKit

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
    @Published var notifications: [AppNotificationItem] = []
    @Published var toastMessage = ""
    @Published var showLoginSheet = false
    @Published var loginMode = "Phone"
    @Published var showSettingsSheet = false
    @Published var showEditProfileSheet = false
    @Published var showLegalSheet = false
    @Published var isAuthenticating = false
    @Published var isDeletingAccount = false
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
    private var bookingRequestID = ""
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
    private let submittedRatingsKey = "apnaservo_user_submitted_ratings"

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
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            toastMessage = "Enter your full name."
            return
        }
        if loginMode == "Email" {
            guard cleanValue.contains("@"), cleanValue.contains(".") else {
                toastMessage = "Enter a valid email address."
                return
            }
        } else {
            guard cleanValue.filter(\.isNumber).count >= 10 else {
                toastMessage = "Enter a valid mobile number."
                return
            }
        }
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task {
            do {
                let token = try await firebaseSessionToken()
                secureStore.set(token, for: tokenKey)
                authToken = token
                profile.name = cleanName
                if loginMode == "Email" {
                    profile.email = cleanValue
                } else {
                    profile.phone = cleanValue.filter(\.isNumber)
                }
                showLoginSheet = false
                startupLocationPhase = .idle
                startupManualAddress = ""
                isStartupManualEntry = false
                navigate(.startupLocation, remember: false)
                _ = await notificationService.requestPermission()
                await syncUserProfile()
                await refreshBookings()
                await openPendingNotificationDeepLinkIfNeeded()
            } catch {
                toastMessage = error.localizedDescription
            }
            isAuthenticating = false
        }
    }

    func requestAccountDeletion(reason: String) async -> Bool {
        guard !isDeletingAccount else { return false }
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await api.requestAccountDeletion(
                reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
                token: apiToken
            )
#if canImport(FirebaseAuth)
            try await Auth.auth().currentUser?.delete()
#endif
            logout()
            return true
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }

    private func firebaseSessionToken() async throws -> String {
        #if canImport(FirebaseAuth)
        if let current = Auth.auth().currentUser {
            return try await current.getIDToken()
        }
        let result = try await Auth.auth().signInAnonymously()
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
            let address = await locationService.address(for: coordinate)
            profile.address = address
            profile.lat = point.latitude
            profile.lng = point.longitude
            startupLocationPhase = .detected
            Task { await syncUserProfile() }
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
        case .failure(let message):
            startupLocationPhase = .failure
            toastMessage = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? StartupLocationPhase.failure.message
                : message
        }
    }

    private func completeStartupLocationGate() {
        navigate(.home, remember: false)
        Task { await openPendingNotificationDeepLinkIfNeeded() }
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
        bookingLocationTask?.cancel()
        bookingLocationTask = nil
        locationService.cancelCurrentRequest()
        selectedService = service
        if Self.preparingServiceIDs.contains(service.id) {
            navigate(.preparing)
            return
        }
        bookingRequestID = "IOS-\(UUID().uuidString)"
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
            toastMessage = "Your session expired. Please sign in again before booking."
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
            } catch {
                toastMessage = "Booking was not confirmed. Check your connection and tap Confirm Booking again."
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
                let live = try await api.updateBookingStatus(booking.id, status: "cancelled", finalAmount: 0, token: apiToken)
                latestBooking = live
                upsertBooking(live)
                stopBookingPolling()
                navigate(.bookings, remember: false)
                toastMessage = "Booking cancelled successfully."
            } catch {
                toastMessage = "Booking cancellation failed. Please retry."
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
        guard ["pending", "accepted", "on_the_way", "arrived"].contains(booking.status) else {
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
        guard let booking = latestBooking else { return }
        do {
            bookingChatMessages = try await api.fetchBookingChatMessages(bookingId: booking.id, token: apiToken)
            await api.markBookingChatSeen(bookingId: booking.id, token: apiToken)
        } catch {
            toastMessage = "Chat could not be refreshed."
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
        Task { await api.markNotificationRead(item.id, token: apiToken) }
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
        selectedService = ServiceCatalog.service(id: serviceId)
        navigate(.preparing)
    }

    private static let preparingServiceIDs: Set<String> = [
        "roadside", "painting", "interior", "ro", "pest"
    ]

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
        submittedRatings = [:]
        defaults.removeObject(forKey: submittedRatingsKey)
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
            _ = await notificationService.requestPermission()
            let fcmToken = await notificationService.refreshFCMToken()
            if isLoggedIn, !fcmToken.isEmpty {
                try? await api.saveFCMToken(fcmToken, token: apiToken)
            }
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
