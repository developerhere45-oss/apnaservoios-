import MapKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PartnerAppView: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            content
            if showsBottomNav {
                PartnerBottomNav()
            }
        }
        .background(AppTheme.bg)
        .task {
            await store.refreshAll()
        }
    }

    private var showsBottomNav: Bool {
        ![.support, .bookingChat, .map, .request].contains(store.screen)
    }

    @ViewBuilder
    private var content: some View {
        switch store.screen {
        case .dashboard:
            DashboardScreen()
        case .request:
            IncomingRequestScreen()
        case .detail:
            OrderDetailScreen()
        case .bookings:
            PartnerBookingsScreen()
        case .earnings:
            EarningsScreen()
        case .map:
            PartnerMapScreen()
        case .notifications:
            PartnerNotificationsScreen()
        case .profile:
            PartnerProfileScreen()
        case .personalInfo:
            PersonalInfoScreen()
        case .documents:
            DocumentsScreen()
        case .myServices:
            MyServicesScreen()
        case .settings:
            PartnerSettingsScreen()
        case .legal:
            PartnerLegalScreen()
        case .support:
            PartnerSupportChatScreen()
        case .bookingChat:
            BookingChatView()
        case .login:
            PartnerLoginView()
        }
    }
}

struct DashboardScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                onlineCard
                HStack(spacing: 10) {
                    StatTile(title: "Active Jobs", value: "\(store.activeBookings.count)", systemImage: "briefcase.fill", tint: AppTheme.rose)
                    StatTile(title: "Completed", value: "\(store.completedBookings.count)", systemImage: "checkmark.shield.fill", tint: AppTheme.green)
                    StatTile(title: "Earnings", value: "Rs \(store.totalEarnings)", systemImage: "wallet.pass.fill", tint: AppTheme.purple)
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "New Requests", actionTitle: "Refresh") {
                        Task { await store.fetchBookings() }
                    }
                    if store.pendingBookings.isEmpty {
                        EmptyState(title: "No new requests", subtitle: "Keep Online ON. Matching bookings will appear here.")
                    } else {
                        ForEach(store.pendingBookings) { booking in
                            PartnerBookingCard(booking: booking, primaryTitle: "View") {
                                store.openBooking(booking)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Active Jobs")
                    if store.activeBookings.isEmpty {
                        EmptyState(title: "No active jobs", subtitle: "Accepted jobs will be tracked here.")
                    } else {
                        ForEach(store.activeBookings) { booking in
                            PartnerBookingCard(
                                booking: booking,
                                primaryTitle: "Open",
                                primaryAction: { store.openBooking(booking) },
                                secondaryTitle: "Map",
                                secondaryAction: { store.openMap(booking) }
                            )
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi \(store.profile.name.isEmpty ? "Partner" : store.profile.name)")
                    .font(.title2.weight(.black))
                    .foregroundStyle(AppTheme.ink)
                Text("\(store.profile.skillsLabel) - \(store.profile.serviceArea)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Button {
                store.screen = .notifications
            } label: {
                Image(systemName: "bell.fill")
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if store.notifications.contains(where: { !$0.isRead }) {
                            Circle().fill(AppTheme.rose).frame(width: 10, height: 10)
                        }
                    }
            }
        }
    }

    private var onlineCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(store.profile.online ? AppTheme.green : AppTheme.muted)
                .frame(width: 18, height: 18)
                .padding(12)
                .background(store.profile.online ? AppTheme.greenSoft : AppTheme.line, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(store.profile.online ? "You are Online" : "You are Offline")
                    .font(.headline.weight(.black))
                Text(store.profile.online ? "Receiving nearby requests" : "Turn online to receive bookings")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { store.profile.online },
                set: { _ in store.toggleOnline() }
            ))
            .labelsHidden()
        }
        .cardStyle()
    }
}

struct IncomingRequestScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "New Booking Request", subtitle: "Request received", backAction: { store.screen = .dashboard })
            ScrollView {
                if let booking = store.selectedBooking {
                    VStack(spacing: 16) {
                        PartnerBookingCard(
                            booking: booking,
                            primaryTitle: "Accept",
                            primaryAction: { store.acceptSelectedBooking() },
                            secondaryTitle: "Decline",
                            secondaryAction: { store.rejectSelectedBooking() }
                        )
                        detail("Customer", booking.customerName)
                        detail("Address", booking.address)
                        detail("Issue", booking.issue)
                        detail("Slot", booking.slot)
                        Button(store.loading ? "Processing..." : "Accept Booking") {
                            store.acceptSelectedBooking()
                        }
                        .primaryButton()
                        Button("Decline") {
                            store.rejectSelectedBooking()
                        }
                        .outlineButton()
                    }
                    .padding(18)
                } else {
                    EmptyState(title: "No request selected", subtitle: "Return to dashboard.")
                        .padding(18)
                }
            }
        }
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(AppTheme.muted)
            Text(value).font(.subheadline).foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct OrderDetailScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                BookingDetailCloneHeader(
                    backAction: { store.screen = .bookings },
                    supportAction: { store.screen = .support }
                )

                if let booking = store.selectedBooking {
                    BookingDetailCloneCard(
                        booking: booking,
                        chatAction: { store.openBookingChat(booking) },
                        callAction: { store.callCustomer(booking) },
                        startAction: { store.openMap(booking) }
                    )
                    BookingDetailCloneAcceptedBanner()
                } else {
                    EmptyState(title: "No job selected", subtitle: "Open a booking from dashboard.")
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
        }
        .background(AppTheme.bg.ignoresSafeArea())
    }
}

private struct BookingDetailCloneHeader: View {
    let backAction: () -> Void
    let supportAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 52, height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 4)

            VStack(spacing: 10) {
                Text("Booking Details")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 16) {
                    Capsule()
                        .fill(AppTheme.rose)
                        .frame(width: 48, height: 6)
                    Circle()
                        .fill(AppTheme.rose)
                        .frame(width: 7, height: 7)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            Button(action: supportAction) {
                HStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Support")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(AppTheme.rose)
                .frame(width: 108, height: 52)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 88)
    }
}

private struct BookingDetailCloneCard: View {
    let booking: PartnerBooking
    let chatAction: () -> Void
    let callAction: () -> Void
    let startAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            customerBlock
                .padding(.bottom, 18)
            BookingDetailCloneDivider()
            BookingDetailCloneInfoRow(icon: "wrench.fill", title: "Service", value: booking.serviceName)
            BookingDetailCloneDivider()
            BookingDetailCloneInfoRow(icon: "doc.text.fill", title: "Issue", value: issueText)
            BookingDetailCloneDivider()
            BookingDetailCloneInfoRow(icon: "mappin", title: "Address", value: booking.address.isEmpty ? booking.city : booking.address)
            BookingDetailCloneDivider()
            dateTimeRow
                .padding(.vertical, 18)
            startButton
        }
        .padding(18)
        .background(
            ZStack(alignment: .topTrailing) {
                Color.white
                Circle()
                    .fill(AppTheme.roseSoft.opacity(0.7))
                    .frame(width: 190, height: 190)
                    .offset(x: 76, y: 12)
                    .blur(radius: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(hex: 0xF1E5E7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.09), radius: 18, x: 0, y: 10)
    }

    private var customerBlock: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(bookingInitials)
                .font(.system(size: 36, weight: .black))
                .foregroundStyle(AppTheme.rose)
                .frame(width: 76, height: 76)
                .background(
                    Circle()
                        .fill(Color(hex: 0xFFE7EE))
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 5) {
                Text(customerName)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(shortPhone)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text(maskedPhone)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: "shield")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x14AEB8))
                    Text("Protected calling")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.rose)
                        .lineLimit(1)
                }
                Text("Only you can call this customer")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button(action: chatAction) {
                    Label("Chat", systemImage: "message")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.rose)
                        .frame(width: 74, height: 50)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(AppTheme.rose, lineWidth: 1.2))
                }
                .buttonStyle(.plain)

                Button(action: callAction) {
                    Label("Call", systemImage: "phone.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 78, height: 50)
                        .background(
                            LinearGradient(colors: [AppTheme.rose, Color(hex: 0xDE235A)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                        )
                        .shadow(color: AppTheme.rose.opacity(0.28), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dateTimeRow: some View {
        HStack(spacing: 14) {
            BookingDetailCloneDateCell(icon: "calendar", title: "Booking Date", value: bookingDateTitle, subvalue: bookingDayTitle)
            Rectangle()
                .fill(Color(hex: 0xEADFE2))
                .frame(width: 1, height: 70)
            BookingDetailCloneDateCell(icon: "clock", title: "Time", value: bookingTimeTitle, subvalue: bookingDurationTitle)
        }
    }

    private var startButton: some View {
        Button(action: startAction) {
            HStack(spacing: 16) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.white.opacity(0.16)))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Start Service")
                        .font(.system(size: 25, weight: .black))
                    Text("Navigate to customer location")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .frame(height: 76)
            .background(
                LinearGradient(colors: [Color(hex: 0x0DB85B), Color(hex: 0x008A36)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color(hex: 0x008B38), lineWidth: 1))
            .shadow(color: Color(hex: 0x008A36).opacity(0.26), radius: 12, x: 0, y: 7)
        }
        .buttonStyle(.plain)
    }

    private var customerName: String {
        booking.customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Customer" : booking.customerName
    }

    private var bookingInitials: String {
        let words = customerName.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }.map { String($0).uppercased() }.joined()
        return letters.isEmpty ? "C" : letters
    }

    private var digitsOnlyPhone: String {
        booking.customerPhone.filter(\.isNumber)
    }

    private var shortPhone: String {
        guard digitsOnlyPhone.count >= 4 else { return "+----" }
        return "+" + String(digitsOnlyPhone.suffix(4))
    }

    private var maskedPhone: String {
        guard digitsOnlyPhone.count >= 4 else { return "******----" }
        return "******" + String(digitsOnlyPhone.suffix(4))
    }

    private var issueText: String {
        booking.issue.isEmpty ? "Customer requested \(booking.serviceName) inspection" : booking.issue
    }

    private var bookingDateTitle: String {
        let extracted = Self.extractDate(from: booking.slot)
        guard !extracted.isEmpty else { return "Today" }
        return Self.isToday(extracted) ? "Today" : extracted
    }

    private var bookingDayTitle: String {
        let extracted = Self.extractDate(from: booking.slot)
        if let date = Self.parseDate(extracted) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        return "Friday"
    }

    private var bookingTimeTitle: String {
        booking.slot.isEmpty ? "Time not set" : booking.slot
    }

    private var bookingDurationTitle: String {
        let slot = booking.slot
        let pattern = #"(\d{1,2}):(\d{2})\s*([AP]M)\s*-\s*(\d{1,2}):(\d{2})\s*([AP]M)"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: slot, range: NSRange(slot.startIndex..., in: slot)),
            let startHourRange = Range(match.range(at: 1), in: slot),
            let startMinuteRange = Range(match.range(at: 2), in: slot),
            let startMeridiemRange = Range(match.range(at: 3), in: slot),
            let endHourRange = Range(match.range(at: 4), in: slot),
            let endMinuteRange = Range(match.range(at: 5), in: slot),
            let endMeridiemRange = Range(match.range(at: 6), in: slot),
            let startMinutes = Self.minutes(hour: String(slot[startHourRange]), minute: String(slot[startMinuteRange]), meridiem: String(slot[startMeridiemRange])),
            let endMinutes = Self.minutes(hour: String(slot[endHourRange]), minute: String(slot[endMinuteRange]), meridiem: String(slot[endMeridiemRange]))
        else {
            return "2 hrs"
        }
        let minutes = max(0, endMinutes - startMinutes)
        if minutes >= 60, minutes % 60 == 0 { return "\(minutes / 60) hrs" }
        if minutes >= 60 { return "\(minutes / 60) hr \(minutes % 60) min" }
        return "\(minutes) min"
    }

    private static func extractDate(from slot: String) -> String {
        let pattern = #"\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4}"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: slot, range: NSRange(slot.startIndex..., in: slot)),
            let range = Range(match.range, in: slot)
        else { return "" }
        return String(slot[range])
    }

    private static func parseDate(_ text: String) -> Date? {
        guard !text.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["d MMM yyyy", "dd MMM yyyy", "d MMMM yyyy", "dd MMMM yyyy"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }

    private static func isToday(_ text: String) -> Bool {
        guard let date = parseDate(text) else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private static func minutes(hour: String, minute: String, meridiem: String) -> Int? {
        guard var h = Int(hour), let m = Int(minute) else { return nil }
        let upper = meridiem.uppercased()
        if upper == "PM", h < 12 { h += 12 }
        if upper == "AM", h == 12 { h = 0 }
        return h * 60 + m
    }
}

private struct BookingDetailCloneInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.rose)
                .frame(width: 60, height: 60)
                .background(AppTheme.roseSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: 0xF7D9E1), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.muted)
                Text(value.isEmpty ? "-" : value)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 18)
    }
}

private struct BookingDetailCloneDateCell: View {
    let icon: String
    let title: String
    let value: String
    let subvalue: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.rose)
                .frame(width: 58, height: 58)
                .background(AppTheme.roseSoft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color(hex: 0xF7D9E1), lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
                Text(value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)
                Text(subvalue)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BookingDetailCloneDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: 0xEFE3E6))
            .frame(height: 1)
    }
}

private struct BookingDetailCloneAcceptedBanner: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Color(hex: 0x008D3E))
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(Color(hex: 0x008D3E), lineWidth: 2))

            Text("Booking accepted")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Color(hex: 0x008D3E))
            Text("\u{2022}")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text("Let's go!")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppTheme.muted)
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(Color(hex: 0xF4FFF9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(hex: 0xCFEEDD), lineWidth: 1))
    }
}

struct PartnerBookingsScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "My Bookings", subtitle: "\(store.bookings.count) jobs", backAction: { store.screen = .dashboard }, trailingSystemImage: "arrow.clockwise") {
                Task { await store.fetchBookings() }
            }
            ScrollView {
                VStack(spacing: 12) {
                    if store.bookings.isEmpty {
                        EmptyState(title: "No bookings", subtitle: "Accepted and completed jobs will appear here.")
                    } else {
                        ForEach(store.bookings) { booking in
                            PartnerBookingCard(
                                booking: booking,
                                primaryTitle: "Open",
                                primaryAction: { store.openBooking(booking) },
                                secondaryTitle: booking.isActive ? "Map" : nil,
                                secondaryAction: booking.isActive ? { store.openMap(booking) } : nil
                            )
                        }
                    }
                }
                .padding(18)
            }
        }
    }
}

struct EarningsScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Earnings", subtitle: "Completed jobs", backAction: { store.screen = .dashboard })
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        StatTile(title: "Total", value: "Rs \(store.totalEarnings)", systemImage: "wallet.pass.fill", tint: AppTheme.purple)
                        StatTile(title: "Today", value: "Rs \(store.todayEarnings)", systemImage: "calendar", tint: AppTheme.rose)
                    }
                    HStack(spacing: 10) {
                        StatTile(title: "This Month", value: "Rs \(store.monthEarnings)", systemImage: "chart.bar.fill", tint: AppTheme.orange)
                        StatTile(title: "Jobs", value: "\(store.completedBookings.count)", systemImage: "checkmark.circle.fill", tint: AppTheme.green)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Download Statement")
                            .font(.headline.weight(.black))
                        TextField("From yyyy-mm-dd", text: $store.statementFrom)
                            .textFieldStyle(.roundedBorder)
                        TextField("To yyyy-mm-dd", text: $store.statementTo)
                            .textFieldStyle(.roundedBorder)
                        Button("Download PDF") {
                            store.downloadStatement()
                        }
                        .primaryButton()
                    }
                    .cardStyle()
                    ForEach(store.completedBookings) { booking in
                        PartnerBookingCard(booking: booking, primaryTitle: "Open") {
                            store.openBooking(booking)
                        }
                    }
                }
                .padding(18)
            }
        }
    }
}

struct PartnerMapScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ServiceStatusCloneHeader(
                    backAction: { store.screen = .detail },
                    supportAction: { store.screen = .support }
                )

            if let booking = store.selectedBooking {
                    ServiceStatusCloneCustomerCard(
                        booking: booking,
                        chatAction: { store.openBookingChat(booking) },
                        callAction: { store.callCustomer(booking) }
                    )
                    ServiceStatusCloneServiceProblemRow(booking: booking)
                    ServiceStatusCloneTimeline(booking: booking)
                    ServiceStatusCloneLocationRow(booking: booking) {
                        store.openAppleMaps(booking)
                    }
                    if let next = ServiceStatusCloneStep.next(for: booking.status) {
                        ServiceStatusCloneActionPanel(step: next, loading: store.loading) {
                            store.updateSelectedStatus(next.status)
                        }
                    }
            } else {
                EmptyState(title: "No map target", subtitle: "Open a booking first.")
            }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppTheme.bg.ignoresSafeArea())
    }
}

private struct ServiceStatusCloneHeader: View {
    let backAction: () -> Void
    let supportAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(AppTheme.rose)
                    .frame(width: 54, height: 54)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 4)

            VStack(spacing: 8) {
                Text("Service Status")
                    .font(.system(size: 27, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("Live updates about your service")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 12) {
                    Capsule().fill(AppTheme.rose).frame(width: 48, height: 6)
                    Capsule().fill(AppTheme.rose).frame(width: 12, height: 6)
                }
                .padding(.top, 2)
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            Button(action: supportAction) {
                HStack(spacing: 7) {
                    Image(systemName: "headphones")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Support")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(AppTheme.rose)
                .frame(width: 110, height: 52)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 104)
    }
}

private struct ServiceStatusCloneCustomerCard: View {
    let booking: PartnerBooking
    let chatAction: () -> Void
    let callAction: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(.top, 12)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: 18) {
            avatar
            customerCopy
            Spacer(minLength: 8)
            actionButtons
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                avatar
                customerCopy
            }
            actionButtons
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(initials)
                .font(.system(size: 35, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 94, height: 94)
                .background(
                    Circle()
                        .fill(LinearGradient(colors: [AppTheme.roseDark, AppTheme.rose], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().stroke(AppTheme.roseSoft, lineWidth: 8))
                )
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(AppTheme.rose, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
        }
    }

    private var customerCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Label("Protected calling only", systemImage: "shield.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.rose)
            Label(maskedPhone, systemImage: "phone.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Label(addressText, systemImage: "mappin")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: chatAction) {
                Label("Chat", systemImage: "message")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.rose)
                    .frame(width: 78, height: 50)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.rose, lineWidth: 1.3))
            }
            .buttonStyle(.plain)

            Button(action: callAction) {
                Label("Call", systemImage: "phone.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 78, height: 50)
                    .background(
                        LinearGradient(colors: [AppTheme.rose, Color(hex: 0xC9004D)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: AppTheme.rose.opacity(0.25), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
    }

    private var name: String {
        booking.customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Customer" : booking.customerName
    }

    private var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0).uppercased() }.joined()
        return letters.isEmpty ? "C" : letters
    }

    private var maskedPhone: String {
        let digits = booking.customerPhone.filter(\.isNumber)
        guard digits.count >= 4 else { return "**** **** ----" }
        return "**** **** \(digits.suffix(4))"
    }

    private var addressText: String {
        booking.address.isEmpty ? booking.city : booking.address
    }
}

private struct ServiceStatusCloneServiceProblemRow: View {
    let booking: PartnerBooking

    var body: some View {
        VStack(spacing: 22) {
            Rectangle()
                .fill(Color(hex: 0xF4CBD4))
                .frame(height: 1)

            HStack(spacing: 18) {
                ServiceStatusCloneMiniInfo(icon: "wrench.fill", title: "Service", value: booking.serviceName)
                Rectangle()
                    .fill(Color(hex: 0xF4CBD4))
                    .frame(width: 1, height: 72)
                ServiceStatusCloneMiniInfo(icon: "doc.text.fill", title: "Problem", value: booking.issue.isEmpty ? "Customer requested \(booking.serviceName)" : booking.issue)
            }
        }
    }
}

private struct ServiceStatusCloneMiniInfo: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.rose)
                .frame(width: 58, height: 58)
                .background(AppTheme.roseSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
                Text(value)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ServiceStatusCloneTimeline: View {
    let booking: PartnerBooking

    var body: some View {
        VStack(spacing: 0) {
            ForEach(ServiceStatusCloneStage.allCases) { stage in
                ServiceStatusCloneTimelineRow(
                    stage: stage,
                    currentRank: booking.serviceCloneRank,
                    acceptedTime: booking.acceptedCloneTime,
                    hasNext: stage != ServiceStatusCloneStage.allCases.last
                )
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ServiceStatusCloneTimelineRow: View {
    let stage: ServiceStatusCloneStage
    let currentRank: Int
    let acceptedTime: String
    let hasNext: Bool

    private var completed: Bool { currentRank > stage.rank || currentRank >= 6 || stage.rank == 1 }
    private var current: Bool { currentRank == stage.rank && currentRank < 6 && stage.rank > 1 }
    private var circleColor: Color { completed ? AppTheme.green : current ? AppTheme.rose : Color(hex: 0xF1F1F1) }
    private var lineColor: Color { completed ? AppTheme.green.opacity(0.45) : current ? AppTheme.rose.opacity(0.65) : Color(hex: 0xE5E5E5) }
    private var textColor: Color { current ? AppTheme.rose : completed ? AppTheme.ink : AppTheme.muted }
    private var statusText: String { completed ? "Completed" : current ? "In Progress" : "Pending" }
    private var statusColor: Color { completed ? AppTheme.green : current ? AppTheme.rose : AppTheme.muted }
    private var statusBg: Color { completed ? AppTheme.greenSoft : current ? AppTheme.roseSoft : Color(hex: 0xF5F5F5) }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack(alignment: .top) {
                if hasNext {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 3, height: 78)
                        .offset(y: 42)
                }
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 54, height: 54)
                    Image(systemName: completed ? "checkmark" : stage.icon)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(completed || current ? .white : AppTheme.muted)
                }
            }
            .frame(width: 58, height: hasNext ? 98 : 62)

            VStack(alignment: .leading, spacing: 5) {
                Text(stage.title)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(textColor)
                Text(stage.rank == 1 ? acceptedTime : current ? acceptedTime : "Pending")
                    .font(.system(size: 15))
                    .foregroundStyle(current || completed ? AppTheme.ink : AppTheme.muted)
            }
            .padding(.top, 7)

            Spacer()

            Text(statusText)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(statusBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 8)
        }
    }
}

private struct ServiceStatusCloneLocationRow: View {
    let booking: PartnerBooking
    let navigateAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "mappin")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.rose)
                .frame(width: 58, height: 58)
                .background(AppTheme.roseSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                Text("Customer Location")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                Text(booking.address.isEmpty ? booking.city : booking.address)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(3)
            }
            Spacer()
            Button(action: navigateAction) {
                Label("Navigate", systemImage: "paperplane.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.rose)
                    .frame(width: 118, height: 50)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.rose.opacity(0.45), lineWidth: 1.2))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

private struct ServiceStatusCloneActionPanel: View {
    let step: ServiceStatusCloneStep
    let loading: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color(hex: 0xF4CBD4))
                .frame(height: 1)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Update Status")
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                    Text(step.hint)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: 0x008D3E)).frame(width: 9, height: 9)
                    Text("Live")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: 0x008D3E))
                }
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(AppTheme.greenSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: step.icon)
                        .font(.system(size: 20, weight: .black))
                    Text(loading ? "Updating..." : step.label)
                        .font(.system(size: 18, weight: .black))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(step.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: step.color.opacity(0.28), radius: 14, x: 0, y: 8)
            }
            .disabled(loading)
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
    }
}

private enum ServiceStatusCloneStage: CaseIterable, Identifiable {
    case accepted
    case onTheWay
    case arrived
    case started
    case completed

    var id: String { title }

    var rank: Int {
        switch self {
        case .accepted: return 1
        case .onTheWay: return 2
        case .arrived: return 3
        case .started: return 4
        case .completed: return 5
        }
    }

    var title: String {
        switch self {
        case .accepted: return "Booking Accepted"
        case .onTheWay: return "On The Way"
        case .arrived: return "Arrived"
        case .started: return "Service Started"
        case .completed: return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .accepted: return "checkmark"
        case .onTheWay: return "car.fill"
        case .arrived: return "mappin"
        case .started: return "play.fill"
        case .completed: return "checkmark"
        }
    }
}

private enum ServiceStatusCloneStep {
    case onTheWay
    case arrived
    case started
    case complete
    case confirmPayment

    var status: String {
        switch self {
        case .onTheWay: return "on_the_way"
        case .arrived: return "arrived"
        case .started: return "started"
        case .complete: return "amount_pending"
        case .confirmPayment: return "completed"
        }
    }

    var label: String {
        switch self {
        case .onTheWay: return "Mark as On The Way"
        case .arrived: return "Mark as Arrived"
        case .started: return "Start Service"
        case .complete: return "Complete Service"
        case .confirmPayment: return "Confirm Payment Received"
        }
    }

    var icon: String {
        switch self {
        case .onTheWay: return "car.fill"
        case .arrived: return "mappin"
        case .started: return "play.fill"
        case .complete, .confirmPayment: return "checkmark"
        }
    }

    var color: Color {
        switch self {
        case .onTheWay: return AppTheme.rose
        case .arrived: return AppTheme.blue
        case .started: return AppTheme.orange
        case .complete, .confirmPayment: return AppTheme.green
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .onTheWay:
            return LinearGradient(colors: [AppTheme.rose, Color(hex: 0xC9004D)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .arrived:
            return LinearGradient(colors: [AppTheme.blue, Color(hex: 0x1454C9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .started:
            return LinearGradient(colors: [AppTheme.orange, Color(hex: 0xE0690F)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .complete, .confirmPayment:
            return LinearGradient(colors: [Color(hex: 0x0DB85B), Color(hex: 0x008A36)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var hint: String {
        switch self {
        case .complete:
            return "Complete the job and enter the final amount."
        case .confirmPayment:
            return "Confirm only after receiving customer payment."
        default:
            return "Tap once. The customer will be notified instantly."
        }
    }

    static func next(for status: String) -> ServiceStatusCloneStep? {
        switch status {
        case "accepted", "pending": return .onTheWay
        case "on_the_way": return .arrived
        case "arrived": return .started
        case "started": return .complete
        case "amount_pending": return .confirmPayment
        default: return nil
        }
    }
}

private extension PartnerBooking {
    var serviceCloneRank: Int {
        switch status {
        case "accepted": return 1
        case "on_the_way": return 2
        case "arrived": return 3
        case "started": return 4
        case "amount_pending": return 5
        case "completed": return 6
        default: return isPending ? 0 : 1
        }
    }

    var acceptedCloneTime: String {
        let date = Date(timeIntervalSince1970: TimeInterval(createdAtMillis) / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy h:mm a"
        return formatter.string(from: date)
    }
}

struct PartnerNotificationsScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Notifications", subtitle: "Booking requests and updates", backAction: { store.screen = .dashboard }, trailingSystemImage: "arrow.clockwise") {
                Task { await store.fetchNotifications() }
            }
            ScrollView {
                VStack(spacing: 12) {
                    if store.notifications.isEmpty {
                        EmptyState(title: "No notifications", subtitle: "FCM/APNs booking alerts will appear here.")
                    } else {
                        ForEach(store.notifications) { item in
                            Button {
                                store.markNotificationRead(item)
                                if let booking = store.bookings.first(where: { $0.id == item.bookingId || $0.bookingCode == item.bookingId }) {
                                    store.openBooking(booking)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.title).font(.headline.weight(.black))
                                        Spacer()
                                        if !item.isRead { Circle().fill(AppTheme.rose).frame(width: 9, height: 9) }
                                    }
                                    Text(item.body)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                .foregroundStyle(AppTheme.ink)
                                .cardStyle()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
            }
        }
    }
}

struct PartnerProfileScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Profile", subtitle: store.profile.skillsLabel, backAction: { store.screen = .dashboard })
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.profile.name)
                            .font(.title3.weight(.black))
                        Text(store.profile.phone)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                        Label(store.profile.faceVerified ? "Face verified" : "Verification pending", systemImage: store.profile.faceVerified ? "checkmark.shield.fill" : "shield")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(store.profile.faceVerified ? AppTheme.green : AppTheme.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    tool("Personal Information", "Name, phone and profile", "person.fill") { store.screen = .personalInfo }
                    tool("Documents", "ID proof and skill certificate", "folder.fill") { store.screen = .documents }
                    tool("My Services", "Services, radius and area", "slider.horizontal.3") { store.screen = .myServices }
                    tool("Support", "Chat, complaint, track issue", "headphones") { store.openSupport("Chat") }
                    tool("Settings", "Notifications and account", "gearshape.fill") { store.screen = .settings }
                    Button("Logout") { store.logout() }.outlineButton()
                }
                .padding(18)
            }
        }
    }

    private func tool(_ title: String, _ subtitle: String, _ image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: image)
                    .foregroundStyle(AppTheme.rose)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.roseSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline.weight(.bold)).foregroundStyle(AppTheme.ink)
                    Text(subtitle).font(.caption).foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(AppTheme.muted)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct PersonalInfoScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Personal Information", subtitle: "Partner details", backAction: { store.screen = .profile })
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 12) {
                        TextField("Partner name", text: $store.profile.name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Phone", text: $store.profile.phone)
                            .keyboardType(.phonePad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Email", text: $store.profile.email)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.roundedBorder)
                        TextField("DD/MM/YYYY", text: $store.profile.dob)
                            .textFieldStyle(.roundedBorder)
                        TextField("Gender", text: $store.profile.gender)
                            .textFieldStyle(.roundedBorder)
                        TextField("Full address", text: $store.profile.address)
                            .textFieldStyle(.roundedBorder)
                        HStack(spacing: 10) {
                            TextField("City", text: $store.profile.city)
                                .textFieldStyle(.roundedBorder)
                            TextField("State", text: $store.profile.state)
                                .textFieldStyle(.roundedBorder)
                        }
                        TextField("PIN Code", text: $store.profile.pinCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Emergency phone", text: $store.profile.emergencyContactNumber)
                            .keyboardType(.phonePad)
                            .textFieldStyle(.roundedBorder)
                        Stepper("Years of Experience: \(store.profile.yearsOfExperience)", value: $store.profile.yearsOfExperience, in: 0...80)
                        TextField("Service Area / Work", text: $store.profile.workingAreas)
                            .textFieldStyle(.roundedBorder)
                        TextField("Languages Known", text: $store.profile.languages)
                            .textFieldStyle(.roundedBorder)
                        Button("Save") {
                            store.persistProfile()
                            Task { await store.syncPartnerProfile() }
                        }
                        .primaryButton()
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Backend Auth")
                            .font(.headline.weight(.black))
                        SecureField("Firebase ID token for API calls", text: $store.authToken)
                            .textFieldStyle(.roundedBorder)
                        Button("Save Token") {
                            store.saveAuthToken()
                        }
                        .outlineButton()
                        Text("In production, Firebase Auth will set this token automatically.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .cardStyle()
                }
                .padding(18)
            }
        }
    }
}

struct DocumentsScreen: View {
    @EnvironmentObject private var store: PartnerAppStore
    @State private var importingDocumentType: String?

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Documents", subtitle: "Verification", backAction: { store.screen = .profile })
            ScrollView {
                VStack(spacing: 14) {
                    documentRow("Aadhaar Card Front", "Upload clear Aadhaar image", status(for: "Aadhaar Card Front"))
                    documentRow("Aadhaar Card Back", "Upload clear Aadhaar image", status(for: "Aadhaar Card Back"))
                    documentRow("PAN Card", "Upload PAN card image", status(for: "PAN Card"))
                    documentRow("Selfie Verification", "Upload clear face photo", status(for: "Selfie Verification"))
                    documentRow("Skill Certificate", "Upload skill certificate", status(for: "Skill Certificate"))
                    documentRow("Training Certificate", "Upload training certificate", status(for: "Training Certificate"))
                    documentRow("Government License", "Upload license if applicable", status(for: "Government License"))
                    documentRow("Trade License", "Upload optional trade license", status(for: "Trade License"))
                    documentRow("Other Supporting Document", "Upload any supporting proof", status(for: "Other Supporting Document"))
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aadhaar last 4")
                            .font(.headline.weight(.black))
                        TextField("1234", text: $store.aadhaarLast4)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        Button("Submit Verification") {
                            store.submitVerification()
                        }
                        .primaryButton()
                        Text("Upload clear and valid verification documents. These files are used only for verification.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .cardStyle()
                }
                .padding(18)
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { importingDocumentType != nil },
                set: { if !$0 { importingDocumentType = nil } }
            ),
            allowedContentTypes: [.jpeg, .png],
            allowsMultipleSelection: false
        ) { result in
            guard let documentType = importingDocumentType else { return }
            importingDocumentType = nil
            if case .success(let urls) = result, let url = urls.first {
                store.uploadDocument(documentType: documentType, fileURL: url)
            }
        }
    }

    private func status(for documentType: String) -> String {
        store.documentStatuses[documentType] ?? (documentType == "Skill Certificate" ? "Required" : "Pending")
    }

    private func documentRow(_ title: String, _ subtitle: String, _ status: String) -> some View {
        Button {
            importingDocumentType = title
        } label: {
            HStack(spacing: 12) {
                Image(systemName: status == "Uploaded" ? "checkmark.seal.fill" : "doc.fill")
                    .foregroundStyle(status == "Uploaded" ? AppTheme.green : AppTheme.rose)
                    .frame(width: 40, height: 40)
                    .background(status == "Uploaded" ? AppTheme.greenSoft : AppTheme.roseSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Text(status)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(status == "Uploaded" ? AppTheme.green : AppTheme.orange)
            }
            .foregroundStyle(AppTheme.ink)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct MyServicesScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "My Services", subtitle: "Services and area", backAction: { store.screen = .profile })
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Services")
                            .font(.headline.weight(.black))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(PartnerSkill.allCases) { skill in
                                let selected = store.profile.skills.contains(skill)
                                Button(skill.label) {
                                    store.setSkill(skill, selected: !selected)
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selected ? .white : AppTheme.ink)
                                .padding(.vertical, 9)
                                .frame(maxWidth: .infinity)
                                .background(selected ? AppTheme.rose : AppTheme.roseSoft, in: Capsule())
                            }
                        }
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Radius")
                            .font(.headline.weight(.black))
                        Picker("Radius", selection: $store.profile.serviceRadiusKm) {
                            ForEach([5, 10, 25, 50], id: \.self) { km in
                                Text("\(km) km").tag(km)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Area")
                            .font(.headline.weight(.black))
                        Picker("Area", selection: $store.profile.serviceArea) {
                            ForEach(["Guwahati", "Dispur", "Ganeshguri", "Zoo Road", "Six Mile"], id: \.self) { area in
                                Text(area).tag(area)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .cardStyle()

                    Button("Save Changes") {
                        store.persistProfile()
                        Task { await store.syncPartnerProfile() }
                    }
                    .primaryButton()
                }
                .padding(18)
            }
        }
    }
}

struct PartnerSettingsScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Settings", subtitle: "Account and notifications", backAction: { store.screen = .profile })
            ScrollView {
                VStack(spacing: 14) {
                    setting("Notifications", "Booking requests, cancellations and updates use APNs + Firebase Messaging.", "bell.fill") {
                        Task { _ = await AppNotificationService().requestPermission() }
                    }
                    setting("Map & Location", "Location heartbeat updates /partners/location while online.", "location.fill") {
                        Task { await store.sendLocationHeartbeat() }
                    }
                    setting("Legal Information", "Privacy, partner terms and account deletion.", "shield.fill") {
                        store.screen = .legal
                    }
                    Button("Delete Account Request") {
                        store.requestAccountDeletion()
                    }
                    .outlineButton()
                }
                .padding(18)
            }
        }
    }

    private func setting(_ title: String, _ subtitle: String, _ image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: image)
                    .foregroundStyle(AppTheme.rose)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.roseSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline.weight(.bold)).foregroundStyle(AppTheme.ink)
                    Text(subtitle).font(.caption).foregroundStyle(AppTheme.muted)
                }
                Spacer()
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct PartnerLegalScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Legal & Information", subtitle: "Partner terms", backAction: { store.screen = .settings })
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    legalCard("Privacy Policy", "ApnaServo stores profile, service area, verification, booking and payment information to operate the platform and send job updates.")
                    legalCard("Partner Terms & Conditions", "Partners must accept only eligible jobs, keep location updated during jobs, avoid direct off-platform payment disputes, and complete status updates honestly.")
                    legalCard("Account Deletion", "Deletion request is sent to backend for review. Pending bookings, statements and compliance records may be retained as required.")
                }
                .padding(18)
            }
        }
    }

    private func legalCard(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline.weight(.black))
            Text(content).font(.subheadline).foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct PartnerSupportChatScreen: View {
    @EnvironmentObject private var store: PartnerAppStore
    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: store.supportType, subtitle: "Partner Support", backAction: { store.screen = .profile })
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(store.supportMessages) { message in
                            ChatBubble(message: message, isMe: message.senderRole == "partner")
                                .id(message.id)
                        }
                    }
                    .padding(18)
                }
                .onChange(of: store.supportMessages.count) { _ in
                    if let last = store.supportMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            HStack(spacing: 10) {
                TextField("Type message", text: $text)
                    .textFieldStyle(.roundedBorder)
                Button {
                    store.sendSupportMessage(text)
                    text = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.rose, in: Circle())
                }
            }
            .padding(12)
            .background(Color.white)
        }
    }
}
