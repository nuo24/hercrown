import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case bible, community, discover, home
    var id: String { rawValue }
    var title: String { switch self { case .bible: "The Bible"; case .community: "Community"; case .discover: "Discover"; case .home: "Home" } }
    var symbol: String { switch self { case .bible: "book"; case .community: "person.2"; case .discover: "safari"; case .home: "house" } }
}

/// .liquid-dock: 80 pt translucent glass capsule 14 pt from the screen edges, 3 pt inset, four 72 pt tabs, 25 pt icons,
/// 12 pt labels; the active tab sits in a sliding glass pill (values from the mockup, light and dark).
struct Dock: View {
    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Namespace private var pill

    var body: some View {
        let dark = scheme == .dark
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let active = tab == selection
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { selection = tab }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol).font(.system(size: 22, weight: .light)).frame(height: 25)
                        Text(tab.title).font(.system(size: 12, weight: active ? .semibold : .regular))
                    }
                    .foregroundStyle(active ? (dark ? Color.white : Color(hex: 0x111111)) : (dark ? Color(hex: 0xC0C5C7) : Color(hex: 0x717177)))
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background {
                        if active {
                            Capsule()
                                .fill(Color.white.opacity(dark ? 0.14 : 0.396))
                                .overlay(Capsule().strokeBorder(LinearGradient(colors: [Color.white.opacity(dark ? 0.27 : 0.7), .clear], startPoint: .top, endPoint: .center), lineWidth: 1))
                                .shadow(color: Color(red: 25 / 255, green: 61 / 255, blue: 73 / 255, opacity: dark ? 0 : 0.25), radius: 4, y: 3)
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
        .padding(3)
        .frame(height: 80)
        .background {
            Capsule()
                .fill(reduceTransparency ? AnyShapeStyle(dark ? Color(hex: 0x292929) : Color(hex: 0xF7F7F8))
                                         : AnyShapeStyle(.ultraThinMaterial))
                .overlay(Capsule().fill(dark ? Color(red: 41 / 255, green: 41 / 255, blue: 41 / 255, opacity: 0.52) : Color.white.opacity(0.44)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(dark ? 0.28 : 0.59), lineWidth: 1))
                .shadow(color: dark ? .black.opacity(0.6) : Color(red: 24 / 255, green: 45 / 255, blue: 60 / 255, opacity: 0.22), radius: 9, y: 12)
                .shadow(color: dark ? .black.opacity(0.4) : Color(red: 35 / 255, green: 53 / 255, blue: 61 / 255, opacity: 0.15), radius: 3, y: 3)
        }
        .padding(.horizontal, 14)
    }
}
