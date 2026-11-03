import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var library: ScriptureLibrary
    @State private var selection = 2
    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { CommunityView() }.tabItem { Label("Community", systemImage: "person.2") }.tag(0)
            NavigationStack { DiscoverView() }.tabItem { Label("Discover", systemImage: "safari") }.tag(1)
            NavigationStack { HomeView() }.tabItem { Label("Home", systemImage: "house") }.tag(2)
            NavigationStack { ReaderView() }.tabItem { Label("The Bible", systemImage: "book") }.tag(3)
        }
        .modifier(SystemGlassTabBar())
        .overlay {
            if let error = library.loadError {
                ContentUnavailableView("Scripture unavailable", systemImage: "book.closed", description: Text(error))
                    .background(Color(uiColor: .systemBackground))
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var library: ScriptureLibrary
    @State private var selected: Passage?
    @State private var showStudy: Passage?
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? "Good morning!" : hour < 18 ? "Good afternoon!" : "Good evening!"
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let daily = library.passages.first {
                    SkyStage { PassagePanel(passage: daily, showReflection: false) }
                }
                Panel {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass").font(.body).frame(width: 38, height: 38)
                                .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                            Text("Verse Search").font(.title2)
                        }
                        Text("Choose a passage to read and reflect on.").font(.subheadline).foregroundStyle(.secondary)
                        Picker("Passage", selection: $selected) {
                            Text("Choose a passage").tag(nil as Passage?)
                            ForEach(library.passages.prefix(9)) { p in Text(p.ref).tag(Optional(p)) }
                        }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                        Button("Study this verse") { showStudy = selected ?? library.passages.first }.buttonStyle(PillButton())
                    }
                }
                NavigationLink { PlansView() } label: {
                    Panel {
                        HStack(spacing: 16) {
                            Image(systemName: "book.closed").font(.title).frame(width: 52, height: 72)
                                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Today’s Reading").font(.title3)
                                Text(library.selectedPlan.isEmpty ? "Choose your plan" : library.selectedPlan).font(.subheadline)
                                Text("Read at your own pace").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }.buttonStyle(.plain)
                Panel {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today’s devotional").font(.caption).foregroundStyle(.secondary)
                        (Text("Make room\nfor ").font(BibleStyle.editorial(30)) + Text("the Word.").font(BibleStyle.editorial(30, italic: true)))
                        Text("Read slowly, reflect, and carry a passage with you today.").font(.body).foregroundStyle(.secondary)
                        Button("Begin with Psalm 23") { showStudy = library.passages.first }.frame(minHeight: 44)
                    }
                }
                Text("King James Version · Sample reading library").font(.caption).foregroundStyle(.secondary)
            }.padding(.horizontal, BibleStyle.gutter).padding(.vertical, 16)
        }.background(Color(uiColor: .systemGroupedBackground)).navigationTitle(greeting).navigationBarTitleDisplayMode(.inline)
            .toolbar { BibleToolbar() }
            .sheet(item: $showStudy) { StudyView(passage: $0) }
    }
}

struct BibleToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            NavigationLink { SavedView() } label: { Image(systemName: "bookmark") }.accessibilityLabel("Saved passages")
            NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
        }
    }
}

struct PassagePanel: View {
    @EnvironmentObject private var library: ScriptureLibrary
    let passage: Passage
    var showReflection = true
    @State private var study = false
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(showReflection ? passage.topic : "Verse of the day").font(.caption).foregroundStyle(.secondary)
                        Text(passage.ref).font(.subheadline)
                    }
                    Spacer()
                    Text("KJV").font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                }
                Text(passage.text).font(BibleStyle.editorial(30)).tracking(-0.35).lineSpacing(3).textSelection(.enabled)
                if showReflection {
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("A moment of reflection").font(.caption).foregroundStyle(.secondary)
                        Text(passage.reflection).font(.body)
                        Text("Reflection prompt · not Scripture").font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Read & reflect") { study = true }.buttonStyle(PillButton())
                }
                HStack {
                    Button { library.toggle(passage) } label: {
                        Label(library.saved.contains(passage.id) ? "Saved" : "Save", systemImage: library.saved.contains(passage.id) ? "heart.fill" : "heart")
                    }.accessibilityLabel("\(library.saved.contains(passage.id) ? "Unsave" : "Save") \(passage.ref)")
                    Spacer()
                    Button { study = true } label: { Label("Reflect", systemImage: "bubble") }
                    Spacer()
                    ShareLink(item: "\(passage.text)\n\(passage.ref) — King James Version") { Label("Share", systemImage: "square.and.arrow.up") }
                }.labelStyle(.iconOnly).font(.title3).buttonStyle(.plain).frame(minHeight: 44)
            }
        }.sheet(isPresented: $study) { StudyView(passage: passage) }
    }
}

struct DiscoverView: View {
    @EnvironmentObject private var library: ScriptureLibrary
    @State private var topic = "For you"
    private var topics: [String] { ["For you"] + Array(Set(library.passages.prefix(9).map(\.topic))).sorted() }
    private var results: [Passage] { Array(library.passages.prefix(9)).filter { topic == "For you" || $0.topic == topic } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Find Scripture for the season you’re in.").foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(topics, id: \.self) { item in
                            Button { topic = item } label: {
                                Text(item).font(.subheadline).padding(.horizontal, 16).frame(minHeight: 44)
                                    .background(topic == item ? Color.primary : Color(uiColor: .secondarySystemBackground), in: Capsule())
                                    .foregroundStyle(topic == item ? Color(uiColor: .systemBackground) : .primary)
                            }.buttonStyle(.plain).accessibilityAddTraits(topic == item ? .isSelected : [])
                        }
                    }
                }.scrollIndicators(.hidden)
                LazyVStack(spacing: 16) { ForEach(results) { PassagePanel(passage: $0) } }
            }.padding(20)
        }.navigationTitle("Discover").navigationBarTitleDisplayMode(.inline).toolbar { BibleToolbar() }
    }
}

struct SavedView: View {
    @EnvironmentObject private var library: ScriptureLibrary
    private var passages: [Passage] { library.passages.filter { library.saved.contains($0.id) } }
    var body: some View {
        Group {
            if passages.isEmpty {
                ContentUnavailableView("Words to keep close", systemImage: "heart", description: Text("Save a passage while reading. It will appear here."))
            } else {
                ScrollView { LazyVStack(spacing: 16) { ForEach(passages) { PassagePanel(passage: $0) } }.padding(20) }
            }
        }.navigationTitle("Saved passages").navigationBarTitleDisplayMode(.inline)
    }
}

struct StudyView: View {
    @Environment(\.dismiss) private var dismiss
    let passage: Passage
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("King James Version").font(.caption).foregroundStyle(.secondary)
                    Text(passage.text).font(BibleStyle.editorial(30)).textSelection(.enabled)
                    Divider()
                    Text("Pause & reflect").font(.headline)
                    Text(passage.reflection)
                    Text("This reflection is a prompt for your quiet time, not a translation or interpretation of Scripture.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(20)
            }.navigationTitle(passage.ref).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
    }
}

struct ReaderView: View {
    @EnvironmentObject private var library: ScriptureLibrary
    @State private var chapter = "Genesis 1"
    @State private var index: Int? = 0
    @State private var railVisible = false
    @State private var hideRailTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var passages: [Passage] { library.passages.filter { $0.ref.hasPrefix(chapter + ":") }.sorted { (Int($0.ref.split(separator: ":").last ?? "0") ?? 0) < (Int($1.ref.split(separator: ":").last ?? "0") ?? 0) } }
    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(passages.enumerated()), id: \.element.id) { offset, p in
                            VStack(spacing: 28) {
                                Spacer(minLength: 24)
                                Text(p.text).font(BibleStyle.editorial(30)).multilineTextAlignment(.center).textSelection(.enabled)
                                Text(p.ref).font(.subheadline).foregroundStyle(.secondary)
                                HStack(spacing: 32) {
                                    Button { library.toggle(p) } label: { Image(systemName: library.saved.contains(p.id) ? "heart.fill" : "heart") }.accessibilityLabel("Save \(p.ref)").frame(minWidth: 44, minHeight: 44)
                                    ShareLink(item: "\(p.text)\n\(p.ref) — KJV") { Image(systemName: "square.and.arrow.up") }.frame(minWidth: 44, minHeight: 44)
                                }.font(.title3)
                                Spacer(minLength: 24)
                                Text(offset == passages.count - 1 ? "End of chapter" : "Scroll up or down to read")
                                    .font(.caption).foregroundStyle(.secondary).padding(.bottom, 24)
                            }.padding(.horizontal, 44).frame(width: geometry.size.width).frame(minHeight: geometry.size.height).id(offset)
                        }
                    }.scrollTargetLayout()
                }.scrollTargetBehavior(.viewAligned(limitBehavior: .never)).scrollPosition(id: $index, anchor: .top).scrollIndicators(.hidden)
                .simultaneousGesture(DragGesture(minimumDistance: 2).onChanged { _ in revealRail() })
            }
            NativeVerseRail(count: passages.count, index: $index)
                .opacity(railVisible ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.24), value: railVisible)
                .accessibilityHidden(false)
        }.background(Color(uiColor: .systemBackground))
            .navigationTitle(chapter).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu { Picker("Chapter", selection: $chapter) { Text("Genesis 1").tag("Genesis 1"); Text("Psalm 23").tag("Psalm 23") } }
                    label: { Image(systemName: "list.bullet") }.accessibilityLabel("Select a chapter")
                }
            }.onChange(of: chapter) { _, _ in index = 0 }
            .onChange(of: index) { _, _ in revealRail() }
            .onDisappear { hideRailTask?.cancel() }
    }
    private func revealRail() {
        railVisible = true
        hideRailTask?.cancel()
        hideRailTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            railVisible = false
        }
    }
}

struct NativeVerseRail: View {
    let count: Int
    @Binding var index: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var magnifiedIndex: CGFloat?
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 8) {
                VStack(spacing: 5) {
                    ForEach(0..<max(count, 1), id: \.self) { verse in
                        HStack(alignment: .top, spacing: 5) {
                            Capsule().fill(verse == (index ?? 0) ? Color.primary : Color.primary.opacity(0.15)).frame(width: 4)
                                .scaleEffect(x: magnification(verse), y: 1 + (magnification(verse) - 1) * 0.16, anchor: .leading)
                                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: magnifiedIndex ?? CGFloat(index ?? 0))
                            Text(verse == (index ?? 0) ? "\(verse + 1)" : "").font(.caption2).monospacedDigit().frame(width: 17, alignment: .leading)
                        }.frame(maxHeight: .infinity)
                    }
                }
                Text("\(count)").font(.caption2).foregroundStyle(.secondary).monospacedDigit()
            }.padding(.vertical, 24).padding(.leading, 10).padding(.trailing, 6)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let height = max(1, proxy.size.height - 68)
                    magnifiedIndex = min(CGFloat(max(0, count - 1)), max(0, (value.location.y - 24) / height * CGFloat(count) - 0.5))
                    index = min(max(0, count - 1), max(0, Int((value.location.y - 24) / height * CGFloat(count))))
                }.onEnded { _ in magnifiedIndex = nil })
        }.frame(width: 44)
            .accessibilityElement(children: .ignore).accessibilityLabel("Verse navigation")
            .accessibilityValue("Verse \((index ?? 0) + 1) of \(count)")
            .accessibilityAdjustableAction { direction in
                if direction == .increment { index = min(max(0, count - 1), (index ?? 0) + 1) }
                else if direction == .decrement { index = max(0, (index ?? 0) - 1) }
            }
    }
    private func magnification(_ verse: Int) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let distance = (CGFloat(verse) - (magnifiedIndex ?? CGFloat(index ?? 0))) / 1.1
        return 1 + 0.8 * exp(-0.5 * distance * distance)
    }

}

struct PlansView: View {
    @EnvironmentObject private var library: ScriptureLibrary
    var body: some View {
        List {
            ForEach(["A quiet beginning", "Peace for anxious hearts", "Rooted in strength"], id: \.self) { title in
                Button { library.choosePlan(title) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title).foregroundStyle(.primary)
                            Text("Read at your own pace").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 8)
                        Spacer()
                        if library.selectedPlan == title { Image(systemName: "checkmark").accessibilityLabel("Selected") }
                    }
                }
            }
            Section { Text("Sample reading plans. The complete Bible is not bundled.").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("Reading plans")
    }
}

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("routine") private var routine = "5 minutes"
    var body: some View {
        Form {
            Section("Appearance") { Picker("Theme", selection: $appearance) { Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") } }
            Section("Daily reading intention") { Picker("Pace", selection: $routine) { ForEach(["2 minutes", "5 minutes", "10 minutes", "No time goal"], id: \.self) { Text($0) } } }
            Section { Text("All passages: King James Version. Saved passages and preferences stay on this device. No account is connected.").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("Settings")
    }
}

struct CommunityView: View {
    var body: some View {
        ContentUnavailableView("Community", systemImage: "person.2", description: Text("Community features are not available in this sample. Explore Scripture in Discover."))
            .navigationTitle("Community")
    }
}


/// Image and fades frame a floating UI panel; Scripture always stays on an opaque surface.
struct SkyStage<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(.horizontal, 18).padding(.top, 20).padding(.bottom, 24)
            .background {
                GeometryReader { proxy in
                    ZStack {
                        Color(red: 0.71, green: 0.86, blue: 0.94)
                        if let path = Bundle.main.path(forResource: "quiet-sky", ofType: "png"), let image = UIImage(contentsOfFile: path) {
                            Image(uiImage: image).resizable().scaledToFill().frame(width: proxy.size.width, height: proxy.size.height).clipped()
                        }
                        LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.02), Color.white.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                        if scheme == .dark { Color.black.opacity(0.55) }
                    }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}


/// Keep native tab semantics: the iOS 26 SDK supplies the floating Liquid Glass material.
struct SystemGlassTabBar: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}
