# Pink interactive accents and Home passage layout

November 23, 2026. Owner inspected the original handoff next to the native UI and requested its exact selected-control color, a visible divider above the daily verse and wider, moderately smaller long-passage text. This supersedes the earlier request to use #31222B for Pink accents; that value remains ordinary text.

The original Home preview Library pill's dominant interior pixel is RGB (130,67,95), #82435F. The supplied CSS independently specifies the same --petal-wine. Add a semantic Theme.accent token: #82435F in Pink, existing neutral text color in Light/Dark. Use for selected pills/navigation, primary button fills, interactive outlines/tints, reader action chrome, Home heart/share/read-and-reflect, Discover selection and Community voting. Preserve ordinary Scripture/body color, red-letter Scripture, destructive semantics, muted controls and Pink background/surfaces. Onboarding's tap behavior remains untouched.

Home's section divider uses the theme border, a one-point line aligned with the 22-point gutters and 12 points of space before the verse card. Faith Medals has its own bottom divider separating it from the devotional. Its arrow sits immediately beside the progress/View medal line, and its three text lines use a tighter four-point gap. Devotional row arrows remain at the trailing edge.

Daily Scripture uses all available card width instead of a 265-point maximum. Long text is measured at that width; reduce from the preferred 28-point size only as needed toward a 22-point floor (proportional to Dynamic Type), then expand vertically without truncation or a fixed height. Accessibility text categories preserve their chosen size and expand. Scripture content and translation attribution remain intact.

Compare the original Psalm 23:1 reference with the corrected native Psalm 23:1 capture and an actual licensed MSG passage returned by staging. Any fixed-passage capture is labelled design-only and must not change production daily content or ship fixture text.
