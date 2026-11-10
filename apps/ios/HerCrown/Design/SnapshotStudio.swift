import SwiftUI
import PhotosUI
import Photos

struct SnapshotArt: Codable, Identifiable, Equatable {
    var id = UUID()
    var asset: String
    var x = 0.5
    var y = 0.2
    var size = 0.19
    var rotation = 0.0
}
enum SnapshotDraftStore {
    static func remove(_ userID: String?) {
        let id = userID ?? "local"
        UserDefaults.standard.removeObject(forKey: "hc.snapshotStudio.\(id)")
        UserDefaults.standard.removeObject(forKey: "hc.widgetStudio.\(id)")
        let widgetPhoto = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("widget-\(id).jpg")
        try? FileManager.default.removeItem(at: widgetPhoto)
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("snapshot-\(id).jpg")
        try? FileManager.default.removeItem(at: url)
    }
}
struct SnapshotDesign: Codable, Equatable {
    var format = "Portrait"
    var colors = ["FFFFFF", "DDEADA", "DCECF5"]
    var third = true
    var intensity = 70.0
    var angle = 155.0
    var ink = "111111"
    var font = "Baskerville"
    var fontSize = 32.0
    var alignment = "Center"
    var watermark = true
    var photoShade = 18.0
    var photoFocus = 50.0
    var caption: String? = nil
    var art = [SnapshotArt(asset: "cosmos")]
    var height: CGFloat { format == "Widget Medium" ? 286 : format == "Widget Large" ? 630 : format == "Widget Small" || format == "Square" ? 600 : format == "Story" ? 1066.6667 : 800 }
    var exportSize: String { format == "Square" ? "1080 × 1080" : format == "Story" ? "1080 × 1920" : "1080 × 1440" }
    var textAlignment: TextAlignment { alignment == "Left" ? .leading : alignment == "Right" ? .trailing : .center }
    static let assets = ["cosmos", "olive", "dove", "butterfly", "faith-hands", "open-book", "journal", "reflection-quill", "prayer-envelope", "faith-key", "hope-nest", "quiet-window", "growth-vase", "devotional-teacup", "wisdom-scroll", "grace-shell", "anchor", "bookmark", "community", "gratitude-basket", "gratitude-bowl", "hourglass", "intention-heart", "lantern", "magnifier", "milestone", "purpose-compass", "reflection", "relationship-hands", "reminder-bell", "rest-stones", "seedling", "sunrise", "wisdom-pearl"]
}

/// Canvas-first editor: Scripture is supplied by BibleStore; only its visual treatment is editable.
struct VerseSnapshotView: View {
    let text: String
    let reference: String
    let translation: String
    var widgetMode = false
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var design = SnapshotDesign()
    @State private var selected: UUID?
    @State private var tab = "Background"
    @State private var expanded = false
    @State private var drawerDragHeight: CGFloat?
    @State private var drawerDragOrigin: CGFloat?
    @FocusState private var captionFocused: Bool
    @State private var studioHeight: CGFloat = 800
    @State private var rendered: UIImage?
    @State private var photo: UIImage?
    @State private var photoSelection: PhotosPickerItem?
    @State private var failure: String?
    @State private var sharing = false
    @State private var widgetSaved = false
    @State private var downloaded = false
    @State private var downloading = false
    @State private var dragOrigin: CGPoint?
    @State private var pinchSize: Double?
    @State private var savedDesign: SnapshotDesign?
    @State private var photoRevision = UUID()
    @State private var savedPhotoRevision = UUID()
    @State private var showingCloseConfirmation = false
    private var hasUnsavedChanges: Bool { savedDesign.map { $0 != design || photoRevision != savedPhotoRevision } ?? false }
    private var ink: Color { Theme.text(scheme) }
    private var translationLabel: String { BibleStore.names.first(where: { $0.value == translation })?.key.uppercased() ?? translation.uppercased() }
    private var watermark: Bool { !widgetMode && design.watermark }
    private var key: String { "hc.\(widgetMode ? "widgetStudio" : "snapshotStudio").\(app.me?.user.id ?? "local")" }
    private var photoURL: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("\(widgetMode ? "widget" : "snapshot")-\(app.me?.user.id ?? "local").jpg") }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { close() } label: { Image(systemName: "chevron.left").frame(width: 36, height: 44) }
                    .accessibilityLabel(widgetMode ? "Close Widget Studio" : "Close Snapshot Studio")
                VStack(alignment: .leading, spacing: 4) {
                    Text(widgetMode ? "Widget Studio" : "Snapshot Studio").font(.serif(26)).lineLimit(1).minimumScaleFactor(0.8)
                    Text("\(reference) · \(translationLabel)").font(.ui(11)).foregroundStyle(Theme.muted(scheme)).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Button("Done") { close() }.font(.ui(14, weight: .medium)).frame(minWidth: 44, minHeight: 44)
            }.padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 14)
            GeometryReader { area in
                let scale = max(0.01, min((area.size.width - 36) / 600, (area.size.height - 44) / design.height))
                VStack(spacing: 8) {
                    Text("Tap an illustration to arrange it.").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    if widgetMode { Spacer(minLength: 0) }
                    ZStack {
                        SnapshotCanvas(text: text, reference: reference, translation: translation, design: design, photo: photo, watermark: watermark)
                        ForEach(design.art) { art in
                            Color.clear.frame(width: max(48 / scale, 600 * art.size), height: max(48 / scale, 600 * art.size))
                                .contentShape(Rectangle()).overlay { if selected == art.id { RoundedRectangle(cornerRadius: 5).stroke(Color(hex: 0x526D82), lineWidth: 2 / scale) } }
                                .position(x: art.x * 600, y: art.y * design.height)
                                .onTapGesture { selected = art.id; tab = "Illustrations" }
                                .gesture(DragGesture(minimumDistance: 3).onChanged { value in
                                    guard let i = design.art.firstIndex(where: { $0.id == art.id }) else { return }
                                    if dragOrigin == nil { dragOrigin = CGPoint(x: design.art[i].x, y: design.art[i].y) }
                                    selected = art.id
                                    design.art[i].x = min(0.93, max(0.07, dragOrigin!.x + value.translation.width / 600))
                                    design.art[i].y = min(0.94, max(0.06, dragOrigin!.y + value.translation.height / design.height))
                                }.onEnded { _ in dragOrigin = nil })
                                .accessibilityLabel("\(art.asset.replacingOccurrences(of: "-", with: " ")) illustration")
                                .accessibilityAddTraits(.isButton)
                        }
                    }.frame(width: 600, height: design.height)
                        .contentShape(Rectangle())
                        // Keep resizing available across the canvas even when the selected cutout is tiny.
                        .simultaneousGesture(MagnifyGesture().onChanged { value in
                            guard let selected, let i = design.art.firstIndex(where: { $0.id == selected }) else { return }
                            if pinchSize == nil { pinchSize = design.art[i].size }
                            design.art[i].size = min(0.8, max(0.05, (pinchSize ?? design.art[i].size) * value.magnification))
                        }.onEnded { _ in pinchSize = nil })
                        .onChange(of: selected) { _, _ in pinchSize = nil }
                        .clipShape(RoundedRectangle(cornerRadius: widgetMode ? 36 : 0)).scaleEffect(max(0.01, scale))
                        .frame(width: 600 * scale, height: design.height * scale).clipped().opacity(area.size.height < 120 ? 0 : 1).shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                    Spacer(minLength: 0)
                }.frame(maxWidth: .infinity).padding(.top, 10)
            }.background(widgetMode ? (scheme == .dark ? Color(hex: 0x131316) : Color(hex: 0xF1F2F2)) : Theme.supporting(scheme))
            tools
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                if captionFocused {
                    HStack { Spacer(); Button("Done typing") { captionFocused = false }.font(.ui(12, weight: .medium)).frame(minHeight: 32) }
                }
                if let failure { Text(failure).font(.ui(12)).foregroundStyle(Theme.muted(scheme)) }
                HStack(spacing: 12) {
                    if !widgetMode {
                        Button { captionFocused = false; Task { await download() } } label: {
                            Image(systemName: downloaded ? "checkmark" : "square.and.arrow.down").frame(width: 52, height: 52)
                                .background(Theme.supporting(scheme), in: Circle())
                        }.accessibilityLabel(downloaded ? "Snapshot saved to Photos" : "Download snapshot").disabled(downloading)
                    }
                    Button { captionFocused = false; if widgetMode { saveWidget() } else { export() } } label: {
                        Label(widgetMode ? (widgetSaved ? "Widget design saved" : "Save widget design") : "Share snapshot", systemImage: widgetMode ? "checkmark" : "square.and.arrow.up").frame(maxWidth: .infinity)
                    }.buttonStyle(CapsuleButtonStyle())
                }
                Text(widgetMode ? "\(design.format.replacingOccurrences(of: "Widget ", with: "")) widget · Your widget verse" : "\(design.exportSize) PNG").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                if widgetMode && widgetSaved { Text("Add Her Crown from your Home Screen’s widget gallery. iOS controls when saved widgets refresh.").font(.ui(10)).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center) }
            }.padding(.horizontal, 18).padding(.vertical, 9).background(Theme.canvas(scheme))
        }
        .foregroundStyle(ink).background(Theme.canvas(scheme)).buttonStyle(.plain).tint(ink)
        .task {
            if let data = UserDefaults.standard.data(forKey: key), let saved = try? JSONDecoder().decode(SnapshotDesign.self, from: data) { design = saved }
            else if widgetMode { design.format = "Widget Medium"; design.art = [SnapshotArt(asset: "olive", x: 0.5, y: 0.18, size: 0.12)] }
            if widgetMode && !design.format.hasPrefix("Widget ") { design.format = "Widget Medium" }
            photo = UIImage(contentsOfFile: photoURL.path)
            savedDesign = design
            savedPhotoRevision = photoRevision
            #if DEBUG
            if let review = UserDefaults.standard.string(forKey: "hcStudioReview"), ["Background", "Text", "Illustrations"].contains(review) { tab = review; expanded = true }
            if UserDefaults.standard.bool(forKey: "hcStudioCaptionFocus") { tab = "Text"; expanded = true; captionFocused = true }
            #endif
            if widgetMode { await Analytics.shared.track("widget_studio_opened") }
            else { await Analytics.shared.track("verse_snapshot_opened") }
        }
        .onChange(of: design) { _, _ in widgetSaved = false; downloaded = false }
        .background(GeometryReader { geometry in Color.clear.onAppear { studioHeight = geometry.size.height }.onChange(of: geometry.size.height) { _, height in studioHeight = height } })
        .onChange(of: photoSelection) { _, item in Task { await loadPhoto(item) } }
        .sheet(isPresented: $sharing) { if let rendered { SnapshotShareSheet(image: rendered) } }
        .toolbar(.hidden, for: .navigationBar)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .disabled(showingCloseConfirmation)
        .accessibilityHidden(showingCloseConfirmation)
        .overlay {
            if showingCloseConfirmation { closeConfirmation.transition(.opacity) }
        }

    }
    private var closeConfirmation: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.48).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("Keep your changes?").font(.serif(28)).accessibilityAddTraits(.isHeader)
                Text("Save this design, or return to the last saved version.")
                    .font(.ui(13)).foregroundStyle(Theme.muted(scheme))
                    .multilineTextAlignment(.center).padding(.bottom, 10)
                Button("Save & Close") {
                    showingCloseConfirmation = false
                    if widgetMode { if saveWidget() { dismiss() } }
                    else if save() { dismiss() }
                }.buttonStyle(CapsuleButtonStyle()).padding(.bottom, 5)
                Button("Discard changes", role: .destructive) { dismiss() }
                    .font(.ui(14)).foregroundStyle(Color(hex: 0xAD4343)).frame(maxWidth: .infinity, minHeight: 48)
                Button("Keep editing") { withAnimation(.easeOut(duration: 0.18)) { showingCloseConfirmation = false } }
                    .font(.ui(14, weight: .medium)).frame(maxWidth: .infinity, minHeight: 48)
            }
            .padding(26).frame(maxWidth: .infinity)
            .background(Theme.canvas(scheme), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(ink).buttonStyle(.plain)
            .padding(.horizontal, 15).padding(.bottom, 15)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("studioUnsavedChanges")
            .accessibilityAddTraits(.isModal)
        }
    }
    private var trayHeight: CGFloat {
        let available = max(96, studioHeight - 180)
        return min(available, captionFocused ? 150 : max(160, min(540, studioHeight * 0.54) - 102))
    }
    private var tools: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Capsule().fill(Theme.muted(scheme).opacity(0.4)).frame(width: 33, height: 4)
                Text(expanded ? "Slide down to arrange" : "Swipe up for tools")
                    .font(.ui(11)).foregroundStyle(Theme.muted(scheme))
            }
            .frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
            // Global coordinates remain fixed as the drawer moves under the finger. A local
            // translation changes its own origin during layout and makes this handle jerk.
            .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                    if drawerDragOrigin == nil { drawerDragOrigin = expanded ? trayHeight : 0 }
                    var transaction = Transaction(); transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        drawerDragHeight = min(trayHeight, max(0, (drawerDragOrigin ?? 0) - value.translation.height))
                    }
                }
                .onEnded { value in
                    let projected = (drawerDragOrigin ?? (expanded ? trayHeight : 0)) - value.predictedEndTranslation.height
                    withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.88)) {
                        expanded = projected > trayHeight * 0.45
                        drawerDragHeight = nil; drawerDragOrigin = nil
                        if !expanded { captionFocused = false }
                    }
                })
            .onTapGesture { withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.88)) { expanded.toggle() } }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Design tools drawer")
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            .accessibilityAdjustableAction { direction in
                withAnimation { expanded = direction == .increment }
            }
            HStack(spacing: 0) {
                ForEach(["Background", "Text", "Illustrations"], id: \.self) { name in
                    Button { tab = name; expanded = true } label: {
                        Label(name, systemImage: name == "Background" ? "photo" : name == "Text" ? "textformat" : "sparkles")
                            .font(.ui(13)).frame(maxWidth: .infinity, minHeight: 44)
                            .background(tab == name ? studioPanel : .clear, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }.padding(.horizontal, 12).padding(.bottom, 8)
            Group {
                Divider()
                ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 5) {
                            ForEach(widgetMode ? ["Widget Small", "Widget Medium", "Widget Large"] : ["Portrait", "Square", "Story"], id: \.self) { format in
                                Button { design.format = format } label: {
                                    Text(format.replacingOccurrences(of: "Widget ", with: "")).font(.ui(13))
                                        .foregroundStyle(design.format == format ? ink : Theme.muted(scheme))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(design.format == format ? Theme.canvas(scheme) : .clear, in: RoundedRectangle(cornerRadius: 9))
                                }.buttonStyle(.plain).accessibilityAddTraits(design.format == format ? .isSelected : [])
                            }
                        }.padding(3).background(studioPanel, in: RoundedRectangle(cornerRadius: 12))
                        if tab == "Background" { backgroundTools }
                        if tab == "Text" { textTools }
                        if tab == "Illustrations" { artTools }
                        Button("Reset design") {
                            design = SnapshotDesign()
                            if widgetMode { design.format = "Widget Medium"; design.art = [SnapshotArt(asset: "olive", x: 0.5, y: 0.18, size: 0.12)] }
                            photo = nil; photoRevision = UUID(); selected = nil
                        }.font(.ui(12)).frame(maxWidth: .infinity, minHeight: 44)
                    }.padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 20)
                }.scrollDismissesKeyboard(.interactively)
                    .onChange(of: captionFocused) { _, focused in
                        if focused { withAnimation { reader.scrollTo("studio-caption", anchor: .bottom) } }
                    }
                }.frame(height: drawerDragHeight ?? (expanded ? trayHeight : 0))
                    .clipped()
            }
        }.background(Theme.canvas(scheme)).clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
    }
    private var backgroundTools: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Your background").font(.serif(23)); Spacer()
                PhotosPicker(selection: $photoSelection, matching: .images) { Label("Use a photo", systemImage: "photo").font(.ui(12)) }
            }
            if photo != nil {
                Button("Remove photo") { photo = nil; photoRevision = UUID() }.font(.ui(13))
                control("Photo shade", value: $design.photoShade, range: 0...70)
                control("Photo position", value: $design.photoFocus, range: 0...100)
            } else {
                HStack(spacing: 10) {
                    preset("Pure white", colors: ["FFFFFF", "FFFFFF", "FFFFFF"])
                    preset("Soft sky", colors: ["FFFFFF", "C4DFF0", "E3EDDF"])
                    preset("Quiet garden", colors: ["FFFFFF", "D6E4CD", "E1EDF4"])
                    preset("Rose mist", colors: ["FFFFFF", "EBD6DC", "DEEAF2"])
                    preset("Evening", colors: ["132029", "344E62", "596D63"])
                }
                HStack(alignment: .center, spacing: 14) {
                    ForEach(0..<(design.third ? 3 : 2), id: \.self) { i in
                        VStack(spacing: 6) {
                            Text("Color \(i + 1)").font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                            colorWell("Gradient color \(i + 1)", color: Binding(get: { design.colors[i] }, set: { design.colors[i] = $0 }), size: 44)
                        }
                    }
                    Spacer(minLength: 0)
                    Button { design.third.toggle() } label: {
                        Label(design.third ? "Third on" : "Third color", systemImage: design.third ? "xmark" : "plus")
                            .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                    }.buttonStyle(.plain)
                }
                control("Intensity", value: $design.intensity, range: 0...100)
                control("Direction", value: $design.angle, range: 0...360)
            }
        }
    }
    private var textTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Let the words lead.").font(.serif(23))
            HStack(alignment: .top, spacing: 5) {
                ForEach(["Ink", "White", "Slate", "Olive", "Rose"], id: \.self) { name in
                    let hex = ["Ink": "111111", "White": "FFFFFF", "Slate": "526D82", "Olive": "506554", "Rose": "8C5B6B"][name]!
                    Button { design.ink = hex } label: {
                        VStack(spacing: 7) {
                            Circle().fill(Color(studioHex: hex)).overlay(Circle().stroke(Theme.border(scheme), lineWidth: 1))
                                .overlay { if design.ink == hex { Image(systemName: "checkmark").font(.system(size: 14)).foregroundStyle(name == "White" ? .black : .white) } }
                                .frame(width: 40, height: 40)
                            Text(name).font(.ui(11))
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.plain).accessibilityLabel("\(name) text").accessibilityAddTraits(design.ink == hex ? .isSelected : [])
                }
                VStack(spacing: 7) { colorWell("Custom text color", color: $design.ink, size: 40); Text("Custom").font(.ui(11)) }.frame(maxWidth: .infinity)
            }
            HStack {
                Text("Typeface").font(.ui(14))
                Spacer()
                Menu {
                    ForEach(["Baskerville", "Baskerville-Italic", "AvenirNext-Regular", "DMSans-Regular"], id: \.self) { font in
                        Button { design.font = font } label: { Label(fontLabel(font), systemImage: design.font == font ? "checkmark" : "") }
                    }
                } label: {
                    HStack(spacing: 12) { Text(fontLabel(design.font)); Image(systemName: "chevron.down").font(.system(size: 10)) }
                        .font(.ui(14)).padding(.horizontal, 12).frame(minHeight: 44)
                        .background(studioPanel, in: RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(.plain).accessibilityLabel("Typeface, \(fontLabel(design.font))")
            }.padding(.bottom, 4).overlay(alignment: .bottom) { Rectangle().fill(Theme.border(scheme)).frame(height: 1) }
            control("Text size", value: $design.fontSize, range: 22...52)
            HStack {
                Text("Alignment").font(.ui(14)); Spacer()
                HStack(spacing: 3) {
                    ForEach(["Left", "Center", "Right"], id: \.self) { alignment in
                        Button { design.alignment = alignment } label: {
                            Text(alignment).font(.ui(12)).padding(.horizontal, 8).frame(minHeight: 44)
                                .foregroundStyle(design.alignment == alignment ? Theme.canvas(scheme) : ink)
                                .background(design.alignment == alignment ? ink : .clear, in: RoundedRectangle(cornerRadius: 7))
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.border(scheme), lineWidth: 1))
                        }.buttonStyle(.plain).accessibilityAddTraits(design.alignment == alignment ? .isSelected : [])
                    }
                }
            }
            if widgetMode {
                TextField("Personal caption (optional)", text: Binding(get: { design.caption ?? "" }, set: { design.caption = String($0.prefix(80)) }))
                    .font(.ui(14)).padding(12).background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 8))
                    .focused($captionFocused).submitLabel(.done).onSubmit { captionFocused = false }.id("studio-caption")
                Text("Your caption appears separately beneath the Bible reference.").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
            } else { Toggle("Her Crown signature", isOn: $design.watermark).font(.ui(14)) }
            Text("Scripture stays exactly as supplied by your Bible translation.").font(.ui(12)).foregroundStyle(Theme.muted(scheme))
        }
    }
    private var artTools: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("A little illustration.").font(.serif(23)); Spacer(); Text("\(design.art.count) / 6").font(.ui(12)).foregroundStyle(Theme.muted(scheme)) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(design.art) { art in
                        ZStack(alignment: .topTrailing) {
                            Button { selected = selected == art.id ? nil : art.id } label: {
                                Image.illustration(art.asset).resizable().scaledToFit().padding(4).frame(width: 58, height: 58)
                                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(selected == art.id ? ink : Theme.border(scheme), lineWidth: 1))
                            }.buttonStyle(.plain).accessibilityLabel("Arrange \(art.asset.replacingOccurrences(of: "-", with: " "))")
                                .padding(.top, 12).padding(.trailing, 12)
                            Button { removeArt(art.id) } label: {
                                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
                                    .frame(width: 24, height: 24)
                                    .background(Theme.canvas(scheme), in: Circle())
                                    .overlay(Circle().stroke(Theme.border(scheme)))
                                    .frame(width: 44, height: 44, alignment: .topTrailing)
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityLabel("Remove \(art.asset.replacingOccurrences(of: "-", with: " ")) illustration")
                        }
                    }
                }.padding(3)
            }
            if let index = design.art.firstIndex(where: { $0.id == selected }) {
                let layer = design.art[index]
                VStack(spacing: 12) {
                    Text(layer.asset.replacingOccurrences(of: "-", with: " ").capitalized).font(.ui(14, weight: .medium))
                    control("Size", value: artBinding(layer.id, \.size), range: 0.07...0.5)
                    control("Rotation", value: artBinding(layer.id, \.rotation), range: -180...180)
                    control("Horizontal position", value: artBinding(layer.id, \.x), range: 0.07...0.93)
                    control("Vertical position", value: artBinding(layer.id, \.y), range: 0.06...0.94)
                    HStack {
                        Button("Duplicate") { guard design.art.count < 6 else { return }; var copy = layer; copy.id = UUID(); copy.x = min(0.93, copy.x + 0.05); design.art.append(copy); selected = copy.id }.disabled(design.art.count >= 6)
                        Spacer()
                        Button("Bring forward") { design.art.removeAll { $0.id == layer.id }; design.art.append(layer) }
                        Spacer()
                        Button("Remove", role: .destructive) { removeArt(layer.id) }
                    }.font(.ui(12)).frame(minHeight: 44)
                }.padding(14).background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 13))
            }
            HStack { Text("Illustration library").font(.serif(20)); Spacer(); Text("34 illustrations").font(.ui(12)).foregroundStyle(Theme.muted(scheme)) }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 3), spacing: 21) {
                ForEach(libraryAssets, id: \.self) { asset in
                    Button {
                        guard design.art.count < 6 else { return }
                        let art = SnapshotArt(asset: asset); design.art.append(art); selected = art.id
                    } label: {
                        VStack(spacing: 7) { Image.illustration(asset).resizable().scaledToFit().frame(height: 88); Text(asset.replacingOccurrences(of: "-", with: " ").capitalized).font(.ui(11)) }
                    }.disabled(design.art.count >= 6)
                }
            }
        }
    }
    private func removeArt(_ id: UUID) {
        design.art.removeAll { $0.id == id }
        if selected == id { selected = nil; pinchSize = nil; dragOrigin = nil }
    }
    private func artBinding(_ id: UUID, _ path: WritableKeyPath<SnapshotArt, Double>) -> Binding<Double> {
        Binding(get: { design.art.first(where: { $0.id == id })?[keyPath: path] ?? 0 }, set: { value in if let i = design.art.firstIndex(where: { $0.id == id }) { design.art[i][keyPath: path] = value } })
    }
    private func preset(_ name: String, colors: [String]) -> some View {
        Button { design.colors = colors; design.third = name != "Pure white"; design.intensity = name == "Evening" || name == "Pure white" ? 100 : name == "Rose mist" ? 65 : 70; design.ink = name == "Evening" ? "FFFFFF" : "111111" } label: {
            VStack(spacing: 7) { LinearGradient(colors: colors.map { Color(studioHex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing).frame(height: 55).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border(scheme), lineWidth: 1)); Text(name).font(.ui(10)).lineLimit(1).minimumScaleFactor(0.8) }
        }.frame(maxWidth: .infinity)
    }
    private var libraryAssets: [String] {
        return ["cosmos", "olive", "journal", "open-book", "magnifier", "bookmark", "reflection", "community", "milestone", "sunrise", "anchor", "dove", "intention-heart", "seedling", "hourglass", "reminder-bell", "butterfly", "lantern", "faith-hands", "purpose-compass", "relationship-hands", "gratitude-basket", "wisdom-pearl", "rest-stones", "devotional-teacup", "prayer-envelope", "reflection-quill", "growth-vase", "quiet-window", "faith-key", "wisdom-scroll", "grace-shell", "hope-nest", "gratitude-bowl"]
    }
    private var studioPanel: Color { scheme == .dark ? Color(hex: 0x141416) : Color(hex: 0xF5F6F7) }
    private func fontLabel(_ font: String) -> String {
        ["Baskerville": "Baskerville", "Baskerville-Italic": "Baskerville Italic", "AvenirNext-Regular": "Avenir Next", "DMSans-Regular": "DM Sans"][font] ?? font
    }
    private func colorWell(_ label: String, color: Binding<String>, size: CGFloat) -> some View {
        ColorPicker(label, selection: Binding(get: { Color(studioHex: color.wrappedValue) }, set: { color.wrappedValue = $0.studioHex }), supportsOpacity: false)
            .labelsHidden().frame(width: size, height: size)
            .overlay { Circle().fill(Color(studioHex: color.wrappedValue)).padding(4).overlay(Circle().stroke(Theme.border(scheme), lineWidth: 1)).allowsHitTesting(false) }
            .accessibilityLabel(label)
    }
    private func control(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(label); Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(range.upperBound <= 1 ? 2 : 0)))
                    .foregroundStyle(Theme.muted(scheme))
                    + Text(label == "Intensity" || label == "Photo shade" || label == "Photo position" ? "%" : label == "Direction" || label == "Rotation" ? "°" : "").foregroundStyle(Theme.muted(scheme))
            }
            StudioSlider(value: value, range: range, ink: UIColor(ink), track: UIColor(Theme.border(scheme)))
                .frame(height: 36).accessibilityLabel(label)
        }.font(.ui(13))
    }
    @discardableResult private func save() -> Bool {
        do {
            let data = try JSONEncoder().encode(design)
            if let imageData = photo?.jpegData(compressionQuality: 0.85) {
                try FileManager.default.createDirectory(at: photoURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try imageData.write(to: photoURL, options: .atomic)
            } else if FileManager.default.fileExists(atPath: photoURL.path) {
                try FileManager.default.removeItem(at: photoURL)
            }
            UserDefaults.standard.set(data, forKey: key)
            savedDesign = design
            savedPhotoRevision = photoRevision
            failure = nil
            return true
        } catch {
            failure = "Your design couldn’t save. Please try again."
            return false
        }
    }
    @MainActor private func close() {
        captionFocused = false
        guard hasUnsavedChanges else { dismiss(); return }
        withAnimation(.easeOut(duration: 0.18)) { showingCloseConfirmation = true }
    }
    @MainActor @discardableResult private func saveWidget() -> Bool {
        do {
            try WidgetDesignStore.publish(design: design, photo: photo, text: text, reference: reference, translation: translation, owner: app.me?.user.id)
            guard save() else { return false }; failure = nil; widgetSaved = true
            Task { await Analytics.shared.track("widget_studio_saved", ["size": .string(design.format.replacingOccurrences(of: "Widget ", with: "").lowercased())]) }
            return true
        } catch { failure = "Your widget design couldn’t save. Please try again."; return false }
    }
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self), data.count <= 20_000_000, let image = UIImage(data: data) else { failure = "Choose an image smaller than 20 MB."; return }
        let size = image.size; let ratio = min(1, 2400 / max(size.width, size.height))
        photo = UIGraphicsImageRenderer(size: CGSize(width: size.width * ratio, height: size.height * ratio)).image { _ in image.draw(in: CGRect(x: 0, y: 0, width: size.width * ratio, height: size.height * ratio)) }
        photoRevision = UUID()
        failure = nil
    }
    @MainActor private func download() async {
        guard !downloading else { return }
        downloading = true
        defer { downloading = false }
        guard let image = SnapshotRenderer.render(text: text, reference: reference, translation: translation, design: design, photo: photo, watermark: watermark) else {
            failure = "The snapshot couldn’t be prepared. Please try again."; return
        }
        let permission = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard permission == .authorized || permission == .limited else {
            failure = "Allow Her Crown to add photos in Settings, or use Share snapshot to save a copy."; return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAsset(from: image) }
            save(); failure = nil; downloaded = true
            await Analytics.shared.track("verse_snapshot_downloaded", ["format": .string(design.format.lowercased())])
        } catch { failure = "Your snapshot couldn’t save to Photos. Please try again." }
    }
    @MainActor private func export() {
        guard let image = SnapshotRenderer.render(text: text, reference: reference, translation: translation, design: design, photo: photo, watermark: watermark) else { failure = "The snapshot couldn’t be prepared. Please try again."; return }
        rendered = image; failure = nil; save(); sharing = true
        Task { await Analytics.shared.track("verse_snapshot_shared", ["format": .string(design.format.lowercased())]) }
    }
}

@MainActor enum SnapshotRenderer {
    static func render(text: String, reference: String, translation: String, design: SnapshotDesign, photo: UIImage?, watermark: Bool) -> UIImage? {
        let renderer = ImageRenderer(content: SnapshotCanvas(text: text, reference: reference, translation: translation, design: design, photo: photo, watermark: watermark).environment(\.colorScheme, .light))
        renderer.scale = 1.8
        guard let image = renderer.uiImage else { return nil }
        // Fractional SwiftUI point heights can round Story to 1921 pixels. Export an exact-size PNG canvas.
        let size = CGSize(width: 1080, height: design.format == "Square" ? 1080 : design.format == "Story" ? 1920 : 1440)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}

struct SnapshotCanvas: View {
    let text: String
    let reference: String
    let translation: String
    let design: SnapshotDesign
    let photo: UIImage?
    let watermark: Bool
    private var fontSize: CGFloat {
        let available = CGSize(width: 504, height: design.height * 0.46)
        var size = CGFloat(design.fontSize)
        while size > 14 {
            let font = UIFont(name: design.font, size: size) ?? .systemFont(ofSize: size)
            let box = (text as NSString).boundingRect(with: CGSize(width: available.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font, .paragraphStyle: paragraph], context: nil)
            if box.height <= available.height { break }; size -= 1
        }
        return size
    }
    private var paragraph: NSMutableParagraphStyle { let p = NSMutableParagraphStyle(); p.lineSpacing = 7; return p }
    var body: some View {
        ZStack {
            if let photo {
                GeometryReader { g in
                    let ratio = max(g.size.width / photo.size.width, g.size.height / photo.size.height)
                    Image(uiImage: photo).resizable().frame(width: photo.size.width * ratio, height: photo.size.height * ratio)
                        .position(x: g.size.width / 2, y: g.size.height / 2 + (50 - design.photoFocus) / 100 * max(0, photo.size.height * ratio - g.size.height))
                }
                Color.black.opacity(design.photoShade / 100)
            } else {
                let radians = design.angle * .pi / 180
                LinearGradient(colors: Array(design.colors.prefix(design.third ? 3 : 2)).map { color in Color.white.opacity(1 - design.intensity / 100).blendOver(Color(studioHex: color)) }, startPoint: UnitPoint(x: 0.5 - sin(radians) / 2, y: 0.5 + cos(radians) / 2), endPoint: UnitPoint(x: 0.5 + sin(radians) / 2, y: 0.5 - cos(radians) / 2))
            }
            Text(text).font(.custom(design.font, fixedSize: fontSize)).lineSpacing(7).multilineTextAlignment(design.textAlignment)
                .frame(width: 504, alignment: design.alignment == "Left" ? .leading : design.alignment == "Right" ? .trailing : .center)
                .fixedSize(horizontal: false, vertical: true).position(x: 300, y: design.height * 0.51)
            Text("\(reference) · \(translation)").font(.custom("DMSans-Regular", fixedSize: 15)).multilineTextAlignment(design.textAlignment).frame(width: 504, alignment: design.alignment == "Left" ? .leading : design.alignment == "Right" ? .trailing : .center).position(x: 300, y: design.height * 0.84)
            ForEach(design.art) { art in
                Image.illustration(art.asset).resizable().scaledToFit().frame(width: 600 * art.size, height: 600 * art.size).rotationEffect(.degrees(art.rotation)).position(x: art.x * 600, y: art.y * design.height)
            }
            if let caption = design.caption, !caption.isEmpty {
                Text(caption).font(.custom("DMSans-Regular", fixedSize: 14)).multilineTextAlignment(design.textAlignment)
                    .frame(width: 504).lineLimit(2).position(x: 300, y: design.height * 0.94)
            }
            if watermark { Image("CrownSignature").resizable().scaledToFit().frame(width: 42, height: 42).position(x: 300, y: design.height * 0.94) }
        }.frame(width: 600, height: design.height).foregroundStyle(Color(studioHex: design.ink)).clipped()
    }
}
private struct SnapshotShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [image], applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
private extension Color {
    init(studioHex: String) { self.init(hex: UInt32(studioHex, radix: 16) ?? 0x111111) }
    var studioHex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    func blendOver(_ color: Color) -> Color {
        let top = UIColor(self), bottom = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        top.getRed(&r, green: &g, blue: &b, alpha: &a); bottom.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(red: r * a + br * (1-a), green: g * a + bg * (1-a), blue: b * a + bb * (1-a))
    }
}

/// The mockup's thin track and circular thumb, with native drag and accessibility behavior.
private struct StudioSlider: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let ink: UIColor
    let track: UIColor
    func makeCoordinator() -> Coordinator { Coordinator(value: $value) }
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return slider
    }
    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.value = $value
        slider.minimumValue = Float(range.lowerBound); slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.minimumTrackTintColor = track; slider.maximumTrackTintColor = track
        let line = UIGraphicsImageRenderer(size: CGSize(width: 3, height: 3)).image { context in
            track.setFill(); context.fill(CGRect(x: 0, y: 0, width: 3, height: 3))
        }.resizableImage(withCapInsets: .zero)
        slider.setMinimumTrackImage(line, for: .normal); slider.setMaximumTrackImage(line, for: .normal)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 23, height: 23))
        let thumb = renderer.image { _ in ink.setFill(); UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 23, height: 23)).fill() }
        slider.setThumbImage(thumb, for: .normal)
        slider.setThumbImage(thumb, for: .highlighted)
    }
    final class Coordinator: NSObject {
        var value: Binding<Double>
        init(value: Binding<Double>) { self.value = value }
        @objc func changed(_ slider: UISlider) { value.wrappedValue = Double(slider.value) }
    }
}
