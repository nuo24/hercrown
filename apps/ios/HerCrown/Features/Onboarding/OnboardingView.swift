import SwiftUI
import UserNotifications

/// The eight onboarding steps from the design kit (specs/SCREEN-MAP.md, content-fixtures.json). Answers are optional;
/// Skip clears that question. Completing saves the answers, marks onboarding complete (flow version 2) and never runs again.
struct OnboardingView: View {
    @Environment(AppModel.self) private var app
    @State private var step = 0
    @State private var entrance = OnboardingEntrance()
    @State private var playedStep: Int?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var typingAvailable: Bool { !reduceMotion && scenePhase == .active }
    private var characterCount: Int { Self.titles[step].filter { !$0.isWhitespace }.count }
    private var copyDelay: Double { 0.22 + Double(characterCount) * 0.032 }
    private static let titles = [
        "Less scrolling.\nMore Scripture.", "If you scroll for\n2 hours a day,\nthat’s 14 hours a\nweek.",
        "What brings\nyou here?", "Every journey\nbegins somewhere.", "What’s on your\nheart lately?",
        "Make room\nfor the Word.", "A gentle\nreminder?", "You’re right where\nyou need to begin."
    ]
    @State private var intention: String?
    @State private var familiarity: String?
    @State private var topics: [String] = []
    @State private var routine: String?
    @State private var reminders = true
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var finishing = false

    init() {
        #if DEBUG
        // Screenshots and UI review: `-hcOnboardingStep 5` opens a given step.
        _step = State(initialValue: min(max(UserDefaults.standard.integer(forKey: "hcOnboardingStep"), 0), 7))
        #endif
    }

    static let intentions = ["Grow closer to God", "Build a reading habit", "Explore the Bible for the first time", "Find encouragement"]
    static let familiarities = ["Just getting started", "A little familiar", "I read regularly"]
    static let topicOptions = ["Peace", "Purpose", "Faith", "Relationships", "Identity", "Anxiety", "Gratitude", "Hope", "Wisdom"]
    static let routines = ["2 minutes", "5 minutes", "10 minutes", "No time goal"]

    var body: some View {
        ZStack {
            AppGradient().environment(\.colorScheme, .light)
            Group {
                switch step {
                case 0: welcome
                case 1: time
                default: question
                }
            }
            .id(step)
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .light) // onboarding is designed in the light palette
        .preferredColorScheme(.light)        // dark status bar text on the light background
        .task(id: "\(step)-\(typingAvailable)") {
            guard typingAvailable, playedStep != step else { entrance.settle(); return }
            playedStep = step
            entrance.begin()
            let clock = ContinuousClock()
            let start = clock.now
            do {
                for index in 0..<characterCount {
                    try await clock.sleep(until: start.advanced(by: .milliseconds(220 + index * 32)))
                    try Task.checkCancellation()
                    entrance.reveal(index + 1)
                }
                try await clock.sleep(until: start.advanced(by: .milliseconds(300 + characterCount * 32)))
                try Task.checkCancellation()
                entrance.settle()
            } catch { }
        }
        .onChange(of: step) { _, s in Task { await Analytics.shared.track("onboarding_step", ["step": .string(Self.stepNames[s]), "index": .number(Double(s))]) } }
        .task { await Analytics.shared.track("onboarding_step", ["step": "welcome", "index": 0]) }
    }

    static let stepNames = ["welcome", "time", "intention", "familiarity", "topics", "rhythm", "reminder", "ready"]

    private func advance(to page: Int) {
        if !reduceMotion { entrance.confirm() }
        if typingAvailable { entrance.begin() }
        step = page
    }

    private func headline(_ text: String, after preceding: String = "", font: Font, color: Color = Self.ink) -> Text {
        guard typingAvailable, let count = entrance.revealed ?? (playedStep == step ? nil : 0) else {
            return Text(text).font(font).foregroundColor(color)
        }
        let limit = max(0, count - preceding.filter { !$0.isWhitespace }.count)
        var seen = 0
        let visibleEnd = text.firstIndex { character in
            if character.isWhitespace { return false }
            seen += 1
            return seen > limit
        } ?? text.endIndex
        return (Text(String(text[..<visibleEnd])).foregroundColor(color) +
                Text(String(text[visibleEnd...])).foregroundColor(.clear)).font(font)
    }

    // Colours from the mockup's onboarding cascade.
    private static let ink = Color(hex: 0x111111)
    private static let body = Color(hex: 0x68686E)
    private static let kicker = Color(hex: 0x777777)
    private static let line = Color(hex: 0xE4E4E7)

    // MARK: 0 · Welcome

    private var welcome: some View {
        GeometryReader { geometry in
            let shortScreen = geometry.size.height <= 700
            let narrowScreen = geometry.size.width <= 359
            let titleSize: CGFloat = geometry.size.height <= 650 ? 37 : narrowScreen ? 42 : 48

            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: -5) {
                        headline("Less scrolling.", font: .serif(titleSize, relativeTo: .largeTitle))
                        headline("More Scripture.", after: "Less scrolling.", font: .serif(titleSize, italic: true, relativeTo: .largeTitle), color: Color(hex: 0x263B32))
                    }
                    .accessibilityElement(children: .ignore).accessibilityLabel(Self.titles[0]).accessibilityAddTraits(.isHeader)
                    .tracking(-titleSize * 0.025)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Self.ink)
                    .frame(maxWidth: 350)

                    Text("Discover the Bible one passage at a time. Make space for God’s Word in your everyday life.")
                        .font(.ui(geometry.size.height <= 650 ? 13 : narrowScreen ? 14 : 15))
                        .lineSpacing(5.4)
                        .foregroundStyle(Color(hex: 0x65686A))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 265)
                        .padding(.top, 20)
                        .modifier(OnboardingCopyEntry(delay: copyDelay + 0.08))
                    Spacer(minLength: 24)
                    welcomeActions.modifier(OnboardingCopyEntry(delay: copyDelay + 0.18))
                }
                .padding(.horizontal, 24)
                .padding(.top, geometry.size.height * (shortScreen ? 0.30 : 0.38))
                .padding(.bottom, 58)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .background(alignment: .top) {
                OnboardingCollage(size: CGSize(width: geometry.size.width * 1.04, height: geometry.size.height * 0.96),
                                  animate: !reduceMotion)
            }
        }
    }

    private var welcomeActions: some View {
        VStack(spacing: 0) {
            Button { advance(to: 1) } label: {
                HStack(spacing: 8) {
                    Text("Get started")
                    Image(systemName: "arrow.right").font(.ui(14, weight: .semibold))
                }
                .font(.ui(14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background {
                    Capsule().fill(Self.ink)
                        .shadow(color: .black.opacity(0.16), radius: 4, y: 3)
                }
            }
            Button { if !reduceMotion { entrance.confirm() }; Task { await finish(guest: true) } } label: {
                Text("Explore as a guest")
                    .font(.ui(14, weight: .medium))
                    .foregroundStyle(Color(hex: 0x333333))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                    .background(Capsule().fill(.white.opacity(0.78)))
                    .overlay(Capsule().strokeBorder(Color(hex: 0xDCDDE0), lineWidth: 1))
            }
            .padding(.top, 10)
            Text("Come as you are. No account needed.")
                .font(.ui(11))
                .foregroundStyle(Self.kicker)
                .frame(minHeight: 16.5)
                .padding(.top, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: 1 · Scroll intro

    private var time: some View {
        VStack(spacing: 0) {
            HStack { backButton; Spacer() }.frame(height: 44)
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        Image.illustration("cosmos").resizable().scaledToFit().frame(width: 60, height: 68)
                            .rotationEffect(.degrees(-18)).modifier(OnboardingArtEntry(delay: 0.28, x: -14, y: -12, rotation: -7))
                        Image.illustration("open-book").resizable().scaledToFit().frame(width: 164, height: 150)
                            .rotationEffect(.degrees(7)).modifier(OnboardingArtEntry(x: 0, y: 22, rotation: -5)).offset(x: 62, y: 9)
                        Image.illustration("hourglass").resizable().scaledToFit().frame(width: 82, height: 100)
                            .rotationEffect(.degrees(-12)).modifier(OnboardingArtEntry(delay: 0.14, x: -18, y: 22, rotation: -8)).offset(x: 25, y: 74)
                        Image.illustration("intention-heart").resizable().scaledToFit().frame(width: 54, height: 54)
                            .rotationEffect(.degrees(14)).modifier(OnboardingArtEntry(delay: 0.42, y: 22, rotation: 8)).offset(x: 206, y: 106)
                    }
                    .frame(width: 260, height: 174, alignment: .topLeading)
                    .accessibilityHidden(true)

                    VStack(spacing: 0) {
                        headline("If you scroll for", font: .serif(37, relativeTo: .largeTitle))
                        headline("2 hours a day,", after: "If you scroll for", font: .serif(37, weight: .semibold, relativeTo: .largeTitle))
                        (headline("that’s ", after: "If you scroll for 2 hours a day,", font: .serif(37, relativeTo: .largeTitle)) +
                         headline("14 hours a\nweek.", after: "If you scroll for 2 hours a day, that’s", font: .serif(37, italic: true, weight: .semibold, relativeTo: .largeTitle), color: Color(hex: 0x334B3E)))
                    }
                    .accessibilityElement(children: .ignore).accessibilityLabel(Self.titles[1]).accessibilityAddTraits(.isHeader)
                    .tracking(-0.7)
                    .multilineTextAlignment(.center).foregroundStyle(Self.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

                    Text("For the woman with a full day and a full heart: make a few of those minutes just you, God, and His Word.")
                        .font(.ui(14)).lineSpacing(6.4).foregroundStyle(Color(hex: 0x59645E))
                        .multilineTextAlignment(.center).frame(maxWidth: 325).padding(.top, 24)
                        .modifier(OnboardingCopyEntry(delay: copyDelay + 0.08))
                }
                .padding(.top, 61)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            footer(button: "Continue", caption: "One passage. A little breathing room.", height: 54, captionSpacing: 14) { step = 2 }
        }
        .padding(EdgeInsets(top: 78, leading: 28, bottom: 0, trailing: 28))
    }

    // MARK: 2–7 · Questions and ready (.screen: 78/28/58; 32 pt serif heading with 82×90 art; 60 pt choices)

    private var question: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                backButton
                Spacer()
                Text("A moment for you").font(.ui(12)).foregroundStyle(Self.kicker)
                Spacer()
                if step < 7 { Button("Skip") { skip() }.font(.ui(12)).foregroundStyle(Self.body).frame(width: 44, height: 44) }
                else { Color.clear.frame(width: 44, height: 44) }
            }
            .frame(height: 48)
            progress.padding(.top, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch step {
                    case 2: choice(title: "What brings\nyou here?", art: "intention-heart", sub: "There is no wrong starting point.", options: Self.intentions, selection: $intention)
                    case 3: choice(title: "Every journey\nbegins somewhere.", art: "seedling", sub: "How familiar are you with the Bible? We’ll adjust the reading guidance, not the words of Scripture.", options: Self.familiarities, selection: $familiarity)
                    case 4: topicsStep
                    case 5: choice(title: "Make room\nfor the Word.", art: "hourglass", sub: "How much time would feel realistic on a typical day?", options: Self.routines, selection: $routine,
                                   details: ["5 minutes": "A little breathing room in your day"],
                                   note: "A gentle rhythm, at your own pace.\nYou’re welcome here, however long you have.")
                    case 6: reminderStep
                    default: readyStep
                    }
                }
                .padding(.top, 36)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            switch step {
            case 4: footer(button: "Continue", caption: "Your interests guide discovery. Scripture stays unchanged.") { step += 1 }
            case 6:
                VStack(spacing: 0) {
                    footer(button: "Continue", caption: nil) { Task { await continueFromReminder() } }
                    Button("Not now") { reminders = false; advance(to: 7) }
                        .font(.ui(14)).foregroundStyle(Color(hex: 0x333333)).frame(maxWidth: .infinity, minHeight: 48)
                }
                .padding(.bottom, 58)
            case 7: footer(button: finishing ? "Getting ready…" : "Start reading", caption: "A little space. An open heart.") { Task { await finish(guest: false) } }
            default: footer(button: "Continue", caption: "Your pace. Your starting point.") { step += 1 }
            }
        }
        .padding(EdgeInsets(top: 78, leading: 28, bottom: 0, trailing: 28))
    }

    /// Eight 2 pt segments, 5 apart; done ones ink, the rest hairline grey.
    private var progress: some View {
        HStack(spacing: 5) {
            ForEach(0..<8) { i in RoundedRectangle(cornerRadius: 3).fill(i <= step ? Self.ink : Self.line).frame(height: 2) }
        }
        .accessibilityElement().accessibilityLabel("Step \(step + 1) of 8")
    }

    private func heading(_ title: String, art: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            headline(title, font: .serif(32, relativeTo: .largeTitle)).tracking(-1)
                .accessibilityLabel(title).accessibilityAddTraits(.isHeader)
                .lineSpacing(-0.96)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image.illustration(art).resizable().scaledToFit().frame(width: 82, height: 90).modifier(OnboardingArtEntry()).accessibilityHidden(true)
        }
    }

    private func subtitle(_ text: String) -> some View {
        Text(text).font(.ui(14)).lineSpacing(6.44).foregroundStyle(Self.body)
            .padding(.vertical, 3.22).padding(.top, 18)
            .modifier(OnboardingCopyEntry(delay: copyDelay + 0.08))
    }

    private func choice(title: String, art: String, sub: String, options: [String], selection: Binding<String?>, details: [String: String] = [:], note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(title, art: art)
            subtitle(sub)
            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    let on = selection.wrappedValue == option
                    Button { if !reduceMotion { entrance.confirm() }; selection.wrappedValue = option } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(on ? Self.ink : .clear)
                                Circle().strokeBorder(on ? Self.ink : Self.body, lineWidth: 1)
                                if on { Circle().fill(.white).frame(width: 7, height: 7) }
                            }
                            .frame(width: 19, height: 19)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(option).font(.ui(14))
                                if let d = details[option] { Text(d).font(.ui(11)).foregroundStyle(Self.body) }
                            }
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(Self.ink)
                        .padding(.horizontal, 17).padding(.vertical, 18)
                        .frame(minHeight: 60)
                        .choiceSurface(selected: on)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    .modifier(OnboardingCopyEntry(delay: copyDelay + 0.14 + Double(min(index, 8)) * 0.045, duration: 0.22))
                }
            }
            .padding(.top, 28)
            if let note { Text(note).font(.ui(11)).lineSpacing(5).foregroundStyle(Self.body).padding(.top, 24) }
        }
    }

    private var topicsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading("What’s on your\nheart lately?", art: "olive")
            subtitle("Choose any topics you might like to explore.")
            FlowLayout(spacing: 11) {
                ForEach(Array(Self.topicOptions.enumerated()), id: \.element) { index, topic in
                    let on = topics.contains(topic)
                    Button { if !reduceMotion { entrance.confirm() }; if on { topics.removeAll { $0 == topic } } else { topics.append(topic) } } label: {
                        Text(topic).font(.ui(14)).foregroundStyle(Self.ink)
                            .padding(.horizontal, 20).frame(height: 48)
                            .choiceSurface(selected: on)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    .modifier(OnboardingCopyEntry(delay: copyDelay + 0.14 + Double(min(index, 8)) * 0.045, duration: 0.22))
                }
            }
            .padding(.top, 32)
        }
    }

    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading("A gentle\nreminder?", art: "reminder-bell")
            subtitle("Optional reminders can help you make Bible reading part of your day.")
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                Toggle(isOn: $reminders) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Daily reminder").font(.ui(15, weight: .medium))
                        Text("A moment that works for you").font(.ui(11)).foregroundStyle(Self.body)
                    }
                }
                .tint(Self.ink).frame(minHeight: 76)
                if reminders {
                    Divider()
                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .font(.ui(13)).frame(minHeight: 68)
                }
                Divider()
            }
            .padding(.top, 28)
            .modifier(OnboardingCopyEntry(delay: copyDelay + 0.14, duration: 0.22))
            VStack(alignment: .leading, spacing: 12) {
                Text("Notification preview").font(.ui(11)).foregroundStyle(Self.body)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Image("AppIcon-preview").resizable().frame(width: 22, height: 22)
                            .clipShape(RoundedRectangle(cornerRadius: 5)).accessibilityHidden(true)
                        Text("Her Crown").font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("now").font(.system(size: 12)).foregroundStyle(Self.body)
                    }
                    .padding(.bottom, 5)
                    Text("A moment in the Word?").font(.system(size: 15, weight: .semibold))
                    Text("Take a breath and spend a little time with Scripture.")
                        .font(.system(size: 14)).lineSpacing(3)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xF2F2F7).opacity(0.86), in: RoundedRectangle(cornerRadius: 22))
                .shadow(color: .black.opacity(0.045), radius: 7, y: 3)
            }
            .padding(.top, 28)
            .accessibilityElement(children: .combine)
            .modifier(OnboardingCopyEntry(delay: copyDelay + 0.185, duration: 0.22))
            Text("You can change this any time in Settings.").font(.system(size: 11)).lineSpacing(5).foregroundStyle(Self.body).padding(.top, 20)
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image.illustration("butterfly").resizable().scaledToFit().frame(width: 90, height: 74).modifier(OnboardingArtEntry()).accessibilityHidden(true)
            headline(Self.titles[7], font: .serif(32, relativeTo: .largeTitle)).tracking(-1)
                .accessibilityLabel(Self.titles[7]).accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 20)
            subtitle("Your Scripture feed is ready. You can change your preferences at any time.")
            VStack(spacing: 0) {
                // The mockup's lines: “The LORD is my / shepherd; / I shall not want.” (text from the bundled KJV).
                let verse = (BibleStore.shared.text("kjv", VerseRef("PSA.23.1")!) ?? "").components(separatedBy: "; ")
                let first = verse.first.map { "“" + $0 + (verse.count > 1 ? ";" : "”") } ?? ""
                let lines = [first.components(separatedBy: " ").dropLast().joined(separator: " "), first.components(separatedBy: " ").last ?? ""]
                    + verse.dropFirst().map { $0 + "”" }
                VStack(spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in Text(line).lineLimit(1).minimumScaleFactor(0.8) }
                }
                .font(.serif(27)).multilineTextAlignment(.center).foregroundStyle(Self.ink)
                VStack(spacing: 0) { Text("PSALM 23:1").frame(height: 18); Text("King James Version").frame(height: 18) }
                    .font(.ui(10)).foregroundStyle(Self.body).padding(.top, 23)
            }
            .padding(.vertical, 32).padding(.horizontal, 24).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Self.line))
            .padding(.top, 36)
            .modifier(OnboardingCopyEntry(delay: copyDelay + 0.14, duration: 0.22))
        }
    }

    // MARK: Pieces

    private var backButton: some View {
        Button { advance(to: max(0, step - 1)) } label: { Image(systemName: "arrow.left").font(.ui(18)).foregroundStyle(Self.ink).frame(width: 44, height: 44) }
            .accessibilityLabel("Back")
    }

    /// Primary 48 pt (54 on the intro), then the 11 pt footnote; the footnote sits 68 pt above the screen bottom.
    private func footer(button: String, caption: String?, height: CGFloat = 48, captionSpacing: CGFloat = 10, action: @escaping () -> Void) -> some View {
        VStack(spacing: captionSpacing) {
            Button { if !reduceMotion { entrance.confirm() }; action() } label: {
                HStack(spacing: 8) { Text(button); Image(systemName: "arrow.right").font(.ui(14, weight: .semibold)) }
                    .font(.ui(14)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: height)
                    .background(Capsule().fill(Self.ink))
                    .shadow(color: .black.opacity(0.267), radius: 4, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(finishing)
            if let caption { Text(caption).font(.ui(11)).foregroundStyle(Self.body).frame(height: 18) }
        }
        .modifier(OnboardingCopyEntry(delay: copyDelay + 0.18))
        .padding(.top, 26)
        .padding(.bottom, caption == nil ? 0 : 68)
    }

    private func skip() {
        switch step {
        case 2: intention = nil
        case 3: familiarity = nil
        case 4: topics = []
        case 5: routine = nil
        case 6: reminders = false
        default: break
        }
        advance(to: step + 1)
    }

    private func continueFromReminder() async {
        let granted = reminders ? await DailyReminder.requestAndSchedule(at: reminderTime) : false
        guard step == 6 else { return }
        reminders = granted
        step = 7
    }

    private func finish(guest: Bool) async {
        finishing = true
        let time = Self.hhmm(reminderTime)
        var patch: [String: Any] = ["topics": guest ? [] : topics, "remindersEnabled": guest ? false : reminders, "reminderTime": time, "timeZone": TimeZone.current.identifier]
        if !guest {
            if let intention { patch["intention"] = intention }
            if let familiarity { patch["familiarity"] = familiarity }
            if let routine { patch["routine"] = routine }
        }
        app.updatePreferences(patch) { p in
            p.topics = guest ? [] : topics; p.remindersEnabled = !guest && reminders; p.reminderTime = time; p.timeZone = TimeZone.current.identifier
            if !guest { p.intention = intention; p.familiarity = familiarity; p.routine = routine }
        }
        await app.completeOnboarding()
        finishing = false
        // Decision 0003: the membership paywall follows onboarding; the guest path goes straight to reading.
        if !guest { app.presentPaywall(placement: "onboarding_complete") }
    }

    static func hhmm(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 8, c.minute ?? 0)
    }
}

/// "Continue →": text first, arrow after.
struct TrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View { HStack(spacing: 8) { configuration.title; configuration.icon.font(.ui(14, weight: .semibold)) } }
}

/// Wrapping row layout for topic chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += line + spacing; line = 0 }
            x += size.width + spacing; line = max(line, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + line)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, line: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += line + spacing; line = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing; line = max(line, size.height)
        }
    }
}

/// The daily reading reminder is a local notification (specs/FULL-STACK.md: native APIs after explicit opt-in).
enum DailyReminder {
    static let id = "hc.dailyReminder"

    /// Asks for permission (only now, after she opted in) and schedules it. Returns false if she declined.
    static func requestAndSchedule(at time: Date) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await Analytics.shared.track("push_permission", ["granted": .bool(granted), "placement": "onboarding_reminder"])
        guard granted else { return false }
        schedule(at: time)
        return true
    }

    static func schedule(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "A moment in the Word?"
        content.body = "A verse is waiting for you in Her Crown."
        content.sound = .default
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
        UNUserNotificationCenter.current().add(request)
    }

    static func time(from hhmm: String) -> Date {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        return Calendar.current.date(bySettingHour: parts.first ?? 8, minute: parts.count > 1 ? parts[1] : 0, second: 0, of: Date()) ?? Date()
    }

    static func cancel() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id]) }
}

private extension View {
    /// Onboarding choice/chip surface: white (selected: #eff4f6), hairline (selected: #8d9ba0), soft low shadow.
    func choiceSurface(selected: Bool, radius: CGFloat? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius ?? 999, style: .continuous)
        return self
            .background {
                shape.fill(selected ? Color(hex: 0xEFF4F6) : .white)
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
            }
            .overlay(shape.strokeBorder(selected ? Color(hex: 0x8D9BA0) : Color(hex: 0xE4E4E7), lineWidth: 1))
    }
}
