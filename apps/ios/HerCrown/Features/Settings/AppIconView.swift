import SwiftUI

struct AppIconView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var controller = AppIconController()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("A little more you.").font(.serif(30, relativeTo: .title)).accessibilityAddTraits(.isHeader)
                Text("Choose the Her Crown you’d like on your Home Screen.")
                    .font(.ui(14)).foregroundStyle(Theme.muted(scheme)).frame(maxWidth: 245)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 28) {
                    ForEach(AppIconController.Choice.allCases) { choice in
                        iconChoice(choice)
                    }
                }
                .padding(.top, 24)
                if controller.isChanging { ProgressView().accessibilityLabel("Changing app icon") }
                Text("Your icon choice applies to this iPhone’s Home Screen.")
                    .font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.text(scheme))
            .padding(22)
        }
        .background(AppGradient())
        .navigationTitle("App icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { controller.refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { controller.refresh() } }
        .alert("App icon", isPresented: Binding(
            get: { controller.errorMessage != nil },
            set: { if !$0 { controller.errorMessage = nil } }
        )) { Button("OK", role: .cancel) {} } message: {
            Text(controller.errorMessage ?? "")
        }
    }

    private func iconChoice(_ choice: AppIconController.Choice) -> some View {
        let selected = choice == controller.selected
        return Button { controller.select(choice) } label: {
            VStack(spacing: 14) {
                Image((choice.alternateName ?? "AppIcon") + "-preview")
                    .resizable()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .frame(width: 104, height: 104)
                    .overlay {
                        if selected { RoundedRectangle(cornerRadius: 24).strokeBorder(Theme.text(scheme), lineWidth: 2) }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.canvas(scheme))
                                .frame(width: 20, height: 20)
                                .background(Theme.text(scheme), in: Circle())
                                .padding(2)
                                .background(Theme.canvas(scheme), in: Circle())
                                .offset(x: 4, y: 4)
                        }
                    }
                    .accessibilityHidden(true)
                Text(choice.title).font(.ui(13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(controller.isChanging)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private extension AppIconController.Choice {
    var title: String {
        switch self {
        case .white: "Pure white"
        case .cloud: "Cloud sky"
        case .sage: "Soft sage"
        case .blue: "Powder blue"
        }
    }
}
