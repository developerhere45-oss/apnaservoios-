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
    @Published var newStaffName = ""
    @Published var newStaffPhone = ""
    @Published var newStaffEmail = ""
    @Published var showFinalAmountSheet = false
    @Published var finalAmountInput = ""

    private let api = APIClient()
    private let secureStore = SecureStore()
    private let notificationService = AppNotificationService()
    private lazy var locationService = LocationService()
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
    var role: PartnerRole { profile.effectiveRole }
    var permissions: PartnerPermissions { profile.permissions }
    var staffMembers: [LaundryStaffMember] { profile.laundryBusiness?.staffMembers ?? [] }
    var pendingBookings: [PartnerBooking] { bookings.filter(\.isPending) }
    var activeBookings: [PartnerBooking] { bookings.filter(\.isActive) }
    var completedBookings: [PartnerBooking] { bookings.filter { $0.status == "completed" } }
    var totalEarnings: Int { completedBookings.reduce(0) { $0 + $1.amount } }
    var unassignedLaundryBookings: [PartnerBooking] {
        bookings.filter { $0.serviceCategory == "laundry" && !$0.isAssignedToStaff && !$0.isFinished }
    }

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
            if role == .laundryStaff {
                await startStaffSession()
            } else if role == .cleaningStaff {
                errorMessage = "Cleaning Staff login is not available in the current Android/backend contract."
            } else {
                await fetchRemoteProfile()
                await syncPartnerProfile()
                await fetchRemoteProfile()
            }
            await refreshAll()
        }
        startRealtimePolling()
        if !role.isStaff {
            startLocationHeartbeat()
        }
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
        guard profile.isValid, !role.isStaff else { return }
        if role == .laundryOwner, profile.approvalStatus != nil {
            return
        }
        do {
            try await api.upsertPartnerProfile(profile, fcmToken: fcmToken, token: authToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRemoteProfile() async {
        guard !role.isStaff else { return }
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
                if role == .laundryStaff {
                    _ = try await api.setStaffOnline(profile.online, fcmToken: fcmToken, token: authToken)
                } else if role == .cleaningStaff {
                    throw APIError.badResponse("Cleaning Staff online API is not present in the Android backend.")
                } else {
                    try await api.setOnline(profile.online, token: authToken)
                    await syncPartnerProfile()
                }
            } catch {
                profile.online.toggle()
                persistProfile()
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
            let live: [PartnerBooking]
            if role == .laundryStaff {
                let envelope = try await api.fetchStaffBookings(token: authToken)
                applyStaffIdentity(envelope.staff)
                live = envelope.bookings ?? []
            } else {
                let all = try await api.fetchPartnerBookings(token: authToken)
                live = role == .cleaningStaff
                    ? all.filter { $0.serviceCategory == PartnerSkill.cleaning.rawValue && !$0.isPending }
                    : all
            }
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

    func markAllNotificationsRead() {
        let unreadIds = notifications.filter { !$0.isRead }.map(\.id)
        guard !unreadIds.isEmpty else { return }
        Task {
            await api.markAllNotificationsRead(unreadIds, token: authToken)
            for index in notifications.indices {
                notifications[index].isRead = true
            }
        }
    }

    func openBooking(_ booking: PartnerBooking) {
        if booking.isPending && !permissions.canAcceptOrReject {
            errorMessage = "This role cannot accept or reject new booking requests."
            return
        }
        selectedBooking = booking
        screen = booking.isPending ? .request : .detail
    }

    func acceptSelectedBooking() {
        guard permissions.canAcceptOrReject, let booking = selectedBooking else {
            errorMessage = "This role cannot accept booking requests."
            return
        }
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
        guard permissions.canAcceptOrReject, let booking = selectedBooking else {
            errorMessage = "This role cannot reject booking requests."
            return
        }
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
        guard permissions.canUpdateJobStatus, var booking = selectedBooking else {
            errorMessage = "This role cannot update job status."
            return
        }
        loading = true
        Task {
            do {
                let updated: PartnerBooking
                if role == .laundryStaff {
                    updated = try await api.updateStaffBookingStatus(bookingId: booking.id, status: status, token: authToken)
                } else if role == .cleaningStaff {
                    throw APIError.badResponse("Cleaning Staff status API is not present in the Android backend.")
                } else {
                    let location = await makeLocationPayload(bookingId: booking.id)
                    updated = try await api.updateBookingStatus(booking.id, status: status, finalAmount: booking.amount, location: location, token: authToken)
                }
                booking = updated
                upsertBooking(updated)
                selectedBooking = booking
                if status == "completed" && role != .laundryStaff {
                    screen = .bookings
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    func requestFinalAmount(_ booking: PartnerBooking) {
        guard permissions.canUpdateJobStatus, booking.status == "started" else {
            errorMessage = "Final amount can be sent only after service starts."
            return
        }
        selectedBooking = booking
        finalAmountInput = booking.amount > 0 ? String(booking.amount) : ""
        showFinalAmountSheet = true
    }

    func submitFinalAmount() {
        guard var booking = selectedBooking,
              let amount = Int(finalAmountInput),
              amount > 0 else {
            errorMessage = "Enter a valid final amount."
            return
        }
        showFinalAmountSheet = false
        loading = true
        Task {
            let location = await makeLocationPayload(bookingId: booking.id)
            do {
                let updated = try await api.updateBookingStatus(
                    booking.id,
                    status: "amount_pending",
                    finalAmount: amount,
                    location: location,
                    token: authToken
                )
                booking = updated
                upsertBooking(updated)
                selectedBooking = updated
                infoMessage = "Final amount sent for customer approval."
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
        guard profile.online, !role.isStaff else { return }
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
        guard role == .individual else { return }
        if selected {
            profile.skills.insert(skill)
        } else if profile.skills.count > 1 {
            profile.skills.remove(skill)
        }
        persistProfile()
    }

    func setRole(_ newRole: PartnerRole) {
        profile.role = newRole
        profile.sessionRole = newRole.isStaff ? newRole.rawValue : nil
        profile.businessType = newRole == .laundryOwner ? "laundry" : nil
        switch newRole {
        case .individual:
            if profile.skills.isEmpty || profile.skills == [.cleaning] || profile.skills == [.laundry] {
                profile.skills = [.ac]
            }
            profile.laundryBusiness = nil
        case .cleaningPartner, .cleaningStaff:
            profile.skills = [.cleaning]
            profile.laundryBusiness = nil
        case .laundryOwner:
            profile.skills = [.laundry]
            var business = profile.laundryBusiness ?? .empty
            if business.shopLocation.isEmpty { business.shopLocation = profile.serviceArea }
            if business.ownerName.isEmpty { business.ownerName = profile.name }
            if business.ownerPhone.isEmpty { business.ownerPhone = profile.phone }
            profile.laundryBusiness = business
        case .laundryStaff:
            profile.skills = [.laundry]
            profile.laundryBusiness = nil
        }
        bookings = []
        selectedBooking = nil
        persistProfile()
        persistBookings()
    }

    func updateLaundryBusiness(
        shopName: String,
        licenseNumber: String,
        shopLocation: String
    ) {
        var business = profile.laundryBusiness ?? .empty
        business.shopName = shopName
        business.shopLicenseNumber = licenseNumber
        business.shopLocation = shopLocation
        business.ownerName = profile.name
        business.ownerPhone = profile.phone
        profile.laundryBusiness = business
        persistProfile()
    }

    func addLaundryStaff() {
        guard permissions.canManageStaff else {
            errorMessage = "Only a Laundry Owner can add staff."
            return
        }
        let name = newStaffName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = newStaffPhone.filter(\.isNumber)
        let email = newStaffEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= 2, phone.count == 10 || email.contains("@") else {
            errorMessage = "Enter staff name and a valid 10-digit phone or email."
            return
        }
        loading = true
        Task {
            do {
                let members = try await api.addLaundryStaff(name: name, phone: phone, email: email, token: authToken)
                var business = profile.laundryBusiness ?? .empty
                business.staffMembers = members
                profile.laundryBusiness = business
                newStaffName = ""
                newStaffPhone = ""
                newStaffEmail = ""
                persistProfile()
                infoMessage = "Laundry staff member added."
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    func assign(_ booking: PartnerBooking, to staff: LaundryStaffMember) {
        guard permissions.canManageStaff else {
            errorMessage = "Only a Laundry Owner can assign staff."
            return
        }
        loading = true
        Task {
            do {
                let updated = try await api.assignLaundryStaff(
                    bookingId: booking.id,
                    staffSequence: staff.sequence,
                    token: authToken
                )
                upsertBooking(updated)
                infoMessage = "\(booking.displayId) assigned to \(staff.name)."
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
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
        bookings = live.sorted { $0.createdAtMillis > $1.createdAtMillis }
        persistBookings()
        if let selected = selectedBooking,
           let updated = bookings.first(where: { $0.id == selected.id }) {
            selectedBooking = updated
        }
    }

    private func startStaffSession() async {
        do {
            let envelope = try await api.startStaffSession(
                fcmToken: fcmToken,
                online: profile.online,
                token: authToken
            )
            profile.sessionRole = envelope.sessionRole ?? PartnerRole.laundryStaff.rawValue
            profile.role = .laundryStaff
            profile.skills = [.laundry]
            applyStaffIdentity(envelope.staff)
            mergeBookings(envelope.bookings ?? [])
            persistProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyStaffIdentity(_ staff: LaundryStaffMember?) {
        guard let staff else { return }
        profile.name = staff.name
        profile.phone = staff.phone
        profile.email = staff.email
        profile.online = staff.online
        profile.sessionRole = PartnerRole.laundryStaff.rawValue
        profile.role = .laundryStaff
        profile.skills = [.laundry]
        persistProfile()
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
