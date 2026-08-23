import SwiftUI
import AuthenticationServices
import UIKit

struct RootView: View {
    @EnvironmentObject private var store: UserAppStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            UserAppView()
        }
        // The app uses a light, image-led visual system. Keeping this fixed also
        // prevents UIKit text fields from adopting white Dark Mode placeholder text.
        .preferredColorScheme(.light)
        .tint(AppTheme.loginRose)
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
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Legal & Account")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Button("Done") { dismiss() }
                }

                legalSection(
                    title: "Privacy Policy",
                    detail: "Explains the account, booking, location, support and notification data ApnaServo processes and how you can delete your account."
                )
                Link("Open Privacy Policy", destination: AppConfig.privacyPolicyURL)
                    .outlineCTA()

                legalSection(
                    title: "Terms & Conditions",
                    detail: "Covers bookings, service quotes, cancellations, customer conduct, support and account responsibilities."
                )
                Link("Open Terms & Conditions", destination: AppConfig.termsURL)
                    .outlineCTA()

                legalSection(
                    title: "Contact Support",
                    detail: "Use authenticated support chat for booking, account, cancellation, privacy or safety assistance."
                )
                Button("Open Help & Support") {
                    dismiss()
                    store.navigate(.support)
                }
                .outlineCTA()

                Divider()

                Label("Permanently Delete Account", systemImage: "trash.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.red)
                Text("This permanently deletes your ApnaServo account, authentication identity, profile, saved addresses, device tokens, support conversations and other personal data. Booking records retained for transaction integrity are de-identified. This action cannot be undone.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                TextField("Reason (optional)", text: $deletionReason, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(AppTheme.ink)
                if store.requiresAppleDeletionAuthorization {
                    Text("For your security, confirm your Apple account before permanent deletion. This also revokes ApnaServo's Sign in with Apple authorization.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    SignInWithAppleButton(.continue) { request in
                        store.prepareAppleAccountDeletion(request)
                    } onCompletion: { result in
                        store.completeAppleAccountDeletionAuthorization(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                Button(role: .destructive) {
                    showDeletionConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        if store.isDeletingAccount { ProgressView() }
                        Text(store.isDeletingAccount ? "Deleting Account…" : "Delete Account Permanently")
                        Spacer()
                    }
                }
                .disabled(store.isDeletingAccount || store.requiresAppleDeletionAuthorization)
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Divider()
                Text("About ApnaServo")
                    .font(.system(size: 17, weight: .bold))
                Text("ApnaServo connects customers with verified service partners for home and commercial service requests in supported areas.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                Text("App version \(appVersion)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
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
            Text("Your authentication identity, profile and personal data will be permanently deleted. Retained booking records will be de-identified. This cannot be undone.")
        }
    }

    private func legalSection(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
