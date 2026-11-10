import SwiftUI

struct CommunityCause: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let category: String
    let photo: String
    let summary: String
    let support: String
    let website: String?
}
struct CommunityRound: Decodable {
    let id: String
    let title: String
    let closesAt: Double
    let preview: Bool
}
struct CommunityGiving: Decodable {
    let totalCents: Int
    let currency: String
    let revenuePercent: Int
}
struct CommunityState: Decodable {
    let giving: CommunityGiving
    let round: CommunityRound?
    let causes: [CommunityCause]
    let ballotNote: String?
    var vote: String?
}

struct CommunityView: View {
    let onExplore: () -> Void
    let onOpenSettings: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var showingSaved = false
    @State private var showingSuggestions = false
    @State private var state: CommunityState?
    @State private var stateAccount: String?
    @State private var failure: String?
    @State private var story: CommunityCause?
    @State private var candidate: CommunityCause?
    @State private var voteAfterStory: CommunityCause?
    @State private var sending = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text("Community").font(.serif(34)).tracking(-0.65).accessibilityAddTraits(.isHeader)
                    Spacer()
                    PageIconButton(glyph: "bookmark", label: "Saved passages") { showingSaved = true }
                    PageIconButton(glyph: "gear", label: "Settings", action: onOpenSettings)
                }.padding(.top, 20).padding(.bottom, 28)
                if let state {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(Double(state.giving.totalCents) / 100, format: .currency(code: state.giving.currency).precision(.fractionLength(0)))
                            .font(.serif(34)).tracking(-0.6)
                        Text("donated so far").font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                    }
                    Text("\(state.giving.revenuePercent)% of revenue goes toward donations.")
                        .font(.ui(9)).tracking(0.4).textCase(.uppercase).foregroundStyle(Theme.muted(scheme)).padding(.top, 5)
                    Divider().padding(.top, 18).padding(.bottom, 24)
                    Text("A little care,\nclose to home.").font(.serif(30)).tracking(-0.6).lineSpacing(0).padding(.bottom, 12)
                    Text("Help guide our future giving. Meet organizations supporting women and girls around the world, then vote for the cause closest to your heart.")
                        .font(.ui(13)).lineSpacing(5).foregroundStyle(Theme.muted(scheme)).padding(.bottom, 9)
                    Button { showingSuggestions = true } label: {
                        Label("Suggest a local cause", systemImage: "arrow.right").labelStyle(TrailingIcon()).font(.ui(13)).frame(minHeight: 44)
                    }.padding(.bottom, 22)
                    Divider()
                    if let round = state.round {
                        HStack(alignment: .firstTextBaseline) {
                            Text(round.title).font(.ui(14, weight: .medium))
                            Spacer()
                            Text("\(state.causes.count) causes · 1 vote").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                        }.padding(.top, 17).padding(.bottom, 22)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16, alignment: .top), GridItem(.flexible(), alignment: .top)], alignment: .leading, spacing: 28) {
                            ForEach(state.causes) { cause in causeTile(cause, selected: state.vote == cause.id) }
                        }
                        Text(state.vote == nil ? "One member. One vote. You can change your choice until \(deadline(round))." : "Your vote is saved. You can change it before \(deadline(round)).")
                            .font(.ui(10)).lineSpacing(5).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 24)
                        if round.preview {
                            Text("Preview ballot · Stock photos illustrate the supplied cause profiles. Recipient details will be confirmed before launch.")
                                .font(.ui(10)).lineSpacing(5).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center).padding(.top, 12)
                        }
                        if let note = state.ballotNote {
                            Text(note).font(.ui(10)).lineSpacing(5).foregroundStyle(Theme.muted(scheme)).padding(.top, 12)
                        }
                    } else {
                        Text("The next ballot is being prepared.").font(.serif(22)).padding(.vertical, 24)
                    }
                } else if failure == nil { ProgressView().frame(maxWidth: .infinity).padding(60) }
                if let failure {
                    Text(failure).font(.ui(13)).padding(.top, 16)
                    Button("Try again") { Task { await load() } }.buttonStyle(CapsuleButtonStyle(kind: .secondary)).padding(.top, 12)
                }
            }.padding(.horizontal, 22).padding(.bottom, 112)
        }
        .scrollIndicators(.hidden).background(Theme.canvas(scheme)).foregroundStyle(Theme.text(scheme)).buttonStyle(.plain)
        .task(id: app.me?.user.id) { await load() }
        .fullScreenCover(isPresented: $showingSaved) { SavedSheet(translation: app.preferences.translation) }
        .sheet(isPresented: $showingSuggestions) { NavigationStack { CommunitySuggestionsView() } }
        .sheet(item: $story, onDismiss: { if let cause = voteAfterStory { voteAfterStory = nil; candidate = cause } }) { cause in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(cause.photo).resizable().scaledToFill().frame(height: 230).clipped().clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(cause.name).font(.serif(30)).tracking(-0.6)
                        Text(cause.summary).font(.ui(14)).lineSpacing(6)
                        Text("Their work").font(.ui(14, weight: .medium))
                        Text(cause.support).font(.ui(14)).lineSpacing(6).foregroundStyle(Theme.muted(scheme))
                        if let website = cause.website, let url = URL(string: website), url.scheme == "https" {
                            Link("Visit official website", destination: url).font(.ui(13, weight: .medium)).tint(Theme.text(scheme))
                        }
                        Text(cause.id == "mercy-multiplied" ? "Representative stock photo, not Mercy Multiplied staff or participants. No endorsement implied." : "Organization program photo, shared with permission confirmed by the owner. No endorsement implied.").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                        Text("A vote never authorizes a payment.").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                        Button(state?.vote == cause.id ? "Your vote is saved" : "Vote for this cause") { voteAfterStory = cause; story = nil }
                            .buttonStyle(CapsuleButtonStyle()).disabled(state?.vote == cause.id)
                        if state?.round?.preview == true { Text("Preview cause profile · representative stock photograph").font(.ui(10)).foregroundStyle(Theme.muted(scheme)) }
                    }.padding(22)
                }.background(Theme.canvas(scheme)).foregroundStyle(Theme.text(scheme))
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { story = nil }.tint(Theme.text(scheme)) } }
            }
        }
        .confirmationDialog(state?.vote == nil ? "Vote for \(candidate?.name ?? "this cause")?" : "Move your vote to \(candidate?.name ?? "this cause")?", isPresented: Binding(get: { candidate != nil }, set: { if !$0 { candidate = nil } }), titleVisibility: .visible, presenting: candidate) { cause in
            Button(state?.vote == nil ? "Confirm vote" : "Change my vote") { Task { await vote(cause) } }
            Button("Cancel", role: .cancel) { candidate = nil }
        } message: { _ in Text("One member, one vote. Your preference helps guide future giving; it does not guarantee a grant, make a donation or charge your account. You can change it before the ballot closes.") }
    }
    private func causeTile(_ cause: CommunityCause, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                Button { story = cause } label: {
                    GeometryReader { g in Image(cause.photo).resizable().scaledToFill().frame(width: g.size.width, height: 192).clipped() }.frame(height: 192).clipShape(RoundedRectangle(cornerRadius: 8))
                }.contentShape(Rectangle()).accessibilityLabel("Read about \(cause.name)")
                Button { candidate = cause } label: {
                    HStack(spacing: 5) { if selected { Image(systemName: "checkmark") }; Text(selected ? "Voted" : "Vote") }
                        .font(.ui(11, weight: .medium)).padding(.horizontal, 14).frame(minHeight: 44)
                        .background(.regularMaterial, in: Capsule()).overlay(Capsule().strokeBorder(.white.opacity(0.5)))
                }.contentShape(Capsule()).padding(9).disabled(sending).accessibilityLabel(selected ? "Your vote for \(cause.name)" : "Vote for \(cause.name)")
            }
            Button { story = cause } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cause.name).font(.serif(21)).tracking(-0.4).fixedSize(horizontal: false, vertical: true)
                    Text(cause.category).font(.ui(9)).tracking(0.5).textCase(.uppercase).foregroundStyle(Theme.muted(scheme)).frame(minHeight: 27, alignment: .topLeading)
                }.padding(.top, 13).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    private static let deadlineFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MMMM d"; f.locale = Locale(identifier: "en_US"); f.timeZone = TimeZone(secondsFromGMT: 0); return f }()
    private func deadline(_ round: CommunityRound) -> String { Self.deadlineFormatter.string(from: Date(timeIntervalSince1970: (round.closesAt - 1) / 1000)) }
    private func load() async {
        guard let userID = app.me?.user.id else { return }
        if stateAccount != userID { state = nil; candidate = nil; story = nil; voteAfterStory = nil; stateAccount = userID }
        failure = nil
        do {
            let response: CommunityState = try await app.api.call("GET", "/me/community")
            guard app.me?.user.id == userID, !Task.isCancelled else { return }
            state = response
        }
        catch { failure = "Community is unavailable right now. Please try again." }
    }
    private func vote(_ cause: CommunityCause) async {
        guard !sending, let round = state?.round, let userID = app.me?.user.id else { return }
        sending = true; defer { sending = false }
        struct Reply: Decodable { let vote: String }
        do {
            let reply: Reply = try await app.api.call("PUT", "/me/community/vote", json: ["roundId": round.id, "causeId": cause.id])
            guard app.me?.user.id == userID else { return }
            state?.vote = reply.vote; failure = nil
        } catch { failure = "Your vote wasn’t saved. Try again when you’re connected." }
    }
}
