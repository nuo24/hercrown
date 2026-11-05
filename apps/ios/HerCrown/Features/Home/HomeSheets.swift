import SwiftUI

/// streak.detail: "Your reading rhythm": the streak card, her progress, and how streaks count.
struct StreakSheet: View {
    let model: HomeModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 10) {
                        StreakFlame()
                            .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                            .foregroundStyle(Theme.streak(scheme))
                            .frame(width: 34, height: 34)
                            .scaleEffect(x: flicker ? 0.95 : 1, y: flicker ? 1.10 : 1, anchor: .bottom)
                            .rotationEffect(.degrees(flicker ? -5 : 3), anchor: .bottom)
                            .frame(width: 62, height: 62)
                            .background(Theme.streak(scheme).opacity(0.09), in: Circle())
                            .accessibilityHidden(true)
                            .task(id: reduceMotion) {
                                if reduceMotion {
                                    flicker = false
                                } else {
                                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                        flicker = true
                                    }
                                }
                            }
                        Text("Your reading rhythm").font(.serif(32, relativeTo: .largeTitle))
                        Text("Build a Bible habit, one day at a time.")
                            .font(.subheadline).foregroundStyle(Theme.muted(scheme))
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    if let m = model.streak.milestone {
                        HStack(spacing: 12) {
                            Image.illustration("milestone").resizable().scaledToFit().frame(width: 56, height: 56).accessibilityHidden(true)
                            Text("\(m) days in a row. What a faithful rhythm.").font(.serif(19))
                        }
                    }
                    StreakCard(streak: model.streak, inDetail: true) { Task { await model.markTodayRead(ref: model.verse?.ref ?? "PSA.23.1"); await model.loadProgress() } }
                    if let p = model.progress { progress(p) } else { ProgressView().frame(maxWidth: .infinity) }
                    Text("One completed reading day counts once. Read on consecutive days to grow your streak. Missing a full day starts a new run; your personal best stays.")
                        .font(.footnote).lineSpacing(4).foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(Theme.Spacing.gutter)
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .task {
            await model.loadProgress()
            await Analytics.shared.track("streak_viewed", ["current": .number(Double(model.streak.current))])
        }
    }

    private func progress(_ p: ReadingProgress) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Through the Bible").font(.serif(25, relativeTo: .title2))
                        Text("\(p.bible.chaptersRead.formatted()) of \(p.bible.totalChapters.formatted()) chapters")
                            .font(.subheadline).foregroundStyle(.secondary)
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
                Text("Your reading journal").font(.serif(26, relativeTo: .title2))
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
                        VStack(spacing: 16) {
                            Text("A gentle reading plan").font(.system(size: 11)).foregroundStyle(Theme.muted(scheme))
                            Text(plan.title).font(.serif(32, relativeTo: .largeTitle))
                            Text(plan.description).font(.system(size: 14)).lineSpacing(7.14)
                        }
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        VStack(spacing: 0) { ForEach(plan.steps) { step in stepRow(plan, step) } }
                        Text("\(plan.days) passages · Read at your own pace")
                            .font(.system(size: 11)).foregroundStyle(Theme.muted(scheme))
                            .frame(maxWidth: .infinity)
                        primaryButton(plan)
                    }
                    .padding(Theme.Spacing.gutter)
                }
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
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
                    Text(ref.flatMap { BibleStore.shared.text(translation, $0) } ?? "").font(.serif(18)).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: locked ? "lock" : "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder private func primaryButton(_ plan: ReadingPlan) -> some View {
        if locked {
            Button("Start with Plus") { app.presentPaywall(placement: "plan_start") }.buttonStyle(CapsuleButtonStyle()).padding(.top, 8)
            Text("Reading plans are part of Her Crown Plus. Reading the Bible stays free.")
                .font(.system(size: 13)).foregroundStyle(Theme.muted(scheme)).frame(maxWidth: .infinity).multilineTextAlignment(.center)
        } else if plan.progress?.completedAt == nil {
            let next = plan.steps.first { $0.completedAt == nil } ?? plan.steps[0]
            Button(plan.progress == nil ? "Start this plan" : "Continue with passage \(next.position + 1)") { read(plan, next) }
                .buttonStyle(CapsuleButtonStyle()).padding(.top, 8)
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
                    HStack {
                        if let tag = devotional.tag { Text(tag.uppercased()).font(.system(size: 12, weight: .semibold)).tracking(1) }
                        Spacer()
                        Text("\(devotional.minutes ?? 1) min read").font(.system(size: 12))
                    }
                    .foregroundStyle(Theme.muted(scheme))
                    Text(devotional.title).font(.serif(32, relativeTo: .largeTitle))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("“\(devotional.passage ?? "")”")
                            .font(.serif(28, relativeTo: .title2)).lineSpacing(4.2)
                        Text("\(devotional.label) · \(BibleStore.offline[devotional.translation] ?? devotional.translation.uppercased())")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.muted(scheme))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 14))
                    ForEach(Array(devotional.body.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph).font(.system(size: 14)).lineSpacing(7.14)
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
                    .buttonStyle(CapsuleButtonStyle(kind: .secondary))
                    Text(attribution).font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                }
                .foregroundStyle(Theme.text(scheme))
                .padding(Theme.Spacing.gutter)
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
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
        return devotional.origin == "ai-draft-reviewed"
            ? "Devotional written with AI assistance\(drawn), and reviewed by our team. Only the quoted passage is Scripture."
            : "Devotional written by Her Crown\(drawn). Only the quoted passage is Scripture."
    }
}

/// plans.list: "Recommended for you" and "Topics & seasons", horizontally scrolling plan cards (237×340, 14 radius,
/// 160 pt tinted cover with a 150 pt cutout).
struct PlansListSheet: View {
    let model: HomeModel
    let onOpen: (ReadingPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private var plans: [ReadingPlan] { model.plans?.plans ?? [] }

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradient()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        section("Recommended for you", "Choose a place to begin. Read at your own pace.", plans.filter { $0.topic == nil || $0.id == "strength" }, top: 18)
                        section("Topics & seasons", "Thoughtful readings for what’s on your heart.", plans.filter { !($0.topic == nil || $0.id == "strength") }, top: 28)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Reading Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .task { await Analytics.shared.track("plans_viewed") }
    }

    @ViewBuilder private func section(_ title: String, _ subtitle: String, _ items: [ReadingPlan], top: CGFloat) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.serif(28, relativeTo: .title)).tracking(-0.4)
                Text(subtitle).font(.system(size: 13)).frame(minHeight: 19.5).foregroundStyle(Theme.muted(scheme))
            }
            .foregroundStyle(Theme.text(scheme))
            .padding(EdgeInsets(top: top + 8, leading: 20, bottom: 12, trailing: 20))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) { ForEach(items) { card($0) } }
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16))
            }
        }
    }

    private func card(_ plan: ReadingPlan) -> some View {
        let dark = scheme == .dark
        let cover: Color = switch plan.tone {
        case "sand": dark ? Color(hex: 0x302C27) : Color(hex: 0xF2EEE7)
        case "lavender": dark ? Color(hex: 0x232D33) : Color(hex: 0xE8F1F3)
        default: dark ? Color(hex: 0x242B29) : Color(hex: 0xEDF2E9)
        }
        let art = plan.id == "quiet" ? "sunrise" : plan.id == "peace" ? "dove" : "anchor"
        return Button { onOpen(plan) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Image.illustration(art).resizable().scaledToFit().frame(width: 150, height: 150)
                    .frame(maxWidth: .infinity, minHeight: 160).background(cover).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 9) {
                    Text(plan.title).font(.system(size: 17, weight: .semibold)).tracking(-0.3)
                    Text("\(plan.days) passages · about 2 min each").font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                    Text(plan.description).font(.system(size: 13)).lineSpacing(4.03).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text(plan.progress == nil ? "Explore plan →" : "Continue reading →").font(.system(size: 12, weight: .medium))
                }
                .multilineTextAlignment(.leading)
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            }
            .foregroundStyle(Theme.text(scheme))
            .frame(width: 237, height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .surfaceCard(radius: 14)
        }
        .buttonStyle(.plain)
    }
}
