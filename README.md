# Bible Scroll · iOS build kit

Frozen from the working browser mockup on **November 2, 2026**. This is a development handoff, not a compiled iOS release.

**Start with [IMPLEMENTATION.md](IMPLEMENTATION.md).** It gives the next coding agent its objective, priorities, build sequence and completion criteria.

## Open the reference

From this directory:

```sh
python3 -m http.server 8879 --bind 127.0.0.1 --directory reference-web/dist
```

Open `http://127.0.0.1:8879/ios-preview.html`. If that port is occupied, choose another port. The preview includes Restart onboarding, Paywall, appearance and live gradient controls. Browser state is local to the host/port. Use a fresh browser profile to review the complete onboarding without changing an existing review session.

## What is included

- `reference-web/`: final working demo, all styles, behavioral modules and three test suites.
- `starter-ios/`: earlier SwiftUI source and Xcode project. **Incomplete relative to the reference.** Port/update it or replace its implementation where necessary.
- `design/asset-catalog/`: importable `.xcassets` catalog with all **28** PNG images and universal image-set metadata.
- `design/icon-pack/`: **30** individually exported SVG interface icons, manifest and Lucide license.
- `design/logo-pack/`: editable black/white wordmarks and existing book symbol. A final independent logo/App Store icon has not been approved.
- `design/asset-inventory.json`: native asset names, original paths, dimensions and SHA-256 checksums.
- `specs/`: current screen map, visual rules, data/backend plan, content fixtures and verification criteria.
- `screenshots/current/`: selected recent evidence with documented limitations; not every screenshot is an exact capture of the final build.
- `history/docs/`: earlier design notes and screenshots for context. These are superseded wherever they conflict with this kit’s current specifications.
- `validation/`: verification results, limitations and package checks.

## Authority

1. Latest user requirements recorded in `specs/CURRENT-DESIGN.md`.
2. Working final reference under `reference-web/dist/` and the current specifications.
3. Selected screenshots, interpreted using `screenshots/README.md`.
4. Starter iOS source.
5. Historical notes.

The target is a faithful native **Bible Scroll** app, not a clone of a third-party website and not a WebView shell. Preserve the approved appearance and app structure while adding the infrastructure and missing product behavior needed to make it work.
