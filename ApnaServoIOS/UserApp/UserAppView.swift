import SwiftUI

struct UserAppView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 18) {
            hero
            services
            bookings
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Book trusted home repair experts in minutes.")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text("AC, plumber, electrician, laundry and RO services with direct partner chat.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var services: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Popular Services", action: "Refresh") {
                store.refresh()
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(store.services) { service in
                    ServiceTile(service: service, isBusy: store.bookingServiceIDs.contains(service.id)) {
                        store.prepareBooking(for: service)
                    }
                }
            }
        }
    }

    private var bookings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "My Bookings", action: nil, actionHandler: nil)
            if store.isRefreshing && store.userBookings.isEmpty {
                ProgressView("Loading bookings…").frame(maxWidth: .infinity).padding()
            } else if store.userBookings.isEmpty {
                EmptyStateView(title: "No bookings yet", message: "Choose a service above to create your first booking.", image: "calendar.badge.plus")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(store.userBookings) { booking in
                        BookingRow(booking: booking, role: .user, isBusy: store.pendingBookingIDs.contains(booking.id)) {
                            store.showChat(for: booking)
                        }
                    }
                }
            }
        }
    }
}

struct BookingFormView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BookingDraft
    @State private var isSubmitting = false

    init(initialDraft: BookingDraft) { _draft = State(initialValue: initialDraft) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") { Text(draft.service.name).font(.headline) }
                Section("Service details") {
                    TextField("Describe the problem", text: $draft.issue, axis: .vertical).lineLimit(2...5)
                    TextField("Full address", text: $draft.address, axis: .vertical).lineLimit(2...4)
                    TextField("City", text: $draft.city)
                    TextField("Preferred date and time", text: $draft.slot)
                }
                Section("Contact") {
                    TextField("Your name", text: $draft.customerName)
                    TextField("Phone number", text: $draft.customerPhone).keyboardType(.phonePad)
                }
                Section {
                    Button {
                        isSubmitting = true
                        Task {
                            if await store.submitBooking(draft) { dismiss() }
                            isSubmitting = false
                        }
                    } label: {
                        HStack { Spacer(); if isSubmitting { ProgressView() } else { Text("Confirm booking") }; Spacer() }
                    }
                    .disabled(!draft.isValid || isSubmitting)
                } footer: { Text("A booking is created only after the server confirms it.") }
            }
            .navigationTitle("Booking details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(isSubmitting) } }
            .interactiveDismissDisabled(isSubmitting)
        }
    }
}
