import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            UserAppView()
        }
        .task {
            guard store.screen == .splash else { return }
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
        .sheet(isPresented: $store.showDateSheet) {
            DateChoiceSheet()
                .presentationDetents([.height(380)])
        }
        .sheet(isPresented: $store.showTimeSheet) {
            TimeChoiceSheet()
                .presentationDetents([.height(520)])
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
        }
        .padding(20)
        .background(AppTheme.bg)
    }
}

struct DateChoiceSheet: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Date")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            ForEach(dateChoices, id: \.self) { date in
                Button {
                    store.chooseDate(date)
                } label: {
                    HStack {
                        Text(date)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Image(systemName: store.draft.date == date ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(store.draft.date == date ? AppTheme.booking : AppTheme.muted)
                    }
                    .foregroundStyle(AppTheme.ink)
                    .androidCard(padding: 14, radius: 12, border: store.draft.date == date ? AppTheme.booking : AppTheme.line)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(18)
        .background(AppTheme.bg)
    }

    private var dateChoices: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy"
        let calendar = Calendar.current
        return (0..<4).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { return nil }
            if offset == 0 { return "Today, \(formatter.string(from: date))" }
            if offset == 1 { return "Tomorrow, \(formatter.string(from: date))" }
            return formatter.string(from: date)
        }
    }
}

struct TimeChoiceSheet: View {
    @EnvironmentObject private var store: UserAppStore
    private let slots = [
        "08:00 AM - 10:00 AM",
        "10:00 AM - 12:00 PM",
        "12:00 PM - 02:00 PM",
        "02:00 PM - 04:00 PM",
        "04:00 PM - 06:00 PM",
        "06:00 PM - 08:00 PM"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Select Time Slot")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Button {
                    store.showTimeSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: Circle())
                        .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
                }
            }

            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.booking)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.bookingSoft, in: RoundedRectangle(cornerRadius: 12))
                Text(store.draft.date.isEmpty ? "Choose date first" : store.draft.date)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                Spacer()
                Button("Change Date") {
                    store.showTimeSheet = false
                    store.showDateSheet = true
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.booking)
            }

            ForEach(slots, id: \.self) { slot in
                let unavailable = !store.isTimeSlotAvailable(slot)
                Button {
                    if !unavailable {
                        store.chooseTime(slot)
                    }
                } label: {
                    HStack {
                        Text(slot)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(unavailable ? "Closed" : (slot == "10:00 AM - 12:00 PM" ? "Recommended" : "Available"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(unavailable ? AppTheme.muted.opacity(0.7) : (slot == "10:00 AM - 12:00 PM" ? AppTheme.green : AppTheme.muted))
                        Image(systemName: unavailable ? "lock.fill" : (store.draft.time == slot ? "largecircle.fill.circle" : "circle"))
                            .foregroundStyle(unavailable ? AppTheme.muted.opacity(0.6) : (store.draft.time == slot ? AppTheme.booking : AppTheme.muted))
                    }
                    .foregroundStyle(unavailable ? AppTheme.muted : AppTheme.ink)
                    .opacity(unavailable ? 0.58 : 1)
                    .androidCard(padding: 14, radius: 12, border: store.draft.time == slot ? AppTheme.booking : AppTheme.line)
                }
                .buttonStyle(.plain)
                .disabled(unavailable)
            }
        }
        .padding(18)
        .background(AppTheme.bg)
    }
}

struct ProfileSettingsSheet: View {
    @EnvironmentObject private var store: UserAppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 22, weight: .bold))
            Toggle("Payment reminders", isOn: $store.paymentInfoExpanded)
            Toggle("About ApnaServo tips", isOn: $store.aboutInfoExpanded)
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
            Button("Save") { store.showEditProfileSheet = false }
                .roseCTA()
            Spacer()
        }
        .padding(20)
        .background(AppTheme.bg)
    }
}

struct LegalInformationSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Legal & Account")
                    .font(.system(size: 24, weight: .bold))
                Text("Privacy Policy")
                    .font(.system(size: 17, weight: .bold))
                Text("ApnaServo keeps profile, address, booking and support details only for service fulfilment through the live platform.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                Text("Terms")
                    .font(.system(size: 17, weight: .bold))
                Text("Final amount is confirmed only after partner inspection. No upfront payment is collected before service.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
                Text("Delete Account")
                    .font(.system(size: 17, weight: .bold))
                Text("You can request account support or deletion through ApnaServo support. Requests are reviewed according to platform policy.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(20)
        }
        .background(AppTheme.bg)
    }
}
