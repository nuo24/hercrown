import SwiftUI
import UserNotifications

/// Final November 8 handoff. Existing members do not re-enter onboarding when this flow changes.
struct OnboardingView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var answers = PersonalOnboardingAnswers()
    @State private var acknowledgement = ""
    @State private var showingAcknowledgement = false
    @State private var acknowledgementOpacity = 1.0
    @State private var prayerRevealing = false
    @State private var revealed = 0
    @State private var settled = false
    @State private var artVisible = false
    @State private var prayerTitleFinished = false
    @State private var prayerTitleRevealed = 0
    @State private var prayerErrorMessage = ""
    @State private var prayerRequest: UUID?
    @State private var prayer = ""
    @State private var prayerError = false
    @State private var generated = false
    @State private var simplePrayerRequested = false
    @State private var loadingPrayer = false
    @State private var requestVersion = 0
    @State private var preparedAnswers: PersonalOnboardingAnswers?
    @State private var preparedVersion = -1
    @State private var bridge = false
    @State private var reminders = false
    @State private var reminderTime = DailyReminder.time(from: "08:00")
    @State private var reminderDenied = false
    @State private var finishing = false
    @State private var awaitingPaywall = false
    @State private var saveError = false
    @FocusState private var textFocused: Bool

    static let intentions = ["Grow closer to God", "Build a reading habit", "Explore the Bible for the first time", "Find encouragement"]
    static let familiarities = ["Just starting", "I know a little", "I read regularly"]
    static let topicOptions = ["Peace", "Purpose", "Faith", "Relationships", "Identity", "Anxiety", "Gratitude", "Hope", "Wisdom"]
    static let routines = ["2 minutes", "5 minutes", "10 minutes", "No time goal"]
    static let seasons = ["Single", "Dating", "Married", "Motherhood", "Separated or divorced", "Prefer not to say"]
    static let stepNames = ["welcome", "time", "demo", "name", "comparison", "season", "familiarity", "topics", "burden", "loved_ones", "rhythm", "prayer", "reminder", "ready"]
    private let ink = Color(hex: 0x111111)
    private let muted = Color(hex: 0x68686E)

    init() {
        #if DEBUG
        _step = State(initialValue: min(max(UserDefaults.standard.integer(forKey: "hcOnboardingStep"), 0), 13))
        #endif
    }

    private var isTextPage: Bool { [3, 8, 9].contains(step) }
    private var name: String { answers.normalizedName }
    private var title: String {
        let titles = ["Less\ndoomscrolling.\nMore Scripture.", "If you scroll for\n2 hours a day,\nthat’ll be 10 years of your life spent on social media.", "We’re going to help you spend less time scrolling social media and more time in the Bible.", "First, what should\nwe call you?", "Which do you spend more time on?", "What season of life are you in?", "How familiar does the Bible feel?", "What’s on your heart lately?", "Tell us something\nthat’s been\nweighing you down.", "Who’s someone in your life\nyou’d like to pray for?", "How much time can you give to God each day?", name.isEmpty ? "A prayer for you." : "A prayer for you,\n\(name).", "When would you like\na moment with God?", "A verse for what’s\non your heart."]
        let base = titles[step]
        if [5, 7].contains(step), !name.isEmpty { return name + ", " + base.prefix(1).lowercased() + base.dropFirst() }
        return base
    }
    private var art: String {
        ["onboarding-collage", "grace-shell", "open-book", "journal", "magnifier", "growth-vase", "wisdom-scroll", "hope-nest", "rest-stones", "prayer-envelope", "quiet-window", "faith-hands", "reminder-bell", "dove"][step]
    }
    private var subtitle: String {
        switch step {
        case 4: "Be honest…"
        case 5: "Life doesn’t fit in one box. Choose all that feel true."
        case 6: "We’ll meet you at your starting point."
        case 7: "More than one feeling can be true. Choose up to three."
        case 10: "A small moment is a beautiful beginning."
        case 11: "Your heart, held in prayer."
        case 12: "A quiet invitation to pause."
        case 13: "Chosen with what you shared in mind. Carry these words into your day."
        default: ""
        }
    }
    private var footnote: String {
        switch step {
        case 2: "A little space for you and His Word."
        case 4: "No judgment. Just a place to begin."
        case 5: "You don’t have to have it all figured out."
        case 6: "No test. No catching up."
        case 7: "Bring the whole of you."
        case 8, 9: "Optional. Your answers are sent securely to our prayer provider to prepare your prayer. They aren’t added to analytics."
        case 10: "A prayer shaped around what’s on your heart."
        case 11: "You can come back to these words."
        case 12: "You can change this anytime in Settings."
        default: "Come as you are."
        }
    }

    var body: some View {
        Group {
            if step == 0 { welcome }
            else {
                VStack(spacing: 0) {
                    HStack {
                        Button { goBack() } label: { Image(systemName: "arrow.left").frame(width: 44, height: 44) }.accessibilityLabel("Back")
                        Spacer()
                        Text("A moment for you").font(.ui(11)).foregroundStyle(muted)
                        Spacer()
                        if [3,4,5,6,7,8,9,10].contains(step) { Button("Skip") { next(skipping: true) }.font(.ui(12)).frame(width: 44, height: 44) }
                        else { Color.clear.frame(width: 44, height: 44) }
                    }
                    HStack(spacing: 5) {
                        ForEach(0..<8) { i in Capsule().fill(i <= Int(Double(step) / 13 * 7) ? ink : Color(hex: 0xE4E4E7)).frame(height: 2) }
                    }.padding(.top, 18).padding(.bottom, 28)
                        .accessibilityElement(children: .ignore).accessibilityLabel("Step \(step + 1) of 14")
                    if showingAcknowledgement {
                        animatedText(acknowledgement).font(.serif(28.8)).tracking(-0.6).frame(maxWidth: .infinity, alignment: .leading).opacity(acknowledgementOpacity).padding(.top, 20)
                        Spacer()
                    } else {
                        ScrollViewReader { prayerScroll in
                        GeometryReader { page in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 18) {
                                if step == 1 { timeIntro }
                                else if step == 11 { prayerPage }
                                else if step == 2 { demoPage(height: page.size.height) }
                                else {
                                    questionHeading
                                    if !subtitle.isEmpty { Text(subtitle).font(.ui(14)).lineSpacing(5).foregroundStyle(muted).opacity(settled ? 1 : 0) }
                                    pageContent.opacity(settled ? 1 : 0).allowsHitTesting(settled)
                                }
                                if step == 11 { Color.clear.frame(height: 18).id("prayer-bottom") }
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .scrollIndicators(.hidden)
                        .clipped()
                        .onChange(of: revealed) { _, count in
                            if step == 11 && prayerRevealing && !loadingPrayer && count % 8 == 0 { prayerScroll.scrollTo("prayer-bottom", anchor: .bottom) }
                        }
                        .onChange(of: settled) { _, done in
                            if step == 11 && done { prayerScroll.scrollTo("prayer-bottom", anchor: .bottom) }
                        }
                        }
                        }
                        if isTextPage { inputDock.opacity(settled ? 1 : 0).allowsHitTesting(settled) }
                        else if !(step == 11 && prayerError) { actions.opacity(settled && !loadingPrayer ? 1 : 0).allowsHitTesting(settled && !loadingPrayer) }
                    }
                }
                .padding(.horizontal, 28).padding(.top, 12).padding(.bottom, 24)
            }
        }
        .foregroundStyle(ink).buttonStyle(.plain)
        .background(Color.white.ignoresSafeArea())
        .environment(\.colorScheme, .light).preferredColorScheme(.light)
        .task(id: "\(step)-\(scenePhase)-\(reduceMotion)-\(requestVersion)") { await enterPage() }
        .task(id: "paywall-\(step)-\(app.me?.user.id ?? "")") {
            if step == 13 { Billing.shared.prepareOnboardingPaywall() }
        }
        .task(id: prayerPreparation) {
            if let preparation = prayerPreparation { await preparePrayer(preparation) }
        }
        .onChange(of: scenePhase) { _, phase in
            // Returning from a system interruption shows the complete page, never a hidden Continue.
            // Prayer generation must finish or offer its retry/fallback before it can advance.
            if phase != .active && step != 11 {
                settled = true; artVisible = true; showingAcknowledgement = false; acknowledgement = ""
            }
        }
        .alert("Couldn’t save your name", isPresented: $saveError) { Button("OK", role: .cancel) {} } message: { Text("Your onboarding answers are still here. Check your connection and try again.") }
    }

    private var welcome: some View {
        GeometryReader { g in
            ZStack(alignment: .top) {
                OnboardingCollage(size: CGSize(width: g.size.width * 1.04, height: (g.size.height + g.safeAreaInsets.top + g.safeAreaInsets.bottom) * 0.96), animate: !reduceMotion).ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer().frame(height: g.size.height * 0.30)
                    animatedText(title).font(.serif(g.size.width < 380 ? 39 : 44)).tracking(-1.2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
                    Text("Discover the Bible one passage at a time. Make space for God’s Word in your everyday life.")
                        .font(.ui(15)).lineSpacing(5).foregroundStyle(muted).multilineTextAlignment(.center).frame(maxWidth: 280).padding(.top, 20)
                    Spacer(minLength: 20)
                    Button { next() } label: { Label("Get started", systemImage: "arrow.right").labelStyle(TrailingIcon()) }.buttonStyle(CapsuleButtonStyle())
                    Button("Explore as a guest") { Task { await complete(guest: true) } }.buttonStyle(CapsuleButtonStyle(kind: .secondary)).padding(.top, 10)
                    Text("Come as you are. No account needed.").font(.ui(11)).foregroundStyle(muted).padding(.top, 16)
                }.padding(.horizontal, 24).padding(.bottom, 54)
            }
        }
    }

    private var timeIntro: some View {
        VStack(spacing: 26) {
            if bridge {
                animatedText("Let’s show you how to turn some of that time toward Christ.").font(.serif(33.3)).tracking(-0.7)
                Image.illustration("cosmos").resizable().scaledToFit().frame(width: 100, height: 100).modifier(OnboardingArtReveal(visible: artVisible, reducedMotion: reduceMotion))
            } else {
                ZStack {
                    Image.illustration("open-book").resizable().scaledToFit().frame(width: 164, height: 150).rotationEffect(.degrees(7)).modifier(OnboardingArtReveal(visible: artVisible, reducedMotion: reduceMotion))
                    Image.illustration("hourglass").resizable().scaledToFit().frame(width: 82, height: 100).offset(x: -65, y: 40).modifier(OnboardingArtReveal(visible: artVisible, reducedMotion: reduceMotion, delay: 0.14))
                    Image.illustration("grace-shell").resizable().scaledToFit().frame(width: 60, height: 68).offset(x: -105, y: -45).modifier(OnboardingArtReveal(visible: artVisible, reducedMotion: reduceMotion, delay: 0.28))
                    Image.illustration("intention-heart").resizable().scaledToFit().frame(width: 54, height: 54).offset(x: 105, y: 55).modifier(OnboardingArtReveal(visible: artVisible, reducedMotion: reduceMotion, delay: 0.42))
                }.frame(height: 174)
                animatedText(title).font(.serif(33.3)).tracking(-0.7)
            }
        }.multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 32)
    }

    private func demoPage(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            animatedText(title).font(.serif(28.8)).tracking(-1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 20)
            pageContent.opacity(artVisible ? 1 : 0).allowsHitTesting(artVisible)
            Spacer(minLength: 20)
        }.frame(minHeight: max(0, height - 8))
    }

    @ViewBuilder private var pageContent: some View {
        switch step {
        case 2:
            OnboardingDemoView(reducedMotion: reduceMotion, isActive: scenePhase == .active && artVisible).frame(width: 165, height: 165 * 2556 / 1180).clipShape(RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(ink, lineWidth: 2)).frame(maxWidth: .infinity).padding(.top, 4).accessibilityLabel("Demonstration of reading and saving a Bible passage")
        case 4: choices(["Social media", "The Bible", "About the same"], selection: $answers.comparison)
        case 5:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Self.seasons, id: \.self) { value in choiceButton(value, selected: answers.season.contains(value)) { toggleSeason(value) } }
            }
        case 6: choices(Self.familiarities, selection: $answers.familiarity)
        case 7:
            FlowLayout(spacing: 10) {
                ForEach(Self.topicOptions, id: \.self) { value in
                    Button { if answers.heart.contains(value) { answers.heart.removeAll { $0 == value } } else if answers.heart.count < 3 { answers.heart.append(value) } } label: {
                        Text(value).font(.ui(13)).padding(.horizontal, 18).frame(minHeight: 44)
                            .foregroundStyle(answers.heart.contains(value) ? .white : ink)
                            .background(answers.heart.contains(value) ? ink : Color.white, in: Capsule())
                            .overlay(Capsule().strokeBorder(Color(hex: 0xE4E4E7)))
                    }.disabled(answers.heart.count >= 3 && !answers.heart.contains(value))
                        .opacity(answers.heart.count >= 3 && !answers.heart.contains(value) ? 0.35 : 1)
                        .accessibilityAddTraits(answers.heart.contains(value) ? .isSelected : [])
                }
            }
            Text("Choose up to three. Tap one again to make room.").font(.ui(11)).foregroundStyle(muted)
        case 10: choices(["2 minutes", "5 minutes", "10 minutes", "No set goal"], selection: $answers.pace)
        case 12: reminder
        case 13:
            Text("Your prayer is saved on this device.").font(.serif(20)).lineSpacing(5)
            if !prayer.isEmpty { ShareLink(item: prayer) { Text("Save a copy of my prayer") }.buttonStyle(CapsuleButtonStyle(kind: .secondary)) }
            OnboardingScriptureCard(answers: answers, prayer: prayer)
        default: EmptyView()
        }
    }

    private var inputDock: some View {
        let value: Binding<String> = step == 3 ? $answers.name : step == 8 ? $answers.burden : $answers.lovedOnes
        let placeholder = step == 3 ? "Your first name" : step == 8 ? "In your own words…" : "My mom, Grace…"
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField(placeholder, text: value).font(.serif(25)).textContentType(step == 3 ? .givenName : nil).textInputAutocapitalization(.sentences)
                    .submitLabel(.next).focused($textFocused).onSubmit { next() }
                    .onChange(of: value.wrappedValue) { _, text in
                        let max = step == 3 ? 24 : step == 8 ? 100 : 60
                        if text.count > max { value.wrappedValue = String(text.prefix(max)) }
                    }
                Button { next() } label: { Image(systemName: "arrow.right").font(.system(size: 24)).frame(width: 44, height: 44) }.accessibilityLabel("Continue")
            }.padding(.vertical, 8).overlay(alignment: .bottom) { Rectangle().fill(Color(hex: 0xAAB4BC)).frame(height: 1) }
            if [8, 9].contains(step) { Text(footnote).font(.ui(10)).foregroundStyle(muted).fixedSize(horizontal: false, vertical: true) }
        }
    }

    private var questionHeading: some View {
                                    animatedText(title).font(.serif(28.8)).tracking(-1).lineSpacing(0)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.trailing, 98)
                                        .overlay(alignment: .bottomTrailing) {
                                            GeometryReader { heading in
                                                Image.illustration(step == 11 ? "faith-hands" : art).resizable().scaledToFit()
                                                    .frame(width: 82, height: min(90, heading.size.height))
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                                    .modifier(OnboardingArtReveal(visible: artVisible, reducedMotion: reduceMotion))
                                                    .id("heading-art-\(step)")
                                                    .accessibilityHidden(true)
                                            }
                                        }
                                    .accessibilityAddTraits(.isHeader)
    }

    private var prayerPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            questionHeading
            Text("Your heart, held in prayer.").font(.ui(14)).foregroundStyle(muted)
            if loadingPrayer { ProgressView("Preparing your prayer…").font(.ui(14)).frame(maxWidth: .infinity).padding(.vertical, 30) }
            else if prayerError {
                Text(prayerErrorMessage.isEmpty ? "We couldn’t prepare your personal prayer right now." : prayerErrorMessage).font(.ui(14)).foregroundStyle(muted)
                Button("Try again") { settled = false; requestVersion += 1 }.buttonStyle(CapsuleButtonStyle())
                Button("Use a simple prayer") {
                    simplePrayerRequested = true; settled = false; prayerRevealing = false; requestVersion += 1
                }.buttonStyle(CapsuleButtonStyle(kind: .secondary))
            } else {
                Text(settled || reduceMotion ? prayer : prayerRevealing ? String(prayer.prefix(revealed)) : "")
                    .font(.serif(20)).lineSpacing(5).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

            }
        }
    }

    private var reminder: some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) { Text("Daily reminder").font(.ui(14)); Text("A quiet nudge, at your pace.").font(.ui(11)).foregroundStyle(muted) }.frame(maxWidth: .infinity, alignment: .leading)
                Toggle("Daily reminder", isOn: $reminders).labelsHidden().fixedSize().tint(ink)
            }.padding(.trailing, 4)
            Divider()
            DatePicker("Remind me at", selection: $reminderTime, displayedComponents: .hourAndMinute).font(.ui(13))
            Text("A little preview").font(.ui(11)).foregroundStyle(muted).padding(.top, 8)
            VStack(alignment: .leading, spacing: 8) {
                HStack { Image("AppIcon-preview").resizable().frame(width: 22, height: 22).clipShape(RoundedRectangle(cornerRadius: 5)); Text("Her Crown").font(.system(size: 12)); Spacer(); Text("now").font(.system(size: 11)).foregroundStyle(muted) }
                Text("A moment in the Word?").font(.system(size: 14, weight: .semibold))
                Text("Set the scroll aside. There’s a little peace waiting for you.").font(.system(size: 13)).lineSpacing(3)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: 0xF2F2F7), in: RoundedRectangle(cornerRadius: 20))
            if reminderDenied { Text("Notifications are off. You can enable them in iPhone Settings.").font(.ui(12)).foregroundStyle(muted) }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                if step == 13 { Task { await complete(guest: false) } }
                else if step == 12 { Task {
                    if reminders {
                        let granted = await DailyReminder.requestAndSchedule(at: reminderTime)
                        reminders = granted
                        if !granted { reminderDenied = true; return }
                    }
                    next()
                } }
                else { next() }
            } label: {
                Label(finishing ? "Getting ready…" : step == 11 ? "Keep this prayer" : step == 12 ? "Save my choice" : step == 13 ? "Open my Bible" : "Continue", systemImage: "arrow.right").labelStyle(TrailingIcon())
            }.buttonStyle(CapsuleButtonStyle()).disabled(finishing || (step == 11 && (prayer.isEmpty || prayerError)))
            if step == 10 {
                Button("Use a simple prayer instead") { simplePrayerRequested = true; next() }
                    .font(.ui(12)).frame(minHeight: 44).foregroundStyle(muted)
            }
            Text(footnote).font(.ui([8, 9].contains(step) ? 10 : 11)).foregroundStyle(muted).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }.padding(.top, 22)
    }

    private func choices(_ options: [String], selection: Binding<String>) -> some View {
        VStack(spacing: 10) { ForEach(options, id: \.self) { value in choiceButton(value, selected: selection.wrappedValue == value) { selection.wrappedValue = value } } }
    }
    private func choiceButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle").font(.system(size: 17)).foregroundStyle(selected ? ink : muted)
                Text(title).font(.ui(14)).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.horizontal, 16).frame(minHeight: 60)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(selected ? ink : Color(hex: 0xE4E4E7), lineWidth: selected ? 1.5 : 1))
        }.accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func animatedText(_ text: String) -> Text {
        let visible: Int
        if step == 11 && text == title && !showingAcknowledgement {
            visible = reduceMotion || prayerTitleFinished ? text.count : min(prayerTitleRevealed, text.count)
        } else {
            visible = settled || reduceMotion ? text.count : min(revealed, text.count)
        }
        let warning = step == 1 && !bridge ? text.range(of: "10 years of your life") : nil
        return text.enumerated().reduce(Text("")) { result, entry in
            let index = text.index(text.startIndex, offsetBy: entry.offset)
            let accent = warning?.contains(index) == true
            let emphasized = step == 1 && !bridge && ["2 hours a day", "10 years of your life", "spent on social media."].contains { text.range(of: $0)?.contains(index) == true }
            let welcomeAccent = step == 0 && text.range(of: "More Scripture.")?.contains(index) == true
            let glyph = welcomeAccent ? Text(String(entry.element)).font(.serif(48, italic: true)) : emphasized ? Text(String(entry.element)).font(.serif(33.3, weight: .semibold)) : Text(String(entry.element))
            return result + glyph.foregroundColor(entry.offset < visible ? (welcomeAccent ? Color(hex: 0x263B32) : accent ? Color(hex: 0xA94F75) : ink) : .clear)
        }
    }
    private func toggleSeason(_ value: String) {
        if value == "Prefer not to say" { answers.season = answers.season.contains(value) ? [] : [value] }
        else { answers.season.removeAll { $0 == "Prefer not to say" }; if answers.season.contains(value) { answers.season.removeAll { $0 == value } } else { answers.season.append(value) } }
    }
    private func next(skipping: Bool = false) {
        textFocused = false
        if skipping {
            switch step { case 3: answers.name = ""; case 4: answers.comparison = ""; case 5: answers.season = []; case 6: answers.familiarity = ""; case 7: answers.heart = []; case 8: answers.burden = ""; case 9: answers.lovedOnes = ""; case 10: answers.pace = ""; default: break }
        }
        if step == 3 { answers.name = name }
        if step == 11, !prayer.isEmpty { PersonalPrayerStore.save(prayer, userID: app.me?.user.id) }
        acknowledgement = skipping ? "" : response(for: step)
        settled = false; artVisible = false; prayerTitleFinished = false; prayerTitleRevealed = 0; prayerRevealing = false; revealed = 0; bridge = false
        if step < 13 { step += 1 }
    }
    private func goBack() { textFocused = false; acknowledgement = ""; settled = false; artVisible = false; prayerTitleFinished = false; prayerTitleRevealed = 0; prayerRevealing = false; revealed = 0; bridge = false; step = max(0, step - 1) }
    private func response(for previous: Int) -> String {
        switch previous {
        case 2: "Now let’s build a Bible experience that’s for you.\n\nWe’ll ask a few questions to shape your own For You page."
        case 3: name.isEmpty ? "" : "It’s lovely to meet you, \(name)."
        case 4: answers.comparison == "Social media" ? "Thank you for being honest. We can begin with one small moment." : answers.comparison == "The Bible" ? "Let’s make space for the time you already love in the Word." : "Let’s find a rhythm that feels right for you."
        case 5: answers.season.contains("Motherhood") ? "You’re making room for God in the midst of motherhood. There’s room for you here, too." : answers.season.contains("Separated or divorced") ? "After a separation, even familiar things can feel different. We’ll begin gently." : "This can be a little space for your faith, in the season you’re in."
        case 6: answers.familiarity == "Just starting" ? "You don’t have to know where everything is to begin." : "There’s room to grow, one passage at a time."
        case 7: answers.heart.isEmpty ? "" : "You’re bringing " + answers.heart.map { $0.lowercased() }.formatted(.list(type: .and)) + " into this space. There’s room for all of it."
        case 8: answers.burden.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "Thank you for sharing that\(name.isEmpty ? "" : ", " + name). We’ll hold what matters to you in prayer."
        case 9: answers.lovedOnes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "We’ll hold your loved ones in prayer, too."
        case 10: answers.pace == "No set goal" ? "No clock to keep up with. Just a little space for God." : "\(answers.pace) is a gentle place to begin. Let’s make those moments yours."
        default: ""
        }
    }
    private func type(_ text: String, prayer: Bool = false) async throws {
        revealed = 0
        if reduceMotion || scenePhase != .active { revealed = text.count; return }
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.prepare()
        let clock = ContinuousClock(); let start = clock.now
        var lastPulse = Date.distantPast
        let characters = Array(text)
        var elapsed = 0
        for count in 1...max(1, text.count) {
            elapsed += prayer ? PrayerReadingPace.delay(before: count - 1, in: characters) : (step == 0 ? 32 : 48)
            try await clock.sleep(until: start.advanced(by: .milliseconds(elapsed)))
            try Task.checkCancellation(); revealed = count
            if step == 11 && !prayer && !showingAcknowledgement { prayerTitleRevealed = count }
            if Date().timeIntervalSince(lastPulse) >= (prayer ? 0.16 : 0.09) {
                feedback.impactOccurred(intensity: prayer ? 0.5 : 0.7)
                feedback.prepare()
                lastPulse = Date()
            }
        }
    }
    private func enterPage() async {
        guard scenePhase == .active, !settled else { return }
        let enteredStep = step
        Task { await Analytics.shared.track("onboarding_step", ["step": .string(Self.stepNames[enteredStep]), "index": .number(Double(enteredStep))]) }
        // Navigation stays available while typing. An interrupted reveal must never strand the footer.
        defer {
            if step == enteredStep && scenePhase == .active && !Task.isCancelled {
                showingAcknowledgement = false
                settled = true
            }
        }
        if step == 1 { bridge = false }
        artVisible = reduceMotion
        do {
            if !acknowledgement.isEmpty, !reduceMotion, scenePhase == .active {
                acknowledgementOpacity = 1
                showingAcknowledgement = true
                try await type(acknowledgement)
                try await Task.sleep(for: .milliseconds(650))
                withAnimation(.easeOut(duration: 0.35)) { acknowledgementOpacity = 0 }
                try await Task.sleep(for: .milliseconds(350))
            }
            showingAcknowledgement = false
            acknowledgement = ""
            if step == 11 {
                artVisible = true
                if !reduceMotion { try await Task.sleep(for: .milliseconds(120)) }
                try await type(title); prayerTitleFinished = true
                while loadingPrayer || (!prayerError && (preparedAnswers != prayerPreparation?.answers || preparedVersion != requestVersion)) {
                    try await Task.sleep(for: .milliseconds(100))
                }
                if prayerError { settled = true; return }
                try Task.checkCancellation(); revealed = 0; prayerRevealing = true
                try await type(prayer, prayer: true)
            }
            else {
                // Side illustrations enter just before typing on every question page.
                // The collage/demo keep their established intro timing.
                if step >= 1 {
                    artVisible = true
                    if !reduceMotion { try await Task.sleep(for: .milliseconds(220)) }
                }
                try await type(title)
                artVisible = true
            }
            if step == 1 {
                try await Task.sleep(for: .milliseconds(1200)); artVisible = false; bridge = true
                try await type("Let’s show you how to turn some of that time toward Christ."); artVisible = true
            }
            try Task.checkCancellation(); settled = true
        } catch { }
    }
    private var prayerPreparation: PrayerPreparation? {
        guard step >= 10 else { return nil }
        return PrayerPreparation(answers: answers, version: requestVersion, simple: simplePrayerRequested)
    }
    private func preparePrayer(_ preparation: PrayerPreparation) async {
        let submittedAnswers = preparation.answers
        guard prayer.isEmpty || preparedAnswers != submittedAnswers || preparedVersion != preparation.version || generated == preparation.simple else { return }
        if preparation.simple {
            prayer = submittedAnswers.simplePrayer; generated = false; prayerError = false
            preparedAnswers = submittedAnswers; preparedVersion = preparation.version
            await Analytics.shared.track("prayer_prepared", ["generated": false])
            return
        }
        loadingPrayer = true; prayerError = false; prayerErrorMessage = ""
        let request = UUID()
        prayerRequest = request
        defer { if prayerRequest == request { loadingPrayer = false } }
        do {
            // Fast onboarding must wait for the initial anonymous session before its authenticated request.
            while app.phase == .launching {
                try await Task.sleep(for: .milliseconds(100))
            }
            try Task.checkCancellation()
            struct Reply: Decodable { let prayer: String }
            let reply: Reply = try await app.api.call("POST", "/me/onboarding/prayer", json: submittedAnswers.prayerInput)
            try Task.checkCancellation()
            guard prayerRequest == request, prayerPreparation == preparation else { return }
            prayer = PrayerParagraphs.two(reply.prayer); generated = true; preparedAnswers = submittedAnswers; preparedVersion = preparation.version
            await Analytics.shared.track("prayer_prepared", ["generated": true])
        } catch {
            if !Task.isCancelled && prayerRequest == request && prayerPreparation == preparation {
                prayerError = true
                prayerErrorMessage = (error as? APIError)?.message ?? "We couldn’t prepare your personal prayer right now. Please try again."
            }
        }
    }
    private func complete(guest: Bool) async {
        guard !finishing else { return }; finishing = true
        defer { if !awaitingPaywall { finishing = false } }
        if !guest, !name.isEmpty, app.displayName != name {
            do { try await app.updateProfile(displayName: name, bio: app.me?.profile.bio ?? "") }
            catch { saveError = true; return }
        }
        let time = Self.hhmm(reminderTime)
        let familiarity = ["Just starting": "Just getting started", "I know a little": "A little familiar", "I read regularly": "I read regularly"][answers.familiarity]
        let routine = answers.pace == "No set goal" ? "No time goal" : answers.pace
        var patch: [String: Any] = ["topics": guest ? [] : answers.heart, "remindersEnabled": !guest && reminders, "reminderTime": time, "timeZone": TimeZone.current.identifier]
        if !guest, let familiarity { patch["familiarity"] = familiarity }
        if !guest, !routine.isEmpty { patch["routine"] = routine }
        app.updatePreferences(patch) { p in
            p.topics = guest ? [] : answers.heart; p.remindersEnabled = !guest && reminders; p.reminderTime = time; p.timeZone = TimeZone.current.identifier
            if !guest { p.familiarity = familiarity; p.routine = routine.isEmpty ? nil : routine }
        }
        // Persist the chosen topics before Home asks for its first matching daily passage.
        if !guest {
            do { _ = try await app.api.send("PATCH", "/me/preferences", json: patch) }
            catch { saveError = true; return }
        }
        if guest {
            Billing.shared.recordPresentationOutcome(placement: "onboarding_complete", outcome: "Guest path intentionally skips paywall")
            await app.completeOnboarding()
            await OnboardingNotificationTest.scheduleIfAllowed()
            if let id = app.me?.user.id { await Billing.shared.scheduleReturnOffer(for: id) }
        } else {
            // Present over the final onboarding page. Only reveal the reader after dismissal,
            // purchase, or a skipped/failed campaign, rather than flashing it during loading.
            awaitingPaywall = true
            app.presentPaywall(placement: "onboarding_complete", onComplete: {
                Task { @MainActor in
                    await app.completeOnboarding()
                    awaitingPaywall = false; finishing = false
                    await OnboardingNotificationTest.scheduleIfAllowed()
                }
            })
        }
    }
    static func hhmm(_ date: Date) -> String { let c = Calendar.current.dateComponents([.hour, .minute], from: date); return String(format: "%02d:%02d", c.hour ?? 8, c.minute ?? 0) }
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

private struct OnboardingArtReveal: ViewModifier {
    let visible: Bool
    let reducedMotion: Bool
    var delay = 0.0
    @State private var mounted = false
    func body(content: Content) -> some View {
        let shown = reducedMotion || (visible && mounted)
        content.opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .scaleEffect(shown ? 1 : 0.96)
            .animation(reducedMotion ? nil : .easeOut(duration: 0.45).delay(shown ? delay : 0), value: shown)
            .task {
                // Commit the hidden entrance frame before revealing. Without this, a new
                // page can mount with visible=true and SwiftUI has no transition to animate.
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled else { return }
                mounted = true
            }
    }
}

/// A single delayed notification for the staging crash-retest workflow only.
@MainActor
enum OnboardingNotificationTest {
    static let id = "hc.onboardingNotificationTest"
    static func scheduleIfAllowed() async {
        guard AppConfig.isStaging else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Her Crown notification test"
        content.body = "Tap to return to Her Crown and check that it opens smoothly."
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false))
        try? await center.add(request)
    }
}
