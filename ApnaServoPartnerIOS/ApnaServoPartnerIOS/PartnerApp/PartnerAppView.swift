import MapKit
import SwiftUI

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
        case .staffManagement:
            StaffManagementScreen()
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
                    if store.permissions.canViewEarnings {
                        StatTile(title: "Earnings", value: "Rs \(store.totalEarnings)", systemImage: "wallet.pass.fill", tint: AppTheme.purple)
                    } else {
                        StatTile(title: "Role", value: "Staff", systemImage: "person.badge.key.fill", tint: AppTheme.blue)
                    }
                }
                if store.permissions.canManageStaff {
                    Button {
                        store.screen = .staffManagement
                    } label: {
                        Label("Manage Laundry Staff & Assign Orders", systemImage: "person.3.fill")
                            .primaryButton()
                    }
                }
                if store.permissions.canReceiveRequests {
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
                Text("\(store.role.label) - \(store.profile.serviceArea)")
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
                Text(onlineSubtitle)
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

    private var onlineSubtitle: String {
        if store.role.isStaff {
            return store.profile.online ? "Ready for assigned jobs" : "Go online for assigned job updates"
        }
        return store.profile.online ? "Receiving nearby requests" : "Turn online to receive bookings"
    }
}

struct IncomingRequestScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "New Booking Request", subtitle: "Slide/accept equivalent", backAction: { store.screen = .dashboard })
            ScrollView {
                if let booking = store.selectedBooking {
                    VStack(spacing: 16) {
                        if store.permissions.canAcceptOrReject {
                            PartnerBookingCard(
                                booking: booking,
                                primaryTitle: "Accept",
                                primaryAction: { store.acceptSelectedBooking() },
                                secondaryTitle: "Reject",
                                secondaryAction: { store.rejectSelectedBooking() }
                            )
                        }
                        detail("Customer", booking.customerName)
                        detail("Address", booking.address)
                        detail("Issue", booking.issue)
                        detail("Slot", booking.slot)
                        if store.permissions.canAcceptOrReject {
                            Button(store.loading ? "Processing..." : "Accept Booking") {
                                store.acceptSelectedBooking()
                            }
                            .primaryButton()
                            Button("Reject") {
                                store.rejectSelectedBooking()
                            }
                            .outlineButton()
                        }
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
        VStack(spacing: 0) {
            TopBar(title: "Order Detail", subtitle: store.selectedBooking?.displayId ?? "", backAction: { store.screen = .dashboard })
            ScrollView {
                if let booking = store.selectedBooking {
                    VStack(spacing: 16) {
                        PartnerBookingCard(
                            booking: booking,
                            primaryTitle: "Map",
                            primaryAction: { store.openMap(booking) },
                            secondaryTitle: "Chat",
                            secondaryAction: { store.openBookingChat(booking) }
                        )
                        VStack(spacing: 10) {
                            actionButton(for: booking)
                            if !store.role.isStaff {
                                Button {
                                    store.callCustomer(booking)
                                } label: {
                                    Label("Protected Call", systemImage: "phone.fill")
                                        .outlineButton()
                                }
                                Button {
                                    store.reportNoResponse(reason: "Customer did not respond")
                                } label: {
                                    Label("Customer No Response", systemImage: "exclamationmark.triangle.fill")
                                        .outlineButton()
                                }
                            }
                        }
                    }
                    .padding(18)
                } else {
                    EmptyState(title: "No job selected", subtitle: "Open a booking from dashboard.")
                        .padding(18)
                }
            }
        }
    }

    @ViewBuilder
    private func actionButton(for booking: PartnerBooking) -> some View {
        if store.role == .laundryStaff {
            switch booking.staffTaskStatus {
            case "assigned":
                Button("Start Laundry Task") { store.updateSelectedStatus("in_progress") }.primaryButton()
            case "in_progress":
                Button("Complete Laundry Task") { store.updateSelectedStatus("completed") }.primaryButton()
            default:
                Button("Refresh") { Task { await store.fetchBookings() } }.outlineButton()
            }
        } else if store.permissions.canUpdateJobStatus {
            switch booking.status {
            case "accepted":
                Button("Mark On The Way") { store.updateSelectedStatus("on_the_way") }.primaryButton()
            case "on_the_way":
                Button("Mark Arrived") { store.updateSelectedStatus("arrived") }.primaryButton()
            case "arrived":
                Button("Start Service") { store.updateSelectedStatus("started") }.primaryButton()
            case "started":
                Button("Send Final Amount") { store.requestFinalAmount(booking) }.primaryButton()
            case "amount_pending":
                Button("Waiting for Customer Approval") { Task { await store.fetchBookings() } }.outlineButton()
            default:
                Button("Refresh") { Task { await store.fetchBookings() } }.outlineButton()
            }
        } else if store.permissions.canManageStaff && !booking.isAssignedToStaff {
            Button("Assign Staff") { store.screen = .staffManagement }.primaryButton()
        } else {
            Button("Refresh") { Task { await store.fetchBookings() } }.outlineButton()
        }
    }
}

struct PartnerBookingsScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: store.role.isStaff ? "My Jobs" : "My Bookings", subtitle: "\(store.bookings.count) jobs", backAction: { store.screen = .dashboard }, trailingSystemImage: "arrow.clockwise") {
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
    @State private var period: EarningsPeriod = .week

    var body: some View {
        VStack(spacing: 0) {
            earningsHeader
            ScrollView {
                VStack(spacing: 18) {
                    periodSelector
                    EarningsHeroCard(
                        title: "Wallet - \(period.walletTitle)",
                        amount: money(periodTotal),
                        subtitle: "\(periodBookings.count) completed jobs in this period"
                    )
                    breakdownCard
                    transactionsCard
                    statementCard
                    rewardsBanner
                }
                .padding(18)
            }
        }
        .background(AppTheme.bg)
    }

    private var earningsHeader: some View {
        HStack {
            Button { store.screen = .dashboard } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.rose)
                    .frame(width: 46, height: 46)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Earnings")
                    .font(.title2.weight(.black))
                    .foregroundStyle(AppTheme.ink)
                Text("Track your income")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Button { store.screen = .notifications } label: {
                Image(systemName: "bell")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(EarningsPeriod.allCases) { item in
                Button { period = item } label: {
                    Text(item.label)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(period == item ? Color.white : AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if period == item {
                                Capsule()
                                    .fill(LinearGradient(colors: [AppTheme.rose, AppTheme.roseDark], startPoint: .leading, endPoint: .trailing))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().stroke(AppTheme.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 5)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Earnings Breakdown", systemImage: "chart.bar.fill")
                .font(.title3.weight(.black))
                .foregroundStyle(AppTheme.ink)
                .labelStyle(EarningsLabelStyle(tint: AppTheme.rose, background: AppTheme.roseSoft))
            EarningsBreakdownRow(icon: "calendar", iconTint: AppTheme.blue, iconBg: Color(hex: 0xE8F3FF), title: "Completed Orders", amount: money(periodTotal))
            Divider().background(AppTheme.line)
            EarningsBreakdownRow(icon: "star.fill", iconTint: Color(hex: 0xE29C1D), iconBg: Color(hex: 0xFFF9E8), title: "Incentives", amount: money(0))
            Divider().background(AppTheme.line)
            EarningsBreakdownRow(icon: "wifi", iconTint: AppTheme.green, iconBg: AppTheme.greenSoft, title: "Tips", amount: money(0))
            Divider().background(AppTheme.line)
            HStack {
                Text("Total")
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(money(periodTotal))
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppTheme.rose)
            }
            .padding(.top, 4)
        }
        .cardStyle(padding: 18)
    }

    private var transactionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Transactions", systemImage: "target")
                .font(.title3.weight(.black))
                .foregroundStyle(AppTheme.ink)
                .labelStyle(EarningsLabelStyle(tint: AppTheme.rose, background: AppTheme.roseSoft))
            if periodBookings.isEmpty {
                Text("No completed transactions in this period.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 14)
            } else {
                ForEach(transactionRows, id: \.element.id) { index, booking in
                    EarningsTransactionRow(title: booking.serviceName, amount: money(booking.amount))
                    if index < transactionRows.count - 1 {
                        Divider().background(AppTheme.line)
                    }
                }
            }
        }
        .cardStyle(padding: 18)
    }

    private var statementCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.blue)
                .frame(width: 54, height: 54)
                .background(Color(hex: 0xEEF1FF), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text("Job Statement PDF")
                    .font(.headline.weight(.black))
                    .foregroundStyle(AppTheme.ink)
                Text("Download completed jobs, commission and payout summary.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button("Download Job Statement") {
                store.downloadStatement()
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(LinearGradient(colors: [AppTheme.rose, AppTheme.roseDark], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .cardStyle(padding: 14)
    }

    private var rewardsBanner: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Keep up the great work!")
                    .font(.headline.weight(.black))
                    .foregroundStyle(AppTheme.roseDark)
                Text("Complete more orders and earn exciting rewards.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink)
                Button("View Rewards") {}
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.rose)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.line, lineWidth: 1))
            }
            Spacer()
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .symbolRenderingMode(.palette)
                .foregroundStyle(AppTheme.rose, AppTheme.roseSoft)
        }
        .padding(18)
        .background(AppTheme.roseSoft.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
    }

    private var periodBookings: [PartnerBooking] {
        store.completedBookings
            .filter { period.contains($0) }
            .sorted { $0.completedAtMillis > $1.completedAtMillis }
    }

    private var transactionRows: [(offset: Int, element: PartnerBooking)] {
        Array(periodBookings.prefix(5).enumerated())
    }

    private var periodTotal: Int {
        periodBookings.reduce(0) { $0 + $1.amount }
    }

    private func money(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return "Rs \(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
}

private enum EarningsPeriod: String, CaseIterable, Identifiable {
    case today
    case week
    case month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        }
    }

    var walletTitle: String {
        switch self {
        case .today: return "Daily Earnings"
        case .week: return "Weekly Earnings"
        case .month: return "Monthly Earnings"
        }
    }

    func contains(_ booking: PartnerBooking) -> Bool {
        let millis = booking.completedAtMillis > 0 ? booking.completedAtMillis : booking.createdAtMillis
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let calendar = Calendar.current
        switch self {
        case .today:
            return calendar.isDateInToday(date)
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return true }
            return interval.contains(date)
        case .month:
            let now = calendar.dateComponents([.year, .month], from: Date())
            let then = calendar.dateComponents([.year, .month], from: date)
            return now.year == then.year && now.month == then.month
        }
    }
}

private struct EarningsHeroCard: View {
    let title: String
    let amount: String
    let subtitle: String

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: 0xFFF1F6))
            EarningsSparkline()
                .frame(height: 82)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppTheme.roseDark)
                        Text(amount)
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(AppTheme.rose)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.ink)
                    }
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.rose)
                            .frame(width: 62, height: 62)
                            .background(Color(hex: 0xFFDDE8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        Text("View Wallet")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.roseDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().stroke(Color(hex: 0xDC7896), lineWidth: 1))
                    }
                }
                Spacer(minLength: 74)
            }
            .padding(18)
        }
        .frame(height: 220)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 8)
    }
}

private struct EarningsSparkline: View {
    private let values: [CGFloat] = [0.24, 0.34, 0.45, 0.39, 0.54, 0.48, 0.62, 0.58, 0.72]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let step = width / CGFloat(max(values.count - 1, 1))
            Path { path in
                for index in values.indices {
                    let x = CGFloat(index) * step
                    let y = height - values[index] * height
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(AppTheme.rose, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            Path { path in
                path.move(to: CGPoint(x: 0, y: height))
                for index in values.indices {
                    let x = CGFloat(index) * step
                    let y = height - values[index] * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [AppTheme.rose.opacity(0.18), AppTheme.rose.opacity(0.02)], startPoint: .top, endPoint: .bottom))
            ForEach(values.indices, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(AppTheme.rose, lineWidth: 2))
                    .frame(width: 8, height: 8)
                    .position(x: CGFloat(index) * step, y: height - values[index] * height)
            }
        }
    }
}

private struct EarningsLabelStyle: LabelStyle {
    let tint: Color
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            configuration.title
        }
    }
}

private struct EarningsBreakdownRow: View {
    let icon: String
    let iconTint: Color
    let iconBg: Color
    let title: String
    let amount: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(iconTint)
                .frame(width: 34, height: 34)
                .background(iconBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(amount)
                .font(.headline.weight(.black))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.vertical, 3)
    }
}

private struct EarningsTransactionRow: View {
    let title: String
    let amount: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(amount)
                .font(.headline.weight(.black))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.vertical, 8)
    }
}

struct PartnerMapScreen: View {
    @EnvironmentObject private var store: PartnerAppStore
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: AppConfig.defaultLatitude, longitude: AppConfig.defaultLongitude), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Navigation", subtitle: store.selectedBooking?.address ?? "", backAction: { store.screen = .detail })
            if let booking = store.selectedBooking {
                Map(coordinateRegion: $region, annotationItems: [booking]) { item in
                    MapMarker(coordinate: CLLocationCoordinate2D(latitude: item.lat, longitude: item.lng), tint: .red)
                }
                .onAppear {
                    region.center = CLLocationCoordinate2D(latitude: booking.lat, longitude: booking.lng)
                }
                VStack(spacing: 10) {
                    Button("Open in Apple Maps") {
                        store.openAppleMaps(booking)
                    }
                    .primaryButton()
                    Button("Back to Order") {
                        store.screen = .detail
                    }
                    .outlineButton()
                }
                .padding(18)
                .background(Color.white)
            } else {
                EmptyState(title: "No map target", subtitle: "Open a booking first.")
                    .padding(18)
            }
        }
    }
}

struct StaffManagementScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                title: "Laundry Staff",
                subtitle: "\(store.staffMembers.count) team members",
                backAction: { store.screen = .dashboard },
                trailingSystemImage: "arrow.clockwise"
            ) {
                Task {
                    await store.fetchRemoteProfile()
                    await store.fetchBookings()
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    approvalStatus
                    addStaffForm
                    staffList
                    assignmentList
                }
                .padding(18)
            }
        }
    }

    private var approvalStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: store.profile.approvalStatus == "approved" ? "checkmark.shield.fill" : "clock.badge.fill")
                .foregroundStyle(store.profile.approvalStatus == "approved" ? AppTheme.green : AppTheme.orange)
                .frame(width: 42, height: 42)
                .background(
                    (store.profile.approvalStatus == "approved" ? AppTheme.greenSoft : AppTheme.roseSoft),
                    in: Circle()
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(store.profile.laundryBusiness?.shopName.isEmpty == false ? store.profile.laundryBusiness?.shopName ?? "Laundry Business" : "Laundry Business")
                    .font(.headline.weight(.black))
                Text((store.profile.approvalStatus ?? "pending_review").replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var addStaffForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Staff Member")
                .font(.headline.weight(.black))
            TextField("Full name", text: $store.newStaffName)
                .textContentType(.name)
                .textFieldStyle(.roundedBorder)
            TextField("10-digit phone", text: $store.newStaffPhone)
                .keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
            TextField("Email optional", text: $store.newStaffEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
            Button(store.loading ? "Adding..." : "Add Laundry Staff") {
                store.addLaundryStaff()
            }
            .primaryButton()
            .disabled(store.loading)
            Text("Staff must sign in with this verified phone or email. Adding staff requires an approved Laundry business.")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
        .cardStyle()
    }

    private var staffList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Team")
            if store.staffMembers.isEmpty {
                EmptyState(title: "No staff added", subtitle: "Add a verified team member to assign Laundry orders.")
            } else {
                ForEach(store.staffMembers) { staff in
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.rose)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(staff.name)
                                .font(.subheadline.weight(.bold))
                            Text(staff.phone.isEmpty ? staff.email : staff.phone)
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }
                        Spacer()
                        Text(staff.online ? "Online" : "Offline")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(staff.online ? AppTheme.green : AppTheme.muted)
                    }
                    .cardStyle(padding: 12)
                }
            }
        }
    }

    private var assignmentList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Unassigned Orders")
            if store.unassignedLaundryBookings.isEmpty {
                EmptyState(title: "No orders to assign", subtitle: "Accepted Laundry orders waiting for staff appear here.")
            } else if store.staffMembers.isEmpty {
                EmptyState(title: "Add staff first", subtitle: "A team member is required before assigning an order.")
            } else {
                ForEach(store.unassignedLaundryBookings) { booking in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(booking.serviceName)
                                    .font(.headline.weight(.black))
                                Text(booking.displayId)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Spacer()
                            Text(booking.statusLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.rose)
                        }
                        Text(booking.address)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                        Menu {
                            ForEach(store.staffMembers) { staff in
                                Button(staff.name) {
                                    store.assign(booking, to: staff)
                                }
                            }
                        } label: {
                            Label("Assign Staff", systemImage: "person.badge.plus")
                                .primaryButton()
                        }
                    }
                    .cardStyle()
                }
            }
        }
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
                    if store.notifications.contains(where: { !$0.isRead }) {
                        Button("Mark All as Read") {
                            store.markAllNotificationsRead()
                        }
                        .outlineButton()
                    }
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
                        Text(store.role.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.rose)
                        Label(store.profile.faceVerified ? "Face verified" : "Verification pending", systemImage: store.profile.faceVerified ? "checkmark.shield.fill" : "shield")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(store.profile.faceVerified ? AppTheme.green : AppTheme.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    tool("Personal Information", "Phone updates and locked identity", "person.fill") { store.screen = .personalInfo }
                    if !store.role.isStaff {
                        tool("Documents", "ID proof and skill certificate", "folder.fill") { store.screen = .documents }
                        tool("My Services", "Services, radius and area", "slider.horizontal.3") { store.screen = .myServices }
                    }
                    if store.permissions.canManageStaff {
                        tool("Laundry Staff", "Add staff and assign orders", "person.3.fill") { store.screen = .staffManagement }
                    }
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
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Verified identity is locked", systemImage: "checkmark.shield.fill")
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppTheme.green)
                        lockedInfoRow("Partner name", value: store.profile.name.isEmpty ? "Partner" : store.profile.name, icon: "person.fill")
                        lockedInfoRow("Email", value: store.profile.email.isEmpty ? "Not added" : store.profile.email, icon: "envelope.fill")
                        TextField("Phone", text: $store.profile.phone)
                            .keyboardType(.phonePad)
                            .textFieldStyle(.roundedBorder)
                        Text("Profile photo and name can only be changed by ApnaServo verification support.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                        Button("Save Phone Number") {
                            store.profile.phone = store.profile.phone.filter(\.isNumber)
                            store.persistProfile()
                            Task { await store.syncPartnerProfile() }
                        }
                        .primaryButton()
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Live Backend")
                            .font(.headline.weight(.black))
                        Label("Connected to the same ApnaServo backend used by Android.", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.green)
                        Text("No manual token entry is required. Release builds use backend authentication; debug builds can use device-scoped headers only when the backend allows development fallback.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .cardStyle()
                }
                .padding(18)
            }
        }
    }

    private func lockedInfoRow(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.rose)
                .frame(width: 38, height: 38)
                .background(AppTheme.roseSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer()
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(12)
        .background(Color(hex: 0xFFF8FA), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
    }
}

struct DocumentsScreen: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Documents", subtitle: "Verification", backAction: { store.screen = .profile })
            ScrollView {
                VStack(spacing: 14) {
                    documentRow("ID Proof", "Upload government ID for verification", store.profile.faceVerified ? "Verified" : "Pending")
                    documentRow("Skill Certificate", "Upload service certificate", "Ready for upload")
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
                        Text("Camera/file picker hooks are ready. Add PhotosUI/DocumentPicker in Xcode and call APIClient.uploadDocument.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .cardStyle()
                }
                .padding(18)
            }
        }
    }

    private func documentRow(_ title: String, _ subtitle: String, _ status: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .foregroundStyle(AppTheme.rose)
                .frame(width: 40, height: 40)
                .background(AppTheme.roseSoft, in: Circle())
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
                .foregroundStyle(status == "Verified" ? AppTheme.green : AppTheme.orange)
        }
        .cardStyle()
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
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Array(store.profile.skills).sorted { $0.label < $1.label }) { skill in
                                Text(skill.label)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.rose)
                                    .padding(.vertical, 9)
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.roseSoft, in: Capsule())
                            }
                        }
                        Label("Services are locked after verification. Contact support to change them.", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Radius")
                            .font(.headline.weight(.black))
                        HStack {
                            Image(systemName: "target")
                                .foregroundStyle(AppTheme.blue)
                                .frame(width: 38, height: 38)
                                .background(Color(hex: 0xE8F3FF), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text("\(store.profile.serviceRadiusKm) km around \(store.profile.serviceArea)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }
                        Text("Radius is controlled by ApnaServo matching rules.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
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

                    Button("Save Service Area") {
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
                        store.infoMessage = "Backend endpoint ready: /partners/delete-account-request."
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
