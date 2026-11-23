import SwiftUI

struct CauseSuggestion: Codable, Identifiable {
    var id: String = ""
    var name = ""
    var type = "Charity"
    var city = ""
    var website = ""
    var reason = ""
    var status = "submitted"
}
struct CommunitySuggestionsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var suggestions: [CauseSuggestion] = []
    @State private var editing: CauseSuggestion?
    @State private var loading = true
    @State private var error: String?
    private struct Inbox: Decodable { let suggestions: [CauseSuggestion] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("A cause close to home?").font(.serif(30)).tracking(-0.6)
                Text("Suggest a charity, local church, or community project supporting women and girls. Every suggestion is reviewed; submitting one doesn’t guarantee a place on the ballot.")
                    .font(.ui(14)).lineSpacing(6).foregroundStyle(Theme.muted(scheme))
                Button("Suggest a cause") { editing = CauseSuggestion() }.buttonStyle(CapsuleButtonStyle())
                if loading { ProgressView().frame(maxWidth: .infinity) }
                if let error { Text(error).font(.ui(13)); Button("Try again") { Task { await load() } } }
                if !suggestions.isEmpty { Text("Your suggestions").font(.ui(14, weight: .medium)).padding(.top, 10) }
                ForEach(suggestions) { suggestion in
                    Button { editing = suggestion } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 7) {
                                Text(suggestion.name).font(.serif(23))
                                Text([suggestion.type, suggestion.city, suggestion.status.capitalized].filter { !$0.isEmpty }.joined(separator: " · ")).font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                            }
                            Spacer(); Image(systemName: "chevron.right").font(.ui(13))
                        }.padding(.vertical, 16).overlay(alignment: .bottom) { Divider() }
                    }.buttonStyle(.plain)
                }
            }.padding(22)
        }.background(Theme.canvas(scheme)).foregroundStyle(Theme.text(scheme))
            .navigationTitle("Suggest a cause").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.tint(Theme.accent(scheme)) } }
            .task { await load() }
            .sheet(item: $editing, onDismiss: { Task { await load() } }) { suggestion in NavigationStack { CauseSuggestionEditor(suggestion: suggestion) } }
    }
    private func load() async {
        loading = true; defer { loading = false }; error = nil
        do { let reply: Inbox = try await app.api.call("GET", "/me/community/suggestions"); suggestions = reply.suggestions }
        catch { self.error = "Your suggestions couldn’t load. Please try again." }
    }
}

private struct CauseSuggestionEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State var suggestion: CauseSuggestion
    @State private var saving = false
    @State private var error: String?
    @State private var saved = false
    @FocusState private var field: String?
    private var readOnly: Bool { suggestion.status != "submitted" }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if saved {
                    Image.illustration("gratitude-basket").resizable().scaledToFit().frame(height: 100).frame(maxWidth: .infinity)
                    Text("Thank you for sharing.").font(.serif(30))
                    Text("Your suggestion is saved for review. We’ll take a thoughtful look before choosing a future ballot.").font(.ui(14)).lineSpacing(6)
                    Button("View my suggestions") { dismiss() }.buttonStyle(CapsuleButtonStyle())
                } else {
                    Text("Tell us a little about them.").font(.serif(30)).tracking(-0.6)
                    textField("Name", key: "name", text: $suggestion.name, max: 90)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type").font(.ui(13, weight: .medium))
                        Picker("Type", selection: $suggestion.type) { ForEach(["Charity", "Local church", "Community project"], id: \.self) { Text($0).tag($0) } }.tint(Theme.accent(scheme))
                    }
                    textField("City (optional)", key: "city", text: $suggestion.city, max: 90)
                    textField("Website (optional)", key: "website", text: $suggestion.website, max: 500)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why this cause?").font(.ui(13, weight: .medium))
                        TextEditor(text: $suggestion.reason).font(.ui(15)).scrollContentBackground(.hidden).focused($field, equals: "reason")
                            .frame(minHeight: 150).padding(12).background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.muted(scheme).opacity(0.25)))
                            .onChange(of: suggestion.reason) { _, value in if value.count > 500 { suggestion.reason = String(value.prefix(500)) } }
                        Text("\(suggestion.reason.count)/500 · Please leave out private or payment information.").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                    }
                    if let error { Text(error).font(.ui(13)).accessibilityAddTraits(.updatesFrequently) }
                    if readOnly { Text("This suggestion is already being reviewed and can no longer be edited.").font(.ui(13)) }
                    else { Button(saving ? "Saving…" : "Save suggestion") { Task { await save() } }.buttonStyle(CapsuleButtonStyle()).disabled(saving) }
                }
            }.padding(22)
        }.background(Theme.canvas(scheme)).foregroundStyle(Theme.text(scheme)).navigationTitle("Suggest a cause").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.tint(Theme.accent(scheme)) } }
    }
    private func textField(_ title: String, key: String, text: Binding<String>, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.ui(13, weight: .medium))
            TextField(title, text: text).font(.ui(15)).textInputAutocapitalization(key == "website" ? .never : .words)
                .autocorrectionDisabled(key == "website").keyboardType(key == "website" ? .URL : .default).focused($field, equals: key)
                .padding(14).background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.muted(scheme).opacity(0.25)))
                .onChange(of: text.wrappedValue) { _, value in if value.count > max { text.wrappedValue = String(value.prefix(max)) } }
        }
    }
    private func save() async {
        if suggestion.name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 { error = "Please enter the cause’s name."; field = "name"; return }
        if !suggestion.website.isEmpty, !["http", "https"].contains(URL(string: suggestion.website)?.scheme?.lowercased() ?? "") { error = "Please enter the full website, starting with https://."; field = "website"; return }
        if suggestion.reason.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 { error = "Tell us a little more—at least 10 characters."; field = "reason"; return }
        saving = true; defer { saving = false }; error = nil; field = nil
        struct Receipt: Decodable { let id: String }
        do {
            let _: Receipt = try await app.api.call(suggestion.id.isEmpty ? "POST" : "PATCH", "/me/community/suggestions" + (suggestion.id.isEmpty ? "" : "/\(suggestion.id)"), json: ["name": suggestion.name, "type": suggestion.type, "city": suggestion.city, "website": suggestion.website, "reason": suggestion.reason])
            saved = true
        } catch { self.error = "Your suggestion wasn’t saved. Please try again." }
    }
}
