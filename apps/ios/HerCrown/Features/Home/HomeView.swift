import SwiftUI

/// Home (specs/SCREEN-MAP.md `home`): greeting with her streak, streak card, verse of the day, verse search,
/// Today's Reading, "For the season you're in" topic cards, and today's devotional in the reflection card.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var model = HomeModel()
    @State private var showingStreak = false
    @State private var showingSaved = false
    @State private var showingSettings = false
    @State private var studyRef: VerseRef?
    @State private var openPlan: ReadingPlan?
    @State private var showingPlans = false
    @State private var openDevotional: Devotional?
    @State private var searchRef = HomeView.searchVerses[0].ref

    private var translation: String { BibleStore.offline[app.preferences.translation] == nil ? "kjv" : app.preferences.translation }

    var body: some View {
        ZStack {
            AppGradient()
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    // .home-stack: 20 pt gutters, 16 pt between cards.
                    VStack(alignment: .leading, spacing: 16) {
                        if let trial = app.membership.subscription?.trial, app.membership.subscription?.isTrial == true,
                           Date().timeIntervalSince1970 * 1000 >= trial.remindFrom { trialNotice(trial) }
                        StreakCard(streak: model.streak) { Task { await model.markTodayRead(ref: model.verse?.ref ?? "PSA.23.1") } }
                        if let verse = model.verse { verseOfTheDay(verse) }
                        verseSearch.id("search")
                        todaysReading
                        season.id("season")
                        if let devotional = model.devotional { devotionalCard(devotional) }
                        Text("\(translationName) · Offline Bible").font(.system(size: 11)).foregroundStyle(Theme.muted(scheme))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .padding(.bottom, 124)
            }
            .refreshable { await model.load(translation: translation) }
            .clipped() // content stops at the status bar, as in the mockup
            #if DEBUG
            // Review switch: `-hcHomeScroll search|season` scrolls there once loaded.
            .task(id: model.loaded) {
                guard model.loaded, let anchor = UserDefaults.standard.string(forKey: "hcHomeScroll") else { return }
                try? await Task.sleep(for: .milliseconds(300)); proxy.scrollTo(anchor, anchor: .top)
            }
            #endif
            }
        }
        // Reload once she's signed in (a brand-new guest signs in while Home is already on screen).
        .task(id: app.me?.user.id) { await model.load(translation: translation) }
        .sheet(isPresented: $showingStreak) { StreakSheet(model: model).presentationDetents([.large]) }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: translation) }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingPlans) { PlansListSheet(model: model) { plan in showingPlans = false; openPlan = plan }.presentationDetents([.large]) }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: translation) { r in app.openInReader(r) }.presentationDetents([.large])
        }
        .sheet(item: $openPlan) { plan in PlanSheet(planId: plan.id, model: model).presentationDetents([.large]) }
        .sheet(item: $openDevotional) { d in DevotionalSheet(devotional: d, model: model).presentationDetents([.large]) }
        #if DEBUG
        // Review switch: `-hcOpenHome streak|devotional|plan|plans|saved|settings`.
        .task(id: model.loaded) {
            guard model.loaded else { return }
            switch UserDefaults.standard.string(forKey: "hcOpenHome") {
            case "streak": showingStreak = true
            case "devotional": openDevotional = model.devotional
            case "plan": openPlan = model.todaysPlan
            case "plans": showingPlans = true
            case "saved": showingSaved = true
            case "settings": showingSettings = true
            default: break
            }
        }
        #endif
    }

    private var translationName: String {
        ["kjv": "King James Version", "bsb": "Berean Standard Bible", "web": "World English Bible"][translation] ?? "King James Version"
    }

    // MARK: Header (.app-header: 20/20/16 padding, 28 pt greeting, 44 pt icon buttons 4 apart)

    private var header: some View {
        HStack(spacing: 4) {
            HStack(spacing: 8) {
                Text(greeting).font(.system(size: 28)).tracking(-0.8)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Image("cosmos").resizable().scaledToFit().frame(width: 30, height: 36).accessibilityHidden(true)
            }
            .foregroundStyle(Theme.text(scheme))
            Spacer(minLength: 8)
            Button { showingStreak = true } label: {
                HStack(spacing: 3) {
                    Image(systemName: "flame").font(.system(size: 17))
                    Text("\(model.streak.current)").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.streak(scheme))
                .frame(width: 52, height: 44)
                .iconSurface(Ellipse())
            }
            .accessibilityLabel("Reading streak, \(model.streak.current) days")
            IconButton(systemName: "bookmark", label: "Saved passages") { showingSaved = true }
            IconButton(systemName: "gearshape", label: "Settings") { showingSettings = true }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var greeting: String {
        let name = app.displayName?.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init)
        return name.map { $0 == "Guest" ? "Hi there!" : "Hi, \($0)!" } ?? "Hi there!"
    }

    // MARK: Trial notice (docs/trial-reminder.md: from 2 days before the trial converts)

    private func trialNotice(_ trial: Membership.Trial) -> some View {
        let ends = Date(timeIntervalSince1970: trial.endsAt / 1000)
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your free trial ends \(ends.formatted(.relative(presentation: .named)))").font(.system(size: 14, weight: .semibold))
                Text(trial.convertsToPaid
                     ? "Her Crown Plus becomes a paid plan on \(ends.formatted(date: .abbreviated, time: .omitted)). To avoid being charged, cancel before then."
                     : "Plus ends on \(ends.formatted(date: .abbreviated, time: .omitted)). You won’t be charged.")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                if trial.convertsToPaid, let url = URL(string: trial.manageUrl) {
                    Link("Manage subscription", destination: url).font(.system(size: 13, weight: .semibold)).padding(.top, 2)
                }
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }

    // MARK: Verse of the day (.verse-stage: sky, 20 radius, 16 inset; .daily-card: 14 radius, 20/20/12)

    private func verseOfTheDay(_ verse: DayVerse) -> some View {
        let dark = scheme == .dark
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Verse of the day").font(.system(size: 11)).foregroundStyle(Theme.muted(scheme))
                    Text(verse.label).font(.system(size: 14, weight: .medium))
                }
                Spacer()
                Badge(text: BibleStore.offline[verse.translation] ?? verse.translation.uppercased())
            }
            Text(verse.text ?? "").font(.serif(29, relativeTo: .title2)).tracking(-0.45).lineSpacing(1.5)
                .padding(.top, 28)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 4) {
                verseAction(app.isSaved(verse.ref) ? "heart.fill" : "heart", app.isSaved(verse.ref) ? "Remove from saved" : "Save verse", active: app.isSaved(verse.ref)) { app.toggleSave(verse.ref) }
                verseAction("message", "Study this verse") { studyRef = VerseRef(verse.ref) }
                ShareLink(item: "“\(verse.text ?? "")” — \(verse.label) (\(BibleStore.offline[verse.translation] ?? ""))") {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 18)).foregroundStyle(Theme.muted(scheme)).frame(maxWidth: .infinity, minHeight: 44)
                }
                .accessibilityLabel("Share verse")
            }
            .padding(.top, 24)
        }
        .foregroundStyle(Theme.text(scheme))
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 12, trailing: 20))
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface(scheme)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(dark ? Color.white.opacity(0.11) : Color.black.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(dark ? 0.467 : 0.06), radius: 14, y: 18)
        .shadow(color: .black.opacity(dark ? 0.333 : 0.05), radius: 9, y: 9)
        .shadow(color: .black.opacity(dark ? 0.267 : 0.04), radius: 3, y: 3)
        .padding(16)
        .background {
            ZStack {
                Image("quiet-sky").resizable().scaledToFill()
                LinearGradient(stops: dark
                               ? [.init(color: Color(red: 11 / 255, green: 23 / 255, blue: 36 / 255, opacity: 0.37), location: 0), .init(color: Color(red: 7 / 255, green: 16 / 255, blue: 29 / 255, opacity: 0.565), location: 1)]
                               : [.init(color: Color(red: 198 / 255, green: 231 / 255, blue: 242 / 255, opacity: 0.25), location: 0), .init(color: Color.white.opacity(0.05), location: 0.55), .init(color: Color(red: 234 / 255, green: 244 / 255, blue: 250 / 255, opacity: 0.6), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func verseAction(_ symbol: String, _ label: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18))
                .foregroundStyle(active ? Theme.text(scheme) : Theme.muted(scheme))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityLabel(label)
    }

    // MARK: Verse search (.search-card)

    /// The mockup's passage picker: one well-known verse per onboarding topic.
    static let searchVerses: [(ref: String, title: String)] = [
        ("PSA.23.1", "Peace"), ("PRO.31.25", "Identity"), ("MAT.11.28", "Anxiety"), ("JER.29.11", "Hope"), ("PRO.3.5", "Faith"),
        ("PSA.119.105", "Purpose"), ("PSA.107.1", "Gratitude"), ("PRO.17.17", "Relationships"), ("JAS.1.5", "Wisdom"),
    ]

    private var verseSearch: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image("magnifier").resizable().scaledToFit().frame(width: 44, height: 44).accessibilityHidden(true)
                    Text("Verse Search").font(.system(size: 22)).tracking(-0.5)
                }
                Text("Choose a passage to read and reflect on.").font(.system(size: 14)).lineSpacing(4.3).foregroundStyle(Theme.muted(scheme))
                    .padding(.top, 10)
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
                    .padding(.horizontal, 12).frame(height: 44)
                    .iconSurface(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
                }
                .padding(.top, 18)
                Button("Study this verse") {
                    studyRef = VerseRef(searchRef)
                    Task { await Analytics.shared.track("verse_search_studied", ["ref": .string(searchRef)]) }
                }
                .buttonStyle(CapsuleButtonStyle())
                .padding(.top, 12)
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }

    private func label(_ ref: String) -> String { VerseRef(ref).map { BibleStore.shared.label($0) } ?? ref }

    // MARK: Today's Reading (.reading-card: 16 padding, 14 gap, 82×100 journal)

    private var todaysReading: some View {
        let active = model.plans.flatMap { list in list.plans.first { $0.id == list.activePlanId } }
        return Button { if let active { openPlan = active } else { showingPlans = true } } label: {
            HStack(alignment: .top, spacing: 14) {
                Image("journal").resizable().scaledToFit().frame(width: 80, height: 96).frame(width: 82, height: 100).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Today’s Reading").font(.system(size: 22)).tracking(-0.5).padding(.top, 3)
                    Text(active?.title ?? "Choose your plan").font(.system(size: 12, weight: .semibold)).padding(.top, 6)
                    Text(active.map(planStatus) ?? "From a Psalm a day to the whole Bible.").font(.system(size: 12)).lineSpacing(3.7)
                        .foregroundStyle(Theme.muted(scheme)).padding(.top, 6)
                    HStack(spacing: 8) {
                        Text(active == nil ? "Explore reading plans" : "View your plan")
                        Image(systemName: "arrow.right").font(.system(size: 11))
                    }
                    .font(.system(size: 11)).foregroundStyle(Theme.muted(scheme)).padding(.top, 10)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.text(scheme))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceCard()
        }
        .buttonStyle(.plain)
    }

    private func planStatus(_ plan: ReadingPlan) -> String {
        guard let p = plan.progress else { return "\(plan.days) passages · Read at your own pace" }
        if p.completedAt != nil { return "Completed · all \(plan.days) passages" }
        return "\(p.completedSteps) of \(plan.days) passages read"
    }

    // MARK: For the season you're in (.home-topic-section)

    private var season: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("For the season you’re in").font(.serif(28, relativeTo: .title)).tracking(-0.4).foregroundStyle(Theme.text(scheme))
            Text("A little guidance for today.").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme)).padding(.top, 8)
            HStack(alignment: .top, spacing: 12) {
                SeasonCard(kind: .faith) { openTopic("Faith") }
                SeasonCard(kind: .purpose) { openTopic("Purpose") }
            }
            .padding(.top, 20)
        }
        .padding(.top, 4).padding(.bottom, 6)
    }

    private func openTopic(_ topic: String) {
        app.discoverTopic = topic
        app.requestedTab = .discover
        Task { await Analytics.shared.track("home_topic_opened", ["topic": .string(topic)]) }
    }

    // MARK: Devotional (.devotional-card: the mockup's "moment of reflection" card)

    private func devotionalCard(_ d: Devotional) -> some View {
        let dark = scheme == .dark
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("Today’s devotional").font(.system(size: 11)).foregroundStyle(Theme.muted(scheme))
                Spacer()
                if let tag = d.tag { Badge(text: tag) }
            }
            Text(d.title).font(.serif(30, relativeTo: .title)).tracking(-0.4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 92)
                .padding(.top, 25)
            Text("\(d.label) · \(d.minutes ?? 1) min read").font(.system(size: 14)).lineSpacing(4.3).foregroundStyle(Theme.muted(scheme))
                .padding(.top, 14)
            Button { openDevotional = d } label: {
                HStack(spacing: 6) {
                    Text(d.readAt == nil ? "Read today’s devotional" : "Read it again")
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                }
                .font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                .padding(8).frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.leading, -8).padding(.top, 8)
        }
        .foregroundStyle(Theme.text(scheme))
        .overlay(alignment: .topTrailing) {
            Image("reflection").resizable().scaledToFit().frame(width: 78, height: 88).padding(.top, 44).accessibilityHidden(true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard(fill: AnyShapeStyle(LinearGradient(stops: [.init(color: Theme.surface(scheme), location: 0.5), .init(color: dark ? Color(hex: 0x1D1D20) : Color(hex: 0xF2F2F4), location: 1)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing)))
    }
}

/// .streak-card: "N days · Reading streak · Best", the week, Mark today as read (20/22 padding).
struct StreakCard: View {
    let streak: Streak
    let onMark: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Card(padding: EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22)) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(streak.current) \(streak.current == 1 ? "day" : "days")").font(.system(size: 23, weight: .semibold)).tracking(-0.5)
                    Text("Reading streak").font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                    Spacer(minLength: 12)
                    Text("Best: \(streak.best) \(streak.best == 1 ? "day" : "days")").font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                }
                HStack(spacing: 8) {
                    ForEach(Array(week.enumerated()), id: \.offset) { i, day in
                        VStack(spacing: 8) {
                            Text(day.letter).font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                            ZStack {
                                Circle().fill(day.read ? Theme.readDay : Theme.supporting(scheme))
                                Circle().strokeBorder(day.read ? Theme.readDay : Theme.border(scheme), lineWidth: 1)
                                if day.read { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white) }
                            }
                            .frame(width: 30, height: 30)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.letter), \(day.read ? "read" : "not read")")
                        if i < week.count - 1 { Spacer(minLength: 0) }
                    }
                }
                .padding(.top, 20).padding(.bottom, 14)
                Button(streak.readToday ? "Today’s reading complete" : "Mark today as read", action: onMark)
                    .buttonStyle(CapsuleButtonStyle(kind: .secondary))
                    .disabled(streak.readToday)
                    .opacity(streak.readToday ? 0.7 : 1)
                Text(streak.readToday ? "A little time in the Word, every day." : "Read a passage, then mark your day complete.")
                    .font(.system(size: 11)).lineSpacing(3.4).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center)
                    .padding(.top, 10)
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

/// .home-topic-card: 175×287, 20 radius, tinted gradient (light and dark values from the mockup), 145×134 art.
private struct SeasonCard: View {
    enum Kind { case faith, purpose }
    let kind: Kind
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        let faith = kind == .faith
        let colors: [Color] = faith
            ? (dark ? [Color(hex: 0x293B30), Color(hex: 0x222E28)] : [Color(hex: 0xE7EEE5), Color(hex: 0xF4F7EF)])
            : (dark ? [Color(hex: 0x293C4B), Color(hex: 0x232E38)] : [Color(hex: 0xE2EDF5), Color(hex: 0xF1F4F7)])
        let ink: Color = faith ? (dark ? Color(hex: 0xEFF4EE) : Color(hex: 0x111111)) : (dark ? Color(hex: 0xEFF5FA) : Color(hex: 0x273B4C))
        let sub: Color = faith ? (dark ? Color(hex: 0xC2D3C6) : Color(hex: 0x506354)) : (dark ? Color(hex: 0xC4D3E0) : Color(hex: 0x526574))
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(faith ? "faith-hands" : "purpose-compass").resizable().scaledToFit().frame(width: 145, height: 134).frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                Text(faith ? "Rooted in faith" : "Find your next step").font(.serif(23, relativeTo: .title3)).tracking(-0.3)
                    .foregroundStyle(ink).fixedSize(horizontal: false, vertical: true).padding(.top, 12)
                Text(faith ? "Find a little reassurance" : "Explore your purpose").font(.system(size: 11)).foregroundStyle(sub).padding(.top, 9)
                Image(systemName: "arrow.right").font(.system(size: 16)).foregroundStyle(ink).padding(.top, 15)
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .padding(EdgeInsets(top: 12, leading: 15, bottom: 20, trailing: 15))
            .frame(maxWidth: .infinity, minHeight: 287, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
            .shadow(color: Color(red: 25 / 255, green: 49 / 255, blue: 44 / 255, opacity: 0.19), radius: 6, y: 9)
        }
        .buttonStyle(.plain)
    }
}
