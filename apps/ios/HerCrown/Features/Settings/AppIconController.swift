import UIKit
import Combine

@MainActor
final class AppIconController: ObservableObject {
    enum Choice: String, CaseIterable, Identifiable {
        case white, cloud, sage, blue
        var id: String { rawValue }
        var alternateName: String? {
            switch self {
            case .white: return nil // Primary AppIcon, not an alternate named "AppIcon".
            case .cloud: return "HerCrownCloud"
            case .sage: return "HerCrownSage"
            case .blue: return "HerCrownBlue"
            }
        }
    }
    @Published private(set) var selected: Choice = .white
    @Published private(set) var isChanging = false
    @Published var errorMessage: String?

    init() { refresh() }

    func refresh() {
        let name = UIApplication.shared.alternateIconName
        selected = Choice.allCases.first { $0.alternateName == name } ?? .white
    }

    func select(_ choice: Choice) {
        guard !isChanging else { return }
        refresh()
        guard choice != selected else { return }
        guard UIApplication.shared.supportsAlternateIcons else {
            errorMessage = "App icon changes aren’t available on this device."
            return
        }
        errorMessage = nil
        isChanging = true
        UIApplication.shared.setAlternateIconName(choice.alternateName) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isChanging = false
                self.refresh() // OS is the source of truth; don't optimistically change selection.
                if error != nil {
                    self.errorMessage = "Your icon couldn’t be changed. Please try again."
                }
            }
        }
    }
}
