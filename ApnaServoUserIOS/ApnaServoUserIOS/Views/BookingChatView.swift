import SwiftUI

struct BookingChatView: View {
    @EnvironmentObject private var store: UserAppStore
    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                title: store.latestBooking?.serviceName ?? "Booking Chat",
                subtitle: store.latestBooking?.displayId ?? "Partner messages",
                backAction: { store.navigate(.track) },
                trailingTitle: "Status"
            ) {
                store.navigate(.track)
            }

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        if store.bookingChatMessages.isEmpty {
                            EmptyState(title: "No chat yet", subtitle: "Chat opens after partner assignment.")
                        } else {
                            ForEach(store.bookingChatMessages) { message in
                                ChatMessageBubble(message: message, isMe: message.senderRole == "user")
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(18)
                }
                .onChange(of: store.bookingChatMessages.count) { _ in
                    if let last = store.bookingChatMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            ChatInputDock(placeholder: "Message partner", text: $text) {
                store.sendBookingChat(text)
                text = ""
            }
        }
        .background(AppTheme.bg)
        .task(id: store.latestBooking?.id) {
            while !Task.isCancelled {
                await store.refreshBookingChat()
                try? await Task.sleep(nanoseconds: 2_500_000_000)
            }
        }
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 42) }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 5) {
                Text(message.senderName.isEmpty ? fallbackSender : message.senderName)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(isMe ? .white.opacity(0.82) : AppTheme.muted)
                Text(message.message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isMe ? .white : AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !message.deliveryStatus.isEmpty {
                    Text(message.deliveryStatus.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(isMe ? .white.opacity(0.68) : AppTheme.muted)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(isMe ? AppTheme.booking : Color.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(isMe ? Color.clear : AppTheme.line, lineWidth: 1))
            .shadow(color: .black.opacity(isMe ? 0.10 : 0.05), radius: 5, y: 2)
            if !isMe { Spacer(minLength: 42) }
        }
    }

    private var fallbackSender: String {
        isMe ? "You" : "ApnaServo"
    }
}

struct ChatInputDock: View {
    let placeholder: String
    @Binding var text: String
    let send: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.line, lineWidth: 1))

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.booking, in: Circle())
                    .shadow(color: AppTheme.booking.opacity(0.25), radius: 6, y: 3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(Rectangle().fill(AppTheme.line).frame(height: 1), alignment: .top)
    }
}
