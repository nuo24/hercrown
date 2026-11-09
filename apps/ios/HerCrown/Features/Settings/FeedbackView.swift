import SwiftUI

struct FeedbackView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var category = "Feedback"
    @State private var message = ""
    @State private var sending = false
    @State private var error: String?
    @State private var receipt: String?
    @State private var history: [Ticket] = []

    private struct Ticket: Decodable, Identifiable {
        let id: String
        let category: String
        let message: String
        let status: String
    }
    private struct Inbox: Decodable { let requests: [Ticket] }
    private struct Receipt: Decodable { let id: String }
    private var trimmedMessage: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help Her Crown grow.").font(.serif(23, relativeTo: .title3)).tracking(-0.4)
                Text("Have an idea, or did something feel wrong? Tell us what happened and what you hoped to see.")
                    .font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                Picker("Message type", selection: $category) {
                    Text("Suggest a feature").tag("Feedback")
                    Text("Report a bug").tag("Something isn't working")
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your message").font(.ui(14, weight: .medium))
                    TextEditor(text: $message)
                        .font(.ui(15)).scrollContentBackground(.hidden)
                        .frame(minHeight: 180).padding(12)
                        .background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.muted(scheme).opacity(0.5)))
                        .accessibilityLabel("Your suggestion or bug report")
                        .onChange(of: message) { _, value in
                            if value.count > 5000 { message = String(value.prefix(5000)) }
                            receipt = nil
                        }
                    Text("\(message.count)/5,000 · Please leave out passwords and payment details.")
                        .font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                }
                if let error {
                    Text(error).font(.ui(13)).foregroundStyle(Theme.text(scheme))
                        .accessibilityAddTraits(.updatesFrequently)
                }
                if let receipt {
                    Text("Thank you. Your message is saved as \(receipt).")
                        .font(.ui(14)).accessibilityAddTraits(.updatesFrequently)
                }
                Button(sending ? "Sending…" : "Send message") { Task { await send() } }
                    .buttonStyle(CapsuleButtonStyle())
                    .disabled(sending || trimmedMessage.isEmpty)
                if !history.isEmpty {
                    Text("Your messages").font(.serif(24, relativeTo: .title2)).padding(.top, 12)
                    ForEach(history) { ticket in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(ticket.category == "Feedback" ? "Feature suggestion" : "Bug report")
                                Spacer()
                                Text(ticket.status.capitalized)
                            }
                            .font(.ui(12, weight: .medium))
                            Text(ticket.message).font(.ui(14))
                            Text(ticket.id).font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                        .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border(scheme)))
                    }
                }
            }
            .padding(22).disabled(sending)
        }
        .background(AppGradient()).foregroundStyle(Theme.text(scheme))
        .navigationTitle("Suggestions & bugs").navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .task {
            await Analytics.shared.track("support_opened")
            await loadHistory()
        }
    }

    private func loadHistory() async {
        do {
            let inbox: Inbox = try await app.api.get("/me/support")
            history = inbox.requests.filter { ["Feedback", "Something isn't working"].contains($0.category) }
        } catch {
            self.error = "Your earlier messages couldn’t load. You can still send a message."
        }
    }

    private func send() async {
        sending = true
        error = nil
        defer { sending = false }
        do {
            let result: Receipt = try await app.api.call("POST", "/me/support", json: [
                "category": category, "message": trimmedMessage, "contactPreference": "in_app",
                "appVersion": AppConfig.appVersion
            ])
            message = ""
            receipt = result.id
            await loadHistory()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
