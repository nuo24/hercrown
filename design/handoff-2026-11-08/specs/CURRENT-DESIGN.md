# Current design contract

Use the runnable reference and measured style export. CSS ordering in `design/css-order.json` is part of the evidence; reading only one legacy stylesheet gives incorrect results.

## Palette and type

Light canvas #FFFFFF, primary text #111111, secondary text #656565, dividers #E5E5E5. Dark canvas #000000, primary #F5F5F5, muted #B1B1B1, dividers #303030; sheet/surface #131313 and secondary #242424. Do not reintroduce cream, a green-black canvas or a blue/yellow dock gradient. User artwork colors in studios are independent from the app theme.

Display/Scripture: Baskerville with Georgia serif fallback only for browser portability. Native uses actual installed Baskerville regular/italic variants and verified PostScript names. Main titles use regular 34/1.05 with −0.65 tracking; nested native-style page titles are typically 30. Controls/body/nav: DM Sans 400 and 500, bundled with its OFL license. Avoid synthetic bold or using italic on every title. Current personalized onboarding deliberately removes italics from specified questions; do not globally strip italics from Scripture or the approved welcome/paywall.

Representative effective values must be checked in `design/computed-styles.json`; source may contain responsive/reader font-size variants. Use Dynamic Type equivalents in native and test wrapping instead of multiplying one screenshot's scale.

## Layout and finish

Quiet editorial hierarchy: serif titles, restrained DM Sans metadata, small uppercase references and section information, thin dividers, selective contextual illustrations. Preserve whitespace with purpose; avoid adding placeholder headings, decorative pills, random shadows or giant standalone artwork to fill a gap.

Home avatar remains circular. Name and streak number share a visual baseline and serif voice; fire+number are a row with “day streak” below. Home Bookmarks/Notes use consistent 24px vertical row padding, 24px heading separation, restrained dividers and readable paragraphs. See final rules in personal-home.css.

The four bottom destinations sit low above the real home indicator, with transparent/fading material over underlying content. Labels stay present. Active glyph/text is fully opaque, inactive muted; do not box the entire bar in an iOS pill. Preserve user-approved filled dock glyphs. Community filled SVG must have no stroke (legacy Discover styling previously added an unwanted outline). Header settings is a gear, not a profile glyph; Discover uses a magnifier, not a star.

Discover horizontal submenu pins while content scrolls. The featured passage combines text and one appropriately sized illustration, followed by compact contextual-art rows. Community inherits this title, line-height and spacing language while using photographs.

Use native pickers, real system permission prompts and native share surfaces. Notification example is an iOS-style notification: app icon/name/time, system sans-serif title/body, muted translucent rounded surface. It is an example within onboarding, not a second custom card design. Reminder time stays visible independently of toggle.

## Assets

Original files are in reference-web/dist and native-ready duplicates in design. Preserve aspect ratio, transparent edges, lighting, shadow and tactile illustration style. No emoji substitutes, regenerated logos or repeated giant icons on every screen. Current UI control paths and filled nav symbols are exported separately from the illustration pack.

Four icons: Pure white (default/first), Cloud sky, Soft sage, Powder blue. Only the selected icon gets an outline and circled tick; no surrounding card border on every icon or redundant “Choose icon” heading. Native selection commits only after setAlternateIconName succeeds.
