import SwiftUI

struct PartnerAppView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        VStack(spacing: 18) {
            onlineCard
            stats
            bookings
        }
    }

    private var onlineCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(AppTheme.muted)
                .frame(width: 18, height: 18)
                .padding(12)
                .background(AppTheme.softGreen, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Availability setup required")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Text("Partner availability is not connected to the backend yet")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        }
        .cardStyle()
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatTile(title: "Pending", value: "\(store.partnerBookings.filter(\.isPendingPartnerAction).count)", image: "clock.fill", tint: AppTheme.rose)
            StatTile(title: "Active", value: "\(store.partnerBookings.filter { $0.isAssigned && !$0.isTerminal }.count)", image: "briefcase.fill", tint: .blue)
            StatTile(title: "Completed", value: "\(store.partnerBookings.filter { $0.normalizedStatus == "completed" }.count)", image: "checkmark.seal.fill", tint: .green)
        }
    }

    private var bookings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Recent Requests", action: "Refresh") {
                store.refresh()
            }
            if store.isRefreshing && store.partnerBookings.isEmpty {
                ProgressView("Loading requests…").frame(maxWidth: .infinity).padding()
            } else if store.partnerBookings.isEmpty {
                EmptyStateView(title: "No requests", message: "New eligible requests will appear after refresh.", image: "briefcase")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(store.partnerBookings) { booking in
                        VStack(spacing: 8) {
                            BookingRow(booking: booking, role: .partner, isBusy: store.pendingBookingIDs.contains(booking.id)) {
                                store.showChat(for: booking)
                            }
                            if booking.isPendingPartnerAction {
                                HStack {
                                    Button("Reject", role: .destructive) { Task { await store.reject(booking) } }
                                    Spacer()
                                    Button("Accept") { Task { await store.accept(booking) } }.buttonStyle(.borderedProminent)
                                }
                                .disabled(store.pendingBookingIDs.contains(booking.id))
                            }
                        }
                    }
                }
            }
        }
    }
}
