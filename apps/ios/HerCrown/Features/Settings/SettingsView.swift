import AuthenticationServices
import PhotosUI
import SafariServices
import SwiftUI
import StoreKit

/// settings.root (specs/SCREEN-MAP.md): profile, membership, Account & reading, Here for you, About & legal.
/// Every change here saves at once and never touches onboarding.
struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var inheritedScheme
    @State private var legal: LegalPage?
    @State private var showingTutorial = false
    @State private var showsTestSession = false
    @State private var changingTestSession = false
    @State private var testSessionError = false
    #if HC_STAGING_TESTFLIGHT
    @State private var checkingYearlyTrial = false
    @State private var yearlyTrialReport = ""
    @State private var showsYearlyTrialReport = false
    #endif
    #if DEBUG
    @State private var previewPage = false
    private static var openedPreviewPage = false
    #endif
    @State private var reminderTime = Date()
    @State private var reminderDenied = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradient()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        VStack(alignment: .leading, spacing: 0) {
                            if showsTestSession, app.me != nil {
                                sectionTitle("Sandbox testing")
                                group {
                                    Button { changeTestSession() } label: {
                                        row("arrow.counterclockwise",
                                            app.hasTestSessionBackup ? "Return to previous account" : "Start fresh onboarding",
                                            app.hasTestSessionBackup ? "Leave this temporary test account" : "Reset Her Crown onboarding. Apple purchases stay on your Apple account.")
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(changingTestSession)
                                    #if HC_STAGING_TESTFLIGHT
                                    divider
                                    Button {
                                        checkingYearlyTrial = true
                                        Task {
                                            yearlyTrialReport = await Billing.shared.yearlyTrialReport()
                                            checkingYearlyTrial = false
                                            showsYearlyTrialReport = true
                                        }
                                    } label: {
                                        row("checkmark.circle", checkingYearlyTrial ? "Checking yearly trial…" : "Check yearly trial",
                                            "Compare Apple’s offer with the last paywall.")
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(checkingYearlyTrial || changingTestSession)
                                    #endif
                                }
                            }
                            NavigationLink { AccountView() } label: { profile }.buttonStyle(.plain)
                            membershipCard
                            sectionTitle("Account & reading")
                            group {
                                NavigationLink { AccountView() } label: { row("person", "Your account", accountSubtitle) }.buttonStyle(.plain)
                                divider
                                NavigationLink { SubscriptionView() } label: { row("bookmark", "Subscription", app.membership.premium ? "Her Crown Plus" : "Free plan · explore Plus") }.buttonStyle(.plain)
                                divider
                                Menu { appearanceChoices } label: { row(scheme == .dark ? "moon" : "sun.max", "Appearance", appearanceTitle, chevron: "chevron.down") }.buttonStyle(.plain)
                                divider
                                NavigationLink { AppIconView() } label: { row("app", "App icon", nil) }.buttonStyle(.plain)
                                divider
                                NavigationLink { TopicsView() } label: { row("heart", "On your heart", app.preferences.topics.isEmpty ? "Choose topics" : app.preferences.topics.joined(separator: " · ")) }.buttonStyle(.plain)
                                divider
                                formRow("book", "Reading pace") {
                                    selectMenu(app.preferences.routine ?? "No time goal", OnboardingView.routines) { v in app.updatePreferences(["routine": v]) { $0.routine = v } }
                                }
                                divider
                                VStack(alignment: .leading, spacing: 0) {
                                    formRow("bell", nil) {
                                        Toggle(isOn: Binding(get: { app.preferences.remindersEnabled }, set: setReminders)) { Text("Daily reminder").font(.system(size: 12, weight: .medium)) }
                                            .tint(Theme.text(scheme)).frame(minHeight: 44)
                                        if app.preferences.remindersEnabled {
                                            DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                                .font(.system(size: 12, weight: .medium))
                                                .onChange(of: reminderTime) { _, t in saveReminderTime(t) }
                                        }
                                    }
                                    Text(reminderDenied ? "Turn on notifications for Her Crown in iPhone Settings to get reminders." : "One gentle reminder a day, at the time you choose.")
                                        .font(.system(size: 10)).lineSpacing(3).foregroundStyle(Theme.muted(scheme))
                                        .padding(EdgeInsets(top: 0, leading: 53, bottom: 14, trailing: 16))
                                }
                            }
                            sectionTitle("Bible text")
                            group {
                                formRow("character.book.closed", "Translation") {
                                    selectMenu(["kjv": "King James Version", "bsb": "Berean Standard Bible", "web": "World English Bible"][app.preferences.translation] ?? "King James Version",
                                               ["King James Version", "Berean Standard Bible", "World English Bible"]) { v in
                                        let id = ["King James Version": "kjv", "Berean Standard Bible": "bsb", "World English Bible": "web"][v] ?? "kjv"
                                        app.updatePreferences(["translation": id]) { $0.translation = id }
                                    }
                                }
                                divider
                                formRow("textformat.size", "Font size") {
                                    selectMenu(ReaderFontSize(rawValue: app.preferences.fontSize)?.title ?? "Default", ReaderFontSize.allCases.map(\.title)) { v in
                                        let id = ReaderFontSize.allCases.first { $0.title == v }?.rawValue ?? "default"
                                        app.updatePreferences(["fontSize": id]) { $0.fontSize = id }
                                    }
                                }
                                divider
                                formRow("quote.opening", nil) {
                                    Toggle(isOn: Binding(get: { app.preferences.wordsOfJesusInRed }, set: { v in app.updatePreferences(["wordsOfJesusInRed": v]) { $0.wordsOfJesusInRed = v } })) {
                                        Text("Words of Jesus in red").font(.system(size: 12, weight: .medium))
                                    }
                                    .tint(Theme.text(scheme)).frame(minHeight: 44)
                                }
                            }
                            sectionTitle("Here for you")
                            group {
                                Button { showingTutorial = true } label: {
                                    row("hand.draw", "How Her Crown works", "A short tour of reading, saving and study")
                                }.buttonStyle(.plain)
                                divider
                                NavigationLink { FeedbackView() } label: {
                                    row("bubble.left.and.text.bubble.right", "Suggestions & bugs", "Share an idea or tell us what needs fixing")
                                }.buttonStyle(.plain)
                                divider
                                Button { contactSupport() } label: { row("envelope", "Contact & Support", "Questions, ideas or a little help") }.buttonStyle(.plain)
                                divider
                                Button { legal = .support } label: { row("questionmark.circle", "Help & FAQs", "Let’s work it out together") }.buttonStyle(.plain)
                            }
                            sectionTitle("About & legal")
                            group {
                                ForEach(Array([LegalPage.privacy, .terms, .refunds, .credits].enumerated()), id: \.element) { i, page in
                                    if i > 0 { divider }
                                    Button { legal = page } label: { row(page.symbol, page.title, nil) }.buttonStyle(.plain)
                                }
                            }
                            VStack(spacing: 8) {
                                Text("Rooted in Scripture. Made for real life.").font(.system(size: 12))
                                Text("Her Crown \(AppConfig.appVersion)").font(.system(size: 10))
                            }
                            .foregroundStyle(Theme.muted(scheme))
                            .frame(maxWidth: .infinity)
                            .padding(EdgeInsets(top: 36, leading: 0, bottom: 10, trailing: 0))
                        }
                        .padding(EdgeInsets(top: 8, leading: 22, bottom: 32, trailing: 22))
                    }
                    .foregroundStyle(Theme.text(scheme))
                }
                .clipped()
            }
            .toolbar(.hidden, for: .navigationBar)
            #if DEBUG
            .navigationDestination(isPresented: $previewPage) {
                switch UserDefaults.standard.string(forKey: "hcPreviewSettings") {
                case "account": AccountView()
                case "subscription": SubscriptionView()
                case "topics": TopicsView()
                case "feedback": FeedbackView()
                default: EmptyView()
                }
            }
            .task {
                guard let page = UserDefaults.standard.string(forKey: "hcPreviewSettings"),
                      !Self.openedPreviewPage else { return }
                Self.openedPreviewPage = true
                if let destination = LegalPage(rawValue: page) { legal = destination }
                else { previewPage = true }
            }
            #endif
        }
        .environment(\.colorScheme, scheme)
        .sheet(isPresented: $showingTutorial) {
            ReaderTutorialView(entryPoint: "settings") { _ in showingTutorial = false }
        }
        .sheet(item: $legal) { page in SafariView(url: page.url).ignoresSafeArea() }
        .task { showsTestSession = await AppModel.allowsTestSessions() }
        .alert("Couldn’t switch test accounts", isPresented: $testSessionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your connection and try again.")
        }
        #if HC_STAGING_TESTFLIGHT
        .alert("Yearly trial check", isPresented: $showsYearlyTrialReport) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(yearlyTrialReport)
        }
        #endif
        .onAppear {
            reminderTime = DailyReminder.time(from: app.preferences.reminderTime)
            Task { await Analytics.shared.track("settings_viewed") }
        }
    }

    // MARK: Header (back · "Settings" · appearance), 20/20/16

    private var header: some View {
        HStack {
            PageIconButton(glyph: "back", label: "Close Settings") { dismiss() }
            Text("Settings").font(.serif(30, relativeTo: .title)).tracking(-0.65).accessibilityAddTraits(.isHeader)
            Spacer()
            Menu { appearanceChoices } label: {
                HStack(spacing: 3) {
                    Image(systemName: scheme == .dark ? "moon" : "sun.max").font(.system(size: 15))
                    Image(systemName: "chevron.down").font(.system(size: 8, weight: .semibold))
                }
                .frame(width: 44, height: 44)
                .iconSurface(Circle())
            }
            .accessibilityLabel("Appearance, \(appearanceTitle)")
        }
        .padding(EdgeInsets(top: 20, leading: 22, bottom: 16, trailing: 22))
    }

    private var scheme: ColorScheme {
        #if DEBUG
        if let appearance = UserDefaults.standard.string(forKey: "hcPreviewAppearance") {
            if appearance == "dark" { return .dark }
            if appearance == "light" { return .light }
        }
        #endif
        return switch app.preferences.appearance {
        case "light": .light
        case "dark": .dark
        default: inheritedScheme
        }
    }

    private var appearanceTitle: String {
        switch app.preferences.appearance {
        case "light": "Light"
        case "dark": "Dark"
        default: "System"
        }
    }

    private var appearanceChoices: some View {
        Picker("Appearance", selection: Binding(get: { app.preferences.appearance }, set: { next in
            app.updatePreferences(["appearance": next]) { $0.appearance = next }
            Task { await Analytics.shared.track("setting_changed", ["setting": "appearance", "value": .string(next)]) }
        })) {
            Text("System").tag("system")
            Text("Light").tag("light")
            Text("Dark").tag("dark")
        }
    }

    // MARK: Profile (.settings-profile: 76 pt avatar, 30 pt serif greeting)

    private var profile: some View {
        HStack(spacing: 15) {
            Avatar(size: 76).shadow(color: Color(red: 16 / 255, green: 25 / 255, blue: 31 / 255, opacity: 0.333), radius: 4, y: 8)
            VStack(alignment: .leading, spacing: 6) {
                Text(app.displayName.flatMap { $0 == "Guest" ? nil : "Hi, \($0.split(separator: " ").first.map(String.init) ?? $0)." } ?? "Hi there.")
                    .font(.serif(30, relativeTo: .title)).tracking(-0.5)
                Text("A little space, just for you.").font(.system(size: 12))
                    .frame(minHeight: 18).foregroundStyle(Theme.muted(scheme))
                    .padding(.bottom, 8)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 15)).foregroundStyle(Theme.text(scheme)).frame(width: 36, height: 44)
        }
        .padding(EdgeInsets(top: 18, leading: 0, bottom: 26, trailing: 0))
    }

    // MARK: Membership (.settings-membership: 75% surface, 20 radius, 20/18 padding)

    private var membershipCard: some View {
        NavigationLink { SubscriptionView() } label: {
            HStack(alignment: .center, spacing: 16) {
                Image.illustration("butterfly").resizable().scaledToFit().frame(width: 76, height: 70).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(app.membership.premium ? "You’re growing with Plus." : "Grow in your own time.").font(.serif(23, relativeTo: .title3)).lineLimit(1).minimumScaleFactor(0.8)
                    Text(app.membership.premium ? "Plans and every study tool are yours." : "Explore Her Crown Plus.").font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                    if !app.membership.premium {
                        HStack(spacing: 6) { Text("View membership"); Image(systemName: "arrow.right") }.font(.system(size: 12, weight: .semibold)).frame(height: 30)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 20, leading: 18, bottom: 20, trailing: 18))
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface(scheme).opacity(0.75)))
            .shadow(color: Color(red: 21 / 255, green: 35 / 255, blue: 42 / 255, opacity: 0.12), radius: 5, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var accountSubtitle: String {
        if app.isGuest { return "Guest · save your account with Apple" }
        return [app.displayName, app.me?.user.email.flatMap { $0.hasSuffix(".invalid") ? nil : $0 }].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: Groups and rows (.settings-group: 88% surface, 18 radius; rows 14/15 padding, hairline between)

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.muted(scheme))
            .padding(EdgeInsets(top: 29, leading: 4, bottom: 11, trailing: 4))
    }

    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface(scheme).opacity(0.88)))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(red: 21 / 255, green: 35 / 255, blue: 42 / 255, opacity: 0.12), radius: 5, y: 5)
    }

    private var divider: some View { Rectangle().fill(Theme.border(scheme)).frame(height: 1) }

    private func row(_ symbol: String, _ title: String, _ subtitle: String?, chevron: String = "chevron.right") -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol).font(.system(size: 19, weight: .light)).frame(width: 25, height: 21)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .medium))
                if let subtitle, !subtitle.isEmpty { Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.muted(scheme)).lineLimit(2) }
            }
            Spacer(minLength: 0)
            Image(systemName: chevron).font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
        }
        .padding(EdgeInsets(top: 14, leading: 15, bottom: 14, trailing: 15))
        .frame(minHeight: 67)
        .contentShape(Rectangle())
    }

    /// .settings-form-row: icon column, then a 12 pt label above its control.
    private func formRow<Control: View>(_ symbol: String, _ label: String?, @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol).font(.system(size: 19, weight: .light)).frame(width: 25, height: 21).padding(.top, label == nil ? 12 : 4)
            VStack(alignment: .leading, spacing: 8) {
                if let label { Text(label).font(.system(size: 12, weight: .medium)) }
                control()
            }
        }
        .padding(15)
    }

    /// The mockup's native select: 44 pt, #f2f2f4, 9 radius, 16 pt value.
    private func selectMenu(_ value: String, _ options: [String], onPick: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(options, id: \.self) { o in Button(o) { onPick(o) } }
        } label: {
            HStack {
                Text(value).font(.system(size: 16))
                Spacer()
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.text(scheme))
            .padding(.horizontal, 12).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.supporting(scheme)))
        }
    }

    private func pref(_ keyPath: WritableKeyPath<Preferences, String>, key: String) -> Binding<String> {
        Binding(get: { app.preferences[keyPath: keyPath] }, set: { v in
            app.updatePreferences([key: v]) { $0[keyPath: keyPath] = v }
            Task { await Analytics.shared.track("setting_changed", ["setting": .string(key), "value": .string(v)]) }
        })
    }

    private func setReminders(_ on: Bool) {
        Task {
            if on {
                let granted = await DailyReminder.requestAndSchedule(at: reminderTime)
                reminderDenied = !granted
                guard granted else { return }
            } else {
                DailyReminder.cancel()
            }
            app.updatePreferences(["remindersEnabled": on, "timeZone": TimeZone.current.identifier]) { $0.remindersEnabled = on }
        }
    }

    private func saveReminderTime(_ t: Date) {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; f.locale = Locale(identifier: "en_US_POSIX")
        let value = f.string(from: t)
        guard value != app.preferences.reminderTime else { return }
        DailyReminder.cancel(); DailyReminder.schedule(at: t)
        app.updatePreferences(["reminderTime": value]) { $0.reminderTime = value }
    }

    private func changeTestSession() {
        changingTestSession = true
        Task {
            defer { changingTestSession = false }
            do {
                if app.hasTestSessionBackup { try await app.restoreTestSession() }
                else { try await app.startTestSession() }
                dismiss()
            } catch {
                testSessionError = true
            }
        }
    }

    /// Opens an email to the team with what we need to help (until in-app messages can be delivered: docs/later.md).
    private func contactSupport() {
        let body = "\n\n\n—\nPlease keep this so we can help:\nAccount: \(app.me?.user.id ?? "unknown")\nApp: \(AppConfig.appVersion) · iOS \(UIDevice.current.systemVersion)"
        var c = URLComponents(); c.scheme = "mailto"; c.path = "macnatephil@gmail.com"
        c.queryItems = [URLQueryItem(name: "subject", value: "Her Crown support"), URLQueryItem(name: "body", value: body)]
        if let url = c.url { UIApplication.shared.open(url) }
        Task { await Analytics.shared.track("support_opened") }
    }
}

// MARK: - Account

/// settings.account: photo, name, bio, Sign in with Apple, delete account.
struct AccountView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var showsAppleSignIn = false
    @State private var name = ""
    @State private var bio = ""
    @State private var photo: PhotosPickerItem?
    @State private var message: String?
    @State private var busy = false
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                photoControls
                field("Name") {
                    TextField("Your name", text: $name)
                        .textContentType(.givenName)
                        .accessibilityLabel("Name")
                        .padding(.horizontal, 13)
                        .frame(minHeight: 46)
                }
                field("Bio") {
                    TextEditor(text: $bio)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .frame(minHeight: 160)
                        .accessibilityLabel("Bio")
                }
                Button("Save") {
                    run {
                        try await app.updateProfile(displayName: trimmedName, bio: bio)
                        message = "Saved."
                    }
                }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(busy || trimmedName.isEmpty)
                .opacity(trimmedName.isEmpty ? 0.55 : 1)

                signInSection
                    .padding(.top, 10)
                if let message { Text(message).font(.ui(13)).accessibilityAddTraits(.updatesFrequently) }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Permanently deletes your profile, photo, saves, notes and reading history. Deleting your account doesn’t cancel Apple billing.")
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted(scheme))
                    Button(role: .destructive) { confirmingDelete = true } label: {
                        Text("Delete account")
                            .font(.ui(15, weight: .medium))
                            .foregroundStyle(scheme == .dark ? Color(hex: 0xFF8D97) : Color(hex: 0xB12638))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Theme.text(scheme))
        .background(AppGradient())
        .safeAreaInset(edge: .top, spacing: 0) {
            ZStack(alignment: .leading) {
                Text("Your account")
                    .font(.ui(16, weight: .medium))
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity)
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 58)
            .background(Theme.canvas(scheme))
        }
        .toolbar(.hidden, for: .navigationBar)
        .disabled(busy)
        .overlay { if busy { ProgressView() } }
        .sheet(isPresented: $showsAppleSignIn) { appleSignIn }
        .onAppear {
            name = app.displayName.flatMap { $0 == "Guest" ? nil : $0 } ?? ""
            bio = app.me?.profile.bio ?? ""
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            run {
                defer { photo = nil }
                guard let data = try await item.loadTransferable(type: Data.self), let jpeg = Self.squareJPEG(data) else { message = "We couldn’t read that photo."; return }
                try await app.uploadAvatar(jpeg)
                message = "Photo updated."
            }
        }
        .confirmationDialog("Delete your account?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) { run { try await app.deleteAccount(); message = "Your account was deleted. You’re starting fresh as a guest." } }
        } message: {
            Text("This can’t be undone.")
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var photoControls: some View {
        VStack(spacing: 14) {
            Avatar(size: 110)
            PhotosPicker(selection: $photo, matching: .images) {
                Label("Choose photo", systemImage: "camera")
            }
            .buttonStyle(CapsuleButtonStyle(kind: .secondary))
            .frame(width: 164)
            if app.me?.profile.avatarUrl != nil {
                Button("Remove photo") { run { try await app.removeAvatar(); message = "Photo removed." } }
                    .font(.ui(13, weight: .medium))
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.ui(13, weight: .medium))
            content()
                .font(.ui(16))
                .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.muted(scheme).opacity(0.42))
                        .allowsHitTesting(false)
                }
        }
    }

    private var signInSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sign in").font(.ui(13, weight: .semibold))
                .foregroundStyle(Theme.muted(scheme))
                .accessibilityAddTraits(.isHeader)
            if app.isGuest {
                Button { showsAppleSignIn = true } label: { signInRow }
                    .buttonStyle(.plain)
            } else {
                signInRow.accessibilityElement(children: .combine)
            }
            Text(app.isGuest ? "You’re reading as a guest. Save your account to keep your reading when you change phones." : "Your reading is saved to your account.")
                .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
        }
    }

    private var signInRow: some View {
        HStack(spacing: 12) {
            Image(systemName: app.isGuest ? "shield" : "checkmark.shield").font(.system(size: 19))
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.isGuest ? "Sign in with Apple" : "Signed in with Apple")
                    .font(.ui(14, weight: .medium))
                Text("Keep your saves, notes and reading history safe")
                    .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
            }
            Spacer(minLength: 0)
            if app.isGuest {
                Image(systemName: "chevron.right").font(.system(size: 12))
                    .foregroundStyle(Theme.muted(scheme))
                    .accessibilityHidden(true)
            }
        }
        .padding(14)
        .frame(minHeight: 58)
        .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }

    private var appleSignIn: some View {
        VStack(spacing: 16) {
            Text("Save your account").font(.serif(28, relativeTo: .title2))
                .accessibilityAddTraits(.isHeader)
            Text("Keep your saves, notes and reading history when you change phones.")
                .font(.ui(14)).foregroundStyle(Theme.muted(scheme))
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                guard case .success(let auth) = result, let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                      let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else {
                    if case .failure(let error) = result, (error as? ASAuthorizationError)?.code == .canceled { return }
                    showsAppleSignIn = false
                    message = "Sign in with Apple didn’t work. Please try again."
                    return
                }
                showsAppleSignIn = false
                let given = credential.fullName?.givenName
                run {
                    try await app.signInWithApple(identityToken: token)
                    if let given, app.displayName == nil || app.displayName == "Guest" { try await app.updateProfile(displayName: given, bio: bio) }
                    name = app.displayName.flatMap { $0 == "Guest" ? nil : $0 } ?? ""
                    bio = app.me?.profile.bio ?? ""
                    message = "Your account is saved."
                }
            }
            .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
            .frame(height: 48)
            Button("Continue as a guest") { showsAppleSignIn = false }
                .font(.ui(13, weight: .medium))
                .frame(minHeight: 44)
                .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .foregroundStyle(Theme.text(scheme))
        .presentationDetents([.medium, .large])
    }

    private func run(_ work: @escaping () async throws -> Void) {
        busy = true; message = nil
        Task {
            do { try await work() } catch let error as APIError { message = error.message } catch { message = "Something went wrong. Please try again." }
            busy = false
        }
    }

    /// Center-crops to a square and scales to 640 px, JPEG (well under the 10 MB limit).
    static func squareJPEG(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let side = min(image.size.width, image.size.height)
        let target: CGFloat = 640
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }())
        let scaled = renderer.image { _ in
            let scale = target / side
            image.draw(in: CGRect(x: -(image.size.width - side) / 2 * scale, y: -(image.size.height - side) / 2 * scale,
                                  width: image.size.width * scale, height: image.size.height * scale))
        }
        return scaled.jpegData(compressionQuality: 0.85)
    }
}

/// Her photo (private, fetched with her session), else her initial, else the cosmos flower.
struct Avatar: View {
    let size: CGFloat
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Circle().fill(Theme.supporting(scheme))
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else if let initial = app.displayName.flatMap({ $0 == "Guest" ? nil : $0.first }) { Text(String(initial)).font(.serif(size * 0.45)) }
            else { Image.illustration("cosmos").resizable().scaledToFit().padding(size * 0.18) }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Theme.border(scheme), lineWidth: 0.8))
        .accessibilityHidden(true)
        .task(id: app.me?.profile.avatarUrl) {
            guard app.me?.profile.avatarUrl != nil, let (data, _) = try? await app.api.send("GET", "/me/avatar") else { image = nil; return }
            image = UIImage(data: data)
        }
    }
}

// MARK: - Subscription

/// settings.subscription: current plan, benefits, Explore Plus, Restore, Manage. Never claims Plus without a verified entitlement.
struct SubscriptionView: View {
    #if DEBUG
    @State private var openingSandboxCheckout = false
    #endif
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var appleSubscriptionFound = false
    @State private var checkedAppleSubscription = false
    @State private var confirmsRestore = false
    @State private var restoring = false
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 12) {
                    Image.illustration("butterfly").resizable().scaledToFit()
                        .frame(width: 96, height: 84).accessibilityHidden(true)
                    Text("Your reading, your way.").font(.serif(30, relativeTo: .title))
                    Text("Enjoy free reading, or explore a little more with Plus.")
                        .font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                        .frame(maxWidth: 260)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
                .padding(.bottom, 24)

                subscriptionGroup("Current plan") { currentPlan }
                subscriptionGroup("Purchases") {
                    Button { confirmsRestore = true } label: {
                        purchaseRow(restoring ? "Restoring…" : "Restore Purchases", icon: "arrow.clockwise")
                    }
                    .disabled(restoring)
                    Divider()
                    Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                        purchaseRow("Manage subscription", icon: "bookmark")
                    }
                    if let message {
                        Divider()
                        Text(message).font(.ui(14)).padding(16)
                    }
                }
                Text("Subscriptions are billed and managed by Apple. Cancel at least 24 hours before your trial or period ends to avoid the next charge.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted(scheme))
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .foregroundStyle(Theme.text(scheme))
        .background(AppGradient())
        .safeAreaInset(edge: .top, spacing: 0) {
            ZStack(alignment: .leading) {
                Text("Subscription")
                    .font(.ui(16, weight: .medium))
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity)
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 58)
            .foregroundStyle(Theme.text(scheme))
            .background(Theme.canvas(scheme))
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            checkedAppleSubscription = false
            let existing = await app.activeAppleSubscription()
            guard !Task.isCancelled else { return }
            appleSubscriptionFound = existing != nil
            checkedAppleSubscription = true
        }
        .confirmationDialog("Restore Plus to this account?", isPresented: $confirmsRestore, titleVisibility: .visible) {
            Button("Restore Purchases") {
                restoring = true
                Task { message = await app.restorePurchases(); restoring = false }
            }
        } message: {
            Text("Restoring connects Plus to your current Her Crown account and may move Plus access from another account.")
        }
    }

    @ViewBuilder
    private var currentPlan: some View {
        if let sub = app.membership.subscription, app.membership.premium {
            VStack(alignment: .leading, spacing: 10) {
                Text("Her Crown Plus").font(.serif(28, weight: .semibold, relativeTo: .title2))
                    .accessibilityAddTraits(.isHeader)
                Text(planName(sub.productId)).font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                if sub.isTrial, let trial = sub.trial {
                    LabeledContent("Free trial ends", value: Date(timeIntervalSince1970: trial.endsAt / 1000).formatted(date: .abbreviated, time: .omitted))
                } else if let expires = sub.expiresAt {
                    LabeledContent(sub.willRenew ? "Renews" : "Ends", value: Date(timeIntervalSince1970: expires / 1000).formatted(date: .abbreviated, time: .omitted))
                }
            }
            .font(.ui(14))
            .padding(18)
        } else if !checkedAppleSubscription {
            ProgressView("Checking for an Apple subscription…").padding(18)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Free reading").font(.serif(28, weight: .semibold, relativeTo: .title2))
                    .accessibilityAddTraits(.isHeader)
                Text(appleSubscriptionFound
                     ? "Apple found a Plus subscription that isn’t connected to this Her Crown account. Restore your purchase to connect it."
                     : "Reading the Bible is always free. Plus adds reading plans and every study tool.")
                    .font(.ui(14))
                    .foregroundStyle(Theme.muted(scheme))
                if !appleSubscriptionFound {
                    Button("Explore Her Crown Plus") {
                        #if DEBUG
                        guard !openingSandboxCheckout else { return }
                        openingSandboxCheckout = true
                        Task { await openSandboxCheckout() }
                        #else
                        app.presentPaywall(placement: "settings_subscription") { appleSubscriptionFound = true }
                        #endif
                    }
                    .buttonStyle(CapsuleButtonStyle())
                }
            }
            .padding(18)
        }
    }

    private func subscriptionGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.ui(13, weight: .semibold))
                .foregroundStyle(Theme.muted(scheme))
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0, content: content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
                .buttonStyle(.plain)
        }
        .padding(.top, 28)
    }

    private func purchaseRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).frame(width: 24)
            Text(title).font(.ui(14, weight: .medium))
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted(scheme))
        }
        .foregroundStyle(Theme.text(scheme))
        .padding(16)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }

    #if DEBUG
    private func openSandboxCheckout() async {
        defer { openingSandboxCheckout = false }
        if await app.activeAppleSubscription() != nil {
            appleSubscriptionFound = true
            return
        }
        message = "Opening Apple sandbox checkout…"
        do {
            guard let product = try await Product.products(for: ["hercrown.plus.yearly"]).first else {
                message = "Apple sandbox did not return the Her Crown yearly plan."
                return
            }
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                message = await app.verifyPurchases()
                await transaction.finish()
            case .userCancelled:
                message = nil
            case .pending:
                message = "Apple is waiting for purchase approval."
            default:
                message = "Apple could not verify the purchase."
            }
        } catch {
            message = "Apple checkout could not open. \(error.localizedDescription)"
        }
    }
    #endif

    private func planName(_ id: String?) -> String {
        switch id {
        case "hercrown.plus.monthly": "Plus · monthly"
        case "hercrown.plus.weekly": "Plus · weekly"
        case "hercrown.plus.yearly", "hercrown.plus.yearly.offer": "Plus · yearly"
        default: "Plus"
        }
    }
}

// MARK: - Topics

/// settings.topics: the nine onboarding topics; saving updates Discover's ordering and returns to Settings.
struct TopicsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var topics: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 12) {
                    Image.illustration("cosmos").resizable().scaledToFit()
                        .frame(width: 82, height: 90).accessibilityHidden(true)
                    Text("What’s on your heart?").font(.serif(30, relativeTo: .title))
                    Text("Choose the themes you’d like to make space for. You can change these anytime.")
                        .font(.system(size: 14)).foregroundStyle(Theme.muted(scheme))
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                VStack(spacing: 10) {
                    ForEach(OnboardingView.topicOptions, id: \.self) { topic in
                        let selected = topics.contains(topic)
                        Button {
                            if selected { topics.removeAll { $0 == topic } }
                            else { topics.append(topic) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 18))
                                Text(topic).font(.system(size: 14))
                                Spacer()
                            }
                            .foregroundStyle(Theme.text(scheme))
                            .padding(16)
                            .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(AppGradient())
        .navigationTitle("On your heart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Save") {
                let chosen = topics
                app.updatePreferences(["topics": chosen]) { $0.topics = chosen }
                Task { await Analytics.shared.track("topics_updated", ["count": .number(Double(chosen.count))]) }
                dismiss()
            }
        }
        .onAppear { topics = app.preferences.topics }
    }
}

// MARK: - Legal

enum LegalPage: String, Identifiable {
    case privacy, terms, refunds, credits, support
    var id: String { rawValue }
    var title: String { switch self { case .privacy: "Privacy Policy"; case .terms: "Terms of Use"; case .refunds: "Refunds & Cancellation"; case .credits: "Credits & Licenses"; case .support: "Help & FAQs" } }
    var symbol: String { switch self { case .privacy: "hand.raised"; case .terms: "doc.text"; case .refunds: "arrow.uturn.backward"; case .credits: "books.vertical"; case .support: "questionmark.circle" } }
    var url: URL { AppConfig.apiBaseURL.appendingPathComponent("legal/\(rawValue)") }
}

/// Legal and help pages, read in the app.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
