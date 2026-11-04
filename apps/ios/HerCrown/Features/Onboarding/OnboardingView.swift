import SwiftUI
import UserNotifications

/// The eight onboarding steps from the design kit (specs/SCREEN-MAP.md, content-fixtures.json). Answers are optional;
/// Skip clears that question. Completing saves the answers, marks onboarding complete (flow version 2) and never runs again.
struct OnboardingView: View {
    @Environment(AppModel.self) private var app
    @State private var step = 0
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
        _step = State(initialValue: UserDefaults.standard.integer(forKey: "hcOnboardingStep"))
        #endif
    }

    static let intentions = ["Grow closer to God", "Build a reading habit", "Explore the Bible for the first time", "Find encouragement"]
    static let familiarities = ["Just getting started", "A little familiar", "I read regularly"]
    static let topicOptions = ["Peace", "Purpose", "Faith", "Relationships", "Identity", "Anxiety", "Gratitude", "Hope", "Wisdom"]
    static let routines = ["2 minutes", "5 minutes", "10 minutes", "No time goal"]

    var body: some View {
        ZStack {
            AppGradient().environment(\.colorScheme, .light)
            if step > 0 { OnboardingClouds() }
            switch step {
            case 0: welcome
            case 1: time
            default: question
            }
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .light) // onboarding is designed in the light palette
        .preferredColorScheme(.light)        // dark status bar text on the light background
        .animation(.easeInOut(duration: 0.25), value: step)
        .onChange(of: step) { _, s in Task { await Analytics.shared.track("onboarding_step", ["step": .string(Self.stepNames[s]), "index": .number(Double(s))]) } }
        .task { await Analytics.shared.track("onboarding_step", ["step": "welcome", "index": 0]) }
    }

    static let stepNames = ["welcome", "time", "intention", "familiarity", "topics", "rhythm", "reminder", "ready"]

    // Colours from the mockup's onboarding cascade.
    private static let ink = Color(hex: 0x111111)
    private static let body = Color(hex: 0x68686E)
    private static let kicker = Color(hex: 0x777777)
    private static let line = Color(hex: 0xE4E4E7)

    // MARK: 0 · Welcome (.screen.welcome: 86/24/58 padding; 48 pt serif; 52 + 44 pt buttons)

    private var welcome: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("Less scrolling.").font(.serif(48, relativeTo: .largeTitle)).tracking(-1.2)
                Text("More Scripture.").font(.serif(48, italic: true, relativeTo: .largeTitle)).tracking(-1.2).foregroundStyle(Color(hex: 0x263B32))
            }
            .foregroundStyle(Self.ink)
            Text("Discover the Bible one passage at a time. Make space for God’s Word in your everyday life.")
                .font(.system(size: 15)).lineSpacing(5.4).foregroundStyle(Color(hex: 0x65686A))
                .multilineTextAlignment(.center).frame(width: 265).padding(.top, 20)
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Button { step = 1 } label: {
                    HStack(spacing: 8) { Text("Get started"); Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)) }
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(Self.ink))
                        .shadow(color: .black.opacity(0.267), radius: 4, y: 3)
                }
                Button { Task { await finish(guest: true) } } label: {
                    Text("Explore as a guest").font(.system(size: 14, weight: .medium)).foregroundStyle(Color(hex: 0x333333))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(Color.white.opacity(0.78)))
                        .overlay(Capsule().strokeBorder(Color(hex: 0xDCDDE0), lineWidth: 1))
                }
                .padding(.top, 10)
                Text("Come as you are. No account needed.").font(.system(size: 11)).foregroundStyle(Self.kicker).padding(.top, 16)
            }
            .buttonStyle(.plain)
        }
        .padding(EdgeInsets(top: 332, leading: 24, bottom: 57, trailing: 24)) // title at 332 pt, as in the mockup
        .background(alignment: .top) {
            GeometryReader { geo in
                Image("onboarding-collage").resizable().scaledToFill()
                    .frame(width: geo.size.width + 8, height: geo.size.height - 35).clipped()
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: 1 · Time (.scroll-intro: 78/28/58; 260×174 art; 37 pt serif)

    private var time: some View {
        VStack(spacing: 0) {
            HStack { backButton; Spacer() }.frame(height: 44)
            ZStack(alignment: .topLeading) {
                Image("cosmos").resizable().scaledToFit().frame(width: 78, height: 83).offset(x: -9, y: -8)
                Image("open-book").resizable().scaledToFit().frame(width: 181, height: 169).offset(x: 53, y: -1)
                Image("hourglass").resizable().scaledToFit().frame(width: 101, height: 115).offset(x: 16, y: 66)
                Image("intention-heart").resizable().scaledToFit().frame(width: 65, height: 65).offset(x: 200, y: 100)
            }
            .frame(width: 260, height: 174, alignment: .topLeading)
            .padding(.top, 61)
            .accessibilityHidden(true)
            VStack(spacing: 0) {
                Text("If you scroll for")
                Text("2 hours a day,").fontWeight(.semibold)
                (Text("that’s ") + Text("14 hours a week.").font(.serif(37, italic: true, weight: .semibold, relativeTo: .largeTitle)).foregroundColor(Color(hex: 0x334B3E)))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.serif(37, relativeTo: .largeTitle)).tracking(-0.7)
            .multilineTextAlignment(.center).foregroundStyle(Self.ink)
            .padding(.top, 30)
            Text("For the woman with a full day and a full heart: make a few of those minutes just you, God, and His Word.")
                .font(.system(size: 14)).lineSpacing(6.4).foregroundStyle(Color(hex: 0x59645E))
                .multilineTextAlignment(.center).frame(width: 325).padding(.top, 23)
            Spacer(minLength: 0)
            footer(button: "Continue", caption: "One passage. A little breathing room.", height: 54) { step = 2 }
        }
        .padding(EdgeInsets(top: 78, leading: 28, bottom: 0, trailing: 28))
    }

    // MARK: 2–7 · Questions and ready (.screen: 78/28/58; 32 pt serif heading with 82×90 art; 60 pt choices)

    private var question: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                backButton
                Spacer()
                Text("A moment for you").font(.system(size: 12)).foregroundStyle(Self.kicker)
                Spacer()
                if step < 7 { Button("Skip") { skip() }.font(.system(size: 12)).foregroundStyle(Self.body).frame(width: 44, height: 44) }
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
                .padding(.top, 39)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            switch step {
            case 4: footer(button: "Continue", caption: "Your interests guide discovery. Scripture stays unchanged.") { step += 1 }
            case 6:
                VStack(spacing: 0) {
                    footer(button: "Continue", caption: nil) { Task { await continueFromReminder() } }
                    Button("Not now") { reminders = false; step = 7 }
                        .font(.system(size: 14)).foregroundStyle(Color(hex: 0x333333)).frame(maxWidth: .infinity, minHeight: 48)
                }
                .padding(.bottom, 9)
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
        HStack(alignment: .top, spacing: 16) {
            Text(title).font(.serif(32, relativeTo: .largeTitle)).tracking(-1).foregroundStyle(Self.ink)
                .fixedSize().padding(.top, 9)
            Spacer(minLength: 0)
            Image(art).resizable().scaledToFit().frame(width: 82, height: 90).accessibilityHidden(true)
        }
    }

    private func subtitle(_ text: String) -> some View {
        Text(text).font(.system(size: 14)).lineSpacing(6.4).foregroundStyle(Self.body).padding(.top, 18)
    }

    private func choice(title: String, art: String, sub: String, options: [String], selection: Binding<String?>, details: [String: String] = [:], note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(title, art: art)
            subtitle(sub)
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let on = selection.wrappedValue == option
                    Button { selection.wrappedValue = option } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(on ? Self.ink : .clear)
                                Circle().strokeBorder(on ? Self.ink : Self.body, lineWidth: 1)
                                if on { Circle().fill(.white).frame(width: 7, height: 7) }
                            }
                            .frame(width: 19, height: 19)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(option).font(.system(size: 14))
                                if on, let d = details[option] { Text(d).font(.system(size: 11)).foregroundStyle(Self.body) }
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
                }
            }
            .padding(.top, 32)
            if let note { Text(note).font(.system(size: 11)).lineSpacing(5).foregroundStyle(Self.body).padding(.top, 24) }
        }
    }

    private var topicsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading("What’s on your\nheart lately?", art: "olive")
            subtitle("Choose any topics you might like to explore.")
            FlowLayout(spacing: 11) {
                ForEach(Self.topicOptions, id: \.self) { topic in
                    let on = topics.contains(topic)
                    Button { if on { topics.removeAll { $0 == topic } } else { topics.append(topic) } } label: {
                        Text(topic).font(.system(size: 14)).foregroundStyle(Self.ink)
                            .padding(.horizontal, 20).frame(height: 48)
                            .choiceSurface(selected: on)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
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
                Toggle(isOn: $reminders) { Text("Daily reminder").font(.system(size: 14)) }.tint(Self.ink).frame(height: 44)
                Text("A moment that works for you").font(.system(size: 12)).foregroundStyle(Self.body).padding(.top, 3)
                if reminders {
                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, minHeight: 49, alignment: .leading)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Self.line))
                        .padding(.top, 16)
                }
            }
            .padding(22)
            .choiceSurface(selected: false, radius: 44)
            .padding(.top, 28)
            VStack(alignment: .leading, spacing: 11) {
                Text("HER CROWN · YOUR DAILY PAUSE").font(.system(size: 9)).tracking(1).foregroundStyle(Self.body)
                Text("A moment in the Word?").font(.serif(24)).foregroundStyle(Self.ink)
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .choiceSurface(selected: false, radius: 47)
            .padding(.top, 26)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Notification preview: A moment in the Word?")
            Text("You can change this any time in Settings.").font(.system(size: 11)).lineSpacing(5).foregroundStyle(Self.body).padding(.top, 20)
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("butterfly").resizable().scaledToFit().frame(width: 90, height: 74).accessibilityHidden(true)
            Text("You’re right where\nyou need to begin.").font(.serif(32, relativeTo: .largeTitle)).tracking(-1).foregroundStyle(Self.ink)
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
                    .font(.system(size: 10)).foregroundStyle(Self.body).padding(.top, 23)
            }
            .padding(.vertical, 32).padding(.horizontal, 24).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Self.line))
            .padding(.top, 36)
        }
    }

    // MARK: Pieces

    private var backButton: some View {
        Button { step = max(0, step - 1) } label: { Image(systemName: "arrow.left").font(.system(size: 19)).foregroundStyle(Self.ink).frame(width: 44, height: 44) }
            .accessibilityLabel("Back")
    }

    /// Primary 48 pt (54 on the intro), then the 11 pt footnote; the footnote sits 68 pt above the screen bottom.
    private func footer(button: String, caption: String?, height: CGFloat = 48, action: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Button(action: action) {
                HStack(spacing: 8) { Text(button); Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)) }
                    .font(.system(size: 14)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: height)
                    .background(Capsule().fill(Self.ink))
                    .shadow(color: .black.opacity(0.267), radius: 4, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(finishing)
            if let caption { Text(caption).font(.system(size: 11)).foregroundStyle(Self.body).frame(height: 18) }
        }
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
        step += 1
    }

    private func continueFromReminder() async {
        if reminders { reminders = await DailyReminder.requestAndSchedule(at: reminderTime) }
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
    func makeBody(configuration: Configuration) -> some View { HStack(spacing: 8) { configuration.title; configuration.icon.font(.system(size: 14, weight: .semibold)) } }
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

    static func cancel() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id]) }
}

private extension View {
    /// Onboarding choice/chip surface: white (selected: #eff4f6), hairline (selected: #8d9ba0), soft low shadow.
    func choiceSurface(selected: Bool, radius: CGFloat? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius ?? 999, style: .continuous)
        return self
            .background(shape.fill(selected ? Color(hex: 0xEFF4F6) : .white))
            .overlay(shape.strokeBorder(selected ? Color(hex: 0x8D9BA0) : Color(hex: 0xE4E4E7), lineWidth: 1))
            .shadow(color: Color(red: 27 / 255, green: 35 / 255, blue: 37 / 255, opacity: 0.2), radius: 2, y: 3)
    }
}

/// The mockup's onboarding clouds: cloud-bank at the top (150% wide) and bottom (170% wide), 22% opacity.
struct OnboardingClouds: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("cloud-bank").resizable().scaledToFit().frame(width: geo.size.width * 1.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.04 + geo.size.width * 0.25)
                Image("cloud-bank").resizable().scaledToFit().frame(width: geo.size.width * 1.7)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.92 - geo.size.width * 0.1)
            }
            .opacity(0.22)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
