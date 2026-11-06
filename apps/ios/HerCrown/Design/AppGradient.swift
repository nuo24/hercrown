import SwiftUI

/// Shared full-bleed canvas behind the main app and its sheets.
struct AppGradient: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Theme.canvas(scheme)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
