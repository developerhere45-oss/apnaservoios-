import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var store: UserAppStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            UserAppView()
        }
        .task {
            store.configureAppServices()
            guard store.screen == .splash else { return }
            if await store.restoreAuthenticatedSession() { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            store.finishSplash()
        }
        .alert("ApnaServo", isPresented: Binding(
            get: { !store.toastMessage.isEmpty },
            set: { if !$0 { store.toastMessage = "" } }
        )) {
            Button("OK", role: .cancel) { store.toastMessage = "" }
        } message: {
            Text(store.toastMessage)
        }
        .sheet(isPresented: $store.showLoginSheet) {
            LoginDetailsSheet()
                .presentationDetents([.height(330)])
        }
        .sheet(isPresented: $store.showSettingsSheet) {
            ProfileSettingsSheet()
                .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $store.showEditProfileSheet) {
            EditProfileSheet()
                .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $store.showLegalSheet) {
            LegalInformationSheet()
                .presentationDetents([.large])
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            Task {
                await store.refreshBookings()
                if let booking = store.latestBooking,
                   !["completed", "cancelled", "rejected"].contains(booking.status) {
                    store.startBookingPolling()
                }
            }
        }
    }
}

struct LoginDetailsSheet: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var name = ""
    @State private var value = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Continue with \(store.loginMode)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text("Enter your details to continue securely.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)

            TextField("Full name", text: $name)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.line, lineWidth: 1))

            TextField(store.loginMode == "Email" ? "Email address" : "Mobile number", text: $value)
                .keyboardType(store.loginMode == "Email" ? .emailAddress : .phonePad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.line, lineWidth: 1))

            Button("Continue") {
                store.completeLogin(name: name, value: value)
            }
            .roseCTA()
            .disabled(store.isAuthenticating)
            .overlay {
                if store.isAuthenticating {
                    ProgressView().tint(.white)
                }
            }
        }
        .padding(20)
        .background(AppTheme.bg)
    }
}

struct ProfileSettingsSheet: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 22, weight: .bold))
            Button {
                Task { await store.enableBookingNotifications() }
            } label: {
                Label("Enable Booking Notifications", systemImage: "bell.badge")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Text("Notifications are requested only when you choose to enable booking updates.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
            Divider()
            Button("Close") { store.showSettingsSheet = false }
                .outlineCTA()
            Spacer()
        }
        .padding(20)
        .background(AppTheme.bg)
    }
}

struct EditProfileSheet: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Profile")
                .font(.system(size: 22, weight: .bold))
            TextField("Name", text: $store.profile.name)
                .textFieldStyle(.roundedBorder)
            TextField("Phone", text: $store.profile.phone)
                .keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $store.profile.email)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            Button("Save") { Task { await store.saveProfileChanges() } }
                .roseCTA()
            Spacer()
        }
        .padding(20)
        .background(AppTheme.bg)
    }
}

struct LegalInformationSheet: View {
    @EnvironmentObject private var store: UserAppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showDeletionConfirmation = false
    @State private var deletionReason = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Legal & Account")
                    .font(.system(size: 24, weight: .bold))
                Text("Privacy Policy")
                    .font(.system(size: 17, weight: .bold))
                Text("ApnaServo keeps profile, address, booking and support details only for service fulfilment and live service updates.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                Button("Open Full Privacy Policy") {
                    UIApplication.shared.open(AppConfig.privacyPolicyURL)
                }
                .outlineCTA()
                Text("Terms")
                    .font(.system(size: 17, weight: .bold))
                Text("Final amount is confirmed after inspection. No upfront payment is collected before service completion.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                Text("Delete Account")
                    .font(.system(size: 17, weight: .bold))
                Text("Permanently deletes your account, profile, saved addresses, device tokens, support conversations and other personal data. Booking records that must be retained are de-identified. You will be signed out immediately.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                TextField("Reason (optional)", text: $deletionReason, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button("Delete Account", role: .destructive) {
                    showDeletionConfirmation = true
                }
                .disabled(store.isDeletingAccount)
                .outlineCTA()
            }
            .padding(20)
        }
        .background(AppTheme.bg)
        .confirmationDialog(
            "Permanently delete your account?",
            isPresented: $showDeletionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task {
                    if await store.requestAccountDeletion(reason: deletionReason) {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and cannot be undone.")
        }
    }
}
