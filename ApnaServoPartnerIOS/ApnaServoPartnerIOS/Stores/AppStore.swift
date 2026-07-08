import Foundation
import SwiftUI
import UIKit

@MainActor
final class PartnerAppStore: ObservableObject {
    @Published var screen: PartnerScreen = .login
    @Published var profile = PartnerProfile()
    @Published var authToken = ""
    @Published var fcmToken = ""
    @Published var bookings: [PartnerBooking] = []
    @Published var selectedBooking: PartnerBooking?
    @Published var notifications: [PartnerNotificationItem] = []
    @Published var messages: [ChatMessage] = []
    @Published var supportMessages: [ChatMessage] = []
    @Published var loading = false
    @Published var errorMessage = ""
    @Published var infoMessage = ""
    @Published var supportType = "Chat"
    @Published var statementFrom = ""
    @Published var statementTo = ""
    @Published var aadhaarLast4 = ""

    private let api = APIClient()
    private let secureStore = SecureStore()
    private let notificationService = AppNotificationService()
    private let locationService = LocationService()
    private let defaults = UserDefaults.standard
    private let profileKey = "apnaservo_partner_profile"
    private let bookingsKey = "apnaservo_partner_bookings"
    private let tokenKey = "firebase_id_token"
    private var refreshTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?

    init() {
        loadLocalState()
        notificationService.configure()
    }

    var loggedIn: Bool { profile.isValid }
    var pendingBookings: [PartnerBooking] { bookings.filter(\.isPending) }
    var activeBookings: [PartnerBooking] { bookings.filter(\.isActive) }
    var completedBookings: [PartnerBooking] { bookings.filter { $0.status == "completed" } }
    var totalEarnings: Int { completedBookings.reduce(0) { $0 + $1.amount } }

    func loadLocalState() {
        if let data = defaults.data(forKey: profileKey),
           let saved = try? JSONDecoder().decode(PartnerProfile.self, from: data) {
            profile = saved
            screen = saved.isValid ? .dashboard : .login
        }
        if let data = defaults.data(forKey: bookingsKey),
           let saved = try? JSONDecoder().decode([PartnerBooking].self, from: data) {
            bookings = saved
        }
        authToken = secureStore.string(for: tokenKey)
        fcmToken = defaults.string(forKey: "partner_fcm_token") ?? ""
        supportMessages = [
            ChatMessage(id: "support-welcome", bookingId: "support", bookingCode: "", senderRole: "support", senderName: "Partner Support", message: "Welcome to partner support. How can we help?", clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
        ]
        if profile.isValid {
            startRealtimePolling()
            startLocationHeartbeat()
        }
    }

    func persistProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: profileKey)
        }
    }

    func persistBookings() {
        if let data = try? JSONEncoder().encode(bookings) {
            defaults.set(data, forKey: bookingsKey)
        }
    }

    func saveAuthToken() {
        secureStore.set(authToken.trimmingCharacters(in: .whitespacesAndNewlines), for: tokenKey)
        infoMessage = "Backend token saved."
    }

    func completeLogin() {
        guard profile.isValid else {
            errorMessage = "Enter your name, a valid 10-digit phone number, and at least one service."
            return
        }
        persistProfile()
        screen = .dashboard
        Task {
            _ = await notificationService.requestPermission()
            fcmToken = notificationService.fcmToken
            defaults.set(fcmToken, forKey: "partner_fcm_token")
            await syncPartnerProfile()
            await refreshAll()
        }
        startRealtimePolling()
        startLocationHeartbeat()
    }

    func logout() {
        refreshTask?.cancel()
        heartbeatTask?.cancel()
        profile = PartnerProfile()
        bookings = []
        selectedBooking = nil
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: bookingsKey)
        screen = .login
    }

    func syncPartnerProfile() async {
        guard profile.isValid else { return }
        do {
            try await api.upsertPartnerProfile(profile, fcmToken: fcmToken, token: authToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRemoteProfile() async {
        do {
            profile = try await api.fetchPartnerProfile(current: profile, token: authToken)
            persistProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleOnline() {
        profile.online.toggle()
        persistProfile()
        Task {
            do {
                try await api.setOnline(profile.online, token: authToken)
                await syncPartnerProfile()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func refreshAll() async {
        await fetchBookings()
        await fetchNotifications()
    }

    func fetchBookings() async {
        do {
            let live = try await api.fetchPartnerBookings(token: authToken)
            mergeBookings(live)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchNotifications() async {
        do {
            notifications = try await api.fetchNotifications(token: authToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markNotificationRead(_ item: PartnerNotificationItem) {
        Task {
            await api.markNotificationRead(item.id, token: authToken)
            if let index = notifications.firstIndex(where: { $0.id == item.id }) {
                notifications[index].isRead = true
            }
        }
    }

    func openBooking(_ booking: PartnerBooking) {
        selectedBooking = booking
        screen = booking.isPending ? .request : .detail
    }

    func acceptSelectedBooking() {
        guard let booking = selectedBooking else { return }
        loading = true
        Task {
            do {
                let accepted = try await api.acceptBooking(booking.id, token: authToken)
                upsertBooking(accepted)
                selectedBooking = accepted
                screen = .detail
                infoMessage = "Booking accepted."
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    func rejectSelectedBooking() {
        guard let booking = selectedBooking else { return }
        loading = true
        Task {
            do {
                try await api.rejectBooking(booking.id, token: authToken)
                var rejected = booking
                rejected.status = "rejected"
                upsertBooking(rejected)
                selectedBooking = nil
                screen = .dashboard
                infoMessage = "Booking rejected."
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    func updateSelectedStatus(_ status: String) {
        guard var booking = selectedBooking else { return }
        loading = true
        Task {
            let location = await makeLocationPayload(bookingId: booking.id)
            do {
                let updated = try await api.updateBookingStatus(booking.id, status: status, finalAmount: booking.amount, location: location, token: authToken)
                booking = updated
                upsertBooking(updated)
                selectedBooking = booking
                if status == "completed" {
                    screen = .bookings
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    func reportNoResponse(reason: String) {
        guard let booking = selectedBooking else { return }
        Task {
            let location = await makeLocationPayload(bookingId: booking.id)
            do {
                try await api.reportNoResponse(bookingId: booking.id, reason: reason, location: location, token: authToken)
                infoMessage = "No-response report submitted."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func openMap(_ booking: PartnerBooking) {
        selectedBooking = booking
        screen = .map
    }

    func openAppleMaps(_ booking: PartnerBooking) {
        let url = URL(string: "http://maps.apple.com/?daddr=\(booking.lat),\(booking.lng)&dirflg=d")!
        UIApplication.shared.open(url)
    }

    func callCustomer(_ booking: PartnerBooking) {
        let digits = booking.customerPhone.filter(\.isNumber)
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else {
            errorMessage = "Customer phone hidden or unavailable."
            return
        }
        Task { await api.createCallLog(bookingId: booking.id, action: "start", reason: "", token: authToken) }
        UIApplication.shared.open(url)
    }

    func openBookingChat(_ booking: PartnerBooking) {
        selectedBooking = booking
        screen = .bookingChat
        Task { await loadBookingChat() }
    }

    func loadBookingChat() async {
        guard let booking = selectedBooking else { return }
        do {
            messages = try await api.fetchBookingChatMessages(bookingId: booking.id, token: authToken)
            await api.markBookingChatSeen(bookingId: booking.id, token: authToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendBookingChatMessage(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let booking = selectedBooking, !clean.isEmpty else { return }
        let local = ChatMessage.local(text: clean, booking: booking)
        messages.append(local)
        Task {
            do {
                let sent = try await api.sendBookingChatMessage(bookingId: booking.id, message: clean, token: authToken)
                if let index = messages.firstIndex(where: { $0.id == local.id }) {
                    messages[index] = sent
                }
                await api.monitorBookingChat(bookingId: booking.id, message: clean, clientMessageId: sent.clientMessageId, token: authToken)
            } catch {
                if let index = messages.firstIndex(where: { $0.id == local.id }) {
                    messages[index].deliveryStatus = "failed"
                }
                errorMessage = error.localizedDescription
            }
        }
    }

    func openSupport(_ type: String, draft: String = "") {
        supportType = type
        if !draft.isEmpty {
            supportMessages.append(ChatMessage(id: UUID().uuidString, bookingId: "support", bookingCode: "", senderRole: "partner", senderName: "You", message: draft, clientMessageId: "", deliveryStatus: "draft", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)))
        }
        screen = .support
    }

    func sendSupportMessage(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        supportMessages.append(ChatMessage(id: UUID().uuidString, bookingId: "support", bookingCode: "", senderRole: "partner", senderName: "You", message: clean, clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)))
        supportMessages.append(ChatMessage(id: UUID().uuidString, bookingId: "support", bookingCode: "", senderRole: "support", senderName: "Partner Support", message: supportReply(for: clean), clientMessageId: "", deliveryStatus: "sent", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)))
    }

    func submitVerification() {
        Task {
            do {
                try await api.submitVerification(aadhaarLast4: aadhaarLast4, selfieURL: profile.photoURL, faceVerified: true, selfieVerified: true, token: authToken)
                profile.faceVerified = true
                persistProfile()
                infoMessage = "Verification submitted."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func downloadStatement() {
        Task {
            do {
                let data = try await api.downloadStatement(from: statementFrom, to: statementTo, token: authToken)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("apnaservo-job-statement.pdf")
                try data.write(to: url)
                UIApplication.shared.open(url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func startRealtimePolling() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshAll()
                try? await Task.sleep(nanoseconds: AppConfig.refreshSeconds)
            }
        }
    }

    func startLocationHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.sendLocationHeartbeat()
                try? await Task.sleep(nanoseconds: AppConfig.locationHeartbeatSeconds)
            }
        }
    }

    func sendLocationHeartbeat() async {
        guard profile.online else { return }
        let payload = await makeLocationPayload(bookingId: activeBookings.first?.id ?? "")
        do {
            try await api.updateLocation(payload, token: authToken)
            profile.lat = payload.lat
            profile.lng = payload.lng
            persistProfile()
        } catch {
        }
    }

    func setSkill(_ skill: PartnerSkill, selected: Bool) {
        if selected {
            profile.skills.insert(skill)
        } else if profile.skills.count > 1 {
            profile.skills.remove(skill)
        }
        persistProfile()
    }

    private func makeLocationPayload(bookingId: String) async -> LocationPayload {
        let location = await locationService.currentLocation()
        return LocationPayload(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            accuracy: max(location.horizontalAccuracy, 0),
            provider: "ios-corelocation",
            isMock: false,
            bookingId: bookingId,
            recordedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    private func mergeBookings(_ live: [PartnerBooking]) {
        for booking in live {
            upsertBooking(booking, persist: false)
        }
        persistBookings()
        if let selected = selectedBooking,
           let updated = bookings.first(where: { $0.id == selected.id }) {
            selectedBooking = updated
        }
    }

    private func upsertBooking(_ booking: PartnerBooking, persist: Bool = true) {
        if let index = bookings.firstIndex(where: { $0.id == booking.id || (!$0.bookingCode.isEmpty && $0.bookingCode == booking.bookingCode) }) {
            bookings[index] = booking
        } else {
            bookings.insert(booking, at: 0)
        }
        if persist { persistBookings() }
    }

    private func supportReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("payment") || lower.contains("earning") {
            return "Earnings are calculated from completed jobs. Use the statement date filter to download a PDF."
        }
        if lower.contains("radius") || lower.contains("area") || lower.contains("location") {
            return "Update service area and radius in My Services, then save. Location heartbeat is sent while Online mode is on."
        }
        if lower.contains("booking") || lower.contains("request") {
            return "Keep Online ON. Requests matching your service category, city, and radius will appear on the dashboard."
        }
        return "Support request recorded. The partner team will follow up."
    }
}
