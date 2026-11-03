# Branding, artwork and native import

## Included assets

The asset inventory contains all 28 PNG files in the final reference: 25 illustration-pack assets, onboarding collage, meadow photo and sky scene. Each has its original pixel dimensions, SHA-256 and universal Xcode image-set path. Copy `apps/ios/HerCrown/Artwork.xcassets (moved from design/asset-catalog)` into the native target, then use the image IDs verbatim with original rendering and scaled-to-fit where appropriate. Confirm target membership in Xcode; the catalog is not automatically added to the older starter project.

Source originals remain in `reference-web/dist/assets` and `reference-web/dist/illustration-pack`. Prompts/provenance are preserved where they exist. The meadow photo has no separate provenance file in the baseline; do not invent one or assume distribution rights beyond the supplied project. Confirm provenance/rights before release. Lucide ISC text is included with the icon pack and web assets.

## Artwork placements

Use the live source for precise dimensions and mappings. Cosmos: Home greeting / onboarding composition. Ceramic heart: intention/Identity. Seedling: starting point and contextual reader art. Olive: topics/Peace and quiet editorial signoff. Hourglass: reading rhythm/time comparison. Bell: reminder. Butterfly: onboarding completion and membership feature. Lantern: discovery/guidance. Open book: insight introduction, paywall and time comparison. Bookmark: saved collection and membership benefit. Journal: reading plan feature. Shared tea: Community. Wreath: conditional streak milestone. Sunrise/dove/anchor: quiet/peace/strength plans. Faith hands, compass, relationship hands, gratitude basket, pearl and rest stones: their corresponding topics. Cloud bank: soft background atmosphere. The reader's exact conditional artwork mapping is in `readerArtwork()`.

Do not enforce old README restrictions that conflict with the final reader artwork, current onboarding collage or latest Settings usage. Future artwork may be added when context calls for it; maintain photographic materials, soft lighting, consistent contours/shadows and purposeful placement.

## Wordmarks and App Store icon

No independent final logo or production AppIcon was approved in the prototype. The editable black/white wordmarks reproduce the product name using the existing serif direction; the book symbol is the existing UI mark. These make the handoff reusable but do not establish a new approved identity.

The next agent should prepare a proposed App Store icon and any necessary export variants as a separately reviewable item. Use a clean original mark compatible with the app. Do not copy third-party site marks, embed SF Symbols in a commercial logo without checking terms, or represent the candidate as an approved trademark. Final font identity/metrics and production wordmark outlining remain validation tasks. System fonts are used in the mockup; no proprietary font binaries are bundled.
