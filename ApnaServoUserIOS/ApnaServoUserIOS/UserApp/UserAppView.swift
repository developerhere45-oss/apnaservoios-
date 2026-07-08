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
        .onAppear {
            store.startLiveBookingSync()
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
        case .bookings:
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
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HomeHero()
                    QuickServiceStrip()
                    CommercialHomeCard()
                    ServiceGridSection(title: "Popular Services", services: Array(store.services.prefix(6)))
                    ServiceGridSection(title: "More Services", services: Array(store.services.dropFirst(6)))
                    WhyChooseCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 128)
                .frame(width: proxy.size.width, alignment: .top)
            }
        }
        .background(AppTheme.bg)
    }
}

private struct HomeHeroSlide {
    let serviceId: String
    let asset: String
    let eyebrow: String
    let title: String
    let line: String
}

struct HomeHero: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var selectedSlide = 0
    private let slideTimer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()
    private let slides = [
        HomeHeroSlide(serviceId: "ac", asset: "banner_ac_service", eyebrow: "VERIFIED SERVICE", title: "AC REPAIR", line: "Inspection - Cleaning - Gas refill"),
        HomeHeroSlide(serviceId: "plumbing", asset: "banner_plumbing_service", eyebrow: "FAST HOME CARE", title: "PLUMBER", line: "Tap - Leakage - Water line repair"),
        HomeHeroSlide(serviceId: "electrician", asset: "banner_electrician_service", eyebrow: "TRUSTED EXPERTS", title: "ELECTRICIAN", line: "Wiring - Switchboard - Fan repair"),
        HomeHeroSlide(serviceId: "cleaning", asset: "banner_cleaning_service", eyebrow: "CLEAN & SAFE", title: "CLEANING", line: "Home - Bathroom - Deep cleaning")
    ]

    private var currentSlide: HomeHeroSlide {
        slides[selectedSlide % slides.count]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                AndroidAssetImage(name: currentSlide.asset, contentMode: .fill)
                    .id(currentSlide.asset)
                    .frame(width: proxy.size.width, height: 398)
                    .clipped()
                    .transition(.opacity)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.82),
                        Color.white.opacity(0.45),
                        AppTheme.bg.opacity(0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomLeading
                )
                .frame(width: proxy.size.width, height: 398)

                VStack(spacing: 12) {
                    HStack {
                        AndroidAssetImage(name: "ic_assam_jaapi", contentMode: .fit)
                            .frame(width: 42, height: 42)

                        Spacer(minLength: 8)

                        AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                            .frame(width: min(184, proxy.size.width * 0.52), height: 54)

                        Spacer(minLength: 8)

                        Button {
                            store.navigate(.notifications)
                        } label: {
                            AndroidAssetImage(name: "ic_assam_jaapi", contentMode: .fit)
                                .frame(width: 42, height: 42)
                                .overlay(alignment: .topTrailing) {
                                    if store.notifications.contains(where: { !$0.isRead }) {
                                        Circle().fill(AppTheme.booking).frame(width: 9, height: 9)
                                    }
                                }
                        }
                        .contentShape(Circle())
                    }

                    Text("Home services at your doorstep")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Button {
                        store.showAllServices()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(AppTheme.rose)
                                .frame(width: 24)
                            Text("Search for services (AC repair, plumber...)")
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Rectangle()
                                .fill(AppTheme.line)
                                .frame(width: 1, height: 30)
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(AppTheme.rose)
                                .frame(width: 24)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                        .padding(.horizontal, 16)
                        .frame(width: proxy.size.width - 28, height: 58)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.rose.opacity(0.72), lineWidth: 1.5))
                        .shadow(color: AppTheme.booking.opacity(0.16), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        Text(currentSlide.eyebrow)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.rose)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentSlide.title)
                                .font(.system(size: 33, weight: .bold))
                                .foregroundStyle(AppTheme.ink.opacity(0.82))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text(currentSlide.line)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.ink.opacity(0.68))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        Button {
                            store.openService(ServiceCatalog.service(id: currentSlide.serviceId))
                        } label: {
                            HStack(spacing: 8) {
                                Text("Book Slot")
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 126, height: 48)
                            .background(Color(hex: 0x11141A), in: Capsule())
                                .overlay(Capsule().stroke(AppTheme.booking, lineWidth: 1))
                                .shadow(color: AppTheme.booking.opacity(0.28), radius: 6, y: 3)
                        }

                        HStack(spacing: 8) {
                            ForEach(0..<slides.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedSlide ? AppTheme.ink.opacity(0.78) : AppTheme.line)
                                    .frame(width: index == selectedSlide ? 8 : 7, height: index == selectedSlide ? 8 : 7)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: proxy.size.width - 28)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
            .frame(width: proxy.size.width, height: 398)
        }
        .frame(height: 398)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 13, y: 7)
        .onReceive(slideTimer) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                selectedSlide = (selectedSlide + 1) % slides.count
            }
        }
    }
}

struct QuickServiceStrip: View {
    @EnvironmentObject private var store: UserAppStore
    private let quickIds = ["ac", "electrician", "plumbing", "cleaning", "appliances"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(quickIds, id: \.self) { id in
                let service = ServiceCatalog.service(id: id)
                Button {
                    store.openService(service)
                } label: {
                    VStack(spacing: 8) {
                        ServiceLogo(service: service, size: 52)
                        Text(quickTitle(for: service))
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                            .frame(height: 30)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.roseSoft, lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
    }

    private func quickTitle(for service: ServiceItem) -> String {
        switch service.id {
        case "ac": return "AC Repair"
        case "electrician": return "Electric"
        case "plumbing": return "Plumber"
        case "cleaning": return "Cleaning\nServices"
        case "appliances": return "Appliance"
        default: return service.name
        }
    }
}

struct CommercialHomeCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        GeometryReader { proxy in
            Button {
                store.navigate(.commercial)
            } label: {
                ZStack(alignment: .leading) {
                    AndroidAssetImage(name: "commercial_home_card", contentMode: .fill)
                        .frame(width: proxy.size.width, height: 172)
                        .clipped()
                    LinearGradient(
                        colors: [AppTheme.bg.opacity(0.94), AppTheme.bg.opacity(0.63), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width, height: 172)
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 10) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppTheme.bookingDark)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.bookingSoft, in: RoundedRectangle(cornerRadius: 14))
                            Text("COMMERCIAL\nSERVICES")
                                .font(.system(size: 23, weight: .bold))
                                .foregroundStyle(AppTheme.bookingDark.opacity(0.78))
                                .lineSpacing(-2)
                                .minimumScaleFactor(0.85)
                        }
                        Text("Offices, shops, hotels, warehouses & more.")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(AppTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        HStack(spacing: 12) {
                            Label("Professional team", systemImage: "checkmark")
                            Label("On-time service", systemImage: "clock.fill")
                        }
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(AppTheme.bookingDark.opacity(0.72))
                        Text("Business Enquiry")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 148, height: 40)
                            .background(
                                LinearGradient(colors: [AppTheme.bookingDark, AppTheme.booking], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                            .shadow(color: AppTheme.booking.opacity(0.20), radius: 8, y: 4)
                    }
                    .padding(.leading, 16)
                    .padding(.vertical, 14)
                    .frame(width: proxy.size.width, alignment: .leading)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.line, lineWidth: 1))
                .shadow(color: .black.opacity(0.14), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 172)
    }
}

struct ServiceGridSection: View {
    @EnvironmentObject private var store: UserAppStore
    let title: String
    let services: [ServiceItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.ink.opacity(0.9))
                Spacer()
                Button("View all") {
                    store.showAllServices()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.rose)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 13), count: 3),
                alignment: .center,
                spacing: 22
            ) {
                ForEach(services) { service in
                    HomeServiceCard(service: service)
                }
            }
            .padding(14)
            .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.roseSoft, lineWidth: 1.1))
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
            VStack(spacing: 10) {
                GeometryReader { proxy in
                    AndroidAssetImage(name: serviceHomeAsset(service), contentMode: .fill)
                        .frame(width: proxy.size.width, height: 78)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(height: 78)
                Text(service.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.ink.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 34)
                    .frame(maxWidth: .infinity)
                Text("Book")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 34)
                    .background(AppTheme.rose, in: Capsule())
                    .shadow(color: AppTheme.rose.opacity(0.35), radius: 7, y: 4)
            }
            .frame(maxWidth: .infinity)
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
        VStack(alignment: .leading, spacing: 18) {
            Text("Why choose us?")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.ink.opacity(0.9))
            HStack(spacing: 0) {
                feature("checkmark", "Verified\nExperts", AppTheme.green)
                divider
                feature("creditcard", "No Upfront\nPayment", Color(hex: 0x13A68C))
                divider
                feature("stopwatch.fill", "On-time\nService", AppTheme.blue)
                divider
                feature("star.fill", "100%\nSatisfaction", Color(hex: 0xE4A900))
            }
        }
        .androidCard(padding: 18, radius: 24, border: AppTheme.line, shadow: 9)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.line)
            .frame(width: 1, height: 70)
    }

    private func feature(_ icon: String, _ title: String, _ color: Color) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
                .frame(height: 30)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.ink.opacity(0.86))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
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
            metric("Final amount", service.priceLabel, "doc.text.fill", AppTheme.booking)
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
            include("Partner shares final amount before payment")
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
            guarantee("No upfront", "Pay after service", "creditcard.fill")
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
                Text("Final amount after inspection - \(store.selectedService.arrival)")
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
            ServiceLocationPreview()
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

struct ServiceLocationPreview: View {
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
                        summaryRow("Final Amount", "Partner will share after inspection")
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

                    Button("Firm Confirm") {
                        store.confirmBooking()
                    }
                    .roseCTA()
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
    @State private var showSuccess = true
    @State private var compactSuccess = false

    var body: some View {
        ZStack {
            confirmedContent
                .opacity(showSuccess ? 0 : 1)

            if showSuccess {
                BookingSuccessTransitionCard(compact: compactSuccess)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .background(AppTheme.bg)
        .onAppear {
            startSuccessTransition()
        }
        .task {
            await store.refreshLiveBookings()
        }
    }

    private var confirmedContent: some View {
        VStack(spacing: 0) {
            TopBar(
                title: store.latestBooking?.isAssigned == true ? "Partner Assigned" : "Finding Partner",
                subtitle: store.latestBooking?.displayId ?? "",
                backAction: { store.navigate(.home) },
                trailingTitle: "Help",
                trailingIcon: "headphones"
            ) {
                store.navigate(.support)
            }
            ScrollView(showsIndicators: false) {
                if let booking = store.latestBooking {
                    VStack(spacing: 16) {
                        if booking.isAssigned {
                            PartnerAssignedCard(booking: booking)
                            BookingPendingDetailsCard(booking: booking)
                        } else {
                            FindingPartnerCard(booking: booking)
                            BookingPendingDetailsCard(booking: booking)
                            safetyNote
                        }
                        Button("View Booking Status") {
                            store.openTrack(booking)
                        }
                        .roseCTA()
                    }
                    .padding(18)
                    .padding(.bottom, 114)
                } else {
                    EmptyState(title: "No booking found", subtitle: "Your confirmed booking will appear here.")
                        .padding(18)
                }
            }
        }
    }

    private var safetyNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.green)
                .frame(width: 46, height: 46)
                .background(AppTheme.greenSoft, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Your safety is our priority")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.ink.opacity(0.9))
                Text("We only connect you with verified and trusted professionals.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
        }
        .androidCard(padding: 14, radius: 18, border: AppTheme.greenSoft, shadow: 3)
    }

    private func startSuccessTransition() {
        showSuccess = true
        compactSuccess = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                compactSuccess = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            withAnimation(.easeInOut(duration: 0.28)) {
                showSuccess = false
            }
        }
    }
}

struct BookingSuccessTransitionCard: View {
    let compact: Bool

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            VStack(spacing: compact ? 8 : 18) {
                ZStack {
                    Circle()
                        .fill(AppTheme.greenSoft)
                        .frame(width: compact ? 62 : 116, height: compact ? 62 : 116)
                    Image(systemName: "checkmark")
                        .font(.system(size: compact ? 29 : 52, weight: .bold))
                        .foregroundStyle(AppTheme.green)
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .fill(index.isMultiple(of: 2) ? AppTheme.green : AppTheme.booking)
                            .frame(width: compact ? 3 : 5, height: compact ? 3 : 5)
                            .offset(x: compact ? 0 : CGFloat([-78, -52, -14, 38, 76, -68, -28, 24, 58, 84][index]),
                                    y: compact ? 0 : CGFloat([-42, 34, -82, -66, 22, 64, 82, 70, -88, -10][index]))
                            .opacity(compact ? 0 : 0.9)
                    }
                }
                Text("Booking Confirmed!")
                    .font(.system(size: compact ? 16 : 28, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text("Your booking has been received successfully.")
                    .font(.system(size: compact ? 10 : 14, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(width: compact ? 210 : nil)
            .padding(compact ? 22 : 24)
            .background(compact ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: compact ? 22 : 0, style: .continuous))
            .shadow(color: .black.opacity(compact ? 0.18 : 0), radius: compact ? 22 : 0, y: compact ? 10 : 0)
            .scaleEffect(compact ? 0.92 : 1)
            .animation(.spring(response: 0.55, dampingFraction: 0.82), value: compact)
        }
    }
}

struct FindingPartnerCard: View {
    var booking: Booking? = nil
    @State private var sweep = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .center) {
                ForEach([150, 112, 74], id: \.self) { size in
                    Circle()
                        .stroke(AppTheme.booking.opacity(size == 150 ? 0.13 : 0.20), lineWidth: 1.2)
                        .frame(width: CGFloat(size), height: CGFloat(size))
                        .background(AppTheme.bookingSoft.opacity(size == 74 ? 0.85 : 0.28), in: Circle())
                }
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.booking.opacity(0.7), AppTheme.booking.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 70, height: 2.5)
                    .offset(x: 35)
                    .rotationEffect(.degrees(sweep ? 360 : 0), anchor: .leading)
                    .animation(.linear(duration: 1.45).repeatForever(autoreverses: false), value: sweep)
                Circle()
                    .fill(AppTheme.booking)
                    .frame(width: 15, height: 15)
                Image(systemName: "person.crop.circle.badge.magnifyingglass")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.booking)
                    .offset(y: -82)
            }
            VStack(spacing: 8) {
                Text("Finding the best expert for you...")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(AppTheme.bookingDark)
                    .multilineTextAlignment(.center)
                Text("Searching nearby verified partners")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                if let booking {
                    Text("Booking ID: \(booking.displayId)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.booking)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.bookingSoft, in: Capsule())
                }
            }
            HStack(spacing: 10) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.bookingSoft, in: Circle())
                Text("We will notify you once a partner is assigned.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(AppTheme.greenSoft.opacity(0.65), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .androidCard(padding: 18, radius: 24, border: AppTheme.bookingSoft, shadow: 7)
        .onAppear {
            sweep = true
        }
    }
}

struct BookingPendingDetailsCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Booking ID")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                    Text(booking.displayId)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.bookingDark)
                }
                Spacer()
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.green)
            }
            Divider()
            detailRow("wrench.and.screwdriver.fill", "Service", booking.serviceName)
            detailRow("calendar", "Date & Time", booking.slot)
            detailRow("mappin.circle.fill", "Address", booking.address)
        }
        .androidCard(padding: 16, radius: 20)
    }

    private func detailRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.green)
                .frame(width: 42, height: 42)
                .background(AppTheme.greenSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.ink.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct PartnerAssignedCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Text(String(displayName.prefix(1)))
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(AppTheme.green, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
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

    private var displayName: String {
        let clean = booking.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? "Assigned Partner" : clean
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
                        if booking.isAssigned {
                            BookingStatusHeader(booking: booking)
                            PartnerAssignedCard(booking: booking)
                            BookingProgressTimeline(booking: booking)
                            LiveStatusMapCard(booking: booking)
                        } else {
                            FindingPartnerCard(booking: booking)
                            BookingPendingDetailsCard(booking: booking)
                            BookingProgressTimeline(booking: booking)
                        }
                        if booking.isAmountApprovalPending {
                            AmountApprovalCard(booking: booking)
                        }
                        if booking.isAssigned {
                            Button("Chat") {
                                store.openBookingChat(booking)
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
            await store.refreshLiveBookings()
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
                StatusChip(status: booking.presentationStatus)
            }
            Text(booking.issue)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
            HStack {
                info("Slot", booking.slot)
                info("Amount", booking.amount > 0 ? "Rs \(booking.amount)" : "After inspection")
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
        if booking.presentationStatus == "amount_pending" { return 4 }
        return steps.firstIndex { $0.0 == booking.presentationStatus } ?? 0
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

struct LiveStatusMapCard: View {
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
            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
            HStack {
                Text(booking.amount > 0 ? "Rs \(booking.amount)" : "Amount pending")
                    .font(.system(size: booking.amount > 0 ? 26 : 20, weight: .black))
                    .foregroundStyle(booking.amount > 0 ? AppTheme.booking : AppTheme.muted)
                Spacer()
                if booking.canSubmitDirectPayment {
                    Button("Paid to Partner") {
                        store.approveAmount()
                    }
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 42)
                    .background(AppTheme.green, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .androidCard(padding: 16, radius: 20, border: AppTheme.bookingSoft)
    }

    private var title: String {
        if booking.isPaymentSubmitted { return "Waiting for verification" }
        return booking.amount > 0 ? "Pay partner" : "Final amount pending"
    }

    private var message: String {
        if booking.isPaymentSubmitted {
            return "Your payment confirmation has been sent. The partner will verify the payment and complete the booking."
        }
        if booking.amount > 0 {
            return "Partner shared the final amount after inspection. Pay the partner directly, then mark it paid here."
        }
        return "Waiting for the partner to enter the final amount after service inspection."
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
        .task {
            await store.refreshLiveBookings()
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
            return store.bookings.filter { $0.presentationStatus == "pending" }
        case "Ongoing":
            return store.bookings.filter { !["pending", "completed", "cancelled", "rejected"].contains($0.presentationStatus) }
        case "Completed":
            return store.bookings.filter { $0.presentationStatus == "completed" }
        case "Cancelled":
            return store.bookings.filter { ["cancelled", "rejected"].contains($0.presentationStatus) }
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
                    .fill(statusColor(booking.presentationStatus))
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
                        StatusChip(status: booking.presentationStatus)
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
            store.markNotificationRead(item)
            if let booking = store.bookings.first(where: { $0.id == item.bookingId || $0.bookingCode == item.bookingId }) {
                store.openTrack(booking)
            }
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
                    SavedAddressPanel()
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
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(AppTheme.booking, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.profile.name.isEmpty ? "ApnaServo Customer" : store.profile.name)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(AppTheme.ink.opacity(0.9))
                    Text(store.profile.phone.isEmpty ? "Phone not shared" : store.profile.phone)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
        .androidCard(padding: 16, radius: 22, border: AppTheme.roseSoft, shadow: 4)
    }

    private var profileInitial: String {
        String((store.profile.name.isEmpty ? "A" : store.profile.name).prefix(1)).uppercased()
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink.opacity(0.88))
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

struct SavedAddressPanel: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var isAddingAddress = false
    @State private var newAddressTitle = ""
    @State private var newAddressDetail = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.bookingSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Saved Addresses")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink.opacity(0.88))
                    Text("\(store.savedAddresses.count)/3 addresses saved")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
            }

            ForEach(store.savedAddresses) { address in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(address.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.ink.opacity(0.88))
                        Text(address.detail)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    Button {
                        store.useSavedAddress(address)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.green)
                    }
                    .buttonStyle(.plain)
                    Button {
                        store.deleteSavedAddress(address)
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(AppTheme.booking)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
            }

            if isAddingAddress {
                VStack(spacing: 10) {
                    addressField("Address title", text: $newAddressTitle)
                    addressField("Full address", text: $newAddressDetail)
                    HStack(spacing: 10) {
                        Button("Cancel") {
                            isAddingAddress = false
                            newAddressTitle = ""
                            newAddressDetail = ""
                        }
                        .outlineCTA()
                        Button("Save Address") {
                            let previousCount = store.savedAddresses.count
                            store.addSavedAddress(title: newAddressTitle, detail: newAddressDetail)
                            if store.savedAddresses.count > previousCount {
                                isAddingAddress = false
                                newAddressTitle = ""
                                newAddressDetail = ""
                            }
                        }
                        .roseCTA()
                    }
                }
                .padding(12)
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Button {
                    newAddressTitle = "Address \(store.savedAddresses.count + 1)"
                    newAddressDetail = store.profile.address
                    isAddingAddress = true
                } label: {
                    Label("Add New Address", systemImage: "plus.circle.fill")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(store.savedAddresses.count >= 3 ? AppTheme.muted : AppTheme.booking)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
                .disabled(store.savedAddresses.count >= 3)
            }
        }
        .androidCard(padding: 14, radius: 17, shadow: 1)
    }

    private func addressField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.line, lineWidth: 1))
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
            InfoNote(text: "Your commercial request will be handled by the ApnaServo operations team.")
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
            InfoNote(text: "Inspection details will be saved when submitted.")
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
    switch displayStatusKey(status) {
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
    switch displayStatusKey(status) {
    case "completed": return AppTheme.green
    case "accepted", "on_the_way", "arrived", "started": return AppTheme.blue
    case "amount_pending": return AppTheme.orange
    case "cancelled", "rejected": return AppTheme.muted
    default: return AppTheme.booking
    }
}

private func displayStatusKey(_ status: String) -> String {
    let clean = status.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    switch clean {
    case "assigned", "partner_assigned", "partner_accepted":
        return "accepted"
    case "work_in_progress", "in_progress", "service_started":
        return "started"
    case "sent_to_partner", "sent", "searching", "processing", "created", "new", "open", "no_partner":
        return "pending"
    default:
        return clean
    }
}
