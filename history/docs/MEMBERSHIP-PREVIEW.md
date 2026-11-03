# Bible Scroll membership preview

Pricing researched November 2, 2026, in USD.

The [official Scroll The Bible US App Store listing](https://apps.apple.com/us/app/scroll-the-bible/id6756558351) includes a $29.99 yearly in-app purchase among multiple annual and monthly offers. A catalog entry does not establish which offer appears to every customer at checkout.

The [official Bible Chat site](https://thebiblechat.com/) advertises $4.99/week, $12.99/month and $59.99/year after a seven-day trial. These two comparables illustrate subscription patterns; they do not establish an industry-wide average.

## Proposed mock pricing

- $29.99/year, selected by default; approximately $2.50/month, billed yearly.
- $2.99/week, billed weekly. This is our proposed lower weekly option, not a measured industry norm.
- No free trial is offered in this mockup.

## Preview behavior

The optional membership screen appears after onboarding. Reopen it with Paywall in the outer preview toolbar or Preview membership plans in Settings. Choose either plan to update billing text and the continue button. Continuing opens an explicitly labeled demo confirmation. Free reading and close remain available.

No payment collection, StoreKit integration, purchase, subscription entitlement or feature gating is implemented. Restore, terms and privacy controls show explanatory demo notices; these are not production legal documents. The separate native SwiftUI project is not updated by this browser mockup.

## Validation

Browser checked: yearly default, weekly selection and confirmation, onboarding completion to paywall, free-reading exit, and cloud backgrounds. Existing onboarding, streak and reader-scroll test suites passed; both JavaScript modules passed syntax checks.

Screenshots: screenshots/membership-paywall.png and screenshots/onboarding-clouds.png.

Paywall refinement: full display background extends behind the preview status bar and home indicator, while controls respect safe areas. Uses live BibleGradient light/dark variables and the app’s semantic neutral button palette. Verified live intensity changes and both appearances.
