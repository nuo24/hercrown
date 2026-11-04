import AuthenticationServices
import PhotosUI
import SafariServices
import SwiftUI

/// settings.root (specs/SCREEN-MAP.md): profile, membership, Account & reading, Here for you, About & legal.
/// Every change here saves at once and never touches onboarding.
struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var legal: LegalPage?
    @State private var reminderTime = Date()
    @State private var reminderDenied = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradient()
                List {
                    Section {
                        NavigationLink { AccountView() } label: { profileHeader }
                        membershipCard
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section("Account & reading") {
                        NavigationLink { AccountView() } label: { row("person", "Your account", accountSubtitle) }
                        NavigationLink { SubscriptionView() } label: { row("bookmark", "Subscription", app.membership.premium ? "Her Crown Plus" : "Free plan · explore Plus") }
                        Picker(selection: pref(\.appearance, key: "appearance")) {
                            Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                        } label: { row("sun.max", "Appearance", nil) }
                        NavigationLink { TopicsView() } label: { row("heart", "On your heart", app.preferences.topics.isEmpty ? "Choose topics" : app.preferences.topics.joined(separator: " · ")) }
                        Picker(selection: Binding(get: { app.preferences.routine ?? "No time goal" }, set: { v in app.updatePreferences(["routine": v]) { $0.routine = v } })) {
                            ForEach(OnboardingView.routines, id: \.self) { Text($0).tag($0) }
                        } label: { row("book", "Reading pace", nil) }
                        Toggle(isOn: Binding(get: { app.preferences.remindersEnabled }, set: setReminders)) { row("bell", "Daily reminder", reminderDenied ? "Turn on notifications for Her Crown in iPhone Settings" : nil) }
                        if app.preferences.remindersEnabled {
                            DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .onChange(of: reminderTime) { _, t in saveReminderTime(t) }
                        }
                    }

                    Section("Bible text") {
                        Picker(selection: pref(\.translation, key: "translation")) {
                            Text("King James Version").tag("kjv"); Text("Berean Standard Bible").tag("bsb"); Text("World English Bible").tag("web")
                        } label: { row("character.book.closed", "Translation", nil) }
                        Picker(selection: pref(\.fontSize, key: "fontSize")) {
                            ForEach(ReaderFontSize.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                        } label: { row("textformat.size", "Font size", nil) }
                        Toggle(isOn: Binding(get: { app.preferences.wordsOfJesusInRed }, set: { v in app.updatePreferences(["wordsOfJesusInRed": v]) { $0.wordsOfJesusInRed = v } })) {
                            row("quote.opening", "Words of Jesus in red", nil)
                        }
                    }

                    Section("Here for you") {
                        Button { contactSupport() } label: { row("envelope", "Contact & Support", "We usually reply within two business days") }
                        Button { legal = .support } label: { row("questionmark.circle", "Help & FAQs", nil) }
                    }

                    Section("About & legal") {
                        ForEach([LegalPage.privacy, .terms, .refunds, .credits]) { page in
                            Button { legal = page } label: { row(page.symbol, page.title, nil) }
                        }
                    }

                    Section {
                        Text("Her Crown \(AppConfig.appVersion)").font(.system(size: 12)).foregroundStyle(Theme.muted(scheme)).frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .tint(Theme.text(scheme))
                .foregroundStyle(Theme.text(scheme))
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(item: $legal) { page in SafariView(url: page.url).ignoresSafeArea() }
        .onAppear {
            reminderTime = Self.time(from: app.preferences.reminderTime)
            Task { await Analytics.shared.track("settings_viewed") }
        }
    }

    // MARK: Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Avatar(size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName.flatMap { $0 == "Guest" ? nil : "Hi, \($0)." } ?? "Hi there.").font(.serif(28, relativeTo: .title))
                Text("A little space, just for you.").font(.system(size: 14)).foregroundStyle(Theme.muted(scheme))
            }
        }
        .padding(.vertical, 6)
    }

    private var membershipCard: some View {
        Button { if !app.membership.premium { app.presentPaywall(placement: "settings") } } label: {
            HStack(spacing: 16) {
                Image("butterfly").resizable().scaledToFit().frame(width: 76).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(app.membership.premium ? "You’re growing with Plus." : "Grow in your own time.").font(.serif(23, relativeTo: .title3))
                    Text(app.membership.premium ? "Plans and every study tool are yours." : "Explore Her Crown Plus.").font(.system(size: 14)).foregroundStyle(Theme.muted(scheme))
                    if !app.membership.premium {
                        HStack(spacing: 6) { Text("View membership"); Image(systemName: "arrow.right") }.font(.system(size: 15, weight: .semibold)).padding(.top, 4)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.surface(scheme)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.border(scheme), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }

    private var accountSubtitle: String {
        if app.isGuest { return "Guest · save your account with Apple" }
        return [app.displayName, app.me?.user.email.flatMap { $0.hasSuffix(".invalid") ? nil : $0 }].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: Rows and preferences

    private func row(_ symbol: String, _ title: String, _ subtitle: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 17)).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16))
                if let subtitle, !subtitle.isEmpty { Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.muted(scheme)).lineLimit(2) }
            }
        }
        .foregroundStyle(Theme.text(scheme))
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

    static func time(from hhmm: String) -> Date {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        return Calendar.current.date(bySettingHour: parts.first ?? 8, minute: parts.count > 1 ? parts[1] : 0, second: 0, of: Date()) ?? Date()
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
    @State private var name = ""
    @State private var bio = ""
    @State private var photo: PhotosPickerItem?
    @State private var message: String?
    @State private var busy = false
    @State private var confirmingDelete = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Avatar(size: 96)
                        PhotosPicker(selection: $photo, matching: .images) { Text(app.me?.profile.avatarUrl == nil ? "Add photo" : "Change photo") }
                        if app.me?.profile.avatarUrl != nil {
                            Button("Remove photo", role: .destructive) { run { try await app.removeAvatar() } }.font(.system(size: 14))
                        }
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

            Section("Profile") {
                TextField("Your name", text: $name).textContentType(.givenName)
                TextField("A line about you (optional)", text: $bio, axis: .vertical).lineLimit(2...4)
                Button("Save") { run { try await app.updateProfile(displayName: name.trimmingCharacters(in: .whitespaces), bio: bio); message = "Saved." } }
                    .disabled(busy || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Section {
                if app.isGuest {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        guard case .success(let auth) = result, let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                              let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else {
                            if case .failure(let error) = result, (error as? ASAuthorizationError)?.code != .canceled { message = "Sign in with Apple didn’t work. Please try again." }
                            return
                        }
                        let given = credential.fullName?.givenName
                        run {
                            try await app.signInWithApple(identityToken: token)
                            if let given, app.displayName == nil || app.displayName == "Guest" { try await app.updateProfile(displayName: given, bio: bio) }
                            message = "Your account is saved. Sign in with Apple on a new phone to bring everything with you."
                        }
                    }
                    .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                    .frame(height: 50)
                } else {
                    Label("Signed in with Apple", systemImage: "checkmark.seal").foregroundStyle(Theme.text(scheme))
                }
            } header: { Text("Sign in") } footer: {
                Text(app.isGuest ? "You’re reading as a guest. Save your account so your saves, notes and streak are safe if you change phones." : "Your reading is saved to your account.")
            }

            if let message { Section { Text(message).font(.system(size: 14)) } }

            Section {
                Button("Delete account", role: .destructive) { confirmingDelete = true }
            } footer: {
                Text("Permanently deletes your profile, photo, saves, notes and reading history. If you subscribe, cancel in iPhone Settings too: deleting your account doesn’t stop Apple billing.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppGradient())
        .navigationTitle("Your account")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(busy)
        .overlay { if busy { ProgressView() } }
        .onAppear {
            name = app.displayName.flatMap { $0 == "Guest" ? nil : $0 } ?? ""
            bio = app.me?.profile.bio ?? ""
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            run {
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
            else { Image("cosmos").resizable().scaledToFit().padding(size * 0.18) }
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
    @Environment(AppModel.self) private var app
    @State private var restoring = false
    @State private var message: String?

    var body: some View {
        Form {
            Section("Your plan") {
                if let sub = app.membership.subscription, app.membership.premium {
                    LabeledContent("Plan", value: planName(sub.productId))
                    if sub.isTrial, let trial = sub.trial {
                        LabeledContent("Free trial ends", value: Date(timeIntervalSince1970: trial.endsAt / 1000).formatted(date: .abbreviated, time: .omitted))
                    } else if let expires = sub.expiresAt {
                        LabeledContent(sub.willRenew ? "Renews" : "Ends", value: Date(timeIntervalSince1970: expires / 1000).formatted(date: .abbreviated, time: .omitted))
                    }
                } else {
                    LabeledContent("Plan", value: "Free")
                    Text("Reading the Bible is always free. Plus adds reading plans and every study tool: Explain easier, Deeper study, Original language and Related verses.")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                    Button("Explore Her Crown Plus") { app.presentPaywall(placement: "settings_subscription") }
                }
            }
            Section {
                Button(restoring ? "Restoring…" : "Restore Purchases") {
                    restoring = true
                    Task { message = await app.restorePurchases(); restoring = false }
                }
                .disabled(restoring)
                if let message { Text(message).font(.system(size: 14)) }
                Link("Manage subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
            } footer: {
                Text("Subscriptions are billed and managed by Apple. Cancel at least 24 hours before your trial or period ends to avoid the next charge.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppGradient())
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func planName(_ id: String?) -> String {
        switch id {
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
    @Environment(\.dismiss) private var dismiss
    @State private var topics: [String] = []

    var body: some View {
        Form {
            Section {
                ForEach(OnboardingView.topicOptions, id: \.self) { topic in
                    Button {
                        if topics.contains(topic) { topics.removeAll { $0 == topic } } else { topics.append(topic) }
                    } label: {
                        HStack { Text(topic); Spacer(); if topics.contains(topic) { Image(systemName: "checkmark") } }
                    }
                }
            } footer: { Text("We’ll put Scripture on these topics first in Discover.") }
        }
        .scrollContentBackground(.hidden)
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
