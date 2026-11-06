import SwiftUI
import UIKit

extension Image {
    static func glyph(_ name: String) -> some View {
        Image("glyph-\(name)").resizable().scaledToFit().accessibilityHidden(true)
    }

    private static let illustrationCache = NSCache<NSString, UIImage>()

    /// Read the original mockup PNG independently of the device's compiled asset catalog.
    static func illustration(_ name: String) -> Image {
        if let cached = illustrationCache.object(forKey: name as NSString) {
            return Image(uiImage: cached)
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Illustrations"),
              let image = UIImage(contentsOfFile: url.path) else {
            return Image(name)
        }
        illustrationCache.setObject(image, forKey: name as NSString)
        return Image(uiImage: image)
    }
}
