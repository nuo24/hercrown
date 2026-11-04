# Later

Ideas and deferred work, parked so they don't derail the current phase.

- **Community tab.** Two directions under discussion: community prayers with a per-prayer "praying" count (engagement), or improved shareability. Either needs real storage, identities, moderation, report/block. Decide before building; the current screen stays an honest empty state.
- **Google sign-in and email magic links.** Playbook includes them; skipped while iOS-only. Add for Android/web.
- **Web app** (`apps/web`, React + Vite) and **Android**.
- **Search in online translations.** Search covers KJV only; modern wording ("love is patient") won't match KJV ("charity suffereth long").
- **Original-language and version comparison** in insights (unavailable in the mockup; needs real sources).
- **Support message delivery** (real destination, rate limits). Replace the mock WhatsApp numbers.
- **Push reminders** (APNs) once reminder opt-in ships in iOS.
- **Bun** instead of npm, to match the playbook commands exactly.
- **Email sign-in (one-time codes).** Built in the API but off for launch: sending needs a domain on Cloudflare. Buy the domain (or use the friend's website domain), set `EMAIL_FROM`, then show it in Settings. Guests save their account with Sign in with Apple until then.
- **Design polish with Appllama** (MCP server https://appllama.io, skills https://github.com/Appllama/appllama-skills). Seen in a social post claiming better-looking AI-built apps. Not evaluated. It's a new vendor, so ask the owner before connecting it. Use it to polish screens, not to replace the friend's mockup (`reference-web/`, `specs/`), which stays the design authority. Best time to try: after the main screens work, before App Store screenshots.
