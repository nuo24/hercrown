import SwiftUI

/// Home (specs/SCREEN-MAP.md `home`): greeting with her streak, streak card, verse of the day, verse search,
/// Today's Reading, "For the season you're in" topic cards, and today's devotional in the reflection card.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var model = HomeModel()
    @State private var showingStreak = false
    @State private var showingSaved = false
    @State private var studyRef: VerseRef?
    @State private var openPlan: ReadingPlan?
    @State private var openDevotional: Devotional?
    @State private var searchRef = HomeView.searchVerses[0].ref

    private var translation: String { BibleStore.offline[app.preferences.translation] == nil ? "kjv" : app.preferences.translation }

    var body: some View {
        ZStack {
            AppGradient()
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    StreakCard(streak: model.streak) { Task { await model.markTodayRead(ref: model.verse?.ref ?? "PSA.23.1") } }
                    if let verse = model.verse { verseOfTheDay(verse) }
                    verseSearch.id("search")
                    if let plan = model.todaysPlan { todaysReading(plan) }
                    season.id("season")
                    if let devotional = model.devotional { devotionalCard(devotional) }
                    Text("\(translationName) · Offline Bible").font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                        .frame(maxWidth: .infinity).padding(.top, 4)
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .refreshable { await model.load(translation: translation) }
            #if DEBUG
            // Review switch: `-hcHomeScroll search|season` scrolls there once loaded.
            .task(id: model.loaded) {
                guard model.loaded, let anchor = UserDefaults.standard.string(forKey: "hcHomeScroll") else { return }
                try? await Task.sleep(for: .milliseconds(300)); proxy.scrollTo(anchor, anchor: .top)
            }
            #endif
            }
        }
        .task { await model.load(translation: translation) }
        .sheet(isPresented: $showingStreak) { StreakSheet(model: model).presentationDetents([.large]) }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: translation) }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: translation) { r in app.openInReader(r) }.presentationDetents([.large])
        }
        .sheet(item: $openPlan) { plan in PlanSheet(planId: plan.id, model: model).presentationDetents([.large]) }
        .sheet(item: $openDevotional) { d in DevotionalSheet(devotional: d, model: model).presentationDetents([.large]) }
        #if DEBUG
        // Review switch: `-hcOpenHome streak|devotional|plan`.
        .task(id: model.loaded) {
            guard model.loaded else { return }
            switch UserDefaults.standard.string(forKey: "hcOpenHome") {
            case "streak": showingStreak = true
            case "devotional": openDevotional = model.devotional
            case "plan": openPlan = model.todaysPlan
            default: break
            }
        }
        #endif
    }

    private var translationName: String {
        ["kjv": "King James Version", "bsb": "Berean Standard Bible", "web": "World English Bible"][translation] ?? "King James Version"
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(greeting).font(.system(size: 32, weight: .semibold)).tracking(-0.8)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Image("cosmos").resizable().scaledToFit().frame(width: 30, height: 30).accessibilityHidden(true)
            }
            .foregroundStyle(Theme.text(scheme))
            Spacer(minLength: 8)
            Button { showingStreak = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "flame").foregroundStyle(Color(hex: 0xD9A35B))
                    Text("\(model.streak.current)").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: 0xD9A35B))
                }
                .frame(height: 42).padding(.horizontal, 13)
                .background(Capsule().fill(Theme.surface(scheme)))
                .overlay(Capsule().strokeBorder(Theme.border(scheme), lineWidth: 0.8))
            }
            .accessibilityLabel("Reading streak, \(model.streak.current) days")
            IconButton(systemName: "bookmark", label: "Saved passages") { showingSaved = true }
        }
        .padding(.top, 6)
    }

    private var greeting: String {
        let name = app.displayName?.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init)
        return name.map { $0 == "Guest" ? "Hi there!" : "Hi, \($0)!" } ?? "Hi there!"
    }

    // MARK: Verse of the day

    private func verseOfTheDay(_ verse: DayVerse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verse of the day").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                    Text(verse.label).font(.system(size: 15, weight: .semibold))
                }
                Spacer()
                Text(BibleStore.offline[verse.translation] ?? verse.translation.uppercased()).font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Theme.border(scheme)))
                    .foregroundStyle(Theme.muted(scheme))
            }
            Text(verse.text ?? "").font(.serif(27, relativeTo: .title2)).lineSpacing(2)
                .padding(.top, 28).padding(.bottom, 26)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button { app.toggleSave(verse.ref) } label: { Image(systemName: app.isSaved(verse.ref) ? "heart.fill" : "heart") }
                    .accessibilityLabel(app.isSaved(verse.ref) ? "Remove from saved" : "Save verse")
                Spacer(); Spacer()
                Button { studyRef = VerseRef(verse.ref) } label: { Image(systemName: "bubble") }.accessibilityLabel("Study this verse")
                Spacer(); Spacer()
                ShareLink(item: "“\(verse.text ?? "")” — \(verse.label) (\(BibleStore.offline[verse.translation] ?? ""))") { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Share verse")
                Spacer()
            }
            .font(.system(size: 19)).foregroundStyle(Theme.text(scheme))
        }
        .foregroundStyle(Theme.text(scheme))
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(scheme == .dark ? Color(hex: 0x141416) : .white))
        .padding(16)
        .background(Image("quiet-sky").resizable().scaledToFill().clipped())
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 14, y: 6)
    }

    // MARK: Verse search

    /// The mockup's passage picker: one well-known verse per onboarding topic.
    static let searchVerses: [(ref: String, title: String)] = [
        ("PSA.23.1", "Peace"), ("PRO.31.25", "Identity"), ("MAT.11.28", "Anxiety"), ("JER.29.11", "Hope"), ("PRO.3.5", "Faith"),
        ("PSA.119.105", "Purpose"), ("PSA.107.1", "Gratitude"), ("PRO.17.17", "Relationships"), ("JAS.1.5", "Wisdom"),
    ]

    private var verseSearch: some View {
        Card(radius: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image("magnifier").resizable().scaledToFit().frame(width: 44, height: 44).accessibilityHidden(true)
                    Text("Verse Search").font(.system(size: 24, weight: .semibold)).tracking(-0.5)
                }
                Text("Choose a passage to read and reflect on.").font(.system(size: 15)).foregroundStyle(Theme.muted(scheme))
                Menu {
                    Picker("Choose a passage to study", selection: $searchRef) {
                        ForEach(Self.searchVerses, id: \.ref) { v in Text("\(label(v.ref)) · \(v.title)").tag(v.ref) }
                    }
                } label: {
                    HStack {
                        Text("\(label(searchRef)) · \(Self.searchVerses.first { $0.ref == searchRef }?.title ?? "")").font(.system(size: 16))
                        Spacer()
                        Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.text(scheme))
                    .padding(.horizontal, 16).frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.border(scheme)))
                }
                Button("Study this verse") {
                    studyRef = VerseRef(searchRef)
                    Task { await Analytics.shared.track("verse_search_studied", ["ref": .string(searchRef)]) }
                }
                .buttonStyle(CapsuleButtonStyle())
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }

    private func label(_ ref: String) -> String { VerseRef(ref).map { BibleStore.shared.label($0) } ?? ref }

    // MARK: Today's Reading

    private func todaysReading(_ plan: ReadingPlan) -> some View {
        Button { openPlan = plan } label: {
            Card(radius: 22) {
                HStack(alignment: .center, spacing: 18) {
                    Image("journal").resizable().scaledToFit().frame(width: 74, height: 84).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today’s Reading").font(.system(size: 22, weight: .semibold)).tracking(-0.4)
                        Text(plan.title).font(.system(size: 15, weight: .semibold))
                        Text(planStatus(plan)).font(.system(size: 14)).foregroundStyle(Theme.muted(scheme))
                        HStack(spacing: 6) {
                            Text(plan.progress == nil ? "View your plan" : "Continue your plan")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14)).foregroundStyle(Theme.muted(scheme)).padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Theme.text(scheme))
            }
        }
        .buttonStyle(.plain)
    }

    private func planStatus(_ plan: ReadingPlan) -> String {
        guard let p = plan.progress else { return "\(plan.days) passages · Read at your own pace" }
        if p.completedAt != nil { return "Completed · all \(plan.days) passages" }
        return "\(p.completedSteps) of \(plan.days) passages read"
    }

    // MARK: For the season you're in

    private var season: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("For the season you’re in").font(.serif(28, relativeTo: .title)).foregroundStyle(Theme.text(scheme))
            Text("A little guidance for today.").font(.system(size: 15)).foregroundStyle(Theme.muted(scheme)).padding(.bottom, 12)
            HStack(alignment: .top, spacing: 12) {
                SeasonCard(art: "faith-hands", title: "Rooted in faith", subtitle: "Find a little reassurance", tint: Color(hex: 0x26352B)) { openTopic("Faith") }
                SeasonCard(art: "purpose-compass", title: "Find your next step", subtitle: "Explore your purpose", tint: Color(hex: 0x24364A)) { openTopic("Purpose") }
            }
        }
        .padding(.top, 8)
    }

    private func openTopic(_ topic: String) {
        app.discoverTopic = topic
        app.requestedTab = .discover
        Task { await Analytics.shared.track("home_topic_opened", ["topic": .string(topic)]) }
    }

    // MARK: Devotional (the mockup's reflection card)

    private func devotionalCard(_ d: Devotional) -> some View {
        Card(radius: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Today’s devotional").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                    Spacer()
                    if let tag = d.tag {
                        Text(tag).font(.system(size: 13)).padding(.horizontal, 10).padding(.vertical, 5)
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.border(scheme)))
                    }
                }
                HStack(alignment: .center, spacing: 12) {
                    Text(d.title).font(.serif(30, relativeTo: .title)).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image("reflection").resizable().scaledToFit().frame(width: 84, height: 84).accessibilityHidden(true)
                }
                Text("\(d.label) · \(d.minutes ?? 1) min read").font(.system(size: 15)).foregroundStyle(Theme.muted(scheme))
                Button { openDevotional = d } label: {
                    HStack(spacing: 6) { Text(d.readAt == nil ? "Read today’s devotional" : "Read it again"); Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)) }
                        .font(.system(size: 16)).padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }
}

/// "0 days · Reading streak · Best", the last seven days, and Mark today as read.
struct StreakCard: View {
    let streak: Streak
    let onMark: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Card(radius: 22) {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(streak.current) \(streak.current == 1 ? "day" : "days")").font(.system(size: 30, weight: .semibold)).tracking(-0.8)
                    Text("Reading streak").font(.system(size: 15)).foregroundStyle(Theme.muted(scheme))
                    Spacer()
                    Text("Best: \(streak.best) \(streak.best == 1 ? "day" : "days")").font(.system(size: 14)).foregroundStyle(Theme.muted(scheme))
                }
                HStack {
                    ForEach(Array(week.enumerated()), id: \.offset) { i, day in
                        VStack(spacing: 10) {
                            Text(day.letter).font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                            ZStack {
                                Circle().fill(day.read ? Color(hex: 0xD9A35B) : Theme.supporting(scheme))
                                Circle().strokeBorder(Theme.border(scheme), lineWidth: 0.8)
                                if day.read { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white) }
                            }
                            .frame(width: 30, height: 30)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.letter), \(day.read ? "read" : "not read")")
                        if i < week.count - 1 { Spacer(minLength: 0) }
                    }
                }
                Button(streak.readToday ? "Today is marked as read" : "Mark today as read", action: onMark)
                    .buttonStyle(CapsuleButtonStyle(kind: .secondary))
                    .disabled(streak.readToday)
                Text(streak.readToday ? "Lovely. Come back tomorrow to keep your streak growing." : "Read a passage, then mark your day complete.")
                    .font(.system(size: 13)).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center)
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }

    /// The server's last seven days, or seven empty days ending today before it has answered.
    private var week: [(letter: String, read: Bool)] {
        let parse = DateFormatter(); parse.dateFormat = "yyyy-MM-dd"; parse.locale = Locale(identifier: "en_US_POSIX")
        let days: [(Date, Bool)] = streak.week.isEmpty
            ? (0..<7).map { (Calendar.current.date(byAdding: .day, value: $0 - 6, to: Date())!, false) }
            : streak.week.compactMap { d in parse.date(from: d.day).map { ($0, d.read) } }
        let letter = DateFormatter(); letter.dateFormat = "EEEEE"
        return days.map { (letter.string(from: $0.0), $0.1) }
    }
}

private struct SeasonCard: View {
    let art: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(art).resizable().scaledToFit().frame(height: 128).frame(maxWidth: .infinity).accessibilityHidden(true)
                Text(title).font(.serif(23, relativeTo: .title3)).fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(.system(size: 13)).opacity(0.85)
                Image(systemName: "arrow.right").font(.system(size: 17)).padding(.top, 4)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(tint))
        }
        .buttonStyle(.plain)
    }
}
