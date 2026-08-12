import Foundation
import Security
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var authToken: String = "" {
        didSet { SecureTokenStore.save(authToken) }
    }
    @AppStorage("apnaservo.ios.role") private var persistedRole = AppRole.user.rawValue
    @Published var role: AppRole = .user
    @Published private(set) var userBookings: [Booking] = []
    @Published private(set) var partnerBookings: [Booking] = []
    @Published private(set) var messages: [ChatMessage] = []
    @Published var selectedBooking: Booking?
    @Published var bookingDraft: BookingDraft?
    @Published private(set) var isRefreshing = false
    @Published private(set) var bookingServiceIDs: Set<String> = []
    @Published private(set) var pendingBookingIDs: Set<String> = []
    @Published private(set) var sendingMessageIDs: Set<String> = []
    @Published var errorMessage: String?

    private let api: APIClient
    private var refreshTask: Task<Void, Never>?
    private var chatLoadTask: Task<Void, Never>?
    private var chatPollingTask: Task<Void, Never>?
    private var bookingRequestIDs: [String: String] = [:]

    let services: [ServiceItem] = [
        ServiceItem(id: "ac", name: "AC Repair & Service", subtitle: "Installation, repair and gas refilling", systemImage: "snowflake", tintName: "blue"),
        ServiceItem(id: "plumbing", name: "Plumber", subtitle: "Leak repair and fitting", systemImage: "wrench.and.screwdriver", tintName: "green"),
        ServiceItem(id: "electrician", name: "Electrician", subtitle: "Wiring, light and fan fixtures", systemImage: "bolt.fill", tintName: "yellow"),
        ServiceItem(id: "carpenter", name: "Carpenter", subtitle: "Furniture repair and installation", systemImage: "hammer.fill", tintName: "orange"),
        ServiceItem(id: "cleaning", name: "Cleaning", subtitle: "Home and office deep cleaning", systemImage: "sparkles", tintName: "green"),
        ServiceItem(id: "laundry", name: "Laundry", subtitle: "Pickup, wash, fold and ironing", systemImage: "washer", tintName: "orange"),
        ServiceItem(id: "appliance", name: "Appliance Repair", subtitle: "Home appliance diagnosis and repair", systemImage: "gearshape.2.fill", tintName: "blue"),
        ServiceItem(id: "ro", name: "RO Service", subtitle: "Water purifier repair and maintenance", systemImage: "drop.fill", tintName: "cyan")
    ]

    init(api: APIClient = APIClient()) {
        self.api = api
        let legacyToken = UserDefaults.standard.string(forKey: "apnaservo.ios.authToken") ?? ""
        authToken = SecureTokenStore.load() ?? legacyToken
        if !legacyToken.isEmpty {
            SecureTokenStore.save(legacyToken)
            UserDefaults.standard.removeObject(forKey: "apnaservo.ios.authToken")
        }
        role = AppRole(rawValue: persistedRole) ?? .user
    }

    var isAuthenticated: Bool { !authToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func setRole(_ newRole: AppRole) {
        guard role != newRole else { return }
        stopChatUpdates()
        selectedBooking = nil
        role = newRole
        persistedRole = newRole.rawValue
        refresh()
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { await performRefresh() }
    }

    func performRefresh() async {
        guard isAuthenticated else {
            userBookings = []
            partnerBookings = []
            errorMessage = nil
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            if role == .user { userBookings = try await api.userBookings(token: authToken) }
            else { partnerBookings = try await api.partnerBookings(token: authToken) }
            errorMessage = nil
        } catch is CancellationError { return }
        catch { errorMessage = error.localizedDescription }
    }

    func prepareBooking(for service: ServiceItem) { bookingDraft = BookingDraft(service: service) }

    func submitBooking(_ draft: BookingDraft) async -> Bool {
        guard draft.isValid, isAuthenticated, !bookingServiceIDs.contains(draft.service.id) else {
            if !isAuthenticated { errorMessage = "Please sign in before creating a booking." }
            return false
        }
        bookingServiceIDs.insert(draft.service.id)
        defer { bookingServiceIDs.remove(draft.service.id) }
        let requestID = bookingRequestIDs[draft.service.id] ?? "IOS-\(UUID().uuidString)"
        bookingRequestIDs[draft.service.id] = requestID
        do {
            let booking = try await api.createBooking(draft: draft, requestID: requestID, token: authToken)
            userBookings = upserting(booking, in: userBookings)
            bookingRequestIDs.removeValue(forKey: draft.service.id)
            bookingDraft = nil
            errorMessage = nil
            return true
        } catch is CancellationError { return false }
        catch { errorMessage = error.localizedDescription; return false }
    }

    func showChat(for booking: Booking) {
        guard booking.canOpenChat else {
            errorMessage = "Chat becomes available after a partner accepts the booking."
            return
        }
        selectedBooking = booking
    }

    func loadChat(for booking: Booking) {
        chatLoadTask?.cancel()
        chatLoadTask = Task { await fetchMessages(for: booking, showError: true) }
        startChatUpdates(for: booking)
    }

    func stopChatUpdates() {
        chatLoadTask?.cancel()
        chatPollingTask?.cancel()
        chatLoadTask = nil
        chatPollingTask = nil
        messages = []
    }

    func sendChat(_ rawText: String) async {
        guard let booking = selectedBooking, isAuthenticated else {
            errorMessage = "Please sign in before sending messages."
            return
        }
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let local = ChatMessage.local(text: text, role: role, booking: booking)
        messages.append(local)
        sendingMessageIDs.insert(local.id)
        defer { sendingMessageIDs.remove(local.id) }
        do {
            let sent = try await api.sendChat(text, clientMessageID: local.clientMessageId, booking: booking, token: authToken)
            messages.removeAll { $0.id == local.id || (!$0.clientMessageId.isEmpty && $0.clientMessageId == sent.clientMessageId) }
            messages.append(sent)
            messages.sort { $0.createdAtMillis < $1.createdAtMillis }
            errorMessage = nil
        } catch is CancellationError { return }
        catch { errorMessage = "Message not sent. \(error.localizedDescription)" }
    }

    func accept(_ booking: Booking) async {
        await runBookingAction(booking) { try await self.api.acceptBooking(booking, token: self.authToken) }
    }

    func reject(_ booking: Booking) async {
        guard beginAction(booking) else { return }
        defer { pendingBookingIDs.remove(booking.id) }
        do {
            try await api.rejectBooking(booking, token: authToken)
            partnerBookings.removeAll { $0.id == booking.id }
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func update(_ booking: Booking, status: String) async {
        await runBookingAction(booking) { try await self.api.updateStatus(booking, status: status, token: self.authToken) }
    }

    func handleBecameActive() {
        refresh()
        if let selectedBooking { loadChat(for: selectedBooking) }
    }

    func handleEnteredBackground() {
        chatLoadTask?.cancel()
        chatPollingTask?.cancel()
        chatLoadTask = nil
        chatPollingTask = nil
    }

    private func beginAction(_ booking: Booking) -> Bool {
        guard isAuthenticated, !pendingBookingIDs.contains(booking.id) else { return false }
        pendingBookingIDs.insert(booking.id)
        return true
    }

    private func runBookingAction(_ booking: Booking, operation: () async throws -> Booking) async {
        guard beginAction(booking) else { return }
        defer { pendingBookingIDs.remove(booking.id) }
        do {
            let updated = try await operation()
            if role == .user { userBookings = upserting(updated, in: userBookings) }
            else { partnerBookings = upserting(updated, in: partnerBookings) }
            selectedBooking = selectedBooking?.id == updated.id ? updated : selectedBooking
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func fetchMessages(for booking: Booking, showError: Bool) async {
        guard isAuthenticated, selectedBooking?.id == booking.id else { return }
        do {
            let fresh = try await api.chatMessages(for: booking, token: authToken)
            guard selectedBooking?.id == booking.id else { return }
            let pending = messages.filter { $0.id.hasPrefix("local-") }
            let serverIDs = Set(fresh.map(\.clientMessageId))
            messages = (fresh + pending.filter { !serverIDs.contains($0.clientMessageId) })
                .reduce(into: [String: ChatMessage]()) { $0[$1.id] = $1 }.values
                .sorted { $0.createdAtMillis < $1.createdAtMillis }
            await api.markChatSeen(booking: booking, token: authToken)
            if showError { errorMessage = nil }
        } catch is CancellationError { return }
        catch { if showError { errorMessage = error.localizedDescription } }
    }

    private func startChatUpdates(for booking: Booking) {
        chatPollingTask?.cancel()
        chatPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                guard !Task.isCancelled, let self else { return }
                await self.fetchMessages(for: booking, showError: false)
            }
        }
    }

    private func upserting(_ booking: Booking, in list: [Booking]) -> [Booking] {
        [booking] + list.filter { $0.id != booking.id }
    }
}

private enum SecureTokenStore {
    private static let service = "com.apnaservo.ios.auth"
    private static let account = "firebase-id-token"

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ value: String) {
        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if value.isEmpty { SecItemDelete(lookup as CFDictionary); return }
        guard let data = value.data(using: .utf8) else { return }
        let attributes = [kSecValueData as String: data]
        if SecItemUpdate(lookup as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            var insert = lookup
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(insert as CFDictionary, nil)
        }
    }
}
