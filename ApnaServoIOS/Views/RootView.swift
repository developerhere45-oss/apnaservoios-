import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        if !store.isAuthenticated { tokenCard }
                        rolePicker

                        if store.role == .user {
                            UserAppView()
                        } else {
                            PartnerAppView()
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
                .refreshable { await store.performRefresh() }
            }
            .task {
                await store.performRefresh()
            }
            .navigationDestination(item: $store.selectedBooking) { booking in
                BookingChatView(booking: booking)
            }
            .sheet(item: $store.bookingDraft) { draft in
                BookingFormView(initialDraft: draft).environmentObject(store)
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("Retry") { store.refresh() }
                Button("Dismiss", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "Please try again.") }
            .onChange(of: scenePhase) { phase in
                if phase == .active { store.handleBecameActive() }
                else if phase == .background { store.handleEnteredBackground() }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ApnaServo")
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text("One iOS app for customers and partners")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Image(systemName: "bell")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 44, height: 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
    }

    private var tokenCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Backend token")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            SecureField("Paste Firebase ID token for live backend", text: $store.authToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.footnote)
                .padding(12)
                .background(AppTheme.softPink, in: RoundedRectangle(cornerRadius: 14))

            Text("Temporary developer access only. Production requires Firebase Auth integration.")
                .font(.caption2)
                .foregroundStyle(AppTheme.muted)
        }
        .cardStyle()
    }

    private var rolePicker: some View {
        Picker("App mode", selection: Binding(get: { store.role }, set: { store.setRole($0) })) {
            ForEach(AppRole.allCases) { role in
                Text(role.rawValue).tag(role)
            }
        }
        .pickerStyle(.segmented)
    }
}
