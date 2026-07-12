import SwiftUI
import UIKit

struct UserAppView: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsFloatingFooter, let booking = store.latestBooking {
                FloatingBookingFooter(booking: booking)
                    .padding(.horizontal, 16)
                    .padding(.bottom, showsBottomNav ? 94 : 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBottomNav {
                BottomNav()
            }
        }
        .background(AppTheme.bg)
    }

    private var showsBottomNav: Bool {
        switch store.screen {
        case .home, .services, .detail, .track, .bookings, .notifications, .profile, .commercial:
            return true
        default:
            return false
        }
    }

    private var showsFloatingFooter: Bool {
        guard store.latestBooking != nil else { return false }
        switch store.screen {
        case .home, .services, .detail, .bookings, .profile, .notifications, .commercial:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch store.screen {
        case .splash:
            SplashScreen()
        case .login:
            LoginScreen()
        case .startupLocation:
            StartupLocationGateScreen()
        case .home:
            HomeScreen()
        case .services:
            AllServicesScreen()
        case .detail:
            ServiceDetailScreen()
        case .booking:
            BookingDetailsScreen()
        case .confirm:
            BookingConfirmScreen()
        case .bookingConfirmed:
            BookingConfirmedScreen()
        case .track:
            TrackBookingScreen()
        case .bookings:
            BookingsListScreen()
        case .notifications:
            NotificationsScreen()
        case .profile:
            ProfileScreen()
        case .support:
            SupportChatScreen()
        case .bookingChat:
            BookingChatView()
        case .commercial:
            CommercialServicesScreen()
        case .commercialFormOne:
            CommercialFormOneScreen()
        case .commercialFormTwo:
            CommercialFormTwoScreen()
        case .commercialSubmitted:
            CommercialStatusScreen(
                title: "Request Submitted",
                subtitle: "Commercial team will inspect your site.",
                icon: "checkmark.seal.fill",
                accent: AppTheme.green,
                primary: "Inspection Scheduled",
                next: .commercialInspection
            )
        case .commercialInspection:
            CommercialStatusScreen(
                title: "Inspection Visit",
                subtitle: "Our expert checks load, scope and site access.",
                icon: "person.text.rectangle.fill",
                accent: AppTheme.booking,
                primary: "View Quote",
                next: .commercialQuote
            )
        case .commercialQuote:
            CommercialStatusScreen(
                title: "Quote Ready",
                subtitle: "Approve the estimate after scope confirmation.",
                icon: "doc.text.fill",
                accent: AppTheme.orange,
                primary: "Approve Quote",
                next: .commercialApproved
            )
        case .commercialApproved:
            CommercialStatusScreen(
                title: "Approved",
                subtitle: "Team assignment and work plan are being prepared.",
                icon: "checkmark.circle.fill",
                accent: AppTheme.green,
                primary: "View Team",
                next: .commercialTeam
            )
        case .commercialTeam:
            CommercialStatusScreen(
                title: "Team Assigned",
                subtitle: "Supervisor and technician details are ready.",
                icon: "person.3.fill",
                accent: AppTheme.purple,
                primary: "Open Work Plan",
                next: .commercialPlan
            )
        case .commercialPlan:
            CommercialStatusScreen(
                title: "Work Plan",
                subtitle: "Milestones, visits and quality checks are listed.",
                icon: "calendar.badge.clock",
                accent: AppTheme.blue,
                primary: "Start Progress",
                next: .commercialProgress
            )
        case .commercialProgress:
            CommercialStatusScreen(
                title: "Work In Progress",
                subtitle: "Track stages and quality checks from this screen.",
                icon: "progress.indicator",
                accent: AppTheme.booking,
                primary: "Mark Completed",
                next: .commercialCompleted
            )
        case .commercialCompleted:
            CommercialStatusScreen(
                title: "Commercial Job Completed",
                subtitle: "Invoice, AMC and support actions appear here.",
                icon: "star.circle.fill",
                accent: AppTheme.green,
                primary: "Back Home",
                next: .home
            )
        }
    }
}

struct SplashScreen: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                .frame(width: 270, height: 96)
                .shadow(color: AppTheme.rose.opacity(0.22), radius: 18, y: 10)
            ProgressView()
                .tint(AppTheme.booking)
                .scaleEffect(1.15)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bg)
    }
}

struct LoginScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack(alignment: .bottomLeading) {
                        AndroidAssetImage(name: "login_home_repair_hero", contentMode: .fill)
                            .frame(height: min(430, proxy.size.height * 0.54))
                            .frame(maxWidth: .infinity)
                            .clipped()
                        LinearGradient(colors: [.clear, AppTheme.loginBg.opacity(0.95)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 10) {
                            AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                                .frame(width: 184, height: 57)
                            Text("Trusted Home Repair Services")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 0))

                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Trusted")
                                .foregroundStyle(AppTheme.ink)
                            Text("Home")
                                .foregroundStyle(AppTheme.ink)
                            Text("Repair")
                                .foregroundStyle(AppTheme.loginRose)
                            Text("Services")
                                .foregroundStyle(AppTheme.loginRose)
                        }
                        .font(.system(size: 40, weight: .black))
                        .lineSpacing(-4)

                        Text("Book verified experts for AC, plumber, electrician, laundry, cleaning, RO and roadside help.")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.muted)
                            .lineSpacing(3)

                        VStack(spacing: 10) {
                            loginButton("Continue with Email", systemImage: "envelope.fill") {
                                store.beginLogin("Email")
                            }
                            loginButton("Continue with Phone", systemImage: "phone.fill") {
                                store.beginLogin("Phone")
                            }
                            loginButton("Continue with Google", systemImage: "g.circle.fill") {
                                store.loginMode = "Email"
                                store.completeLogin(name: "ApnaServo Customer", value: "customer@apnaservo.app")
                            }
                        }

                        HStack(spacing: 10) {
                            trustPill("Verified experts")
                            trustPill("No upfront pay")
                            trustPill("Live tracking")
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppTheme.loginRose)
                                .frame(width: 48, height: 48)
                                .background(AppTheme.bookingSoft, in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your home is in safe hands")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)
                                Text("Same design language as Android: warm background, rose CTAs and compact cards.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                        .androidCard(padding: 14, radius: 18)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
            .background(AppTheme.loginBg)
            .ignoresSafeArea(edges: .top)
        }
    }

    private func loginButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 22)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(AppTheme.ink)
            .font(.system(size: 15, weight: .bold))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func trustPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AppTheme.loginRose)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.bookingSoft, in: Capsule())
    }
}

struct StartupLocationGateScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.roseSoft)
                    .frame(width: 210, height: 210)
                AndroidAssetImage(name: "ic_assam_jaapi", contentMode: .fit)
                    .frame(width: 142, height: 142)
            }
            VStack(spacing: 8) {
                Text("Enable service location")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                Text("ApnaServo uses your location to show nearby verified partners in Guwahati.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }
            Button("Use Current Location") {
                store.finishLocationGate()
            }
            .roseCTA()
            .padding(.horizontal, 24)
            Button("Enter Manually Later") {
                store.finishLocationGate()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            Spacer()
        }
        .background(AppTheme.bg)
    }
}

struct HomeScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                HomeHero()
                QuickServiceStrip()
                CommercialHomeCard()
                ServiceGridSection(title: "Popular Services", services: Array(store.services.prefix(6)))
                if !store.bookings.isEmpty {
                    RecentBookingSection()
                }
                ServiceGridSection(title: "More Services", services: Array(store.services.dropFirst(6)))
                WhyChooseCard()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 130)
        }
        .background(AppTheme.bg)
    }
}

struct HomeHero: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        ZStack(alignment: .top) {
            AndroidAssetImage(name: "hero_ro_background", contentMode: .fill)
                .frame(height: 326)
                .frame(maxWidth: .infinity)
                .clipped()
            LinearGradient(colors: [.black.opacity(0.42), .black.opacity(0.10), .black.opacity(0.55)], startPoint: .top, endPoint: .bottom)

            VStack(spacing: 14) {
                HStack(alignment: .center) {
                    AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                        .frame(width: 128, height: 42)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
                    Spacer()
                    Button {
                        store.navigate(.notifications)
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: 42, height: 42)
                            .background(.white, in: Circle())
                            .overlay(alignment: .topTrailing) {
                                if store.notifications.contains(where: { !$0.isRead }) {
                                    Circle().fill(AppTheme.booking).frame(width: 10, height: 10)
                                }
                            }
                    }
                }

                Button {
                    store.showAllServices()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                        Text("Search for AC, plumber, cleaning...")
                            .lineLimit(1)
                        Spacer()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.horizontal, 15)
                    .frame(height: 48)
                    .background(Color(hex: 0x111111).opacity(0.92), in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(alignment: .bottom, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("RO SERVICE")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                        Text("Filter - Leakage - Installation")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                        Text("Starts at Rs 299")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.booking.opacity(0.9), in: Capsule())
                    }
                    Spacer()
                    Button {
                        store.openService(ServiceCatalog.service(id: "ro"))
                    } label: {
                        Text("Book")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 86, height: 42)
                            .background(AppTheme.booking, in: RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 326)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 7)
    }
}

struct QuickServiceStrip: View {
    @EnvironmentObject private var store: UserAppStore
    private let quickIds = ["ac", "electrician", "plumbing", "appliances"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(quickIds, id: \.self) { id in
                let service = ServiceCatalog.service(id: id)
                Button {
                    store.openService(service)
                } label: {
                    VStack(spacing: 7) {
                        ServiceLogo(service: service, size: 44)
                        Text(service.id == "appliances" ? "Appliance" : service.name.components(separatedBy: " ").first ?? service.name)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CommercialHomeCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        Button {
            store.navigate(.commercial)
        } label: {
            ZStack(alignment: .leading) {
                AndroidAssetImage(name: "commercial_home_card", contentMode: .fill)
                    .frame(height: 126)
                    .frame(maxWidth: .infinity)
                    .clipped()
                LinearGradient(colors: [.black.opacity(0.56), .clear], startPoint: .leading, endPoint: .trailing)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Commercial Services")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                    Text("AC, plumbing and appliances for offices.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Explore")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(.white, in: Capsule())
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 9, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct ServiceGridSection: View {
    @EnvironmentObject private var store: UserAppStore
    let title: String
    let services: [ServiceItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: title, actionTitle: "View all") {
                store.showAllServices()
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(services) { service in
                    HomeServiceCard(service: service)
                }
            }
        }
    }
}

struct HomeServiceCard: View {
    @EnvironmentObject private var store: UserAppStore
    let service: ServiceItem

    var body: some View {
        Button {
            store.openService(service)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    AndroidAssetImage(name: serviceHomeAsset(service), contentMode: .fill)
                        .frame(height: 92)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text(service.rating)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppTheme.green, in: Capsule())
                        .padding(8)
                }
                Text(service.name)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .frame(minHeight: 34, alignment: .topLeading)
                HStack {
                    Text(service.priceLabel)
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(AppTheme.rose)
            }
            .androidCard(padding: 10, radius: 18, shadow: 3)
        }
        .buttonStyle(.plain)
    }
}

struct RecentBookingSection: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Recent Bookings", actionTitle: "View all") {
                store.navigate(.bookings)
            }
            ForEach(Array(store.bookings.prefix(2))) { booking in
                BookingHistoryCard(booking: booking)
            }
        }
    }
}

struct WhyChooseCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why choose ApnaServo?")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.ink)
            feature("Verified local partners", "Background checked experts for home services.")
            feature("No upfront payment", "Final amount is confirmed after inspection.")
            feature("Live booking status", "Finding partner, assigned and progress states match Android.")
        }
        .androidCard(padding: 16, radius: 20)
    }

    private func feature(_ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
        }
    }
}

struct AllServicesScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "All Services", subtitle: store.activeCategory, backAction: { store.back() })
            HStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(store.categories, id: \.self) { category in
                            CategoryRailButton(category: category)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 110)
                }
                .frame(width: 116)
                .background(Color(hex: 0xFFF1ED))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(store.filteredServices) { service in
                            ServiceListCard(service: service)
                        }
                    }
                    .padding(14)
                    .padding(.bottom, 120)
                }
            }
        }
        .background(AppTheme.bg)
    }
}

struct CategoryRailButton: View {
    @EnvironmentObject private var store: UserAppStore
    let category: String

    var body: some View {
        Button {
            store.activeCategory = category
        } label: {
            Text(category)
                .font(.system(size: 12, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(store.activeCategory == category ? .white : AppTheme.ink)
                .frame(width: 94, height: 58)
                .background(categoryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(store.activeCategory == category ? AppTheme.booking.opacity(0.3) : AppTheme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var categoryBackground: some View {
        if store.activeCategory == category {
            LinearGradient(colors: [AppTheme.rose, AppTheme.booking], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Color.white
        }
    }
}

struct ServiceListCard: View {
    @EnvironmentObject private var store: UserAppStore
    let service: ServiceItem

    var body: some View {
        Button {
            store.openService(service)
        } label: {
            HStack(spacing: 12) {
                AndroidAssetImage(name: serviceHomeAsset(service), contentMode: .fill)
                    .frame(width: 82, height: 82)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text(service.name)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                    Text(service.description)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Text(service.priceLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.booking)
                        Text(service.arrival)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.muted)
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.rose)
            }
            .androidCard(padding: 10, radius: 18, shadow: 2)
        }
        .buttonStyle(.plain)
    }
}

struct ServiceDetailScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: store.selectedService.name, subtitle: store.selectedService.category, backAction: { store.back() })
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    DetailHeroCard(service: store.selectedService)
                    DetailMetricRow(service: store.selectedService)
                    ServiceIncludesCard(service: store.selectedService)
                    GuaranteeStrip()
                }
                .padding(18)
                .padding(.bottom, 112)
            }
            Button("Book Slot") {
                store.startBooking(store.selectedService)
            }
            .darkCTA()
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            .background(AppTheme.bg)
        }
    }
}

struct DetailHeroCard: View {
    let service: ServiceItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AndroidAssetImage(name: service.id == "ac" ? "ac_repair_photo" : heroAsset(service), contentMode: .fill)
                .frame(height: 230)
                .frame(maxWidth: .infinity)
                .clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 7) {
                Text(bannerTitle(service))
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
                Text(bannerLine(service))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
    }
}

struct DetailMetricRow: View {
    let service: ServiceItem

    var body: some View {
        HStack(spacing: 10) {
            metric("Rating", service.rating, "star.fill", AppTheme.green)
            metric("Starts at", service.priceLabel, "indianrupeesign.circle.fill", AppTheme.booking)
            metric("Arrival", service.arrival, "clock.fill", AppTheme.blue)
        }
    }

    private func metric(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 18, weight: .bold))
            Text(value)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .androidCard(padding: 12, radius: 16)
    }
}

struct ServiceIncludesCard: View {
    let service: ServiceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Includes")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text(service.description)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
            include("Problem inspection and diagnosis")
            include("Verified nearby service partner")
            include("Clear quote before paid work")
            include("Booking chat and live status updates")
        }
        .androidCard(padding: 16, radius: 20)
    }

    private func include(_ text: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.green)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
        }
    }
}

struct GuaranteeStrip: View {
    var body: some View {
        HStack(spacing: 10) {
            guarantee("No upfront", "Pay after quote", "creditcard.fill")
            guarantee("Safe", "Verified partner", "shield.fill")
        }
    }

    private func guarantee(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.booking)
                .frame(width: 34, height: 34)
                .background(AppTheme.bookingSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .black))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
        }
        .androidCard(padding: 12, radius: 16)
    }
}

struct BookingDetailsScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Booking Details", subtitle: "Secure booking", backAction: { store.back() }, trailingTitle: "Secure") {}
            BookingStepper(current: 2)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    BookingSelectedServiceCard()
                    ProblemDetailsCard()
                    DateTimeCard()
                    AddressSelectionCard()
                    Button("Confirm Booking") {
                        store.continueToConfirm()
                    }
                    .roseCTA()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.bg)
    }
}

struct BookingSelectedServiceCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: store.selectedService, size: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.selectedService.name)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                Text("\(store.selectedService.priceLabel) onwards - \(store.selectedService.arrival)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Text("STEP 2")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(AppTheme.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(AppTheme.greenSoft, in: Capsule())
        }
        .androidCard(padding: 14, radius: 18)
    }
}

struct ProblemDetailsCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tell us the issue")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(AppTheme.ink)
            TextField("Example: water leakage, cooling not working...", text: $store.draft.problem, axis: .vertical)
                .lineLimit(4...7)
                .font(.system(size: 14))
                .padding(12)
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
            Text("\(store.draft.problem.count)/500")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .androidCard(padding: 16, radius: 20)
    }
}

struct DateTimeCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AndroidAssetImage(name: "booking_icon_date_time", contentMode: .fit)
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date & Time")
                        .font(.system(size: 17, weight: .black))
                    Text("Choose a convenient slot")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            HStack(spacing: 10) {
                selector(title: store.draft.date.isEmpty ? "Select date" : store.draft.date, image: "booking_icon_date") {
                    store.showDateSheet = true
                }
                selector(title: store.draft.time.isEmpty ? "Select time" : store.draft.time, image: "booking_icon_time") {
                    store.showTimeSheet = true
                }
            }
            Text("Partners accept slots based on nearby availability. No upfront payment is collected.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
        }
        .androidCard(padding: 16, radius: 20)
    }

    private func selector(title: String, image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AndroidAssetImage(name: image, contentMode: .fit)
                    .frame(width: 34, height: 34)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 34)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct AddressSelectionCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                AndroidAssetImage(name: "booking_icon_service_address", contentMode: .fit)
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Service Address")
                        .font(.system(size: 17, weight: .black))
                    Text("Current location or manual address")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            HStack(spacing: 10) {
                addressModeButton(.current, title: "Current", image: "booking_icon_current_location")
                addressModeButton(.manual, title: "Manual", image: "booking_icon_manual_address")
            }

            if store.addressMode == .current {
                currentAddressFields
            } else {
                manualAddressFields
            }

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "shield.fill")
                    .foregroundStyle(AppTheme.green)
                Text("For safety, share the exact house/flat and landmark before confirming.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(12)
            .background(AppTheme.greenSoft, in: RoundedRectangle(cornerRadius: 14))
        }
        .androidCard(padding: 16, radius: 20)
    }

    private func addressModeButton(_ mode: BookingAddressMode, title: String, image: String) -> some View {
        Button {
            if mode == .current {
                store.useCurrentLocation()
            } else {
                store.useManualAddress()
            }
        } label: {
            HStack(spacing: 8) {
                AndroidAssetImage(name: image, contentMode: .fit)
                    .frame(width: 28, height: 28)
                Text(title)
                    .font(.system(size: 13, weight: .black))
                Spacer()
                Image(systemName: store.addressMode == mode ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(store.addressMode == mode ? AppTheme.booking : AppTheme.ink)
            .padding(12)
            .background(store.addressMode == mode ? AppTheme.bookingSoft : AppTheme.bg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(store.addressMode == mode ? AppTheme.booking : AppTheme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var currentAddressFields: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                formField("House / Flat", text: $store.houseFlat)
                formField("Floor", text: $store.floor)
            }
            formField("Building / Area", text: $store.building)
            formField("Landmark", text: $store.landmark)
            Button {
                store.useCurrentLocation()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text(store.draft.hasLocation ? store.draft.address : "Detect current location")
                    Spacer()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.booking)
                .padding(12)
                .background(AppTheme.bookingSoft, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            MockMapPreview()
        }
    }

    private var manualAddressFields: some View {
        VStack(spacing: 10) {
            formField("House / Flat", text: $store.houseFlat)
            formField("Building / Street", text: $store.building)
            formField("Full address", text: $store.draft.address)
            HStack(spacing: 10) {
                formField("City", text: $store.city)
                formField("State", text: $store.state)
            }
            formField("PIN code", text: $store.pinCode, keyboard: .numberPad)
        }
    }

    private func formField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.line, lineWidth: 1))
    }
}

struct MockMapPreview: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE5F2EC), Color(hex: 0xFDF7F2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.booking)
                Text("Ganeshguri, Guwahati")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                Text("Map preview placeholder")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .frame(height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.line, lineWidth: 1))
    }
}

struct BookingConfirmScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Confirm Booking", subtitle: store.selectedService.name, backAction: { store.back() })
            BookingStepper(current: 3)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        summaryRow("Service", store.selectedService.name)
                        summaryRow("Issue", store.draft.problem.isEmpty ? "Service request" : store.draft.problem)
                        summaryRow("Date & Time", "\(store.draft.date), \(store.draft.time)")
                        summaryRow("Address", store.bookingAddressPreview())
                        summaryRow("Service Tier", store.draft.tier.rawValue)
                        summaryRow("Estimated Start", store.selectedService.priceLabel)
                    }
                    .androidCard(padding: 16, radius: 20)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(AppTheme.booking)
                            Text("No upfront payment")
                                .font(.system(size: 17, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                        }
                        Text("Partner will inspect the issue and share the final amount inside ApnaServo before payment.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .androidCard(padding: 16, radius: 20, border: AppTheme.bookingSoft)

                    HStack(spacing: 10) {
                        Button("Edit Date") {
                            store.showDateSheet = true
                        }
                        .outlineCTA()
                        Button("Edit Address") {
                            store.navigate(.booking)
                        }
                        .outlineCTA()
                    }

                    Button(store.isBookingSubmitting ? "Confirming..." : "Confirm Booking") {
                        store.confirmBooking()
                    }
                    .roseCTA()
                    .disabled(store.isBookingSubmitting)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AppTheme.muted)
            Text(value.isEmpty ? "Not added" : value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BookingConfirmedScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Booking Confirmed", subtitle: store.latestBooking?.displayId ?? "", backAction: { store.navigate(.home) })
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    successHeader
                    if let booking = store.latestBooking {
                        BookingHistoryCard(booking: booking)
                        if booking.status == "pending" {
                            FindingPartnerCard()
                        } else {
                            PartnerAssignedCard(booking: booking)
                        }
                        Button("View Booking Status") {
                            store.openTrack(booking)
                        }
                        .darkCTA()
                    } else {
                        EmptyState(title: "No booking found", subtitle: "Your confirmed booking will appear here.")
                    }
                }
                .padding(18)
            }
        }
        .task {
            store.startBookingPolling()
        }
    }

    private var successHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.greenSoft)
                    .frame(width: 92, height: 92)
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(AppTheme.green)
            }
            Text("Your request is confirmed")
                .font(.system(size: 23, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text("We are searching nearby verified partners. This screen updates automatically when a partner accepts your booking.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .androidCard(padding: 18, radius: 22)
    }
}

struct FindingPartnerCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().stroke(AppTheme.bookingSoft, lineWidth: 18).frame(width: 130, height: 130)
                Circle().stroke(AppTheme.booking.opacity(0.28), lineWidth: 9).frame(width: 96, height: 96)
                ProgressView()
                    .tint(AppTheme.booking)
                    .scaleEffect(1.35)
                Image(systemName: "location.north.fill")
                    .foregroundStyle(AppTheme.booking)
                    .offset(x: 42, y: -36)
            }
            Text("Finding best partner")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text("Request sent to nearby verified experts. We will notify you as soon as a partner accepts.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .androidCard(padding: 18, radius: 22, border: AppTheme.bookingSoft)
    }
}

struct PartnerAssignedCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Text(String(booking.partnerName.prefix(1)))
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(AppTheme.green, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.partnerName)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                    Text("Verified expert - 4.8 rating")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Text("ASSIGNED")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppTheme.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppTheme.greenSoft, in: Capsule())
            }
            HStack(spacing: 10) {
                Label("Call", systemImage: "phone.fill")
                    .outlineCTA()
                Label("Chat", systemImage: "message.fill")
                    .outlineCTA()
            }
        }
        .androidCard(padding: 16, radius: 20, border: AppTheme.greenSoft)
    }
}

struct TrackBookingScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Track Booking", subtitle: store.latestBooking?.displayId ?? "", backAction: { store.navigate(.home) })
            ScrollView(showsIndicators: false) {
                if let booking = store.latestBooking {
                    VStack(spacing: 16) {
                        BookingStatusHeader(booking: booking)
                        if booking.isAssigned {
                            PartnerAssignedCard(booking: booking)
                        } else {
                            FindingPartnerCard()
                        }
                        BookingProgressTimeline(booking: booking)
                        MockLiveMapCard(booking: booking)
                        if booking.isAmountApprovalPending {
                            AmountApprovalCard(booking: booking)
                        }
                        HStack(spacing: 10) {
                            Button("Chat") {
                                store.openBookingChat(booking)
                            }
                            .outlineCTA()
                            Button("Refresh Status") {
                                Task {
                                    await store.refreshLatestBooking()
                                }
                            }
                            .outlineCTA()
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 110)
                } else {
                    EmptyState(title: "No active booking", subtitle: "Book a service to start tracking.")
                        .padding(18)
                }
            }
        }
        .task {
            store.startBookingPolling()
        }
    }
}

struct BookingStatusHeader: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.serviceName)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                    Text(booking.displayId)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                StatusChip(status: booking.status)
            }
            Text(booking.issue)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
            HStack {
                info("Slot", booking.slot)
                info("Amount", booking.amount > 0 ? "Rs \(booking.amount)" : "After quote")
            }
        }
        .androidCard(padding: 16, radius: 20)
    }

    private func info(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BookingProgressTimeline: View {
    let booking: Booking
    private let steps = [
        ("pending", "Finding Partner"),
        ("accepted", "Assigned"),
        ("on_the_way", "On The Way"),
        ("arrived", "Arrived"),
        ("started", "Started"),
        ("completed", "Completed")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Progress")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.ink)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                timelineRow(title: step.1, active: index <= activeIndex, isLast: index == steps.count - 1)
            }
        }
        .androidCard(padding: 16, radius: 20)
    }

    private var activeIndex: Int {
        if booking.status == "amount_pending" { return 4 }
        return steps.firstIndex { $0.0 == booking.status } ?? 0
    }

    private func timelineRow(title: String, active: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Circle()
                    .fill(active ? AppTheme.green : AppTheme.line)
                    .frame(width: 18, height: 18)
                if !isLast {
                    Rectangle()
                        .fill(active ? AppTheme.green : AppTheme.line)
                        .frame(width: 2, height: 24)
                }
            }
            Text(title)
                .font(.system(size: 13, weight: active ? .black : .semibold))
                .foregroundStyle(active ? AppTheme.ink : AppTheme.muted)
            Spacer()
        }
    }
}

struct MockLiveMapCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live Location")
                .font(.system(size: 18, weight: .black))
            ZStack {
                LinearGradient(colors: [Color(hex: 0xE7F2EA), Color(hex: 0xFFF5F1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.green)
                    Text(booking.address)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding()
            }
            .frame(height: 148)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.line, lineWidth: 1))
        }
        .androidCard(padding: 16, radius: 20)
    }
}

struct AmountApprovalCard: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount approval required")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text(booking.quoteStatus == "payment_submitted" ? "Waiting for partner payment verification." : "Partner shared the final amount after inspection.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
            HStack {
                Text("Rs \(booking.amount)")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(AppTheme.booking)
                Spacer()
                Button(booking.quoteStatus == "payment_submitted" ? "Waiting" : "Paid to Partner") {
                    store.approveAmount()
                }
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 42)
                .background(AppTheme.green, in: RoundedRectangle(cornerRadius: 14))
                .disabled(booking.quoteStatus == "payment_submitted")
            }
        }
        .androidCard(padding: 16, radius: 20, border: AppTheme.bookingSoft)
    }
}

struct BookingsListScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var filter = "All"
    private let filters = ["All", "Pending", "Ongoing", "Completed", "Cancelled"]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "My Bookings", subtitle: "\(store.bookings.count) total", backAction: { store.navigate(.home) })
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    bookingsSummary
                    filterBar
                    if filteredBookings.isEmpty {
                        EmptyState(title: "No bookings", subtitle: "Bookings matching this status will appear here.")
                    } else {
                        ForEach(filteredBookings) { booking in
                            BookingHistoryCard(booking: booking)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 114)
            }
        }
    }

    private var bookingsSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent bookings")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                Text("\(store.activeBookings.count) active right now")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Image(systemName: "list.bullet.rectangle.fill")
                .foregroundStyle(AppTheme.booking)
                .frame(width: 50, height: 50)
                .background(AppTheme.bookingSoft, in: Circle())
        }
        .androidCard(padding: 16, radius: 20)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { value in
                    Button(value) {
                        filter = value
                    }
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(filter == value ? .white : AppTheme.ink)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(filter == value ? AppTheme.booking : Color.white, in: Capsule())
                    .overlay(Capsule().stroke(filter == value ? AppTheme.booking : AppTheme.line, lineWidth: 1))
                }
            }
        }
    }

    private var filteredBookings: [Booking] {
        switch filter {
        case "Pending":
            return store.bookings.filter { $0.status == "pending" }
        case "Ongoing":
            return store.bookings.filter { !["pending", "completed", "cancelled", "rejected"].contains($0.status) }
        case "Completed":
            return store.bookings.filter { $0.status == "completed" }
        case "Cancelled":
            return store.bookings.filter { ["cancelled", "rejected"].contains($0.status) }
        default:
            return store.bookings
        }
    }
}

struct BookingHistoryCard: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking

    var body: some View {
        Button {
            store.openTrack(booking)
        } label: {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(statusColor(booking.status))
                    .frame(width: 5)
                    .clipShape(Capsule())
                ServiceLogo(service: ServiceCatalog.service(id: booking.serviceCategory), size: 54)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(booking.serviceName)
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Spacer()
                        StatusChip(status: booking.status)
                    }
                    Text(booking.displayId)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                    Text(booking.slot)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(1)
                }
            }
            .androidCard(padding: 12, radius: 18, border: AppTheme.line, shadow: 2)
        }
        .buttonStyle(.plain)
    }
}

struct NotificationsScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Messages", subtitle: "Notifications and updates", backAction: { store.navigate(.home) }, trailingTitle: "Mark all") {
                store.markAllNotificationsRead()
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if store.notifications.isEmpty {
                        EmptyState(title: "No messages", subtitle: "Booking alerts and partner updates will appear here.")
                    } else {
                        ForEach(store.notifications) { item in
                            NotificationRow(item: item)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 112)
            }
        }
    }
}

struct NotificationRow: View {
    @EnvironmentObject private var store: UserAppStore
    let item: AppNotificationItem

    var body: some View {
        Button {
            store.openNotification(item)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.isRead ? "bell" : "bell.fill")
                    .foregroundStyle(item.isRead ? AppTheme.muted : AppTheme.booking)
                    .frame(width: 38, height: 38)
                    .background(item.isRead ? AppTheme.bg : AppTheme.bookingSoft, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                    Text(item.body)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                if !item.isRead {
                    Circle().fill(AppTheme.booking).frame(width: 9, height: 9)
                }
            }
            .androidCard(padding: 14, radius: 18)
        }
        .buttonStyle(.plain)
    }
}

struct ProfileScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Profile", subtitle: "Account and settings", backAction: { store.navigate(.home) }, trailingIcon: "gearshape.fill") {
                store.showSettingsSheet = true
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    profileHero
                    profileAction("Edit Profile", "Name, phone and email", "person.crop.circle.fill") {
                        store.showEditProfileSheet = true
                    }
                    profileAction("My Bookings", "Track active and past bookings", "list.bullet.rectangle.fill") {
                        store.navigate(.bookings)
                    }
                    profileAction("Saved Addresses", "Home and service locations", "house.fill") {
                        store.toastMessage = store.profile.address.isEmpty ? "No saved address yet." : store.profile.address
                    }
                    profileAction("Payments", "No upfront payment enabled", "creditcard.fill") {
                        store.paymentInfoExpanded.toggle()
                    }
                    if store.paymentInfoExpanded {
                        Text("Final payment is shown only after partner inspection and customer approval.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .androidCard(padding: 12, radius: 14)
                    }
                    profileAction("Help & Support", "Chat with ApnaServo support", "questionmark.circle.fill") {
                        store.navigate(.support)
                    }
                    profileAction("Legal & Account", "Privacy, terms and deletion", "shield.fill") {
                        store.showLegalSheet = true
                    }
                    profileAction("About ApnaServo", "Trusted home repair services", "info.circle.fill") {
                        store.aboutInfoExpanded.toggle()
                    }
                    if store.aboutInfoExpanded {
                        Text("Your profile, bookings, support chats, and service updates stay connected with the ApnaServo backend.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .androidCard(padding: 12, radius: 14)
                    }
                    Button("Logout") {
                        store.logout()
                    }
                    .outlineCTA()
                }
                .padding(18)
                .padding(.bottom, 114)
            }
        }
    }

    private var profileHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(profileInitial)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(AppTheme.booking, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.profile.name.isEmpty ? "ApnaServo Customer" : store.profile.name)
                        .font(.system(size: 21, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                    Text(store.profile.phone.isEmpty ? "Phone not shared" : store.profile.phone)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                    Text("Bookings, addresses and support in one place")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            HStack(spacing: 10) {
                profileStat("Bookings", "\(store.bookings.count)")
                profileStat("Active", "\(store.activeBookings.count)")
                profileStat("City", AppConfig.defaultCity)
            }
        }
        .androidCard(padding: 16, radius: 22, border: AppTheme.roseSoft, shadow: 4)
    }

    private var profileInitial: String {
        String((store.profile.name.isEmpty ? "A" : store.profile.name).prefix(1)).uppercased()
    }

    private func profileStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 13))
    }

    private func profileAction(_ title: String, _ subtitle: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.bookingSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
            }
            .androidCard(padding: 14, radius: 17, shadow: 1)
        }
        .buttonStyle(.plain)
    }
}

struct SupportChatScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Support Chat", subtitle: "24x7 help", backAction: { store.navigate(.profile) })
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(store.supportMessages) { message in
                            ChatMessageBubble(message: message, isMe: message.senderRole == "user")
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
            ChatInputDock(placeholder: "Type message", text: $text) {
                store.sendSupportMessage(text)
                text = ""
            }
        }
    }
}

struct CommercialServicesScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Commercial Services", subtitle: "Offices, shops and buildings", backAction: { store.navigate(.home) })
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ZStack(alignment: .bottomLeading) {
                        AndroidAssetImage(name: "commercial_page_hero", contentMode: .fill)
                            .frame(height: 226)
                            .frame(maxWidth: .infinity)
                            .clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Commercial care by ApnaServo")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(.white)
                            Text("Inspection, quote, approval, team, plan and progress tracking.")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                        .padding(18)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    commercialCard("Commercial AC Service", "Scheduled AC service for office floors.", "hero_banner_ac", "ac")
                    commercialCard("Commercial Plumbing", "Leakage, washroom and water line support.", "commercial_plumbing", "plumbing")
                    commercialCard("Commercial Appliances", "Repair and maintenance for workplace appliances.", "commercial_appliances", "appliances")
                }
                .padding(18)
                .padding(.bottom, 114)
            }
        }
    }

    private func commercialCard(_ title: String, _ subtitle: String, _ image: String, _ id: String) -> some View {
        Button {
            store.openCommercialService(title, serviceId: id)
        } label: {
            HStack(spacing: 12) {
                AndroidAssetImage(name: image, contentMode: .fill)
                    .frame(width: 92, height: 82)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.booking)
            }
            .androidCard(padding: 12, radius: 18)
        }
        .buttonStyle(.plain)
    }
}

struct CommercialFormOneScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var company = ""
    @State private var contact = ""
    @State private var phone = ""

    var body: some View {
        CommercialFormShell(title: "Commercial Details", subtitle: store.selectedCommercialServiceTitle, back: { store.back() }) {
            FormField("Business / Company", text: $company)
            FormField("Contact Person", text: $contact)
            FormField("Mobile Number", text: $phone, keyboard: .phonePad)
            InfoNote(text: "This mirrors Android commercial form step one. Data stays local in this frontend build.")
            Button("Continue") {
                store.navigate(.commercialFormTwo)
            }
            .roseCTA()
        }
    }
}

struct CommercialFormTwoScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var address = ""
    @State private var scope = ""
    @State private var preferredTime = ""

    var body: some View {
        CommercialFormShell(title: "Site & Scope", subtitle: store.selectedCommercialServiceTitle, back: { store.back() }) {
            FormField("Site Address", text: $address)
            FormField("Work Scope", text: $scope)
            FormField("Preferred Inspection Time", text: $preferredTime)
            InfoNote(text: "Inspection request will be shared with the ApnaServo operations team.")
            Button("Submit Request") {
                store.navigate(.commercialSubmitted)
            }
            .roseCTA()
        }
    }
}

struct CommercialFormShell<Content: View>: View {
    let title: String
    let subtitle: String
    let back: () -> Void
    let content: Content

    init(title: String, subtitle: String, back: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.back = back
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: title, subtitle: subtitle, backAction: back)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .padding(18)
            }
        }
        .background(AppTheme.bg)
    }
}

struct CommercialStatusScreen: View {
    @EnvironmentObject private var store: UserAppStore
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let primary: String
    let next: UserScreen

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: title, subtitle: store.selectedCommercialServiceTitle, backAction: { store.back() })
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(accent)
                            .frame(width: 92, height: 92)
                            .background(accent.opacity(0.13), in: Circle())
                        Text(title)
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(AppTheme.ink)
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .androidCard(padding: 20, radius: 22)

                    CommercialTimeline(current: title)

                    Button(primary) {
                        store.navigate(next)
                    }
                    .roseCTA()
                }
                .padding(18)
            }
        }
    }
}

struct CommercialTimeline: View {
    let current: String
    private let stages = ["Request Submitted", "Inspection Visit", "Quote Ready", "Approved", "Team Assigned", "Work Plan", "Work In Progress", "Commercial Job Completed"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Commercial Flow")
                .font(.system(size: 17, weight: .black))
            ForEach(stages, id: \.self) { stage in
                HStack {
                    Circle()
                        .fill(stage == current ? AppTheme.booking : AppTheme.line)
                        .frame(width: 10, height: 10)
                    Text(stage)
                        .font(.system(size: 12, weight: stage == current ? .black : .semibold))
                        .foregroundStyle(stage == current ? AppTheme.ink : AppTheme.muted)
                    Spacer()
                }
            }
        }
        .androidCard(padding: 16, radius: 18)
    }
}

struct FormField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    init(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.keyboard = keyboard
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
    }
}

struct InfoNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.booking)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
            Spacer()
        }
        .androidCard(padding: 12, radius: 14)
    }
}

struct FloatingBookingFooter: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var hidden = false
    let booking: Booking

    var body: some View {
        if !hidden {
            HStack(spacing: 12) {
                ServiceLogo(service: ServiceCatalog.service(id: booking.serviceCategory), size: 50)
                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.serviceName)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text(booking.statusTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Button("Track") {
                    store.openTrack(booking)
                }
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 88, height: 42)
                .background(AppTheme.booking, in: RoundedRectangle(cornerRadius: 15))
                Button {
                    hidden = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: 34, height: 42)
                }
            }
            .padding(10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.line, lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        }
    }
}

struct StatusChip: View {
    let status: String

    var body: some View {
        Text(statusTitle(status))
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(statusColor(status).opacity(0.12), in: Capsule())
    }
}

func statusTitle(_ status: String) -> String {
    switch status {
    case "pending": return "PENDING"
    case "accepted": return "ASSIGNED"
    case "on_the_way": return "ON WAY"
    case "arrived": return "ARRIVED"
    case "started": return "STARTED"
    case "amount_pending": return "AMOUNT"
    case "completed": return "DONE"
    case "cancelled": return "CANCELLED"
    case "rejected": return "REJECTED"
    default: return status.uppercased()
    }
}

func statusColor(_ status: String) -> Color {
    switch status {
    case "completed": return AppTheme.green
    case "accepted", "on_the_way", "arrived", "started": return AppTheme.blue
    case "amount_pending": return AppTheme.orange
    case "cancelled", "rejected": return AppTheme.muted
    default: return AppTheme.booking
    }
}
