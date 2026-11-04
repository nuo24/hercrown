import SwiftUI

/// streak.detail: "Your reading rhythm": the streak card, her progress, and how streaks count.
struct StreakSheet: View {
    let model: HomeModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your reading rhythm").font(.serif(32, relativeTo: .largeTitle)).frame(maxWidth: .infinity)
                    if let m = model.streak.milestone {
                        HStack(spacing: 12) {
                            Image("milestone").resizable().scaledToFit().frame(width: 56, height: 56).accessibilityHidden(true)
                            Text("\(m) days in a row. What a faithful rhythm.").font(.serif(19))
                        }
                    }
                    StreakCard(streak: model.streak) { Task { await model.markTodayRead(ref: model.verse?.ref ?? "PSA.23.1"); await model.loadProgress() } }
                    if let p = model.progress { progress(p) } else { ProgressView().frame(maxWidth: .infinity) }
                    Text("One completed reading day counts once. Read on consecutive days to grow your streak. Missing a full day starts a new run; your personal best stays.")
                        .font(.system(size: 15)).multilineTextAlignment(.center).foregroundStyle(Theme.muted(scheme))
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
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Through the Bible").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("\(p.bible.chaptersRead) of \(p.bible.totalChapters) chapters").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                }
                ProgressView(value: Double(p.bible.chaptersRead), total: Double(max(p.bible.totalChapters, 1))).tint(Color(hex: 0xD9A35B))
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                stat("\(p.daysRead.total)", p.daysRead.total == 1 ? "day read" : "days read")
                stat("\(p.daysThisYear)", p.daysThisYear == 1 ? "day this year" : "days this year")
                stat("\(p.weeksInARow)", p.weeksInARow == 1 ? "week in a row" : "weeks in a row")
                stat("\(p.devotionalsRead)", p.devotionalsRead == 1 ? "devotional read" : "devotionals read")
                stat("\(p.daysOpened.total)", p.daysOpened.total == 1 ? "day opened" : "days opened")
                stat("\(p.versesStudied)", p.versesStudied == 1 ? "verse studied" : "verses studied")
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 24, weight: .semibold))
            Text(label).font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.supporting(scheme)))
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
                        Image("journal").resizable().scaledToFit().frame(width: 70, height: 80).accessibilityHidden(true)
                        Text(plan.title).font(.serif(32, relativeTo: .largeTitle))
                        Text(plan.description).font(.system(size: 16)).foregroundStyle(Theme.muted(scheme))
                        Text("\(plan.days) passages · Read at your own pace").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.muted(scheme))
                        VStack(spacing: 0) { ForEach(plan.steps) { step in stepRow(plan, step) } }
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
                    Text(devotional.title).font(.serif(34, relativeTo: .largeTitle))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("“\(devotional.passage ?? "")”").font(.serif(21, italic: true, relativeTo: .title3))
                        Text("\(devotional.label) · \(BibleStore.offline[devotional.translation] ?? devotional.translation.uppercased())")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.muted(scheme))
                    }
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) { Rectangle().fill(Color(hex: 0xD9A35B)).frame(width: 2) }
                    ForEach(Array(devotional.body.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph).font(.system(size: 17)).lineSpacing(5)
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
