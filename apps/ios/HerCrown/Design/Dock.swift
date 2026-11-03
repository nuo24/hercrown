import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case bible, community, discover, home
    var id: String { rawValue }
    var title: String { switch self { case .bible: "The Bible"; case .community: "Community"; case .discover: "Discover"; case .home: "Home" } }
    var symbol: String { switch self { case .bible: "book"; case .community: "person.2"; case .discover: "safari"; case .home: "house" } }
}

/// Lifted floating capsule dock in neutral translucent glass (no authored colour gradient). The active tab sits in a
/// raised inner capsule. Respects Reduce Transparency.
struct Dock: View {
    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let active = tab == selection
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol).font(.system(size: 19, weight: .regular))
                        Text(tab.title).font(.system(size: 11, weight: active ? .semibold : .regular))
                    }
                    .foregroundStyle(Theme.text(scheme).opacity(active ? 1 : 0.72))
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background {
                        if active {
                            Capsule()
                                .fill(scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.06))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(scheme == .dark ? 0.16 : 0.7), lineWidth: 0.6))
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(5)
        .background {
            Capsule()
                .fill(reduceTransparency ? AnyShapeStyle(scheme == .dark ? Color(hex: 0x1C2022) : Color(hex: 0xF7F7F8)) : AnyShapeStyle(.ultraThinMaterial))
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [Color.white.opacity(scheme == .dark ? 0.22 : 0.9), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8))
                .shadow(color: .black.opacity(scheme == .dark ? 0.5 : 0.12), radius: 22, y: 10)
        }
        .padding(.horizontal, 14)
    }
}
