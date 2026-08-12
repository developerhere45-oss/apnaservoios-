import SwiftUI

enum AppTheme {
    static let rose = Color(red: 239 / 255, green: 77 / 255, blue: 112 / 255)
    static let ink = Color(red: 31 / 255, green: 29 / 255, blue: 34 / 255)
    static let muted = Color(red: 110 / 255, green: 101 / 255, blue: 105 / 255)
    static let background = Color(red: 255 / 255, green: 247 / 255, blue: 245 / 255)
    static let softPink = Color(red: 255 / 255, green: 235 / 255, blue: 240 / 255)
    static let green = Color(red: 26 / 255, green: 176 / 255, blue: 111 / 255)
    static let softGreen = Color(red: 232 / 255, green: 250 / 255, blue: 242 / 255)
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }
}

struct SectionTitle: View {
    let title: String
    let action: String?
    let actionHandler: (() -> Void)?

    init(title: String, action: String?, actionHandler: (() -> Void)?) {
        self.title = title
        self.action = action
        self.actionHandler = actionHandler
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            if let action, let actionHandler {
                Button(action, action: actionHandler)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.rose)
            }
        }
    }
}

struct ServiceTile: View {
    let service: ServiceItem
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: service.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 15))
                Text(service.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                Text(service.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
                Text(isBusy ? "Booking…" : "Book")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.rose)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }

    private var tint: Color {
        switch service.tintName {
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "cyan": return .cyan
        default: return AppTheme.rose
        }
    }
}

struct BookingRow: View {
    let booking: Booking
    let role: AppRole
    let isBusy: Bool
    let chatAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(accent)
            }
            .frame(width: 46, height: 46)
            .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 5) {
                Text(booking.serviceName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text(role == .user ? booking.partnerName : booking.customerName)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                Text(booking.slot)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            VStack(spacing: 8) {
                Text(booking.statusLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(booking.isAssigned ? AppTheme.green : AppTheme.rose)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(booking.isAssigned ? AppTheme.softGreen : AppTheme.softPink, in: Capsule())
                Button(isBusy ? "Working…" : "Chat", action: chatAction)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.rose, in: Capsule())
                    .disabled(isBusy || !booking.canOpenChat)
            }
        }
        .cardStyle()
    }

    private var accent: Color {
        booking.isAssigned ? AppTheme.green : AppTheme.rose
    }

    private var icon: String {
        switch booking.serviceCategory {
        case "ro": return "drop.fill"
        case "laundry": return "washer"
        case "plumbing": return "wrench.and.screwdriver"
        case "electrician": return "bolt.fill"
        default: return "calendar"
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let image: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: image)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.14), in: Circle())
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let image: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: image).font(.title2).foregroundStyle(AppTheme.muted)
            Text(title).font(.headline).foregroundStyle(AppTheme.ink)
            Text(message).font(.caption).foregroundStyle(AppTheme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}
