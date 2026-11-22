import SwiftUI
import UIKit

/// Decorative headings wrap at spaces. Reduce their size only when the longest word
/// cannot fit the actual text column; never truncate or split that word into letters.
struct WholeWordHeading: UIViewRepresentable {
    let text: String
    let pointSize: CGFloat
    var tracking: CGFloat = 0
    var ink: Color

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.lineBreakStrategy = .standard
        label.backgroundColor = .clear
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.isAccessibilityElement = true
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.accessibilityLabel = text
        configure(label, width: label.preferredMaxLayoutWidth > 0 ? label.preferredMaxLayoutWidth : .greatestFiniteMagnitude)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView label: UILabel, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        configure(label, width: width)
        let size = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(size.height))
    }

    private func configure(_ label: UILabel, width: CGFloat) {
        label.preferredMaxLayoutWidth = width
        let font = WholeWordHeadingMetrics.font(text: text, width: width, pointSize: pointSize, tracking: tracking)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.hyphenationFactor = 0
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: font, .kern: tracking, .foregroundColor: UIColor(ink), .paragraphStyle: paragraph,
        ])
    }
}

enum WholeWordHeadingMetrics {
    static func font(text: String, width: CGFloat, pointSize: CGFloat, tracking: CGFloat) -> UIFont {
        let nominal = UIFont(name: "Baskerville", size: pointSize) ?? .systemFont(ofSize: pointSize)
        guard width.isFinite, width > 0 else { return nominal }
        let words = text.split(whereSeparator: \.isWhitespace)
        func longest(_ font: UIFont) -> CGFloat {
            words.map { NSAttributedString(string: String($0), attributes: [.font: font, .kern: tracking]).size().width }.max() ?? 0
        }
        // Binary search accounts for kerning, which need not scale in proportion to the font.
        guard longest(nominal) > max(1, width - 1) else { return nominal }
        var low: CGFloat = 0.1
        var high = pointSize
        for _ in 0..<24 {
            let size = (low + high) / 2
            if longest(nominal.withSize(size)) <= max(1, width - 1) { low = size } else { high = size }
        }
        return nominal.withSize(low)
    }
}
