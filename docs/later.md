# Later

Ideas and deferred work, parked so they don't derail the current phase.

- **Community tab.** Two directions under discussion: community prayers with a per-prayer "praying" count (engagement), or improved shareability. Either needs real storage, identities, moderation, report/block. Decide before building; the current screen stays an honest empty state.
- **Google sign-in and email magic links.** Playbook includes them; skipped while iOS-only. Add for Android/web.
- **Web app** (`apps/web`, React + Vite) and **Android**.
- **Search in online translations.** Search covers KJV only; modern wording ("love is patient") won't match KJV ("charity suffereth long").
- **Original-language and version comparison** in insights (unavailable in the mockup; needs real sources).
- **Support email delivery.** Settings → Suggestions & bugs stores tickets through `POST /me/support` and shows the sender their ticket history. Team email delivery still needs `EMAIL_FROM` (a domain). The owner can export tickets to CSV with `apps/api/scripts/export-feedback.mjs`. Contact & Support also retains its email path.
- **Achievements (V2).** Design the achievement system after the first release.
- **Return-offer timing decision.** The current staging test waits 20 minutes after a declined paywall and caps impressions at one per rolling 24 hours. Consider a first offer after 48 hours and reading on two separate days, with a longer cooldown after dismissal. Discuss cancellation and never-subscribed audiences separately before changing eligibility. Both offers remain off for production 1.0.
- **Plus reminders for free readers.** Keep “Explore as a guest” as a free path. Decide where occasional in-app Plus reminders belong and whether to offer opt-in subscription notifications.
- **Push reminders** (APNs) once reminder opt-in ships in iOS.
- **Bun** instead of npm, to match the playbook commands exactly.
- **Email sign-in (one-time codes).** Built in the API but off for launch: sending needs a domain on Cloudflare. Buy the domain (or use the friend's website domain), set `EMAIL_FROM`, then show it in Settings. Guests save their account with Sign in with Apple until then.
- **Design polish with Appllama** (MCP server https://appllama.io, skills https://github.com/Appllama/appllama-skills). Seen in a social post claiming better-looking AI-built apps. Not evaluated. It's a new vendor, so ask the owner before connecting it. Use it to polish screens, not to replace the friend's mockup (`reference-web/`, `specs/`), which stays the design authority. Best time to try: after the main screens work, before App Store screenshots.
