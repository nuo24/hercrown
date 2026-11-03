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
            AppGradient()
            if step > 0 { CloudAtmosphere().opacity(0.8) }
            switch step {
            case 0: welcome
            case 1: time
            default: question
            }
        }
        .environment(\.colorScheme, .light) // onboarding is designed in the light palette
        .preferredColorScheme(.light)        // dark status bar text on the light background
        .animation(.easeInOut(duration: 0.25), value: step)
        .onChange(of: step) { _, s in Task { await Analytics.shared.track("onboarding_step", ["step": .string(Self.stepNames[s]), "index": .number(Double(s))]) } }
        .task { await Analytics.shared.track("onboarding_step", ["step": "welcome", "index": 0]) }
    }

    static let stepNames = ["welcome", "time", "intention", "familiarity", "topics", "rhythm", "reminder", "ready"]

    // MARK: 0 · Welcome

    private var welcome: some View {
        VStack(spacing: 18) {
                Spacer()
                VStack(spacing: 2) {
                    Text("Less scrolling.").font(.serif(44, relativeTo: .largeTitle))
                    Text("More Scripture.").font(.serif(44, italic: true, relativeTo: .largeTitle))
                }
                .foregroundStyle(Color(hex: 0x111111))
                Text("Discover the Bible one passage at a time. Make space for God’s Word in your everyday life.")
                    .font(.system(size: 16)).foregroundStyle(Color(hex: 0x3A3A3F)).multilineTextAlignment(.center).frame(maxWidth: 290)
                Spacer()
                VStack(spacing: 10) {
                    Button { step = 1 } label: { Label("Get started", systemImage: "arrow.right").labelStyle(TrailingIcon()) }
                        .buttonStyle(CapsuleButtonStyle())
                    Button("Explore as a guest") { Task { await finish(guest: true) } }
                        .buttonStyle(CapsuleButtonStyle(kind: .secondary))
                    Text("Come as you are. No account needed.").font(.system(size: 12)).foregroundStyle(Color(hex: 0x6B6B70))
                }
                .padding(.horizontal, 24).padding(.bottom, 12)
        }
        .background { Image("onboarding-collage").resizable().scaledToFill().ignoresSafeArea().accessibilityHidden(true) }
    }

    // MARK: 1 · Time

    private var time: some View {
        VStack(spacing: 0) {
            HStack { backButton; Spacer() }.padding(.horizontal, 20).frame(height: 52)
            Spacer()
            ZStack {
                Image("open-book").resizable().scaledToFit().frame(width: 150).offset(x: 10)
                Image("hourglass").resizable().scaledToFit().frame(width: 46).offset(x: -70, y: 30)
                Image("intention-heart").resizable().scaledToFit().frame(width: 52).offset(x: 88, y: 40)
                Image("cosmos").resizable().scaledToFit().frame(width: 52).offset(x: -60, y: -60)
            }
            .frame(height: 170).accessibilityHidden(true)
            VStack(spacing: 4) {
                Text("If you scroll for").font(.serif(36, relativeTo: .largeTitle))
                Text("2 hours a day,").font(.serif(36, weight: .semibold, relativeTo: .largeTitle))
                (Text("that’s ").font(.serif(36, relativeTo: .largeTitle)) + Text("14 hours a week.").font(.serif(36, italic: true, relativeTo: .largeTitle)).foregroundColor(Color(hex: 0x3D5A47)))
            }
            .multilineTextAlignment(.center).foregroundStyle(Color(hex: 0x111111)).padding(.top, 28)
            Text("For the woman with a full day and a full heart: make a few of those minutes just you, God, and His Word.")
                .font(.system(size: 15)).foregroundStyle(Color(hex: 0x4A4A50)).multilineTextAlignment(.center).frame(maxWidth: 320).padding(.top, 20)
            Spacer()
            footer(button: "Continue", caption: "One passage. A little breathing room.") { step = 2 }
        }
    }

    // MARK: 2–7 · Questions and ready

    private var question: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                backButton
                Spacer()
                Text("A moment for you").font(.system(size: 13)).foregroundStyle(Color(hex: 0x6B6B70))
                Spacer()
                if step < 7 { Button("Skip") { skip() }.font(.system(size: 13)).foregroundStyle(Color(hex: 0x6B6B70)) } else { Color.clear.frame(width: 30) }
            }
            .padding(.horizontal, 20).frame(height: 52)
            progress.padding(.horizontal, 28).padding(.top, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch step {
                    case 2: choice(title: ["What brings", "you here?"], art: "intention-heart", sub: "There is no wrong starting point.", options: Self.intentions, selection: $intention)
                    case 3: choice(title: ["Every journey", "begins somewhere."], art: "seedling", sub: "How familiar are you with the Bible? We’ll adjust the reading guidance, not the words of Scripture.", options: Self.familiarities, selection: $familiarity)
                    case 4: topicsStep
                    case 5: choice(title: ["Make room", "for the Word."], art: "hourglass", sub: "How much time would feel realistic on a typical day?", options: Self.routines, selection: $routine,
                                   details: ["5 minutes": "A little breathing room in your day"],
                                   note: "A gentle rhythm, at your own pace.\nYou’re welcome here, however long you have.")
                    case 6: reminderStep
                    default: readyStep
                    }
                }
                .padding(.horizontal, 28).padding(.top, 36)
            }
            .scrollBounceBehavior(.basedOnSize)
            switch step {
            case 4: footer(button: "Continue", caption: "Your interests guide discovery. Scripture stays unchanged.") { step += 1 }
            case 6:
                VStack(spacing: 6) {
                    footer(button: "Continue", caption: nil) { Task { await continueFromReminder() } }
                    Button("Not now") { reminders = false; step = 7 }.font(.system(size: 14, weight: .medium)).foregroundStyle(Color(hex: 0x111111)).padding(.bottom, 8)
                }
            case 7: footer(button: finishing ? "Getting ready…" : "Start reading", caption: "A little space. An open heart.") { Task { await finish(guest: false) } }
            default: footer(button: "Continue", caption: "Your pace. Your starting point.") { step += 1 }
            }
        }
    }

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(0..<8) { i in
                Capsule().fill(Color(hex: 0x111111).opacity(i <= step ? 0.85 : 0.14)).frame(height: 2)
            }
        }
        .accessibilityElement().accessibilityLabel("Step \(step + 1) of 8")
    }

    private func heading(_ lines: [String], art: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) { ForEach(lines, id: \.self) { Text($0) } }
                .font(.serif(34, relativeTo: .largeTitle)).foregroundStyle(Color(hex: 0x111111))
            Spacer()
            Image(art).resizable().scaledToFit().frame(width: 76, height: 76).accessibilityHidden(true)
        }
    }

    private func choice(title: [String], art: String, sub: String, options: [String], selection: Binding<String?>, details: [String: String] = [:], note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(title, art: art)
            Text(sub).font(.system(size: 15)).foregroundStyle(Color(hex: 0x4A4A50)).padding(.top, 18).padding(.bottom, 22)
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    let on = selection.wrappedValue == option
                    Button { selection.wrappedValue = option } label: {
                        HStack(spacing: 14) {
                            Image(systemName: on ? "largecircle.fill.circle" : "circle").font(.system(size: 20, weight: .light))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option).font(.system(size: 15))
                                if on, let d = details[option] { Text(d).font(.system(size: 12)).foregroundStyle(Color(hex: 0x6B6B70)) }
                            }
                            Spacer()
                        }
                        .foregroundStyle(Color(hex: 0x111111))
                        .padding(.horizontal, 20).frame(minHeight: on && details[option] != nil ? 70 : 58)
                        .background(Capsule().fill(on ? Color(hex: 0xEEF1F2) : .white))
                        .overlay(Capsule().strokeBorder(on ? Color(hex: 0x6B7A80).opacity(0.6) : Color(hex: 0xE5E5E8), lineWidth: on ? 1.2 : 1))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            if let note { Text(note).font(.system(size: 12)).foregroundStyle(Color(hex: 0x6B6B70)).padding(.top, 18) }
        }
    }

    private var topicsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(["What’s on your", "heart lately?"], art: "olive")
            Text("Choose any topics you might like to explore.").font(.system(size: 15)).foregroundStyle(Color(hex: 0x4A4A50)).padding(.top, 18).padding(.bottom, 22)
            FlowLayout(spacing: 10) {
                ForEach(Self.topicOptions, id: \.self) { topic in
                    let on = topics.contains(topic)
                    Button { if on { topics.removeAll { $0 == topic } } else { topics.append(topic) } } label: {
                        Text(topic).font(.system(size: 15)).foregroundStyle(Color(hex: 0x111111))
                            .padding(.horizontal, 20).frame(height: 48)
                            .background(Capsule().fill(on ? Color(hex: 0xEEF1F2) : .white))
                            .overlay(Capsule().strokeBorder(on ? Color(hex: 0x6B7A80).opacity(0.6) : Color(hex: 0xE5E5E8), lineWidth: on ? 1.2 : 1))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(["A gentle", "reminder?"], art: "reminder-bell")
            Text("Optional reminders can help you make Bible reading part of your day.").font(.system(size: 15)).foregroundStyle(Color(hex: 0x4A4A50)).padding(.top, 18).padding(.bottom, 22)
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Daily reminder", isOn: $reminders).font(.system(size: 15)).tint(Color(hex: 0x111111))
                Text("A moment that works for you").font(.system(size: 12)).foregroundStyle(Color(hex: 0x6B6B70))
                if reminders {
                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .font(.system(size: 15))
                }
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            VStack(alignment: .leading, spacing: 6) {
                Text("HER CROWN · YOUR DAILY PAUSE").font(.system(size: 10, weight: .semibold)).tracking(1).foregroundStyle(Color(hex: 0x6B6B70))
                Text("A moment in the Word?").font(.serif(22))
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            .padding(.top, 14)
            .accessibilityLabel("Notification preview: A moment in the Word?")
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("butterfly").resizable().scaledToFit().frame(width: 84, height: 70).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) { Text("You’re right where"); Text("you need to begin.") }
                .font(.serif(34, relativeTo: .largeTitle)).foregroundStyle(Color(hex: 0x111111)).padding(.top, 18)
            Text("Your Scripture feed is ready. You can change your preferences at any time.").font(.system(size: 15)).foregroundStyle(Color(hex: 0x4A4A50)).padding(.top, 18).padding(.bottom, 26)
            VStack(spacing: 10) {
                Text("“\(BibleStore.shared.text("kjv", VerseRef("PSA.23.1")!) ?? "")”").font(.serif(26)).multilineTextAlignment(.center)
                Text("PSALM 23:1").font(.system(size: 11, weight: .medium)).tracking(0.6).foregroundStyle(Color(hex: 0x4A4A50))
                Text("King James Version").font(.system(size: 11)).foregroundStyle(Color(hex: 0x6B6B70))
            }
            .padding(28).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(hex: 0xE5E5E8)))
        }
    }

    // MARK: Pieces

    private var backButton: some View {
        Button { step = max(0, step - 1) } label: { Image(systemName: "arrow.left").font(.system(size: 18)).foregroundStyle(Color(hex: 0x111111)).frame(width: 44, height: 44) }
            .accessibilityLabel("Back")
    }

    private func footer(button: String, caption: String?, action: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Button(action: action) { Label(button, systemImage: "arrow.right").labelStyle(TrailingIcon()) }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(finishing)
            if let caption { Text(caption).font(.system(size: 12)).foregroundStyle(Color(hex: 0x6B6B70)) }
        }
        .padding(.horizontal, 28).padding(.bottom, 12)
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
