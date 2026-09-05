import SwiftUI
import AuthenticationServices
import UIKit
import Combine

struct UserAppView: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsFloatingFooter, let booking = store.latestBooking {
                FloatingBookingFooter(booking: booking)
                    .padding(.horizontal, 16)
                    .padding(.bottom, showsBottomNav ? 8 : 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBottomNav {
                BottomNav()
            }
        }
        .background(AppTheme.bg)
        .foregroundStyle(AppTheme.ink)
        .tint(store.remotePrimaryColor)
        .overlay {
            if store.showSavedAddressCard {
                SavedAddressOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(200)
            }
        }
        .animation(.easeOut(duration: 0.2), value: store.showSavedAddressCard)
    }

    private var showsBottomNav: Bool {
        switch store.screen {
        case .home, .services, .detail, .commercial,
             .bookings, .track, .bookingChat,
             .notifications, .profile, .support:
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
        case .otp:
            OTPVerificationScreen()
        case .startupLocation:
            StartupLocationGateScreen()
        case .home:
            HomeScreen()
        case .services:
            AllServicesScreen()
        case .detail:
            ServiceDetailScreen()
        case .preparing:
            ServicePreparingScreen()
        case .servicePreparing:
            ServicePreparingScreen()
        case .serviceHighDemand:
            ServiceHighDemandScreen()
        case .serviceLaunching:
            ServiceLaunchingScreen()
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
    @FocusState private var focusedField: LoginField?

    private enum LoginField { case name, phone }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        AndroidAssetImage(name: "login_home_repair_hero", contentMode: .fill)
                            .frame(
                                width: proxy.size.width,
                                height: min(max(proxy.size.width * 0.70, 250), 310)
                            )
                            .clipped()
                        LinearGradient(
                            colors: [AppTheme.loginBg, AppTheme.loginBg.opacity(0.90), AppTheme.loginBg.opacity(0.18), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        LinearGradient(colors: [.clear, AppTheme.loginBg.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 8) {
                            AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                                .frame(width: min(172, proxy.size.width * 0.44), height: 52)
                            Text("Home Services At\nYour Doorstep")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.muted)
                                .lineSpacing(1)
                            VStack(alignment: .leading, spacing: -2) {
                                Text("Trusted\nHome")
                                    .foregroundStyle(AppTheme.ink)
                                Text("Services")
                                    .foregroundStyle(AppTheme.loginRose)
                            }
                            .font(.system(size: proxy.size.width < 360 ? 29 : 34, weight: .bold, design: .serif))
                            Text("Just a tap away.")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .padding(.leading, 22)
                        .padding(.top, max(12, proxy.safeAreaInsets.top + 4))
                    }

                    trustStrip

                    VStack(spacing: 14) {
                        AndroidAssetImage(name: "login_namaste_portrait", contentMode: .fill)
                            .frame(width: 86, height: 86)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.bookingSoft, lineWidth: 5))
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "sparkle").foregroundStyle(AppTheme.loginRose).offset(x: 16, y: 4)
                            }
                        Text("Namaste!")
                            .font(.system(size: 30, weight: .bold, design: .serif).italic())
                            .foregroundStyle(AppTheme.loginRose)
                        Text("Sign in or continue to book trusted\nhome services.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                            .multilineTextAlignment(.center)

                        loginField(icon: "person.fill", placeholder: "Full name (optional)", text: $store.loginName, field: .name)
                        phoneField

                        Button { store.showOTPLogin() } label: {
                            HStack {
                                Spacer()
                                if store.isAuthenticating {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Send OTP")
                                }
                                Spacer()
                                if !store.isAuthenticating {
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .roseCTA()
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isAuthenticating)

                        HStack(spacing: 14) {
                            Rectangle().fill(AppTheme.line).frame(height: 1)
                            Text("OR").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.muted)
                            Rectangle().fill(AppTheme.line).frame(height: 1)
                        }

                        SignInWithAppleButton(.signIn) { request in
                            store.prepareAppleSignIn(request)
                        } onCompletion: { result in
                            store.completeAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(store.isAuthenticating)

                        (Text("By continuing, you agree to our ").foregroundColor(AppTheme.muted)
                         + Text("Terms of Service").foregroundColor(AppTheme.loginRose).underline()
                         + Text(" and ").foregroundColor(AppTheme.muted)
                         + Text("Privacy Policy").foregroundColor(AppTheme.loginRose).underline())
                            .font(.system(size: 10, weight: .medium))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .overlay {
                                HStack(spacing: 0) {
                                    Link("", destination: AppConfig.termsURL).frame(maxWidth: .infinity)
                                    Link("", destination: AppConfig.privacyPolicyURL).frame(maxWidth: .infinity)
                                }.opacity(0.01)
                            }
                    }
                    .padding(.horizontal, proxy.size.width < 360 ? 16 : 20)
                    .padding(.vertical, 22)
                    .background(AppTheme.surface.opacity(0.96), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(AppTheme.loginRose.opacity(0.10)))
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 7)
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 18)
                    .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 12))
                }
                .frame(width: proxy.size.width, alignment: .leading)
                .frame(minHeight: proxy.size.height)
            }
            .background(AppTheme.loginBg)
            .ignoresSafeArea(edges: .top)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var trustStrip: some View {
        HStack(spacing: 0) {
            trustItem("Verified", "Professionals", icon: "checkmark.shield.fill")
            trustDivider
            trustItem("No Upfront", "Payment", icon: "creditcard.fill")
            trustDivider
            trustItem("Quick & Reliable", "Support", icon: "headphones")
        }
        .padding(.vertical, 14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.loginRose.opacity(0.10)))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
        .padding(.horizontal, 18)
    }

    private func trustItem(_ title: String, _ subtitle: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.loginRose)
                .frame(width: 40, height: 40)
                .background(AppTheme.bookingSoft, in: Circle())
            Text(title).font(.system(size: 11, weight: .bold))
            Text(subtitle).font(.system(size: 10)).foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private var trustDivider: some View {
        Rectangle()
            .fill(AppTheme.line)
            .frame(width: 1, height: 42)
    }

    private func loginField(icon: String, placeholder: String, text: Binding<String>, field: LoginField) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).frame(width: 26)
            TextField(placeholder, text: text)
                .textContentType(.name)
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit { focusedField = .phone }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.loginRose.opacity(0.32), lineWidth: 1.2))
    }

    private var phoneField: some View {
        HStack(spacing: 12) {
            Text("+91").fontWeight(.bold)
            Divider()
            Image(systemName: "iphone").foregroundStyle(AppTheme.loginRose)
            TextField("Enter your mobile number", text: $store.loginPhone)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .focused($focusedField, equals: .phone)
                .onChange(of: store.loginPhone) { value in
                    store.loginPhone = String(value.filter(\.isNumber).prefix(10))
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.loginRose.opacity(0.32), lineWidth: 1.2))
    }
}

struct OTPVerificationScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var otp = ""
    @State private var now = Date()
    @FocusState private var otpFocused: Bool
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                HStack {
                    Button { store.back() } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Label("Secure", systemImage: "checkmark.shield")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.loginRose)

                VStack(spacing: 10) {
                    (Text("Verify Your ").foregroundColor(AppTheme.ink) + Text("Mobile Number").foregroundColor(AppTheme.loginRose))
                        .font(.system(size: 27, weight: .bold))
                    Text("We’ve sent a 6-digit OTP to")
                        .foregroundStyle(AppTheme.muted)
                    HStack(spacing: 14) {
                        Image(systemName: "phone.fill").foregroundStyle(AppTheme.loginRose)
                        Text("+91 \(store.loginPhone)").font(.system(size: 21, weight: .bold, design: .monospaced))
                        Button("Edit") { store.back() }.foregroundStyle(AppTheme.loginRose)
                    }
                }

                AndroidAssetImage(name: "otp_phone_illustration", contentMode: .fit)
                    .frame(width: 190, height: 190)

                otpBoxes
                    .contentShape(Rectangle())
                    .onTapGesture { otpFocused = true }
                    .overlay(alignment: .topLeading) {
                        TextField("", text: $otp)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .focused($otpFocused)
                            .opacity(0.01)
                            .frame(width: 1, height: 1)
                            .onChange(of: otp) { value in
                                let sanitized = String(value.filter(\.isNumber).prefix(6))
                                if sanitized != value { otp = sanitized; return }
                                if sanitized.count == 6, !store.isAuthenticating { Task { await verifyOTP() } }
                            }
                    }

                Label("Enter the 6-digit code sent to your number", systemImage: "checkmark.shield")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)

                HStack(spacing: 14) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 32)).foregroundStyle(AppTheme.loginRose)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Didn’t receive the code?").fontWeight(.bold)
                        Text("We can resend a new OTP").foregroundStyle(AppTheme.muted)
                    }
                    Spacer()
                    Button("Resend OTP") {
                        Task { await resendOTP() }
                    }
                        .disabled(secondsRemaining > 0 || store.isAuthenticating)
                        .foregroundStyle(secondsRemaining > 0 || store.isAuthenticating ? AppTheme.muted : AppTheme.loginRose)
                }
                .padding(16)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.line))

                Text(secondsRemaining > 0 ? "Resend OTP in  00:\(String(format: "%02d", secondsRemaining))" : "You can resend the OTP now")
                    .foregroundStyle(AppTheme.muted)

                Button {
                    Task { await verifyOTP() }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.shield")
                        Spacer()
                        Text("Verify & Continue")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .roseCTA()
                }
                .buttonStyle(.plain)
                .disabled(otp.count != 6 || secondsRemaining == 0 || store.isAuthenticating)
                .opacity(otp.count == 6 && secondsRemaining > 0 && !store.isAuthenticating ? 1 : 0.65)

                safeCard(title: "Your data is protected.", subtitle: "We use your details only to provide and support your requested service.")
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .background(AppTheme.loginBg.ignoresSafeArea())
        .onAppear {
            now = Date()
            otpFocused = true
        }
        .onReceive(timer) { _ in now = Date() }
        .onChange(of: scenePhase) { phase in if phase == .active { now = Date() } }
    }

    private var otpBoxes: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                Text(index < otp.count ? String(Array(otp)[index]) : "–")
                    .font(.system(size: 25, weight: .semibold, design: .monospaced))
                    .foregroundStyle(index < otp.count ? AppTheme.loginRose : AppTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(index == otp.count ? AppTheme.loginRose : AppTheme.loginRose.opacity(0.25), lineWidth: 1.5))
            }
        }
    }

    private func resendOTP() async {
        guard await store.resendLoginOTP() else { return }
        otp = ""
        now = Date()
        otpFocused = true
        store.toastMessage = "A new OTP has been sent."
    }

    private func verifyOTP() async {
        guard otp.count == 6 else { return }
        _ = await store.verifyLoginOTP(otp)
    }

    private var secondsRemaining: Int {
        guard let expiresAt = store.loginOTPExpiresAt else { return 0 }
        return max(0, Int(ceil(expiresAt.timeIntervalSince(now))))
    }
}

private func safeCard(title: String, subtitle: String) -> some View {
    HStack(spacing: 14) {
        Image(systemName: "checkmark.shield.fill")
            .font(.system(size: 28))
            .foregroundStyle(AppTheme.loginRose)
            .frame(width: 52, height: 52)
            .background(AppTheme.surface.opacity(0.8), in: Circle())
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(AppTheme.loginRose)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(AppTheme.muted)
        }
        Spacer()
        Image(systemName: "house.fill").font(.system(size: 34)).foregroundStyle(AppTheme.loginRose.opacity(0.7))
    }
    .padding(14)
    .background(AppTheme.bookingSoft, in: RoundedRectangle(cornerRadius: 16))
}

struct StartupLocationGateScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var manualFieldFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer(minLength: max(18, proxy.safeAreaInsets.top + 8))
                    VStack(spacing: 0) {
                        AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                            .frame(width: min(214, proxy.size.width - 88), height: 70)
                            .padding(.bottom, 16)

                        StartupLocationPulse(
                            isDetected: presentation.isDetected,
                            isAnimating: presentation.isAnimating
                        )
                        .frame(width: 174, height: 174)
                        .padding(.bottom, 18)

                        Text(presentation.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)

                        Text(presentation.message)
                            .font(.system(size: 13))
                            .foregroundStyle(presentation.isDetected ? Color(hex: 0x3A7457) : AppTheme.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 4)

                        if store.isStartupManualEntry {
                            manualLocationForm
                                .padding(.top, 18)
                        } else {
                            locationActions
                                .padding(.top, 20)
                        }

                        Text("Location is used only to show nearby services and booking support.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x827B78))
                            .multilineTextAlignment(.center)
                            .padding(.top, 18)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 430)
                    .background(
                        LinearGradient(
                            colors: [.white, Color(hex: 0xFFFAF9), Color(hex: 0xFFEEF2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color(hex: 0xF4D7DA), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
                    .padding(.horizontal, 18)
                    Spacer(minLength: max(18, proxy.safeAreaInsets.bottom + 8))
                }
                .frame(minHeight: proxy.size.height)
            }
            .background(AppTheme.bg)
        }
        .task {
            guard case .idle = store.startupLocationPhase else { return }
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, !store.isStartupManualEntry else { return }
            store.detectStartupLocation()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active, !store.isStartupManualEntry else { return }
            switch store.startupLocationPhase {
            case .permissionDenied, .unavailable:
                store.detectStartupLocation()
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var locationActions: some View {
        switch store.startupLocationPhase {
        case .idle:
            VStack(spacing: 10) {
                locationButton("Use Current Location", primary: true) {
                    store.detectStartupLocation()
                }
                locationButton("Enter Location Manually", primary: false) {
                    store.showStartupManualEntry()
                }
            }
        case .detecting, .detected:
            EmptyView()
        case .permissionDenied:
            fallbackActions(primaryTitle: "Open Settings", primaryAction: store.openLocationSettings)
        case .restricted:
            fallbackActions(primaryTitle: "Try Again", primaryAction: store.detectStartupLocation)
        case .unavailable:
            fallbackActions(primaryTitle: "Open Settings", primaryAction: store.openLocationSettings)
        case .failure:
            fallbackActions(primaryTitle: "Retry", primaryAction: store.detectStartupLocation)
        }
    }

    private var manualLocationForm: some View {
        VStack(spacing: 12) {
            TextField("Area, locality or landmark", text: $store.startupManualAddress)
                .focused($manualFieldFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .font(.system(size: 14))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color(hex: 0xE8D5D5), lineWidth: 1)
                )
                .onSubmit { store.submitStartupManualLocation() }

            HStack(spacing: 10) {
                locationButton("Use GPS", primary: false) {
                    store.isStartupManualEntry = false
                    store.detectStartupLocation()
                }
                locationButton("Continue", primary: true) {
                    store.submitStartupManualLocation()
                }
            }
        }
        .onAppear { manualFieldFocused = true }
    }

    private func fallbackActions(primaryTitle: String, primaryAction: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                locationButton(primaryTitle, primary: true, action: primaryAction)
                locationButton("Enter Manually", primary: false) {
                    store.showStartupManualEntry()
                }
            }
            Button("Continue without location") {
                store.continueWithoutStartupLocation()
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppTheme.muted)
            .buttonStyle(.plain)
        }
    }

    private func locationButton(_ title: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(primary ? Color.white : AppTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(primary ? AppTheme.rose : AppTheme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(primary ? AppTheme.rose : Color(hex: 0xE8D5D5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var presentation: StartupLocationPresentation {
        switch store.startupLocationPhase {
        case .idle, .detecting:
            return .init(
                title: "Detecting your location",
                message: "Finding the best service area near you...",
                isDetected: false,
                isAnimating: true
            )
        case .detected:
            return .init(
                title: "Location detected",
                message: "Nearby ApnaServo services are ready.",
                isDetected: true,
                isAnimating: false
            )
        case .permissionDenied:
            return .init(
                title: "Allow location access",
                message: "Allow location permission to detect your service area automatically.",
                isDetected: false,
                isAnimating: false
            )
        case .restricted:
            return .init(
                title: "Location access restricted",
                message: "Location access is restricted on this device. Enter your area manually or continue without it.",
                isDetected: false,
                isAnimating: false
            )
        case .unavailable:
            return .init(
                title: "Turn on device location",
                message: store.startupLocationPhase.message,
                isDetected: false,
                isAnimating: false
            )
        case .failure:
            return .init(
                title: "Location not found yet",
                message: store.startupLocationPhase.message,
                isDetected: false,
                isAnimating: false
            )
        }
    }
}

private struct StartupLocationPresentation {
    let title: String
    let message: String
    let isDetected: Bool
    let isAnimating: Bool
}

private struct StartupLocationPulse: View {
    let isDetected: Bool
    let isAnimating: Bool
    @State private var pulses = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFFE0E5).opacity(0.62))
                .frame(width: 166, height: 166)
                .scaleEffect(isAnimating && pulses ? 1.08 : 0.82)
                .opacity(isAnimating && pulses ? 0.28 : 0.64)
            Circle()
                .fill(Color(hex: 0xFFF4F6))
                .overlay(Circle().stroke(Color(hex: 0xF6B0BB), lineWidth: 1))
                .frame(width: 124, height: 124)
                .scaleEffect(isAnimating && pulses ? 1.04 : 0.94)
            Text(isDetected ? "OK" : "GPS")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 86, height: 86)
                .background(isDetected ? AppTheme.green : AppTheme.rose, in: Circle())
                .shadow(color: (isDetected ? AppTheme.green : AppTheme.rose).opacity(0.28), radius: 8, y: 5)
        }
        .onAppear {
            guard isAnimating else { return }
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                pulses = true
            }
        }
        .onChange(of: isAnimating) { animating in
            pulses = false
            guard animating else { return }
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                pulses = true
            }
        }
    }
}

struct HomeScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var showSearch = false

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if store.isOutsideGuwahatiServiceArea {
                            OutsideServiceAreaBanner()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        HomeHero(
                            showSearch: $showSearch,
                            height: min(340, max(292, physicalScreenHeight * 0.38))
                        )
                        .frame(width: proxy.size.width)
                        VStack(spacing: 18) {
                            if store.isHomeSectionVisible("announcements") { RemoteContentStrip(items: store.remoteAnnouncements, kind: "announcement") }
                            if store.isHomeSectionVisible("quick_services") { QuickServiceStrip() }
                            if store.isHomeSectionVisible("commercial") { CommercialHomeCard() }
                            if store.isHomeSectionVisible("popular_services") { ServiceGridSection(title: store.homeSectionTitle("popular_services", fallback: "Popular Services"), services: homeServices(["ac", "electrician", "plumbing", "carpenter", "cleaning", "laundry"])) }
                            if store.isHomeSectionVisible("more_services") { ServiceGridSection(title: store.homeSectionTitle("more_services", fallback: "More Services"), services: homeServices(["roadside", "painting", "interior", "ro", "pest", "appliances"])) }
                            if store.isHomeSectionVisible("feature_strip") { WhyChooseCard() }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, store.latestBooking == nil ? 18 : 104)
                    }
                    .frame(width: proxy.size.width)
                }
                .background(AppTheme.bg)
            }

            if showSearch {
                ServiceSearchOverlay(isPresented: $showSearch)
                    .environmentObject(store)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showSearch)
        .task {
            await store.refreshAppControl()
        }
    }

    private func homeServices(_ ids: [String]) -> [ServiceItem] {
        ids.compactMap { id in store.services.first(where: { $0.id == id }) }
    }

    private var physicalScreenHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }
            .first ?? 844
    }
}

private struct OutsideServiceAreaBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: 0xB26A00))
            VStack(alignment: .leading, spacing: 3) {
                Text("Attention")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(hex: 0x6D4100))
                Text("ApnaServo is currently available only in Guwahati. We'll be available in your area soon.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0x765522))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(Color(hex: 0xFFF4D6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xE8B84D), lineWidth: 1))
        .accessibilityIdentifier("outsideServiceAreaAttention")
    }
}

/// Content published from Admin → Control Center. The app deliberately accepts
/// only title, message, image and a known service action, never executable UI.
private struct RemoteContentStrip: View {
    @EnvironmentObject private var store: UserAppStore
    let items: [RemoteAppContent]
    let kind: String

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 8) {
                ForEach(items) { item in
                    Button {
                        guard !item.serviceCategory.isEmpty else { return }
                        let service = store.services.first(where: { $0.id == item.serviceCategory }) ?? ServiceCatalog.service(id: item.serviceCategory)
                        store.openService(service)
                    } label: {
                        HStack(spacing: 12) {
                            if let url = URL(string: item.imageUrl), !item.imageUrl.isEmpty {
                                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { ProgressView() }
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(.system(size: 14, weight: .bold)).foregroundStyle(AppTheme.ink)
                                if !item.message.isEmpty { Text(item.message).font(.system(size: 12)).foregroundStyle(AppTheme.muted).lineLimit(2) }
                            }
                            Spacer(minLength: 0)
                            if !item.ctaText.isEmpty { Text(item.ctaText).font(.system(size: 12, weight: .bold)).foregroundStyle(store.remotePrimaryColor) }
                        }
                        .padding(12)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(item.serviceCategory.isEmpty)
                }
            }
        }
    }
}

struct HomeHero: View {
    @EnvironmentObject private var store: UserAppStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var slideIndex = 0
    @State private var pageChangedAt = Date()
    @Binding var showSearch: Bool
    let height: CGFloat

    private var slides: [HomeHeroSlide] {
        let remote = store.remoteBanners.compactMap { banner -> HomeHeroSlide? in
            guard !banner.title.isEmpty || !banner.message.isEmpty else { return nil }
            return HomeHeroSlide(id: banner.serviceCategory, asset: "", title: banner.title, subtitle: banner.message, imageURL: banner.imageUrl, style: banner.bannerStyle)
        }
        return remote.isEmpty ? HomeHeroSlide.androidSlides : remote
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $slideIndex) {
                ForEach(slides.indices, id: \.self) { index in
                    let slide = slides[index]
                    HomeHeroSlideView(slide: slide, height: height) {
                        if !slide.id.isEmpty { store.openService(store.services.first(where: { $0.id == slide.id }) ?? ServiceCatalog.service(id: slide.id)) }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    AndroidAssetImage(name: "ic_assam_jaapi", contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(-8))
                    Spacer(minLength: 4)
                    VStack(spacing: 0) {
                        AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                            .frame(width: 164, height: 52)
                        Text(store.remoteHomeSubtitle.isEmpty ? "Home services at your doorstep" : store.remoteHomeSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x363231))
                        if !store.remoteHomeTitle.isEmpty {
                            Text(store.remoteHomeTitle)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(store.remotePrimaryColor)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    AndroidAssetImage(name: "ic_assam_jaapi", contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(8))
                }

                Button {
                    showSearch = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.rose)
                            .frame(width: 34)
                        Text("Search for services (AC repair, plumber...)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer()
                        Rectangle()
                            .fill(Color(hex: 0xEBE0E0))
                            .frame(width: 1, height: 30)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.rose)
                            .frame(width: 32)
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0x6C6565))
                    .padding(.leading, 8)
                    .padding(.trailing, 6)
                    .frame(height: 48)
                    .background(Color(hex: 0xFFFBFB), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: 0xE1A6AE), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.11), radius: 7, y: 4)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(slides.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == slideIndex ? AppTheme.ink : AppTheme.ink.opacity(0.25))
                            .frame(width: index == slideIndex ? 18 : 6, height: 6)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
        .frame(height: height)
        .clipped()
        .onChange(of: slideIndex) { _ in
            pageChangedAt = Date()
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                guard Date().timeIntervalSince(pageChangedAt) >= 3.2 else { continue }
                withAnimation(.easeInOut(duration: 0.35)) {
                    slideIndex = (slideIndex + 1) % slides.count
                }
            }
        }
    }
}

private struct HomeHeroSlide: Identifiable {
    let id: String
    let asset: String
    let title: String
    let subtitle: String
    var imageURL: String = ""
    var style: RemoteBannerStyle? = nil

    static let androidSlides = [
        HomeHeroSlide(id: "ro", asset: "hero_ro_background", title: "RO SERVICE", subtitle: "Filter • Leakage • Installation"),
        HomeHeroSlide(id: "ac", asset: "hero_banner_ac", title: "AC REPAIR", subtitle: "Inspection • Cleaning • Gas refill"),
        HomeHeroSlide(id: "electrician", asset: "hero_banner_electrician", title: "ELECTRICIAN", subtitle: "Switch • Wiring • Fan repair"),
        HomeHeroSlide(id: "plumbing", asset: "hero_banner_plumbing", title: "PLUMBER", subtitle: "Tap • Leak • Drain repair"),
        HomeHeroSlide(id: "cleaning", asset: "service_home_cleaning", title: "DEEP CLEAN", subtitle: "Home • Bathroom • Sofa cleaning"),
        HomeHeroSlide(id: "laundry", asset: "hero_banner_laundry", title: "LAUNDRY", subtitle: "Wash • Iron • Dry clean pickup"),
        HomeHeroSlide(id: "roadside", asset: "hero_banner_roadside", title: "ROADSIDE", subtitle: "Towing • Battery • Flat tyre"),
        HomeHeroSlide(id: "appliances", asset: "hero_banner_appliances", title: "APPLIANCE", subtitle: "Repair • Service • Installation"),
        HomeHeroSlide(id: "painting", asset: "hero_banner_painting", title: "PAINTING", subtitle: "Inspection • Repair • Installation"),
        HomeHeroSlide(id: "interior", asset: "service_home_interior", title: "INTERIOR", subtitle: "Inspection • Repair • Installation")
    ]
}

private struct HomeHeroSlideView: View {
    let slide: HomeHeroSlide
    let height: CGFloat
    let bookAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                Color(hexString: slide.style?.backgroundColor ?? "#161616")
                if let url = URL(string: slide.imageURL), !slide.imageURL.isEmpty {
                    AsyncImage(url: url) { image in image.resizable().aspectRatio(contentMode: .fill) } placeholder: { AndroidAssetImage(name: slide.asset, contentMode: .fill) }
                        .frame(width: proxy.size.width, height: height).clipped()
                } else {
                    AndroidAssetImage(name: slide.asset, contentMode: .fill)
                        .frame(width: proxy.size.width, height: height).clipped()
                }
                LinearGradient(
                    colors: [Color(hexString: slide.style?.overlayColor ?? "#FFF8F4").opacity(slide.style?.overlayOpacity ?? 0.76), Color(hexString: slide.style?.overlayColor ?? "#FFF8F4").opacity((slide.style?.overlayOpacity ?? 0.76) * 0.65), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(colors: [.white.opacity(0.1), .clear, AppTheme.bg.opacity(0.28)], startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 5) {
                    Text("VERIFIED SERVICE ✓")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AppTheme.rose)
                    Text(slide.title)
                        .font(.system(size: titleSize, weight: titleWeight, design: titleDesign))
                        .foregroundStyle(Color(hexString: slide.style?.titleColor ?? "#161616"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(slide.subtitle)
                        .font(.system(size: CGFloat(slide.style?.messageSize ?? 12), weight: .semibold, design: titleDesign))
                        .foregroundStyle(Color(hexString: slide.style?.messageColor ?? "#161616").opacity(0.86))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: bookAction) {
                        Text("Book Now ›")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color(hexString: slide.style?.ctaTextColor ?? "#ffffff"))
                            .frame(width: 112, height: 34)
                            .background(Color(hexString: slide.style?.ctaBackgroundColor ?? "#11141A"), in: Capsule())
                            .overlay(Capsule().stroke(AppTheme.rose, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: min(max(proxy.size.width * 0.60, 190), 250), alignment: .leading)
                .padding(.leading, 16)
                .padding(.bottom, 22)
            }
        }
        .frame(height: height)
    }

    private var titleSize: CGFloat {
        if let value = slide.style?.titleSize { return CGFloat(value) }
        if slide.title.count >= 10 { return 24 }
        if slide.title.count >= 8 { return 26 }
        return 28
    }

    private var titleDesign: Font.Design {
        switch slide.style?.titleFont {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }

    private var titleWeight: Font.Weight {
        switch slide.style?.titleWeight {
        case "regular": return .regular
        case "semibold": return .semibold
        case "bold": return .bold
        default: return .heavy
        }
    }
}

private struct ServiceSearchOverlay: View {
    @EnvironmentObject private var store: UserAppStore
    @Binding var isPresented: Bool
    @AppStorage("apnaservo_recent_service_searches") private var recentStorage = "AC repair|Plumber|Electrician|Sofa cleaning"
    @FocusState private var searchFocused: Bool
    @State private var query = ""

    private let popularIDs = ["ac", "plumbing", "electrician", "cleaning", "laundry", "ro", "painting"]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { isPresented = false }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.rose)
                        .frame(width: 34)
                    TextField("Search services...", text: $query)
                        .focused($searchFocused)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.search)
                        .font(.system(size: 16))
                    Button {
                        if query.isEmpty { isPresented = false } else { query = "" }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: 0xB2B2B2))
                            .frame(width: 32, height: 42)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .frame(height: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xECDDDD), lineWidth: 1))

                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Searches")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            Button("Clear all") { recentStorage = "" }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.rose)
                                .buttonStyle(.plain)
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                            ForEach(recentSearches, id: \.self) { recent in
                                HStack(spacing: 3) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundStyle(AppTheme.rose)
                                        Text(recent).lineLimit(1).minimumScaleFactor(0.7)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { query = recent }
                                    Spacer(minLength: 0)
                                    Button {
                                        removeRecent(recent)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(AppTheme.muted)
                                            .frame(width: 18, height: 28)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                                .padding(.leading, 8)
                                .padding(.trailing, 4)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(.white, in: Capsule())
                                .overlay(Capsule().stroke(Color(hex: 0xF7D8DE), lineWidth: 1))
                            }
                        }
                    }
                }

                Text(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Popular Services" : "Search Results")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.ink)

                if results.isEmpty {
                    EmptyState(title: "No service found", subtitle: "Try another service name.")
                } else {
                    VStack(spacing: 8) {
                        ForEach(results) { service in
                            searchResult(service)
                        }
                    }
                }

                    }
                    .padding(16)
                }
                .frame(width: proxy.size.width * 0.94)
                .frame(maxHeight: max(320, proxy.size.height - 112))
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0xECDDDD), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
                .padding(.top, max(16, proxy.safeAreaInsets.top + 56))
            }
        }
        .task { searchFocused = true }
    }

    private var recentSearches: [String] {
        recentStorage.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    private var results: [ServiceItem] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matches: [ServiceItem]
        if clean.isEmpty {
            matches = popularIDs.map { ServiceCatalog.service(id: $0) }
        } else {
            matches = store.services.filter {
                $0.name.lowercased().contains(clean)
                    || $0.description.lowercased().contains(clean)
                    || $0.category.lowercased().contains(clean)
            }
        }
        return Array(matches.prefix(clean.isEmpty ? 7 : 5))
    }

    private func searchResult(_ service: ServiceItem) -> some View {
        Button {
            remember(service)
            isPresented = false
            DispatchQueue.main.async { store.openService(service) }
        } label: {
            HStack(spacing: 12) {
                ServiceLogo(service: service, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text(searchSubtitle(service))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.rose)
                    .frame(width: 34)
            }
            .padding(.horizontal, 2)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }

    private func remember(_ service: ServiceItem) {
        let label: String
        switch service.id {
        case "ac": label = "AC repair"
        case "plumbing": label = "Plumber"
        case "electrician": label = "Electrician"
        case "cleaning": label = "Sofa cleaning"
        case "laundry": label = "Laundry"
        case "ro": label = "RO service"
        default: label = service.name
        }
        var values = recentSearches.filter { $0.caseInsensitiveCompare(label) != .orderedSame }
        values.insert(label, at: 0)
        recentStorage = values.prefix(6).joined(separator: "|")
    }

    private func removeRecent(_ value: String) {
        recentStorage = recentSearches.filter { $0 != value }.joined(separator: "|")
    }

    private func searchSubtitle(_ service: ServiceItem) -> String {
        switch service.id {
        case "ac": return "Installation, repair & gas refilling"
        case "plumbing": return "Leak repair, pipe fitting, installation"
        case "electrician": return "Wiring, light, fan & fixture repair"
        case "cleaning": return "Home, kitchen & sofa cleaning"
        case "laundry": return "Wash, iron, dry clean & pickup"
        case "ro": return "Filter change, servicing & leakage repair"
        case "painting": return "Wall painting & texture"
        default: return service.description
        }
    }
}

struct QuickServiceStrip: View {
    @EnvironmentObject private var store: UserAppStore
    private let quickIds = ["ac", "electrician", "plumbing", "cleaning", "appliances"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(quickIds, id: \.self) { id in
                if let service = store.services.first(where: { $0.id == id }) {
                    Button {
                        store.openService(service)
                    } label: {
                    VStack(spacing: 7) {
                        ServiceLogo(service: service, size: 52)
                        Text(service.id == "appliances" ? "Appliance" : service.name.components(separatedBy: " ").first ?? service.name)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 104)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xEED5D3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                }
            }
        }
        .padding(6)
        .frame(height: 116)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 5, y: 3)
    }
}

struct CommercialHomeCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        Button {
            store.openCommercialServices()
        } label: {
            ZStack(alignment: .leading) {
                AndroidAssetImage(name: "commercial_home_card", contentMode: .fill)
                    .frame(height: 166)
                    .frame(maxWidth: .infinity)
                    .clipped()
                LinearGradient(colors: [AppTheme.surface.opacity(0.94), AppTheme.surface.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 10) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: 0x78202C))
                            .frame(width: 42, height: 42)
                            .background(Color(hex: 0xFFEAEE).opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("COMMERCIAL\nSERVICES")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(Color(hex: 0x6D1F2B))
                                .lineSpacing(-2)
                            Text("Offices, shops, hotels, warehouses & more.")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: 0x3C3638))
                                .lineLimit(2)
                        }
                    }
                    HStack(spacing: 18) {
                        commercialPerk("checkmark", "Professional team")
                        commercialPerk("clock", "On-time service")
                    }
                    Text("Business Enquiry  ›")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 142, height: 34)
                        .background(Color(hex: 0x51141D), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .frame(height: 166)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(hex: 0xF1DCDF), lineWidth: 1))
            .shadow(color: .black.opacity(0.11), radius: 4, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func commercialPerk(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: 0xAE3A4A))
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: 0x493D40))
                .lineLimit(1)
        }
    }
}

struct ServiceGridSection: View {
    @EnvironmentObject private var store: UserAppStore
    let title: String
    let services: [ServiceItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: title, actionTitle: nil, action: nil)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 10
            ) {
                ForEach(services) { service in
                    HomeServiceCard(service: service)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xFFF7F7), Color(hex: 0xFFEFF2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xF8E2E5), lineWidth: 1))
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
            VStack(spacing: 0) {
                AndroidAssetImage(name: serviceHomeAsset(service), contentMode: .fill)
                    .frame(height: 92)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xF4E1E4), lineWidth: 1))
                Text(showcaseServiceTitle(service))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 35, alignment: .center)
                    .padding(.horizontal, 4)
                Text("Book")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 29)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xE29DA1), Color(hex: 0xD9898D), Color(hex: 0xC66F76)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .padding(.bottom, 10)
            }
            .frame(height: 176, alignment: .top)
        }
        .buttonStyle(.plain)
    }

    private func showcaseServiceTitle(_ service: ServiceItem) -> String {
        switch service.id {
        case "ac": return "AC Repair"
        case "electrician": return "Electrician"
        case "plumbing": return "Plumber"
        case "cleaning": return "Cleaning Services"
        case "laundry": return "Laundry Services"
        case "appliances": return "Appliance Service"
        case "roadside": return "Roadside Assistance"
        case "interior": return "Interior Design"
        case "ro": return "RO Service"
        case "pest": return "Pest Control"
        default: return service.name
        }
    }
}

struct WhyChooseCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why choose us?")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.ink)
            HStack(spacing: 0) {
                feature("checkmark", "Verified\nExperts", Color(hex: 0x16B16F))
                divider
                feature("indianrupeesign", "Upfront\nPricing", Color(hex: 0x158E7A))
                divider
                feature("clock", "On-time\nService", Color(hex: 0x2A7CE6))
                divider
                feature("headphones", "Customer\nSupport", Color(hex: 0xEBA822))
            }
            .frame(height: 84)
        }
        .androidCard(padding: 18, radius: 18, shadow: 5)
    }

    private func feature(_ icon: String, _ title: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
                .frame(height: 30)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.line)
            .frame(width: 1, height: 74)
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
            AppTheme.surface
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
                ServiceLogo(service: service, size: 66)
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                    Text("\(service.arrival) booking • Verified expert")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                    if !store.serviceIsBookable(service) {
                        Text(store.serviceUnavailableMessage(for: service))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 4)
                Text("Book  ›")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 78, height: 36)
                    .background(AppTheme.bookingSoft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(hex: 0xE8CBCA), lineWidth: 1))
            }
            .androidCard(padding: 10, radius: 18, shadow: 2)
        }
        .buttonStyle(.plain)
    }
}

struct ServicePreparingScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                preparingHeader(topInset: proxy.safeAreaInsets.top)
                Spacer(minLength: max(42, proxy.size.height * 0.10))
                AndroidAssetImage(name: "service_preparing_barrier", contentMode: .fit)
                    .frame(
                        width: min(proxy.size.width - 46, proxy.size.height * 0.40, 360),
                        height: min(proxy.size.width - 46, proxy.size.height * 0.40, 360)
                    )
                    .accessibilityLabel("Service preparation illustration")
                Spacer().frame(height: max(28, proxy.size.height * 0.035))
                HStack(spacing: 16) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(AppTheme.loginRose)
                        .frame(width: 72, height: 72)
                        .background(AppTheme.bookingSoft, in: Circle())
                    Rectangle().fill(AppTheme.line).frame(width: 1, height: 62)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We’re Preparing\nThis Service")
                            .font(.system(size: proxy.size.width < 360 ? 20 : 22, weight: .bold))
                            .foregroundStyle(AppTheme.loginRose)
                        Text(store.selectedServiceStatusMessage.isEmpty
                             ? "Please wait while we set\nthings up for you."
                             : store.selectedServiceStatusMessage)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
                .background(AppTheme.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.loginRose.opacity(0.20), lineWidth: 1.2))
                .shadow(color: AppTheme.loginRose.opacity(0.08), radius: 14, y: 7)
                .padding(.horizontal, 20)
                Spacer(minLength: max(38, proxy.safeAreaInsets.bottom + 18))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.loginBg)
            .ignoresSafeArea(edges: .top)
        }
    }

    private func preparingHeader(topInset: CGFloat) -> some View {
        HStack {
            Button { store.back() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 50, height: 50)
                    .background(AppTheme.bookingSoft.opacity(0.85), in: RoundedRectangle(cornerRadius: 17))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, topInset + 12)
        .padding(.bottom, 14)
        .background(AppTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.loginRose.opacity(0.08)).frame(height: 1) }
        .shadow(color: AppTheme.loginRose.opacity(0.07), radius: 12, y: 6)
    }
}

struct ServiceHighDemandScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 24) {
            TopBar(title: "High Demand", subtitle: store.selectedService.name, backAction: { store.back() })
            Spacer()
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 82, weight: .semibold))
                .foregroundStyle(AppTheme.orange)
                .frame(width: 170, height: 170)
                .background(AppTheme.orange.opacity(0.12), in: Circle())
            Text("Service Is in High Demand")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
            Text(store.selectedServiceStatusMessage.isEmpty
                 ? "We are currently receiving a high number of requests. Please try again after some time."
                 : store.selectedServiceStatusMessage)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)
            Button("Back to Home") { store.selectTab(.home) }
                .roseCTA()
                .padding(.horizontal, 24)
            Spacer()
        }
        .background(AppTheme.bg.ignoresSafeArea())
    }
}

struct ServiceLaunchingScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Button { store.back() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        Spacer()
                        Label("Secure", systemImage: "checkmark.shield")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.loginRoseDark)
                    }

                    AndroidAssetImage(name: "apna_servo_wordmark", contentMode: .fit)
                        .frame(width: 230, height: 94)
                        .padding(.top, 16)

                    launchTitle
                        .padding(.top, 42)

                    Text("This service is not currently offered in your selected area.\nChoose another service or contact support for assistance.")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .foregroundStyle(AppTheme.ink)
                        .padding(.top, 45)

                    Text("✦  What you will get  ✦")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.top, 38)

                    HStack(spacing: 4) {
                        launchBenefit("checkmark.seal", "Verified")
                        launchBenefit("calendar", "Fast Booking")
                        launchBenefit("checkmark.shield", "Secure")
                        launchBenefit("headphones", "Support")
                    }
                    .padding(.top, 18)

                    Button { store.selectTab(.home) } label: {
                        Label("Back to Home", systemImage: "house")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(AppTheme.loginRose, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 40)

                    Text("Need help? Open Profile → Help & Support.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.muted)
                        .padding(.top, 24)
                        .padding(.bottom, 26)
                }
                .padding(.horizontal, 28)
                .padding(.top, 14)
                .frame(width: proxy.size.width)
                .frame(minHeight: proxy.size.height)
            }
        }
        .background(AppTheme.loginBg.ignoresSafeArea())
    }

    private var launchTitle: some View {
        VStack(spacing: -9) {
            Text("Service")
                .font(.custom("Georgia", size: 43).weight(.bold))
                .foregroundStyle(AppTheme.ink)
            HStack(spacing: 10) {
                Text("✦")
                Text("Unavailable")
                    .font(.custom("Georgia", size: 52).weight(.bold))
                Image(systemName: "mappin.slash")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppTheme.loginRoseDark)
            }
            .foregroundStyle(AppTheme.ink)
        }
    }

    private func launchBenefit(_ icon: String, _ title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(AppTheme.loginRoseDark)
                .frame(height: 34)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
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
                    DetailTrustSummary(service: store.selectedService)
                    ServiceIncludesCard(service: store.selectedService)
                    GuaranteeStrip()
                }
                .padding(18)
                .padding(.bottom, 112)
            }
            Button("Book Now") {
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

struct DetailTrustSummary: View {
    let service: ServiceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(service.name)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Label("Clear quote before paid work", systemImage: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.green)
            HStack(spacing: 8) {
                trustChip("Verified", color: AppTheme.green)
                trustChip("Skilled Experts", color: AppTheme.purple)
                trustChip("On-time Service", color: AppTheme.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trustChip(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.11), in: Capsule())
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
        HStack(spacing: 8) {
            guarantee("Experienced\nTechnicians", "person.badge.shield.checkmark.fill")
            guarantee("Clear\nQuotes", "wrench.and.screwdriver.fill")
            guarantee("In-app\nSupport", "checkmark.seal.fill")
        }
    }

    private func guarantee(_ title: String, _ icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.booking)
                .frame(width: 34, height: 34)
                .background(AppTheme.bookingSoft, in: Circle())
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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
                    if store.selectedService.id == "cleaning" {
                        CleaningBookingOptionsCard()
                    } else if store.selectedService.id == "laundry" {
                        LaundryBookingOptionsCard()
                    }
                    ProblemDetailsCard()
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

struct CleaningBookingOptionsCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Cleaning Type")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text("Choose the type of cleaning service you need")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(store.cleaningTypes, id: \.self) { type in
                    Button {
                        store.selectedCleaningType = type
                    } label: {
                        VStack(spacing: 7) {
                            AndroidAssetImage(name: cleaningAsset(type), contentMode: .fit)
                                .frame(height: 62)
                            Text(type)
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                                .multilineTextAlignment(.center)
                                .frame(minHeight: 30)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(
                            store.selectedCleaningType == type ? AppTheme.bookingSoft : AppTheme.surface,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(store.selectedCleaningType == type ? AppTheme.booking : AppTheme.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .androidCard(padding: 16, radius: 20)
    }

    private func cleaningAsset(_ type: String) -> String {
        switch type {
        case "Deep Cleaning": return "cleaning_type_deep_art"
        case "Bathroom Cleaning": return "cleaning_type_bathroom_art"
        case "Room Cleaning": return "cleaning_type_room_art"
        default: return "cleaning_type_home_art"
        }
    }
}

struct LaundryBookingOptionsCard: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Service Type")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(AppTheme.ink)
            Text("Choose the type of laundry service you need")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.muted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 9) {
                ForEach(store.laundryServiceTypes, id: \.self) { type in
                    Button {
                        store.selectedLaundryServiceType = type
                    } label: {
                        Label(type, systemImage: laundryServiceIcon(type))
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(store.selectedLaundryServiceType == type ? AppTheme.booking : AppTheme.ink)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(
                                store.selectedLaundryServiceType == type ? AppTheme.bookingSoft : AppTheme.surface,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(store.selectedLaundryServiceType == type ? AppTheme.booking : AppTheme.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            includedBenefits
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("What would you like to wash?")
                        .font(.system(size: 15, weight: .black))
                    Text("\(store.selectedLaundryItems.values.reduce(0, +)) items selected")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Button("Select all") {
                    store.selectAllLaundryItems()
                }
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AppTheme.booking)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 8)], spacing: 8) {
                ForEach(store.laundryItems, id: \.self) { item in
                    laundryItem(item)
                }
            }
        }
        .androidCard(padding: 16, radius: 20)
    }

    private var includedBenefits: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's Included in Laundry Service?")
                .font(.system(size: 13, weight: .black))
            ForEach(["Premium detergent", "Fabric softener", "Stain removal", "Hygienic cleaning", "Neatly folded & packed"], id: \.self) { benefit in
                Label(benefit, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bookingSoft, in: RoundedRectangle(cornerRadius: 14))
    }

    private func laundryItem(_ item: String) -> some View {
        let count = store.selectedLaundryItems[item] ?? 0
        return VStack(spacing: 5) {
            AndroidAssetImage(name: laundryAsset(item), contentMode: .fit)
                .frame(width: 42, height: 38)
            Text(item)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 24)
            HStack(spacing: 7) {
                Button {
                    store.updateLaundryItem(item, delta: -1)
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(count == 0)
                Text("\(count)")
                    .font(.system(size: 11, weight: .black))
                    .frame(minWidth: 14)
                Button {
                    store.updateLaundryItem(item, delta: 1)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(AppTheme.booking)
        }
        .padding(7)
        .frame(maxWidth: .infinity)
        .background(count > 0 ? AppTheme.bookingSoft : AppTheme.surface, in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(count > 0 ? AppTheme.booking : AppTheme.line, lineWidth: 1))
    }

    private func laundryServiceIcon(_ type: String) -> String {
        switch type {
        case "Dry Cleaning": return "sparkles"
        case "Ironing": return "rectangle.and.hand.point.up.left.fill"
        case "Wash & Iron": return "washer.fill"
        default: return "tshirt.fill"
        }
    }

    private func laundryAsset(_ item: String) -> String {
        switch item {
        case "T-Shirts": return "laundry_item_tshirt"
        case "Shirts": return "laundry_item_shirt"
        case "Lowers / Track Pants": return "laundry_item_trackpants"
        case "Jeans": return "laundry_item_jeans"
        case "Bed Sheet": return "laundry_item_bedsheet"
        case "Blanket": return "laundry_item_blanket"
        case "Pillow Cover": return "laundry_item_pillow_cover"
        case "Curtain": return "laundry_item_curtain"
        case "Towel": return "laundry_item_towel"
        case "Saree": return "laundry_item_saree"
        case "Suit / Kurta": return "laundry_item_kurta"
        case "Jacket": return "laundry_item_jacket"
        case "Shoes": return "laundry_item_shoes"
        default: return "laundry_basket_reference"
        }
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
                Text(selectedServiceSubtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("No upfront pay")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppTheme.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppTheme.orange.opacity(0.11), in: Capsule())
                Text("Pay after service")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .androidCard(padding: 14, radius: 18)
    }

    private var selectedServiceSubtitle: String {
        switch store.selectedService.id {
        case "laundry": return "Fresh & Clean Laundry"
        case "cleaning": return "Professional home cleaning"
        default: return "Verified service partner"
        }
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
                    Text("Add the exact entrance and property details for your expert.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            HStack(spacing: 10) {
                addressModeButton(.current, title: "Current", image: "booking_icon_current_location")
                addressModeButton(.manual, title: "Manual", image: "booking_icon_manual_address")
            }

            labeledFormField(
                "Contact Mobile Number",
                placeholder: "10-digit number for service coordination",
                text: $store.profile.phone,
                required: true,
                keyboard: .phonePad
            )

            if store.addressMode == .current {
                currentAddressFields
            } else {
                manualAddressFields
            }

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "shield.fill")
                    .foregroundStyle(AppTheme.green)
                Text("House/flat number is required even when your current location is detected.")
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
            labeledFormField("House / Flat number", placeholder: "e.g. House 12 or Flat 3B", text: $store.houseFlat, required: true)
            labeledFormField("Apartment / Building", placeholder: "Apartment, society or building name", text: $store.building)
            HStack(alignment: .top, spacing: 10) {
                labeledFormField("Floor", placeholder: "e.g. 2nd floor", text: $store.floor)
                labeledFormField("Room number", placeholder: "e.g. Room 204", text: $store.room)
            }
            labeledFormField("Landmark", placeholder: "Nearby landmark (optional)", text: $store.landmark)
            ServiceLocationPreview()
        }
    }

    private var manualAddressFields: some View {
        VStack(spacing: 10) {
            labeledFormField("Street / Locality / Area", placeholder: "Enter complete service address", text: $store.draft.address, required: true)
            labeledFormField("House / Flat number", placeholder: "e.g. House 12 or Flat 3B", text: $store.houseFlat, required: true)
            labeledFormField("Apartment / Building", placeholder: "Apartment, society or building name", text: $store.building)
            HStack(alignment: .top, spacing: 10) {
                labeledFormField("Floor", placeholder: "e.g. 2nd floor", text: $store.floor)
                labeledFormField("Room number", placeholder: "e.g. Room 204", text: $store.room)
            }
            labeledFormField("Landmark", placeholder: "Nearby landmark (optional)", text: $store.landmark)
            HStack(alignment: .top, spacing: 10) {
                labeledFormField("City", placeholder: "City", text: $store.city, required: true)
                labeledFormField("State", placeholder: "State", text: $store.state, required: true)
            }
            labeledFormField("PIN code", placeholder: "6-digit PIN code", text: $store.pinCode, required: true, keyboard: .numberPad)
        }
    }

    private func labeledFormField(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        required: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 2) {
                Text(label)
                    .foregroundStyle(AppTheme.ink)
                if required {
                    Text("*")
                        .foregroundStyle(AppTheme.booking)
                }
            }
            .font(.system(size: 11, weight: .bold))
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.line, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ServiceLocationPreview: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE5F2EC), Color(hex: 0xFDF7F2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Text("──────      ──────\n   ────────\n────      ───────")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: 0xB0B7C2).opacity(0.78))
                .multilineTextAlignment(.center)
            VStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.booking)
                Text(store.draft.hasLocation ? store.draft.address : "Service location not detected")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(store.draft.hasLocation ? "Current service location" : "Use Current Location above to detect it")
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
                        summaryRow("Issue", store.bookingRequestDetails().isEmpty ? "Service request" : store.bookingRequestDetails())
                        summaryRow("Address", store.bookingAddressPreview())
                        summaryRow("Customer", store.profile.name)
                        if !store.profile.phone.isEmpty { summaryRow("Contact", store.profile.phone) }
                        if !store.profile.email.isEmpty { summaryRow("Email", store.profile.email) }
                        summaryRow("Service Tier", store.draft.tier.rawValue)
                        summaryRow("Booking Charge", "No upfront charge")
                    }
                    .androidCard(padding: 16, radius: 20)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "shield.checkered")
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

                    Button("Edit Address") {
                        store.navigate(.booking)
                    }
                    .outlineCTA()

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
    @State private var showsConfirmation = true

    var body: some View {
        VStack(spacing: 0) {
            if !showsConfirmation || store.latestBooking?.status != "pending" {
                BookingFlowTopBar(booking: store.latestBooking, backAction: { store.selectTab(.home) })
            }
            ScrollView(showsIndicators: false) {
                if let booking = store.latestBooking {
                    if showsConfirmation && booking.status == "pending" {
                        BookingConfirmationSplash(booking: booking)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    } else {
                        BookingLifecycleContent(booking: booking)
                            .transition(.opacity)
                    }
                } else {
                    EmptyState(title: "No booking found", subtitle: "Your confirmed booking will appear here.")
                        .padding(18)
                }
            }
        }
        .task {
            store.startBookingPolling()
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            withAnimation(.easeInOut(duration: 0.35)) {
                showsConfirmation = false
            }
        }
        .onChange(of: store.latestBooking?.status) { status in
            if status != "pending" {
                showsConfirmation = false
            }
        }
    }
}

private struct BookingConfirmationSplash: View {
    let booking: Booking

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 76)
            ZStack {
                Circle().fill(AppTheme.greenSoft).frame(width: 148, height: 148)
                Circle().stroke(AppTheme.green.opacity(0.22), lineWidth: 14).frame(width: 178, height: 178)
                Image(systemName: "checkmark")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 104, height: 104)
                    .background(AppTheme.green, in: Circle())
                    .shadow(color: AppTheme.green.opacity(0.28), radius: 16, y: 8)
            }
            .padding(.bottom, 12)
            Text("Booking Confirmed!")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text("Your booking has been received successfully.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
            Text(booking.displayId)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.booking)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.bookingSoft, in: Capsule())
            Spacer(minLength: 120)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 620)
        .background(AppTheme.surface)
    }
}

private struct BookingFlowTopBar: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking?
    let backAction: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            VStack(spacing: 2) {
                Text("Booking Status")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(booking?.displayId ?? "Live updates about your service")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            Button {
                store.navigate(.support)
            } label: {
                Image(systemName: "headphones")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.bg)
    }
}

struct TrackBookingScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            BookingFlowTopBar(booking: store.latestBooking, backAction: { store.back() })
            ScrollView(showsIndicators: false) {
                if let booking = store.latestBooking {
                    BookingLifecycleContent(booking: booking)
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

private struct BookingLifecycleContent: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking

    @ViewBuilder
    var body: some View {
        switch booking.status {
        case "pending", "sent_to_partner", "searching":
            FindingPartnerPage(booking: booking)
        case "accepted", "on_the_way", "arrived", "started":
            ActiveBookingPage(booking: booking)
        case "amount_pending":
            if booking.isWaitingForPaymentVerification {
                PaymentVerificationPage(booking: booking)
            } else {
                ServicePaymentPage(booking: booking)
            }
        case "completed":
            PaymentVerifiedPage(booking: booking)
        case "cancelled", "rejected":
            ClosedBookingPage(booking: booking)
        default:
            ActiveBookingPage(booking: booking)
        }
    }
}

private struct FindingPartnerPage: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking
    @State private var confirmsCancellation = false

    var body: some View {
        VStack(spacing: 14) {
            FindingPartnerArtwork()
                .frame(height: 160)
            VStack(spacing: 5) {
                Text("Finding the best expert\nfor you...")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(Color(hex: 0x061B2F))
                    .multilineTextAlignment(.center)
                Text("Searching nearby verified partners")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.muted)
            }
            BookingDetailsPanel(booking: booking, showsAmount: false)
            Button {
                confirmsCancellation = true
            } label: {
                Label(store.bookingActionInFlight ? "Cancelling..." : "Cancel Booking", systemImage: "xmark.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.booking)
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .disabled(store.bookingActionInFlight)
            .buttonStyle(.plain)
            FlowNotice(icon: "bell.badge", title: "Stay notified", message: "We will notify you as soon as a verified partner accepts your booking.", accent: AppTheme.booking)
            FlowNotice(icon: "shield.checkered", title: "You're covered", message: "Verified partners, protected calling and in-app support are included.", accent: AppTheme.green)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
        .confirmationDialog("Cancel this booking?", isPresented: $confirmsCancellation, titleVisibility: .visible) {
            Button("Cancel Booking", role: .destructive) { store.cancelLatestBooking() }
            Button("Keep Booking", role: .cancel) {}
        } message: {
            Text("Cancellation is available before the partner starts travelling.")
        }
    }
}

private struct FindingPartnerArtwork: View {
    @State private var pulses = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(AppTheme.green.opacity(0.22 - Double(index) * 0.045), lineWidth: 2)
                    .frame(width: CGFloat(68 + index * 38), height: CGFloat(68 + index * 38))
                    .scaleEffect(pulses ? 1.05 : 0.9)
                    .opacity(pulses ? 0.45 : 1)
                    .animation(.easeOut(duration: 1.55).repeatForever(autoreverses: true).delay(Double(index) * 0.16), value: pulses)
            }
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(AppTheme.green, in: Circle())
                .shadow(color: AppTheme.green.opacity(0.28), radius: 14, y: 8)
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(AppTheme.booking)
                .offset(x: 64, y: -49)
        }
        .frame(maxWidth: .infinity)
        .onAppear { pulses = true }
    }
}

private struct ActiveBookingPage: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking
    @State private var confirmsCancellation = false

    var body: some View {
        VStack(spacing: 14) {
            BookingStateHero(
                icon: heroIcon,
                title: booking.statusTitle + (booking.status == "accepted" || booking.status == "arrived" ? "!" : ""),
                subtitle: heroSubtitle,
                accent: heroAccent
            )
            PartnerFlowCard(booking: booking)
            if booking.canCustomerCancel {
                Button {
                    confirmsCancellation = true
                } label: {
                    Label("Cancel Booking", systemImage: "calendar.badge.minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.booking)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            BookingProgressPanel(booking: booking)
            BookingDetailsPanel(booking: booking, showsAmount: false)
            FlowNotice(icon: "bell", title: "Live booking updates", message: "This page refreshes automatically whenever your partner updates the job.", accent: AppTheme.booking)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
        .confirmationDialog("Cancel this booking?", isPresented: $confirmsCancellation, titleVisibility: .visible) {
            Button("Cancel Booking", role: .destructive) { store.cancelLatestBooking() }
            Button("Keep Booking", role: .cancel) {}
        }
    }

    private var heroIcon: String {
        switch booking.status {
        case "accepted": return "checkmark.seal.fill"
        case "on_the_way": return "scooter"
        case "arrived": return "mappin.and.ellipse"
        default: return "wrench.and.screwdriver.fill"
        }
    }

    private var heroAccent: Color {
        switch booking.status {
        case "on_the_way": return AppTheme.booking
        case "arrived": return AppTheme.orange
        case "started": return AppTheme.green
        default: return AppTheme.green
        }
    }

    private var heroSubtitle: String {
        switch booking.status {
        case "accepted": return "A verified professional has accepted your booking."
        case "on_the_way": return "Your partner is on the way to your location. We're almost there!"
        case "arrived": return "Your partner has arrived at your location. Get ready for your service."
        case "started": return "Your partner is working on your service. We will notify you when it is done."
        default: return "Your booking is active and updating automatically."
        }
    }
}

private struct BookingStateHero: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.1)).frame(width: 118, height: 118)
                Circle().stroke(accent.opacity(0.2), lineWidth: 10).frame(width: 92, height: 92)
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(accent, in: Circle())
                    .shadow(color: accent.opacity(0.25), radius: 12, y: 7)
            }
            Text(title)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

private struct PartnerFlowCard: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 13) {
                Text(partnerInitials)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(AppTheme.booking, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.partnerName.isEmpty ? "Assigned Partner" : booking.partnerName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Label("Verified service partner", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.green)
                }
                Spacer()
                StatusChip(status: booking.status)
            }
            HStack(spacing: 10) {
                Button { store.callPartner(booking) } label: {
                    Label("Call", systemImage: "phone.fill")
                        .flowActionStyle(color: AppTheme.green)
                }
                Button { store.openBookingChat(booking) } label: {
                    Label("Chat", systemImage: "message.fill")
                        .flowActionStyle(color: AppTheme.booking)
                }
            }
            .buttonStyle(.plain)
        }
        .flowPanel()
    }

    private var partnerInitials: String {
        let initials = booking.partnerName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
        return initials.isEmpty ? "AS" : initials.uppercased()
    }
}

private struct BookingProgressPanel: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking
    private let steps = [
        ("accepted", "Partner Assigned"),
        ("on_the_way", "On The Way"),
        ("arrived", "Arrived"),
        ("started", "Work in Progress"),
        ("amount_pending", "Service Completed")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Booking Progress")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 14)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                let rank = statusRank
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Image(systemName: index < rank ? "checkmark.circle.fill" : index == rank ? "circle.inset.filled" : "circle")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(index <= rank ? AppTheme.green : AppTheme.line)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < rank ? AppTheme.green.opacity(0.45) : AppTheme.line)
                                .frame(width: 2, height: 27)
                        }
                    }
                    Text(step.1)
                        .font(.system(size: 13, weight: index == rank ? .bold : .medium))
                        .foregroundStyle(index <= rank ? AppTheme.ink : AppTheme.muted)
                        .padding(.top, 1)
                    Spacer()
                    if index == rank {
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(AppTheme.greenSoft, in: Capsule())
                    }
                }
            }
            if booking.quoteStatus == "pending" && booking.amount > 0 {
                Button("Send Counter Offer") {
                    store.requestCounterOffer(booking)
                }
                .outlineCTA()
            } else if booking.quoteStatus == "countered" {
                Label(
                    "Counter offer Rs \(booking.quoteCounterAmount) sent. Waiting for a revised quote.",
                    systemImage: "clock.fill"
                )
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.booking)
            }
        }
        .flowPanel()
    }

    private var statusRank: Int {
        switch booking.status {
        case "accepted": return 0
        case "on_the_way": return 1
        case "arrived": return 2
        case "started": return 3
        case "amount_pending", "completed": return 4
        default: return 0
        }
    }
}

private struct BookingDetailsPanel: View {
    let booking: Booking
    let showsAmount: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Booking ID").font(.system(size: 11)).foregroundStyle(AppTheme.muted)
                    Text(booking.displayId).font(.system(size: 15, weight: .bold)).foregroundStyle(AppTheme.booking)
                }
                Spacer()
                StatusChip(status: booking.status)
            }
            .padding(.bottom, 12)
            Divider()
            FlowDetailRow(icon: "wrench.and.screwdriver", title: "Service", value: booking.serviceName)
            Divider().padding(.leading, 48)
            FlowDetailRow(icon: "mappin", title: "Service Address", value: booking.address)
            if showsAmount {
                Divider().padding(.leading, 48)
                FlowDetailRow(icon: "indianrupeesign.circle", title: "Final Amount", value: "Rs \(booking.amount)")
            }
        }
        .flowPanel()
    }
}

private struct FlowDetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.booking)
                .frame(width: 36, height: 36)
                .background(AppTheme.bookingSoft, in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11)).foregroundStyle(AppTheme.muted)
                Text(value.isEmpty ? "Pending" : value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }
}

private struct ServicePaymentPage: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking
    @State private var showsCounterOffer = false

    var body: some View {
        VStack(spacing: 14) {
            BookingStateHero(icon: "checkmark.circle.fill", title: "Service Completed!", subtitle: "Your service has been completed successfully.", accent: AppTheme.green)
            PartnerFlowCard(booking: booking)
            FlowNotice(icon: "wallet.pass", title: "Pay directly to your service partner", message: "Confirm only after you have paid the amount directly to the partner.", accent: AppTheme.green)
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "indianrupeesign")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(AppTheme.booking)
                        .frame(width: 58, height: 58)
                        .background(AppTheme.bookingSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Amount to be paid").font(.system(size: 12)).foregroundStyle(AppTheme.muted)
                        Text("Rs \(booking.amount)").font(.system(size: 27, weight: .bold)).foregroundStyle(AppTheme.booking)
                    }
                    Spacer()
                    Image(systemName: "doc.text.fill").font(.system(size: 30)).foregroundStyle(AppTheme.booking.opacity(0.7))
                }
                Divider()
                Text("The exact amount was sent by your service partner after completing the service.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .flowPanel()
            FlowNotice(icon: "shield.checkered", title: "Pay only after service", message: "Never share OTP, PIN or card details with anyone.", accent: AppTheme.booking)
            if quoteExpired {
                FlowNotice(icon: "exclamationmark.triangle.fill", title: "Quote expired", message: "Ask your partner to send a fresh final amount before confirming payment.", accent: AppTheme.orange)
                Button("Chat with Partner") { store.openBookingChat(booking) }
                    .outlineCTA()
            } else if booking.quoteStatus == "countered" {
                FlowNotice(icon: "clock.arrow.circlepath", title: "Counter offer sent", message: "Waiting for your partner to send an updated final amount.", accent: AppTheme.orange)
            } else {
                Button {
                    store.approveAmount()
                } label: {
                    HStack {
                        Image(systemName: "wallet.pass.fill")
                        Text(store.bookingActionInFlight ? "Submitting..." : "Paid to Partner")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(AppTheme.booking, in: RoundedRectangle(cornerRadius: 18))
                }
                .disabled(store.bookingActionInFlight || booking.amount <= 0)
                .buttonStyle(.plain)

                Button("Send Counter Offer") { showsCounterOffer = true }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.booking)
                    .disabled(store.bookingActionInFlight)
            }
            Text("Secure & Safe Payment")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
        .sheet(isPresented: $showsCounterOffer) {
            CounterOfferSheet(booking: booking)
                .presentationDetents([.height(330)])
        }
    }

    private var quoteExpired: Bool {
        booking.quoteExpiresAtMillis > 0
            && booking.quoteExpiresAtMillis <= Int64(Date().timeIntervalSince1970 * 1000)
    }
}

private struct CounterOfferSheet: View {
    @EnvironmentObject private var store: UserAppStore
    @Environment(\.dismiss) private var dismiss
    let booking: Booking
    @State private var amount = ""
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Send Counter Offer").font(.system(size: 21, weight: .bold)).foregroundStyle(AppTheme.ink)
            Text("Partner amount: Rs \(booking.amount)").font(.system(size: 13)).foregroundStyle(AppTheme.muted)
            TextField("Your amount", text: $amount)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 13))
            TextField("Reason (optional)", text: $message)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 13))
            Button("Send Offer") {
                guard let value = Int(amount), value > 0 else {
                    store.toastMessage = "Enter a valid counter amount."
                    return
                }
                store.sendCounterOffer(amount: value, message: message)
                dismiss()
            }
            .roseCTA()
            Spacer()
        }
        .padding(20)
        .background(AppTheme.surface)
    }
}

private struct PaymentVerificationPage: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking

    var body: some View {
        VStack(spacing: 14) {
            BookingStateHero(icon: "clock.badge.checkmark", title: "Waiting for Verification", subtitle: "\(booking.partnerName) will verify your payment shortly.", accent: AppTheme.green)
            PartnerFlowCard(booking: booking)
            FlowNotice(icon: "info.circle.fill", title: "What happens next?", message: "Once the partner verifies your payment, this service will automatically be marked completed.", accent: AppTheme.green)
            FlowNotice(icon: "lock.shield.fill", title: "Your confirmation is protected", message: "The booking stays open until your partner confirms the payment receipt.", accent: AppTheme.booking)
            Button {
                store.navigate(.support)
            } label: {
                Label("Need Help? Contact Support", systemImage: "headphones")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.booking)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
    }
}

private struct PaymentVerifiedPage: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking
    @State private var rating = 0

    var body: some View {
        VStack(spacing: 14) {
            BookingStateHero(icon: "checkmark.seal.fill", title: "Service Completed!", subtitle: "Payment verified. Thank you!", accent: AppTheme.green)
            PartnerFlowCard(booking: booking)
            FlowNotice(icon: "checkmark.circle.fill", title: "Paid directly to your service partner", message: "Thank you for using ApnaServo.", accent: AppTheme.green)
            VStack(spacing: 11) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(AppTheme.booking)
                Text("Rate your service partner").font(.system(size: 18, weight: .bold)).foregroundStyle(AppTheme.ink)
                Text("Your feedback helps us improve").font(.system(size: 12)).foregroundStyle(AppTheme.muted)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            if store.submittedRatings[booking.id] == nil { rating = value }
                        } label: {
                            Image(systemName: value <= displayedRating ? "star.fill" : "star")
                                .font(.system(size: 30))
                                .foregroundStyle(value <= displayedRating ? Color(hex: 0xF4B400) : AppTheme.line)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button(store.submittedRatings[booking.id] == nil ? "Submit Rating" : "Rating Submitted") {
                    store.submitServiceRating(rating)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(store.submittedRatings[booking.id] == nil ? AppTheme.booking : AppTheme.green)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(store.submittedRatings[booking.id] == nil ? AppTheme.booking.opacity(0.5) : AppTheme.green.opacity(0.5), lineWidth: 1))
                .disabled(rating == 0 || store.bookingActionInFlight || store.submittedRatings[booking.id] != nil)
            }
            .flowPanel()
            Button("Go to Home") { store.navigate(.home, remember: false) }
                .outlineCTA()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
    }

    private var displayedRating: Int {
        store.submittedRatings[booking.id] ?? rating
    }
}

private struct ClosedBookingPage: View {
    @EnvironmentObject private var store: UserAppStore
    let booking: Booking

    var body: some View {
        VStack(spacing: 16) {
            BookingStateHero(icon: "xmark.circle.fill", title: booking.statusTitle, subtitle: "This booking is closed and remains available in your booking history.", accent: .red)
            BookingDetailsPanel(booking: booking, showsAmount: false)
            Button("View My Bookings") { store.navigate(.bookings, remember: false) }
                .outlineCTA()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
    }
}

private struct FlowNotice: View {
    let icon: String
    let title: String
    let message: String
    let accent: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 48, height: 48)
                .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(AppTheme.ink)
                Text(message).font(.system(size: 12)).foregroundStyle(AppTheme.muted).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(accent.opacity(0.045), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(accent.opacity(0.16), lineWidth: 1))
    }
}

private extension View {
    func flowPanel() -> some View {
        self
            .padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.line, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.04), radius: 7, y: 3)
    }

    func flowActionStyle(color: Color) -> some View {
        self
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.28), lineWidth: 1))
    }
}

struct BookingsListScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var filter = "All"
    private let filters = ["All", "Pending", "Ongoing", "Completed", "Cancelled"]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "My Bookings", subtitle: "\(store.bookings.count) total", backAction: { store.selectTab(.home) })
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
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
            .refreshable { await store.refreshBookings() }
        }
        .task {
            await store.refreshBookings()
            store.startBookingPolling()
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
                    .background(filter == value ? AppTheme.booking : AppTheme.surface, in: Capsule())
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
                    Text(booking.address)
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
            TopBar(title: "Messages", subtitle: "Notifications and updates", backAction: { store.selectTab(.home) }, trailingTitle: "Mark all") {
                store.markAllNotificationsRead()
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
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
            .refreshable { await store.refreshNotifications() }
        }
        .task { await store.refreshNotifications() }
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
            TopBar(title: "Profile", subtitle: "Account and settings", backAction: { store.selectTab(.home) }, trailingIcon: "gearshape.fill") {
                store.showSettingsSheet = true
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    profileHero
                    profileAction("Update Email", "Name and mobile number are locked", "person.crop.circle.fill") {
                        store.showEditProfileSheet = true
                    }
                    profileAction("My Bookings", "Track active and past bookings", "list.bullet.rectangle.fill") {
                        store.selectTab(.bookings)
                    }
                    profileAction("Saved Addresses", "Home and service locations", "house.fill") {
                        store.showSavedAddressCard = true
                    }
                    profileAction("No Upfront Payment", "Pay only after service and quote approval", "shield.checkered") {
                        store.paymentInfoExpanded.toggle()
                    }
                    if store.paymentInfoExpanded {
                        Text("ApnaServo never collects upfront payment. The partner shares the final quote after inspection, and payment is handled only after service with your approval.")
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
                    profileAction("Delete Account", "Permanently delete your account and personal data", "trash.fill") {
                        store.showLegalSheet = true
                    }
                    profileAction("About ApnaServo", "Trusted home repair services", "info.circle.fill") {
                        store.aboutInfoExpanded.toggle()
                    }
                    if store.aboutInfoExpanded {
                        Text("ApnaServo helps customers book trusted home service experts for AC repair, electrician, plumbing, cleaning, pest control and more. You can book, track and get support from one single app.")
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

private struct SavedAddressOverlay: View {
    @EnvironmentObject private var store: UserAppStore

    private var savedAddress: String {
        let address = store.profile.address.trimmingCharacters(in: .whitespacesAndNewlines)
        return address.isEmpty ? "No saved address yet." : address
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { store.showSavedAddressCard = false }

            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(AppTheme.booking)
                        .frame(width: 62, height: 62)
                        .background(AppTheme.bookingSoft, in: Circle())
                        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saved Address")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(AppTheme.ink)
                        Text("Your selected address")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer(minLength: 8)

                    Button {
                        store.showSavedAddressCard = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: 46, height: 46)
                            .background(AppTheme.line.opacity(0.6), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close saved address")
                }

                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(AppTheme.booking)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.bookingSoft, in: Circle())

                    VStack(alignment: .leading, spacing: 5) {
                        Text("ApnaServo")
                            .font(.system(size: 19, weight: .black))
                            .foregroundStyle(AppTheme.ink)
                        Text(savedAddress)
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)

                    Text("Default")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.booking)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.bookingSoft, in: Capsule())
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.bookingSoft.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.booking.opacity(0.16), lineWidth: 1)
                }
            }
            .padding(22)
            .frame(maxWidth: 370)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 24, y: 12)
            .padding(.horizontal, 20)
        }
    }
}

struct SupportChatScreen: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Support Chat", subtitle: supportSubtitle, backAction: { store.selectTab(.profile) })
            if !store.supportTicketId.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "ticket.fill").foregroundStyle(AppTheme.rose)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ticket \(store.supportTicketId)")
                            .font(.system(size: 12, weight: .black))
                        Text(ticketDetail)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.muted)
                    }
                    Spacer()
                    Text(store.supportTicketStatus.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(AppTheme.rose)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(AppTheme.surface)
                .overlay(alignment: .bottom) { Divider() }
            }
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(store.supportMessages) { message in
                            ChatMessageBubble(message: message, isMe: message.senderRole == "user")
                                .id(message.id)
                                .onTapGesture {
                                    store.retrySupportMessage(message)
                                }
                        }
                        if store.isSupportBotTyping {
                            SupportTypingIndicator()
                                .id("support-typing")
                        }
                    }
                    .padding(18)
                }
                .onChange(of: store.supportMessages.count) { _ in
                    if let last = store.supportMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: store.isSupportBotTyping) { typing in
                    if typing { proxy.scrollTo("support-typing", anchor: .bottom) }
                }
            }
            .task {
                await store.loadSupportChat()
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    guard !Task.isCancelled else { break }
                    await store.loadSupportChat(showError: false)
                }
            }
            ChatInputDock(placeholder: "Type message", text: $text) {
                store.sendSupportMessage(text)
                text = ""
            }
        }
    }

    private var supportSubtitle: String {
        store.supportAssignedAgent.isEmpty ? "24x7 help • Waiting for agent" : "Connected with \(store.supportAssignedAgent)"
    }

    private var ticketDetail: String {
        var parts = [store.supportAssignedAgent.isEmpty ? "Unassigned" : "Agent: \(store.supportAssignedAgent)"]
        if !store.supportBookingCode.isEmpty { parts.append("Booking: \(store.supportBookingCode)") }
        return parts.joined(separator: " • ")
    }
}

private struct SupportTypingIndicator: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.32)) { context in
            let phase = Int(context.date.timeIntervalSinceReferenceDate / 0.32) % 3
            HStack(spacing: 9) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.rose)
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AppTheme.muted)
                            .frame(width: 6, height: 6)
                            .opacity(index == phase ? 1 : 0.3)
                    }
                }
                Text("ApnaServo is typing")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: 230, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CommercialServicesScreen: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Commercial Services", subtitle: "Offices, shops and buildings", backAction: { store.selectTab(.home) })
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
            InfoNote(text: "Enter the primary contact details for this commercial service request.")
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

    var body: some View {
        CommercialFormShell(title: "Site & Scope", subtitle: store.selectedCommercialServiceTitle, back: { store.back() }) {
            FormField("Site Address", text: $address)
            FormField("Work Scope", text: $scope)
            InfoNote(text: "Inspection request will be shared with the ApnaServo operations team. They will coordinate the visit with you after submission.")
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
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
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
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22))
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
