import SwiftUI
import UIKit

enum AppTheme {
    static let bg = Color(hex: 0xFFF8F4)
    static let loginBg = Color(hex: 0xFFF8F7)
    static let ink = Color(hex: 0x161616)
    static let muted = Color(hex: 0x605B58)
    static let line = Color(hex: 0xEEE1DD)
    static let rose = Color(hex: 0xD9898D)
    static let roseDark = Color(hex: 0x171717)
    static let roseSoft = Color(hex: 0xF8E1E1)
    static let loginRose = Color(hex: 0xE12A53)
    static let loginRoseDark = Color(hex: 0xC01541)
    static let booking = Color(hex: 0xFF3F5F)
    static let bookingDark = Color(hex: 0x7E0012)
    static let bookingSoft = Color(hex: 0xFFEEF2)
    static let green = Color(hex: 0x16B16F)
    static let greenSoft = Color(hex: 0xE8FAF2)
    static let blue = Color(hex: 0x2D7ADA)
    static let purple = Color(hex: 0x7E58D2)
    static let orange = Color(hex: 0xFF662E)
    static let premier = Color(hex: 0xAA7479)
    static let premierSoft = Color(hex: 0xF9E4E4)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

enum AndroidAsset {
    static func image(_ name: String) -> UIImage? {
        for fileExtension in ["png", "jpg", "jpeg"] {
            if let url = Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "ImportedAndroidAssets"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return UIImage(named: name)
    }
}

struct AndroidAssetImage: View {
    let name: String
    var contentMode: ContentMode = .fit

    var body: some View {
        Group {
            if let image = AndroidAsset.image(name) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ZStack {
                    LinearGradient(colors: [AppTheme.roseSoft, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(name.prefix(2).uppercased())
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.rose)
                }
            }
        }
    }
}

extension View {
    func androidCard(padding: CGFloat = 16, radius: CGFloat = 14, border: Color = AppTheme.line, shadow: CGFloat = 2) -> some View {
        self
            .padding(padding)
            .background(Color.white, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(border, lineWidth: 1))
            .shadow(color: .black.opacity(shadow > 4 ? 0.13 : 0.055), radius: shadow, y: shadow > 4 ? 4 : 2)
    }

    func darkCTA() -> some View {
        self
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: [Color(hex: 0x14181D), Color(hex: 0x080C12)], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 21, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(AppTheme.booking, lineWidth: 1))
            .shadow(color: AppTheme.booking.opacity(0.25), radius: 9, y: 5)
    }

    func roseCTA() -> some View {
        self
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: [AppTheme.booking, AppTheme.loginRose, AppTheme.loginRoseDark], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .shadow(color: AppTheme.booking.opacity(0.28), radius: 10, y: 5)
    }

    func outlineCTA() -> some View {
        self
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
    }
}

struct TopBar: View {
    let title: String
    var subtitle: String = ""
    var backAction: (() -> Void)?
    var trailingTitle: String = ""
    var trailingIcon: String = ""
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if let backAction {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.rose)
                        .frame(width: 44, height: 44)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let trailingAction {
                if !trailingIcon.isEmpty {
                    Button(action: trailingAction) {
                        Image(systemName: trailingIcon)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.rose)
                            .frame(width: 42, height: 42)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.line, lineWidth: 1))
                    }
                } else if !trailingTitle.isEmpty {
                    Button(trailingTitle, action: trailingAction)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.rose)
                        .frame(height: 38)
                        .padding(.horizontal, 12)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.line, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct SectionTitle: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.rose)
            }
        }
    }
}

struct ServiceLogo: View {
    let service: ServiceItem
    var size: CGFloat = 58
    var boxed = true

    var body: some View {
        ZStack {
            if boxed {
                LinearGradient(colors: [.white, Color(hex: 0xFFF5F5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Color.clear
            }
            AndroidAssetImage(name: serviceLogoAsset(service), contentMode: .fit)
                .padding(boxed ? 5 : 1)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: boxed ? 11 : 8, style: .continuous))
        .overlay {
            if boxed {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color(hex: 0xEFDADA), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(boxed ? 0.12 : 0), radius: boxed ? 3 : 0, y: boxed ? 2 : 0)
    }
}

struct BookingStepper: View {
    let current: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                stepCircle("1", active: current >= 1)
                line(active: current >= 2)
                stepCircle("2", active: current >= 2)
                line(active: current >= 3)
                stepCircle("3", active: current >= 3)
            }
            HStack {
                stepLabel("Service", active: current >= 1)
                stepLabel("Date & Address", active: current >= 2)
                stepLabel("Confirm", active: current >= 3)
            }
        }
        .padding(.horizontal, 34)
        .padding(.top, 6)
        .padding(.bottom, 16)
    }

    private func stepCircle(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(active ? .white : AppTheme.ink)
            .frame(width: 36, height: 36)
            .background(active ? AppTheme.green : Color(hex: 0xE8E8E8), in: Circle())
            .shadow(color: active ? AppTheme.green.opacity(0.25) : .clear, radius: 5, y: 3)
    }

    private func line(active: Bool) -> some View {
        Rectangle()
            .fill(active ? AppTheme.green : AppTheme.line)
            .frame(height: 2)
    }

    private func stepLabel(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.system(size: 10, weight: active ? .bold : .regular))
            .foregroundStyle(active ? AppTheme.green : AppTheme.ink)
            .frame(maxWidth: .infinity)
    }
}

struct BottomNav: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        HStack(spacing: 0) {
            nav("Home", "house.fill", .home)
            nav("Bookings", "list.bullet.rectangle.fill", .bookings)
            nav("Profile", "person.fill", .profile)
        }
        .frame(height: 80)
        .padding(.horizontal, 12)
        .background(Color.white)
        .overlay(Rectangle().fill(AppTheme.line).frame(height: 1), alignment: .top)
        .shadow(color: .black.opacity(0.12), radius: 16, y: -3)
    }

    private func nav(_ title: String, _ image: String, _ target: UserScreen) -> some View {
        Button {
            store.navigate(target)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: image)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: store.screen == target ? .bold : .regular))
            }
            .foregroundStyle(store.screen == target ? AppTheme.rose : Color(hex: 0x707070))
            .opacity(store.screen == target ? 1 : 0.76)
            .offset(y: store.screen == target ? -6 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyState: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.rose)
                .frame(width: 52, height: 52)
                .background(AppTheme.roseSoft, in: Circle())
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .androidCard(padding: 18, radius: 18)
    }
}

func serviceLogoAsset(_ service: ServiceItem) -> String {
    switch service.id {
    case "ac": return "service_logo_ac"
    case "plumbing": return "service_logo_plumbing"
    case "electrician": return "service_logo_electrician"
    case "carpenter": return "service_home_carpenter"
    case "painting": return "service_home_painting"
    case "interior": return "service_home_interior"
    case "roadside": return "service_home_roadside"
    case "cleaning": return "service_logo_cleaning"
    case "laundry": return "service_home_laundry"
    case "pest": return "ic_service_pest_logo"
    case "ro": return "ro_service_logo"
    case "appliances": return "service_logo_appliances"
    default: return "apna_servo_wordmark"
    }
}

func serviceHomeAsset(_ service: ServiceItem) -> String {
    switch service.id {
    case "ac": return "service_home_ac"
    case "plumbing": return "service_home_plumbing"
    case "electrician": return "service_home_electrician"
    case "carpenter": return "service_home_carpenter"
    case "painting": return "service_home_painting"
    case "interior": return "service_home_interior"
    case "roadside": return "service_home_roadside"
    case "cleaning": return "service_home_cleaning"
    case "laundry": return "service_home_laundry"
    case "pest": return "service_home_pest"
    case "ro": return "service_home_ro"
    case "appliances": return "service_home_appliances"
    default: return serviceLogoAsset(service)
    }
}

func heroAsset(_ service: ServiceItem) -> String {
    switch service.id {
    case "ro": return "hero_ro_background"
    case "ac": return "hero_banner_ac"
    case "electrician": return "hero_banner_electrician"
    case "plumbing": return "hero_banner_plumbing"
    case "laundry": return "hero_banner_laundry"
    case "roadside": return "hero_banner_roadside"
    case "painting": return "hero_banner_painting"
    case "appliances": return "hero_banner_appliances"
    default: return serviceHomeAsset(service)
    }
}

func bannerTitle(_ service: ServiceItem) -> String {
    switch service.id {
    case "ro": return "RO SERVICE"
    case "ac": return "AC REPAIR"
    case "electrician": return "ELECTRICIAN"
    case "plumbing": return "PLUMBER"
    case "laundry": return "LAUNDRY"
    case "roadside": return "ROADSIDE"
    case "appliances": return "APPLIANCES"
    default: return service.name.uppercased()
    }
}

func bannerLine(_ service: ServiceItem) -> String {
    switch service.id {
    case "ro": return "Filter - Leakage - Installation"
    case "ac": return "Inspection - Cleaning - Gas refill"
    case "electrician": return "Wiring - Fan - MCB"
    case "plumbing": return "Leakage - Tap - Drain"
    case "laundry": return "Pickup - Wash - Iron"
    case "roadside": return "Jump-start - Tyre - Towing"
    case "appliances": return "Repair - Service - Install"
    default: return "\(service.arrival) booking - No upfront payment"
    }
}
