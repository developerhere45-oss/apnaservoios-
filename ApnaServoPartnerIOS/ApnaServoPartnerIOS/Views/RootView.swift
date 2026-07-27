import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            if store.loggedIn {
                PartnerAppView()
            } else {
                PartnerLoginView()
            }
        }
        .alert("ApnaServo Partner", isPresented: Binding(
            get: { !store.errorMessage.isEmpty },
            set: { if !$0 { store.errorMessage = "" } }
        )) {
            Button("OK", role: .cancel) { store.errorMessage = "" }
        } message: {
            Text(store.errorMessage)
        }
        .alert("Done", isPresented: Binding(
            get: { !store.infoMessage.isEmpty },
            set: { if !$0 { store.infoMessage = "" } }
        )) {
            Button("OK", role: .cancel) { store.infoMessage = "" }
        } message: {
            Text(store.infoMessage)
        }
        .sheet(isPresented: $store.showFinalAmountSheet) {
            FinalAmountSheet()
                .presentationDetents([.height(330)])
        }
    }
}

struct FinalAmountSheet: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Send Final Amount")
                .font(.title2.weight(.black))
                .foregroundStyle(AppTheme.ink)
            Text("Customer will approve this quote before the booking is completed.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
            TextField("Amount in rupees", text: $store.finalAmountInput)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            Button("Send for Approval") {
                store.submitFinalAmount()
            }
            .primaryButton()
            Button("Close") {
                store.showFinalAmountSheet = false
            }
            .outlineButton()
            Spacer()
        }
        .padding(20)
        .background(AppTheme.bg)
    }
}

struct PartnerLoginView: View {
    @EnvironmentObject private var store: PartnerAppStore

    var body: some View {
        ZStack {
            AndroidAssetImage(name: "partner_login_bg", contentMode: .fill)
                .ignoresSafeArea()
                .opacity(0.22)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    AndroidAssetImage(name: "apna_servo_logo")
                        .frame(width: 132, height: 70)
                    Text("ApnaServo Partner")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(AppTheme.roseDark)
                    Text("Login Existing Partner")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Go online, receive bookings, accept jobs, update service status and track earnings.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.top, 28)

                VStack(spacing: 12) {
                    TextField("Partner name", text: $store.profile.name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)
                    TextField("Phone number", text: $store.profile.phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Email optional", text: $store.profile.email)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                    Picker("Partner type", selection: Binding(
                        get: { store.role },
                        set: { store.setRole($0) }
                    )) {
                        ForEach(PartnerRole.allCases) { role in
                            Text(role.label).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    if store.role == .individual {
                        skillGrid
                    }
                    if store.role == .laundryOwner {
                        laundryBusinessFields
                    }
                    if store.role == .cleaningStaff {
                        Label(
                            "The current Android backend has no Cleaning Staff session API.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.orange)
                    }
                    Button("Continue") {
                        store.completeLogin()
                    }
                    .primaryButton()
                    Button {
                        store.infoMessage = "Google sign-in uses Firebase Auth when the Firebase and GoogleSignIn packages are added in Xcode."
                    } label: {
                        Label("Continue with Google", systemImage: "g.circle.fill")
                            .outlineButton()
                    }
                }
                .cardStyle()
            }
            .padding(18)
            }
        }
    }

    private var skillGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Services")
                .font(.headline.weight(.bold))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(PartnerSkill.allCases) { skill in
                    let selected = store.profile.skills.contains(skill)
                    Button(skill.label) {
                        store.setSkill(skill, selected: !selected)
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(selected ? .white : AppTheme.ink)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(selected ? AppTheme.rose : AppTheme.roseSoft, in: Capsule())
                }
            }
        }
    }

    private var laundryBusinessFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Laundry Business")
                .font(.headline.weight(.bold))
            TextField("Shop name", text: businessBinding(\.shopName))
                .textFieldStyle(.roundedBorder)
            TextField("Shop license number", text: businessBinding(\.shopLicenseNumber))
                .textFieldStyle(.roundedBorder)
            TextField("Shop location", text: businessBinding(\.shopLocation))
                .textFieldStyle(.roundedBorder)
        }
    }

    private func businessBinding(_ keyPath: WritableKeyPath<LaundryBusiness, String>) -> Binding<String> {
        Binding(
            get: { (store.profile.laundryBusiness ?? .empty)[keyPath: keyPath] },
            set: { value in
                var business = store.profile.laundryBusiness ?? .empty
                business[keyPath: keyPath] = value
                business.ownerName = store.profile.name
                business.ownerPhone = store.profile.phone
                store.profile.laundryBusiness = business
            }
        )
    }
}
