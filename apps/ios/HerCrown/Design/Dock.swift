import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case bible, community, discover, home
    var id: String { rawValue }
    var title: String { switch self { case .bible: "The Bible"; case .community: "Community"; case .discover: "Discover"; case .home: "Home" } }
    var glyph: String {
        self == .bible ? "dock-book" : "dock-\(rawValue)"
    }
}

struct Dock: View {
    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let active = selection == tab
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) { selection = tab }
                } label: {
                    VStack(spacing: 5) {
                        Image.glyph(tab.glyph).frame(width: 22, height: 22)
                        Text(tab.title).font(.ui(11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(Theme.text(scheme))
                    .opacity(active ? 1 : scheme == .dark ? 0.48 : 0.58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .background {
            let canvas = Theme.canvas(scheme)
            if reduceTransparency {
                canvas.ignoresSafeArea(edges: .bottom)
            } else {
                Rectangle().fill(.ultraThinMaterial)
                    .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, canvas.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    }
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
