import SwiftUI
import UIKit

/// Sprite cells are cropped in memory; the supplied full-resolution originals remain intact.
@MainActor enum MedalArtwork {
    private static var images: [String: UIImage] = [:]
    static func image(_ medal: FaithMedal) -> UIImage? {
        if let image = images[medal.id] { return image }
        guard let original = UIImage(named: medal.artwork) else { return nil }
        guard let cell = medal.spriteCell, let source = original.cgImage else { images[medal.id] = original; return original }
        let w = source.width / 3, h = source.height / cell.rows
        guard let cropped = source.cropping(to: CGRect(x: cell.column * w, y: cell.row * h, width: w, height: h)) else { return nil }
        let image = UIImage(cgImage: cropped, scale: original.scale, orientation: original.imageOrientation)
        images[medal.id] = image
        return image
    }
}

struct MedalImage: View {
    let medal: FaithMedal
    var locked = false
    var body: some View {
        Group {
            if let image = MedalArtwork.image(medal) {
                Image(uiImage: image).resizable().scaledToFit()
            }
        }
        .saturation(locked ? 0 : 1).opacity(locked ? 0.5 : 1)
        .accessibilityHidden(true)
    }
}

struct FaithMedalsView: View {
    let model: FaithMedalsModel
    let onBack: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var group: FaithMedal.Collection = .fruit
    @State private var selection: String?
    @State private var shareFile: URL?
    @State private var sharing = false
    private var items: [FaithMedal] { FaithMedal.items(group) }
    private var selected: FaithMedal { items.first { $0.id == selection } ?? items[0] }
    private var progress: MedalProgress { model.progress ?? .empty }
    private func state(_ medal: FaithMedal) -> String {
        guard model.progress != nil else { return "Not synced" }
        return medal.earned(progress) ? "Collected" : medal.fraction(progress) > 0 ? "In progress" : "Locked"
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: onBack) { Image(systemName: "arrow.left").frame(width: 44, height: 44) }.accessibilityLabel("Back to Home")
                Text("Your Faith Medals").font(.serif(30)).tracking(-0.65).frame(maxWidth: .infinity, alignment: .leading)
                if selected.earned(progress) {
                    Button(action: share) { Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44) }.accessibilityLabel("Share \(selected.name)")
                }
            }.padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)
            ScrollView {
                VStack(spacing: 0) {
                    Text(selected.name).font(.serif(36)).tracking(-0.5).multilineTextAlignment(.center).padding(.top, 18)
                    Text(group.reference).font(.ui(11)).foregroundStyle(Theme.muted(scheme)).padding(.top, 7)
                    Text("\(selected.rarity) milestone").font(.ui(11, weight: .medium))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .overlay(Capsule().stroke(Theme.border(scheme))).padding(.top, 12)
                    carousel
                    Text(state(selected)).font(.ui(13, weight: .medium))
                    Text(selected.requirement).font(.ui(13)).lineSpacing(4).multilineTextAlignment(.center)
                        .foregroundStyle(Theme.muted(scheme)).frame(maxWidth: 285).padding(.top, 9)
                    if model.progress != nil {
                        ProgressView(value: selected.fraction(progress)).tint(Theme.text(scheme)).frame(width: 160).padding(.top, 16)
                        let counts = selected.counts(progress)
                        Text("\(counts.days) of \(selected.days) days · \(counts.chapters) of \(selected.chapters) chapters")
                            .font(.ui(11)).foregroundStyle(Theme.muted(scheme)).padding(.top, 7)
                    }
                    if model.unavailable {
                        Text(model.progress == nil ? "Connect to load your reading progress." : "Showing your last synced progress.")
                            .font(.ui(12)).foregroundStyle(Theme.muted(scheme)).padding(.top, 12)
                        Button("Try again") { Task { await model.load(app: app) } }.frame(minHeight: 44)
                    }
                    collection.padding(.top, 30)
                }.padding(.bottom, 115)
            }
        }
        .foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme)).buttonStyle(.plain)
        .task {
            selection = model.homeMedal.id
            await Analytics.shared.track("faith_medals_viewed")
            await model.load(app: app)
        }
        .onChange(of: app.me?.user.id) { _, _ in Task { await model.load(app: app) } }
        .sheet(isPresented: $sharing) { if let shareFile { MedalShareSheet(file: shareFile) } }
    }
    private var carousel: some View {
        GeometryReader { geometry in
            let width = min(228.0, geometry.size.width * 0.60)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(items) { medal in
                        MedalImage(medal: medal, locked: !medal.earned(progress))
                            .frame(width: width, height: 250).id(medal.id)
                            .accessibilityElement().accessibilityLabel("\(medal.name), \(state(medal))")
                    }
                }.scrollTargetLayout()
            }
            .contentMargins(.horizontal, (geometry.size.width - width) / 2, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned).scrollPosition(id: $selection, anchor: .center)
            .scrollIndicators(.hidden)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.25), trigger: selection) { old, new in old != nil && new != nil }
            .onChange(of: selection) { old, new in
                if old != nil, let new { Task { await Analytics.shared.track("faith_medal_selected", ["medal": .string(new)]) } }
            }
        }.frame(height: 265).padding(.top, 5)
    }
    private var collection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().padding(.bottom, 21)
            HStack {
                Text("Your collection").font(.serif(26))
                Spacer()
                Text("\(items.filter { $0.earned(progress) }.count) of \(items.count) collected").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
            }
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(FaithMedal.Collection.allCases) { category in
                        Button {
                            group = category; selection = FaithMedal.items(category)[0].id
                            Task { await Analytics.shared.track("faith_medal_collection_viewed", ["collection": .string(category.rawValue)]) }
                        } label: {
                            Text(category.title).font(.ui(11, weight: .medium)).frame(minHeight: 44)
                                .foregroundStyle(category == group ? Theme.text(scheme) : Theme.muted(scheme))
                                .overlay(alignment: .bottom) { if category == group { Rectangle().frame(height: 1) } }
                        }.accessibilityAddTraits(category == group ? .isSelected : [])
                    }
                }
            }.scrollIndicators(.hidden).padding(.top, 16)
            Divider().padding(.bottom, 14)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(items) { medal in
                    Button { selection = medal.id } label: {
                        VStack(spacing: 3) {
                            MedalImage(medal: medal, locked: !medal.earned(progress)).frame(height: 80)
                            Text(medal.name).font(.ui(11, weight: .medium))
                            Text(state(medal)).font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                        }
                        .multilineTextAlignment(.center).padding(8).frame(maxWidth: .infinity, minHeight: 134)
                        .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(medal.id == selected.id ? Theme.text(scheme) : Theme.border(scheme)))
                    }.accessibilityAddTraits(medal.id == selected.id ? .isSelected : [])
                }
            }
            Text("Reading milestones celebrate time in the Word; they don’t measure your faith or character. Rarity describes the goal’s difficulty.")
                .font(.ui(10)).foregroundStyle(Theme.muted(scheme)).padding(.top, 20)
        }.padding(.horizontal, 22)
    }
    @MainActor private func share() {
        guard selected.earned(progress) else { return }
        let renderer = ImageRenderer(content: MedalShareCard(medal: selected, date: .now, scheme: scheme))
        renderer.scale = 3
        guard let data = renderer.uiImage?.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("her-crown-medal-\(selected.id).png")
        do { try data.write(to: url, options: .atomic) } catch { return }
        shareFile = url; sharing = true
        Task { await Analytics.shared.track("faith_medal_shared", ["medal": .string(selected.id)]) }
    }
}

private struct MedalShareCard: View {
    let medal: FaithMedal
    let date: Date
    let scheme: ColorScheme
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image("her-crown-thorns").resizable().scaledToFit().frame(width: 24, height: 24)
                Text("Her Crown").font(.serif(16))
                Spacer()
                Text(date.formatted(date: .long, time: .omitted)).font(.ui(8)).foregroundStyle(Theme.muted(scheme))
            }
            MedalImage(medal: medal).frame(maxWidth: .infinity).frame(height: 260)
            Text(medal.name).font(.serif(23)).padding(.top, 12)
            Text(medal.requirement).font(.ui(10)).multilineTextAlignment(.center).foregroundStyle(Theme.muted(scheme)).padding(.top, 8)
        }
        .padding(22).frame(width: 400, height: 400).foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme))
    }
}

private struct MedalShareSheet: UIViewControllerRepresentable {
    let file: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [file], applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
