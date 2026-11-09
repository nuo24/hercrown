import SwiftUI

/// streak.detail: "Your reading rhythm": the streak card, her progress, and how streaks count.
struct StreakSheet: View {
    let model: HomeModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(spacing: 9) {
                        Text(model.streak.current.formatted())
                            .font(.serif(76, relativeTo: .largeTitle)).monospacedDigit()
                        Text("DAYS OF A LITTLE FAITHFULNESS").font(.ui(10, weight: .medium))
                            .tracking(0.8).foregroundStyle(Theme.muted(scheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    week
                    Text(model.streak.readToday
                         ? "You’ve made a little room for the Word today. Come back tomorrow and keep your rhythm growing."
                         : "One quiet moment counts. Make a little room for the Word today.")
                        .font(.ui(15)).foregroundStyle(Theme.muted(scheme))
                    Button(model.streak.readToday ? "Keep reading" : "Make time for today") {
                        app.requestedTab = .bible
                        dismiss()
                    }
                    .buttonStyle(CapsuleButtonStyle())
                    Divider()
                    HStack {
                        Text("Your longest streak").font(.ui(13, weight: .medium))
                        Spacer()
                        Text("\(model.streak.best) \(model.streak.best == 1 ? "day" : "days")").font(.ui(13))
                    }
                    if let p = model.progress { progress(p) }
                    else { ProgressView().frame(maxWidth: .infinity) }
                }
                .padding(22)
            }
            .foregroundStyle(Theme.text(scheme))
            .background(AppGradient())
            .navigationTitle("Your reading rhythm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button { dismiss() } label: { Image(systemName: "xmark").font(.ui(14)).frame(width: 44, height: 44) }.buttonStyle(.plain).accessibilityLabel("Close reading rhythm") } }
        }
        .task {
            await model.loadProgress()
            await Analytics.shared.track("streak_viewed", ["current": .number(Double(model.streak.current))])
        }
    }

    private var week: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let offset = (calendar.component(.weekday, from: today) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return HStack {
            ForEach(0..<7, id: \.self) { index in
                let date = calendar.date(byAdding: .day, value: index, to: monday) ?? monday
                let read = date <= today && model.streak.week.contains { $0.day == formatter.string(from: date) && $0.read }
                let weekday = date.formatted(.dateTime.weekday(.wide))
                VStack(spacing: 8) {
                    Text(String(weekday.prefix(1))).font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    ZStack {
                        Circle().strokeBorder(Theme.border(scheme))
                        if read {
                            Circle().fill(Theme.text(scheme))
                            Image.glyph("check").frame(width: 15, height: 15).foregroundStyle(Theme.canvas(scheme))
                        } else {
                            Circle().fill(Theme.border(scheme)).frame(width: 3, height: 3)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(weekday), \(read ? "read" : "not read")")
            }
        }
    }

    private func progress(_ p: ReadingProgress) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Through the Bible").font(.ui(15, weight: .semibold))
                        Text("\(p.bible.chaptersRead.formatted()) of \(p.bible.totalChapters.formatted()) chapters")
                            .font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                    }
                    Spacer(minLength: 0)
                    Image.illustration("open-book").resizable().scaledToFit()
                        .frame(width: 58, height: 52).accessibilityHidden(true)
                }
                ProgressView(value: Double(p.bible.chaptersRead), total: Double(max(p.bible.totalChapters, 1)))
                    .tint(scheme == .dark ? Color(hex: 0xAAC5B0) : Theme.readDay)
                    .accessibilityLabel("Bible reading progress")
            }
            .padding(18)
            .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border(scheme)) }

            VStack(alignment: .leading, spacing: 0) {
                Text("Your reading journal").font(.ui(15, weight: .semibold))
                    .padding(.bottom, 8)
                journalRow("Days read", detail: "\(p.daysThisYear.formatted()) this year", count: p.daysRead.total, art: "seedling")
                Divider()
                journalRow("Weeks in a row", detail: "\(p.daysOpened.total.formatted()) days opened", count: p.weeksInARow, art: "olive")
                Divider()
                journalRow("Devotionals read", count: p.devotionalsRead, art: "journal")
                Divider()
                journalRow("Verses studied", count: p.versesStudied, art: "magnifier")
            }
            .padding(.horizontal, 4)
            Text("One reading day counts once. Missing a full day starts a new run; your personal best stays.")
                .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
        }
    }

    private func journalRow(_ label: String, detail: String? = nil, count: Int, art: String) -> some View {
        HStack(spacing: 12) {
            Image.illustration(art).resizable().scaledToFit()
                .frame(width: 34, height: 34).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.serif(20, relativeTo: .title3))
                if let detail { Text(detail).font(.footnote).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 8)
            Text(count.formatted()).font(.serif(29, relativeTo: .title2)).monospacedDigit()
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

/// plans.detail: title, description, the exact passages, start/continue. Plans are Plus; free readers see the passages
/// and the paywall when they start.
struct PlanSheet: View {
    let planId: String
    let model: HomeModel
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private var plan: ReadingPlan? { model.plans?.plans.first { $0.id == planId } }
    private var locked: Bool { model.plans?.locked ?? !app.membership.premium }
    private var translation: String { BibleStore.offline[app.preferences.translation] == nil ? "kjv" : app.preferences.translation }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let plan {
                    VStack(alignment: .leading, spacing: 16) {
                        SheetControls(back: { dismiss() }, done: { dismiss() })
                        VStack(spacing: 16) {
                            Image.illustration("journal").resizable().scaledToFit().frame(width: 90, height: 90).padding(.vertical, 12)
                            Text(plan.title).font(.serif(28, relativeTo: .title))
                            Text(plan.description).font(.system(size: 14)).lineSpacing(7.14)
                        }
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        Text("\(plan.progress?.completedSteps ?? 0) of \(plan.days) passages · Read at your own pace")
                            .font(.ui(13)).foregroundStyle(Theme.muted(scheme)).padding(.top, 28)
                        VStack(spacing: 0) { ForEach(plan.steps) { step in stepRow(plan, step) } }
                            .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
                        primaryButton(plan)
                    }
                    .padding(Theme.Spacing.gutter)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme))
        }
        .task { await Analytics.shared.track("plan_viewed", ["plan": .string(planId), "locked": .bool(locked)]) }
    }

    private func stepRow(_ plan: ReadingPlan, _ step: ReadingPlan.Step) -> some View {
        let ref = VerseRef(step.ref)
        let done = step.completedAt != nil
        return Button { read(plan, step) } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().fill(done ? Color(hex: 0xD9A35B) : Theme.supporting(scheme))
                    if done { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white) }
                    else { Text("\(step.position + 1)").font(.system(size: 12, weight: .semibold)) }
                }
                .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(ref.map { BibleStore.shared.label($0) } ?? step.ref).font(.system(size: 14, weight: .semibold))
                    Text("A moment in the Word").font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .padding(16).frame(minHeight: 74)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder private func primaryButton(_ plan: ReadingPlan) -> some View {
        if locked {
            Button("Start with Plus") { app.presentPaywall(placement: "plan_start") }.buttonStyle(PlanActionStyle()).padding(.top, 8)
            Text("Reading plans are part of Her Crown Plus. Reading the Bible stays free.")
                .font(.system(size: 13)).foregroundStyle(Theme.muted(scheme)).frame(maxWidth: .infinity).multilineTextAlignment(.center)
        } else if plan.progress?.completedAt == nil {
            if let next = plan.steps.first(where: { $0.completedAt == nil }) {
            Button(plan.progress == nil ? "Start this plan" : "Continue with passage \(next.position + 1)") { read(plan, next) }
                .buttonStyle(PlanActionStyle()).padding(.top, 8)
            }
        } else {
            Text("You finished this plan. Well done.").font(.serif(19)).frame(maxWidth: .infinity)
        }
    }

    /// Opens the passage in The Bible and counts the step (steps may be read in any order).
    private func read(_ plan: ReadingPlan, _ step: ReadingPlan.Step) {
        guard !locked else { app.presentPaywall(placement: "plan_start"); return }
        guard let ref = VerseRef(step.ref) else { return }
        Task {
            if plan.progress == nil { _ = await model.startPlan(plan.id); await Analytics.shared.track("plan_started", ["plan": .string(plan.id)]) }
            await model.completeStep(plan.id, step.position)
            await Analytics.shared.track("plan_step_read", ["plan": .string(plan.id), "step": .number(Double(step.position))])
        }
        dismiss()
        app.openInReader(ref)
    }
}

/// Today's devotional. The passage is Scripture from our Bibles; the devotional and the reflection prompt are ours and
/// labeled as such, with how they were written.
struct DevotionalSheet: View {
    let devotional: Devotional
    let model: HomeModel
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SheetControls(back: { dismiss() }, done: { dismiss() })
                    Text(devotional.title).font(.ui(20, weight: .semibold)).tracking(-0.4)
                    Text("\(devotional.minutes ?? 1) min read" + (devotional.tag.map { " · " + $0 } ?? ""))
                        .font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    Image.illustration("journal").resizable().scaledToFit().frame(width: 90, height: 90).frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 8) {
                        ScriptureText(text: devotional.passage ?? "", reference: devotional.ref, translation: devotional.translation)
                            .font(.serif(20, relativeTo: .title3)).lineSpacing(3)
                        Text("\(devotional.label) · \(BibleStore.offline[devotional.translation] ?? devotional.translation.uppercased())")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.muted(scheme))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 14))
                    ForEach(Array(devotional.body.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph).font(.ui(14)).lineSpacing(7.14).fixedSize(horizontal: false, vertical: true)
                    }
                    if let reflection = devotional.reflection {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("A moment of reflection").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted(scheme))
                            Text(reflection).font(.serif(20, relativeTo: .title3))
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.supporting(scheme)))
                    }
                    Button("Read \(devotional.label) in context") {
                        if let ref = VerseRef(devotional.ref) { dismiss(); app.openInReader(ref) }
                    }
                    .buttonStyle(PlanActionStyle())
                    if let ref = VerseRef(devotional.ref), let passage = BibleStore.shared.text(devotional.translation, ref) {
                        VerseShareButton(text: passage, reference: devotional.label, translation: devotional.translation)
                    }
                    Text(attribution).font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                }
                .foregroundStyle(Theme.text(scheme))
                .padding(Theme.Spacing.gutter)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Theme.canvas(scheme))
        }
        .task {
            await model.markDevotionalRead(devotional.id)
            await Analytics.shared.track("devotional_opened", ["id": .string(devotional.id)])
        }
    }

    /// Devotionals aren't Scripture: say so, and how this one was written.
    private var attribution: String {
        let names = ["Henry": "Matthew Henry", "Clarke": "Adam Clarke", "JFB": "Jamieson, Fausset & Brown"]
        let sources = devotional.sources.map { names[$0] ?? $0 }
        let drawn = sources.isEmpty ? "" : " drawing on \(ListFormatter.localizedString(byJoining: sources))"
        return "Reflection · separate from Scripture.\(drawn.isEmpty ? "" : " Commentary" + drawn + ".")"
    }
}

/// The supplied vertical illustrated plan catalogue. Browsing remains free.
struct PlansListSheet: View {
    let model: HomeModel
    let onOpen: (ReadingPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                Button { dismiss() } label: { Image(systemName: "arrow.left").frame(width: 24, height: 44) }
                Text("Reading Plans").font(.serif(28)).tracking(-0.5)
                Spacer()
                Button("Done") { dismiss() }.font(.ui(12, weight: .medium))
            }.buttonStyle(.plain).padding(.horizontal, 22).padding(.top, 12)
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        Image.illustration("journal").resizable().scaledToFit().frame(width: 90, height: 90)
                        Text("A place to begin.").font(.serif(28)).tracking(-0.5)
                        Text("Read at your own pace, one passage at a time.").font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                    }.multilineTextAlignment(.center).padding(.top, 30).padding(.bottom, 24)
                    ForEach(model.plans?.plans ?? []) { plan in card(plan) }
                }.padding(22)
            }
        }
        .foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme))
        .task { await Analytics.shared.track("plans_viewed") }
    }

    private func card(_ plan: ReadingPlan) -> some View {
        let art = plan.id == "quiet" ? "sunrise" : plan.id == "peace" ? "dove" : "anchor"
        return Button { onOpen(plan) } label: {
            HStack(spacing: 18) {
                Image.illustration(art).resizable().scaledToFit().frame(width: 90, height: 100).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 14) {
                    Text(plan.title).font(.serif(24)).tracking(-0.4)
                    Text("\(plan.days) passages · about 2 min each").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    Text(plan.description).font(.ui(12)).lineSpacing(3)
                    Text("Explore plan →").font(.ui(12, weight: .medium)).padding(.top, 4)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .multilineTextAlignment(.leading).padding(20).frame(maxWidth: .infinity, minHeight: 175)
            .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border(scheme).opacity(scheme == .dark ? 0 : 1), lineWidth: 0.5))
        }.buttonStyle(.plain)
    }
}

private struct PlanActionStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.ui(14, weight: .medium))
            .foregroundStyle(scheme == .dark ? Color.black : Color.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(scheme == .dark ? Color(hex: 0xF5F5F5) : Color(hex: 0x111111), in: RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
