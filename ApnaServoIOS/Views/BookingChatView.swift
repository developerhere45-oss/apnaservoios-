import SwiftUI

struct BookingChatView: View {
    @EnvironmentObject private var store: AppStore
    let booking: Booking
    @State private var draft = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Today")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.rose)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.softPink, in: Capsule())

                        ForEach(store.messages) { message in
                            ChatBubble(message: message, currentRole: store.role)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: store.messages.count) { _ in
                    if let last = store.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            composer
                .padding(12)
                .background(.white)
        }
        .background(AppTheme.background)
        .navigationTitle(store.role == .user ? "Partner Chat" : "Customer Chat")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.loadChat(for: booking)
        }
        .onDisappear { store.stopChatUpdates() }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Type your message...", text: $draft, axis: .vertical)
                .lineLimit(1...3)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(AppTheme.softPink, in: RoundedRectangle(cornerRadius: 18))

            Button {
                let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                draft = ""
                isSending = true
                Task { await store.sendChat(text); isSending = false }
            } label: {
                Group {
                    if isSending { ProgressView().tint(.white) }
                    else { Image(systemName: "paperplane.fill").font(.headline) }
                }
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.rose, in: RoundedRectangle(cornerRadius: 17))
            }
            .disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let currentRole: AppRole

    private var isMine: Bool {
        (currentRole == .user && message.senderRole == "user")
            || (currentRole == .partner && message.senderRole == "partner")
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer(minLength: 50) }
            if !isMine {
                avatar
            }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(isMine ? AppTheme.softPink : .white, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(isMine ? 0 : 0.05), radius: 8, y: 4)
                Text(message.deliveryStatus.isEmpty ? "sent" : message.deliveryStatus)
                    .font(.caption2)
                    .foregroundStyle(isMine ? AppTheme.green : AppTheme.muted)
            }
            if !isMine { Spacer(minLength: 50) }
        }
    }

    private var avatar: some View {
        Text(message.senderRole == "partner" ? "P" : "C")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(message.senderRole == "partner" ? .blue : AppTheme.rose, in: Circle())
    }
}
