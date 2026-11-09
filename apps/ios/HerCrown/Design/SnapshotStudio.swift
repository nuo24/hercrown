import SwiftUI
import PhotosUI

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
    var art = [SnapshotArt(asset: "cosmos")]
    var height: CGFloat { format == "Square" ? 600 : format == "Story" ? 1066.6667 : 800 }
    var exportSize: String { format == "Square" ? "1080 × 1080" : format == "Story" ? "1080 × 1920" : "1080 × 1440" }
    var textAlignment: TextAlignment { alignment == "Left" ? .leading : alignment == "Right" ? .trailing : .center }
    static let assets = ["cosmos", "olive", "dove", "butterfly", "faith-hands", "open-book", "journal", "reflection-quill", "prayer-envelope", "faith-key", "hope-nest", "quiet-window", "growth-vase", "devotional-teacup", "wisdom-scroll", "grace-shell", "anchor", "bookmark", "community", "gratitude-basket", "gratitude-bowl", "hourglass", "intention-heart", "lantern", "magnifier", "milestone", "purpose-compass", "reflection", "relationship-hands", "reminder-bell", "rest-stones", "seedling", "sunrise", "wisdom-pearl"]
}

/// Canvas-first editor: Scripture is supplied by BibleStore; only its visual treatment is editable.
struct VerseSnapshotView: View {
    let text: String
    let reference: String
    let translation: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var design = SnapshotDesign()
    @State private var selected: UUID?
    @State private var tab = "Background"
    @State private var expanded = false
    @State private var rendered: UIImage?
    @State private var photo: UIImage?
    @State private var photoSelection: PhotosPickerItem?
    @State private var failure: String?
    @State private var sharing = false
    @State private var dragOrigin: CGPoint?
    private var ink: Color { Theme.text(scheme) }
    private var watermark: Bool { !app.membership.premium || design.watermark }
    private var key: String { "hc.snapshotStudio.\(app.me?.user.id ?? "local")" }
    private var photoURL: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("snapshot-\(app.me?.user.id ?? "local").jpg") }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { save(); dismiss() } label: { Image(systemName: "arrow.left").frame(width: 44, height: 44) }.accessibilityLabel("Close Snapshot Studio")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snapshot Studio").font(.serif(26))
                    Text("\(reference) · \(translation)").font(.ui(11)).foregroundStyle(Theme.muted(scheme)).lineLimit(1)
                }
                Spacer()
                Button("Done") { save(); dismiss() }.font(.ui(14, weight: .medium)).frame(minWidth: 44, minHeight: 44)
            }.padding(.horizontal, 16).padding(.bottom, 8)
            GeometryReader { area in
                let scale = min((area.size.width - 36) / 600, (area.size.height - 44) / design.height)
                VStack(spacing: 8) {
                    Text("Tap an illustration to arrange it.").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
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
                    }.frame(width: 600, height: design.height).scaleEffect(max(0.01, scale))
                        .frame(width: 600 * scale, height: design.height * scale).clipped().shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                    Spacer(minLength: 0)
                }.frame(maxWidth: .infinity).padding(.top, 10)
            }.background(Theme.supporting(scheme))
            tools
            VStack(spacing: 6) {
                if let failure { Text(failure).font(.ui(12)).foregroundStyle(Theme.muted(scheme)) }
                Button { export() } label: { Label("Share snapshot", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }.buttonStyle(CapsuleButtonStyle())
                Text("\(design.exportSize) PNG").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
            }.padding(.horizontal, 18).padding(.vertical, 9).background(Theme.canvas(scheme))
        }
        .foregroundStyle(ink).background(Theme.canvas(scheme)).buttonStyle(.plain).tint(ink)
        .task {
            if let data = UserDefaults.standard.data(forKey: key), let saved = try? JSONDecoder().decode(SnapshotDesign.self, from: data) { design = saved }
            photo = UIImage(contentsOfFile: photoURL.path)
            #if DEBUG
            if let review = UserDefaults.standard.string(forKey: "hcStudioReview"), ["Background", "Text", "Illustrations"].contains(review) { tab = review; expanded = true }
            #endif
            await Analytics.shared.track("verse_snapshot_opened")
        }
        .onDisappear { save() }
        .onChange(of: photoSelection) { _, item in Task { await loadPhoto(item) } }
        .sheet(isPresented: $sharing) { if let rendered { SnapshotShareSheet(image: rendered) } }
        .presentationDetents([.large]).presentationDragIndicator(.hidden)
    }
    private var tools: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() } } label: {
                VStack(spacing: 4) {
                    Capsule().fill(Theme.muted(scheme).opacity(0.4)).frame(width: 33, height: 4)
                    Text(expanded ? "Slide down to arrange" : "Swipe up for tools").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                }.frame(maxWidth: .infinity).frame(height: 44)
            }.accessibilityLabel(expanded ? "Collapse design tools" : "Expand design tools")
            HStack(spacing: 0) {
                ForEach(["Background", "Text", "Illustrations"], id: \.self) { name in
                    Button { tab = name; expanded = true } label: {
                        Label(name, systemImage: name == "Background" ? "photo" : name == "Text" ? "textformat" : "sparkles")
                            .font(.ui(13)).frame(maxWidth: .infinity, minHeight: 44)
                            .background(tab == name ? Theme.supporting(scheme) : .clear, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }.padding(.horizontal, 12).padding(.bottom, 8)
            if expanded {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Picker("Snapshot format", selection: $design.format) { ForEach(["Portrait", "Square", "Story"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                        if tab == "Background" { backgroundTools }
                        if tab == "Text" { textTools }
                        if tab == "Illustrations" { artTools }
                        Button("Reset design") { design = SnapshotDesign(); photo = nil; selected = nil }.font(.ui(12)).frame(maxWidth: .infinity, minHeight: 44)
                    }.padding(22)
                }.frame(height: 260)
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
                Button("Remove photo") { photo = nil }.font(.ui(13))
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
                HStack {
                    ForEach(0..<(design.third ? 3 : 2), id: \.self) { i in ColorPicker("Color \(i + 1)", selection: Binding(get: { Color(studioHex: design.colors[i]) }, set: { design.colors[i] = $0.studioHex }), supportsOpacity: false).font(.ui(11)) }
                }
                Toggle("Third gradient color", isOn: $design.third).font(.ui(13))
                control("Intensity", value: $design.intensity, range: 0...100)
                control("Direction", value: $design.angle, range: 0...360)
            }
        }
    }
    private var textTools: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Let the words lead.").font(.serif(23))
            ColorPicker("Text color", selection: Binding(get: { Color(studioHex: design.ink) }, set: { design.ink = $0.studioHex }), supportsOpacity: false).font(.ui(14))
            Picker("Typeface", selection: $design.font) { ForEach(["Baskerville", "Baskerville-Italic", "AvenirNext-Regular", "DMSans-Regular"], id: \.self) { Text($0.replacingOccurrences(of: "-Regular", with: "")) } }.font(.ui(14))
            control("Text size", value: $design.fontSize, range: 22...52)
            Picker("Alignment", selection: $design.alignment) { ForEach(["Left", "Center", "Right"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
            if app.membership.premium { Toggle("Her Crown watermark", isOn: $design.watermark).font(.ui(14)) }
            else { Text("Snapshots include the Her Crown watermark. Plus members can turn it off.").font(.ui(12)).foregroundStyle(Theme.muted(scheme)) }
            Text("Scripture stays exactly as supplied by your Bible translation.").font(.ui(12)).foregroundStyle(Theme.muted(scheme))
        }
    }
    private var artTools: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("Illustrations").font(.serif(23)); Spacer(); Text("\(design.art.count) / 6").font(.ui(12)) }
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
                        Button("Remove", role: .destructive) { design.art.removeAll { $0.id == layer.id }; selected = nil }
                    }.font(.ui(12)).frame(minHeight: 44)
                }.padding(14).background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 13))
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(SnapshotDesign.assets, id: \.self) { asset in
                    Button {
                        guard design.art.count < 6 else { return }
                        let art = SnapshotArt(asset: asset); design.art.append(art); selected = art.id
                    } label: {
                        VStack(spacing: 7) { Image.illustration(asset).resizable().scaledToFit().frame(height: 70); Text(asset.replacingOccurrences(of: "-", with: " ").capitalized).font(.ui(11)) }
                    }.disabled(design.art.count >= 6)
                }
            }
        }
    }
    private func artBinding(_ id: UUID, _ path: WritableKeyPath<SnapshotArt, Double>) -> Binding<Double> {
        Binding(get: { design.art.first(where: { $0.id == id })?[keyPath: path] ?? 0 }, set: { value in if let i = design.art.firstIndex(where: { $0.id == id }) { design.art[i][keyPath: path] = value } })
    }
    private func preset(_ name: String, colors: [String]) -> some View {
        Button { design.colors = colors; design.intensity = name == "Evening" || name == "Pure white" ? 100 : 70 } label: {
            VStack(spacing: 7) { LinearGradient(colors: colors.map { Color(studioHex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing).frame(height: 48).clipShape(RoundedRectangle(cornerRadius: 12)); Text(name).font(.ui(9)) }
        }.frame(maxWidth: .infinity)
    }
    private func control(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 4) { HStack { Text(label); Spacer(); Text(value.wrappedValue, format: .number.precision(.fractionLength(range.upperBound <= 1 ? 2 : 0))) }; Slider(value: value, in: range) }.font(.ui(13)).tint(ink)
    }
    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(design), forKey: key)
        if let data = photo?.jpegData(compressionQuality: 0.85) {
            try? FileManager.default.createDirectory(at: photoURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: photoURL, options: .atomic)
        } else { try? FileManager.default.removeItem(at: photoURL) }
    }
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self), data.count <= 20_000_000, let image = UIImage(data: data) else { failure = "Choose an image smaller than 20 MB."; return }
        let size = image.size; let ratio = min(1, 2400 / max(size.width, size.height))
        photo = UIGraphicsImageRenderer(size: CGSize(width: size.width * ratio, height: size.height * ratio)).image { _ in image.draw(in: CGRect(x: 0, y: 0, width: size.width * ratio, height: size.height * ratio)) }
        failure = nil
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
            if watermark { Text("Her Crown").font(.custom("Baskerville-Italic", fixedSize: 22)).position(x: 300, y: design.height * 0.94) }
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
