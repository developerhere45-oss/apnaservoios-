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
    @Published var documentStatuses: [String: String] = [:]
    @Published var uploadingDocumentType = ""

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
    private var backendToken: String {
        authToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
    var todayEarnings: Int {
        let calendar = Calendar.current
        return completedBookings
            .filter { calendar.isDate(Date(milliseconds: $0.completedAtMillis), inSameDayAs: Date()) }
            .reduce(0) { $0 + $1.amount }
    }
    var monthEarnings: Int {
        let calendar = Calendar.current
        let now = Date()
        return completedBookings
            .filter { calendar.isDate(Date(milliseconds: $0.completedAtMillis), equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
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
            errorMessage = "Name, 10 digit phone, aur at least one service required hai."
            return
        }
        persistProfile()
        screen = .dashboard
        Task {
            _ = await notificationService.requestPermission()
            fcmToken = notificationService.fcmToken
            defaults.set(fcmToken, forKey: "partner_fcm_token")
            await saveFCMTokenIfNeeded()
            await syncPartnerProfile()
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
            try await api.upsertPartnerProfile(profile, fcmToken: fcmToken, token: backendToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveFCMTokenIfNeeded() async {
        guard !fcmToken.isEmpty else { return }
        do {
            try await api.saveFCMToken(fcmToken, token: backendToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRemoteProfile() async {
        guard !role.isStaff else { return }
        do {
            profile = try await api.fetchPartnerProfile(current: profile, token: backendToken)
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
                try await api.setOnline(profile.online, token: backendToken)
                await syncPartnerProfile()
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
            let live = try await api.fetchPartnerBookings(token: backendToken)
            mergeBookings(live)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchNotifications() async {
        do {
            notifications = try await api.fetchNotifications(token: backendToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markNotificationRead(_ item: PartnerNotificationItem) {
        Task {
            await api.markNotificationRead(item.id, token: backendToken)
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
                let accepted = try await api.acceptBooking(booking.id, token: backendToken)
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
                try await api.rejectBooking(booking.id, token: backendToken)
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
                let updated = try await api.updateBookingStatus(booking.id, status: status, finalAmount: booking.amount, location: location, token: backendToken)
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
                try await api.reportNoResponse(bookingId: booking.id, reason: reason, location: location, token: backendToken)
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
        openExternalURL(url)
    }

    func callCustomer(_ booking: PartnerBooking) {
        let digits = booking.customerPhone.filter(\.isNumber)
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else {
            errorMessage = "Customer phone hidden or unavailable."
            return
        }
        Task { await api.createCallLog(bookingId: booking.id, action: "start", reason: "", token: backendToken) }
        openExternalURL(url)
    }

    func openBookingChat(_ booking: PartnerBooking) {
        selectedBooking = booking
        screen = .bookingChat
        Task { await loadBookingChat() }
    }

    func loadBookingChat() async {
        guard let booking = selectedBooking else { return }
        do {
            messages = try await api.fetchBookingChatMessages(bookingId: booking.id, token: backendToken)
            await api.markBookingChatSeen(bookingId: booking.id, token: backendToken)
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
                let sent = try await api.sendBookingChatMessage(bookingId: booking.id, message: clean, token: backendToken)
                if let index = messages.firstIndex(where: { $0.id == local.id }) {
                    messages[index] = sent
                }
                await api.monitorBookingChat(bookingId: booking.id, message: clean, clientMessageId: sent.clientMessageId, token: backendToken)
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
        let clientMessageId = "IOSSUPPORT\(Int(Date().timeIntervalSince1970 * 1000))"
        let local = ChatMessage(id: clientMessageId, bookingId: "support", bookingCode: "", senderRole: "partner", senderName: "You", message: clean, clientMessageId: clientMessageId, deliveryStatus: "queued", createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
        supportMessages.append(local)
        Task {
            do {
                try await api.createPartnerSupportTicket(category: supportType, message: clean, clientMessageId: clientMessageId, attachmentURL: "", token: backendToken)
                if let index = supportMessages.firstIndex(where: { $0.id == clientMessageId }) {
                    supportMessages[index].deliveryStatus = "sent"
                }
                infoMessage = "Support request submitted."
            } catch {
                if let index = supportMessages.firstIndex(where: { $0.id == clientMessageId }) {
                    supportMessages[index].deliveryStatus = "failed"
                }
                errorMessage = error.localizedDescription
            }
        }
    }

    func submitVerification() {
        guard aadhaarLast4.isEmpty || aadhaarLast4.range(of: #"^\d{4}$"#, options: .regularExpression) != nil else {
            errorMessage = "Enter the last 4 digits of Aadhaar."
            return
        }
        Task {
            do {
                try await api.submitVerification(aadhaarLast4: aadhaarLast4, selfieURL: profile.photoURL, faceVerified: false, selfieVerified: false, token: backendToken)
                persistProfile()
                infoMessage = "Verification submitted for review."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func uploadDocument(documentType: String, fileURL: URL) {
        Task {
            let scoped = fileURL.startAccessingSecurityScopedResource()
            defer {
                if scoped { fileURL.stopAccessingSecurityScopedResource() }
            }
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
                guard size <= AppConfig.maxDocumentBytes else {
                    errorMessage = "Document must be under 4 MB."
                    return
                }
                uploadingDocumentType = documentType
                documentStatuses[documentType] = "Uploading"
                try await api.uploadDocument(documentType: documentType, fileURL: fileURL, aadhaarLast4: aadhaarLast4, token: backendToken)
                documentStatuses[documentType] = "Uploaded"
                infoMessage = "\(documentType) uploaded for verification."
            } catch {
                documentStatuses[documentType] = "Failed"
                errorMessage = error.localizedDescription
            }
            uploadingDocumentType = ""
        }
    }

    func requestAccountDeletion(reason: String = "Partner requested account deletion from iOS app") {
        Task {
            do {
                try await api.requestAccountDeletion(reason: reason, token: backendToken)
                logout()
                infoMessage = "Account deletion request submitted."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func downloadStatement() {
        Task {
            do {
                let data = try await api.downloadStatement(from: statementFrom, to: statementTo, token: backendToken)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("apnaservo-job-statement.pdf")
                try data.write(to: url)
                openExternalURL(url)
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
            try await api.updateLocation(payload, token: backendToken)
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

    private func openExternalURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}

private extension Date {
    init(milliseconds: Int64) {
        if milliseconds > 0 {
            self.init(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
        } else {
            self.init(timeIntervalSince1970: 0)
        }
    }
}
