# App Store listing (draft)

Copy for App Store Connect → Her Crown (app 6830437910). Draft, 2026-11-04: the owner approves before it's submitted. Every claim here is true of the app today. Don't add ratings, reader counts or awards until they're real.

## Name and subtitle (decide before submitting)

| | Name (30 max) | Subtitle (30 max) |
|---|---|---|
| **A. Chosen** | Her Crown: Scroll the Bible | Daily Bible for women |
| **B. Lower risk** | Her Crown: Bible for Women | Scroll less. Read the Word. |

"Scroll the Bible" is a competitor's app name. Apple can reject a name that uses another app's brand (guidelines 4.1 and 5.2), or the competitor can file a complaint after launch ([decision 0009](decisions/0009-name-her-crown.md)). B keeps the idea without the brand. Either way, the competitor's name never goes in keywords (Apple rejects that).

## Promotional text (170 max, can change any time without review)

> Trade a few minutes of scrolling for a few minutes in the Word. Swipe through Scripture one verse at a time, with a fresh devotional every day.

## Description (4,000 max)

> Her Crown turns the spare minutes you'd spend scrolling into a calm, daily habit of reading Scripture.
>
> Swipe through the Bible one verse at a time. Each verse gets the whole screen, in a beautiful serif, with nothing competing for your attention. Save the verses that speak to you, write a note, reflect, and share.
>
> READ FREE, EVEN OFFLINE
> • The King James Version, Berean Standard Bible and World English Bible, built into the app so they work without a connection
> • Every book and chapter, with words of Jesus in red if you like
> • Verse of the Day, and a short devotional every day
> • Discover: Scripture for peace, purpose, faith, hope, anxiety, identity, gratitude, wisdom and relationships, each with a reflection question
> • A gentle reading streak and progress through the whole Bible
> • A home-screen widget with your chosen verse or today's verse
> • Daily reminders, if you want them
>
> GO DEEPER WITH HER CROWN PLUS
> • Explain Easier: a verse in plain language
> • Deeper Study: background, meaning and how it applies
> • Original Language: every Hebrew and Greek word, with its meaning
> • Related Verses: passages that are often read alongside it
> • Reading plans, like A Quiet Beginning and Peace for Anxious Hearts
>
> Explain Easier and Deeper Study are written by AI from respected public-domain commentaries (Matthew Henry; Jamieson, Fausset & Brown; Adam Clarke), and every answer names its sources. They're clearly labeled, never mixed with Scripture, and you can report any answer that seems wrong. The Bible text itself is never changed.
>
> SUBSCRIPTION
> Reading the Bible in Her Crown is always free. Her Crown Plus is $29.99 a year with a 7-day free trial, or $2.99 a week. We'll send you a reminder before your free trial ends. Payment is charged to your Apple ID when you confirm the purchase, or when the free trial ends. Subscriptions renew automatically unless you cancel at least 24 hours before the end of the current period. Manage or cancel any time in your App Store account settings.
>
> Terms of Use: https://bible-scroll-api-staging.bible-scroll-api.workers.dev/legal/terms
> Privacy Policy: https://bible-scroll-api-staging.bible-scroll-api.workers.dev/legal/privacy

## Keywords (100 max, commas, no spaces)

```
bible,women,devotional,scripture,verse,daily,christian,faith,prayer,kjv,study,reading,plan,god,jesus
```

## URLs

| Field | Value |
|---|---|
| Support URL | https://bible-scroll-api-staging.bible-scroll-api.workers.dev/legal/support |
| Privacy Policy URL | https://bible-scroll-api-staging.bible-scroll-api.workers.dev/legal/privacy |
| Marketing URL | Leave empty until the website exists |

These are the staging server's addresses. They must change to the production server, or the domain, before submitting, and the description's links must change with them.

## Category, rights, age

- **Primary category:** Lifestyle. **Secondary:** Reference.
- **Copyright:** 2026 Nathan Okolo
- **Content rights:** "Yes, it contains third-party content, and I have the rights." The Bibles are public domain; the study data is licensed CC BY with credit in the app (Settings → Credits & Licenses).
- **Age rating:** answer **None** to every content question. The app doesn't have unrestricted web access, user-to-user chat, gambling, or contests. If asked about AI-generated content: the study tools generate text about the selected verse only, from fixed sources. There's no open-ended chat. Expected result: 4+.

## In-app purchases (each subscription's App Store page)

| Product | Display name | Description (45 max) |
|---|---|---|
| hercrown.plus.yearly | Her Crown Plus · Yearly | Reading plans and every study tool |
| hercrown.plus.weekly | Her Crown Plus · Weekly | Reading plans and every study tool |
| hercrown.plus.yearly.offer | Her Crown Plus · Yearly Offer | Your first year of Plus at a lower price |

Recommended: turn on **Family Sharing** for the subscriptions. Its absence was a complaint in the competitor's reviews.

Apple reviews the first subscriptions with the first app version. Attach them on the version page under "In-App Purchases and Subscriptions" before submitting.

## App Privacy (the "nutrition label")

**Tracking:** No. The app doesn't track people across other companies' apps or websites, and has no ads.

**Data collected.** For every type, mark it as *linked to the user* and *not used for tracking*.

| Data type | Purposes | What it is |
|---|---|---|
| Contact Info → Email Address | App Functionality | The email Apple shares with Sign in with Apple (can be a private relay address) |
| Contact Info → Name | App Functionality | The display name she chooses |
| User Content → Photos | App Functionality | Optional profile photo |
| User Content → Other User Content | App Functionality | Notes on verses, and support messages |
| Identifiers → User ID | App Functionality, Analytics | Her account id |
| Identifiers → Device ID | Analytics | A random install id (not the advertising id) |
| Purchases → Purchase History | App Functionality | Subscription status from Apple and Superwall |
| Usage Data → Product Interaction | Analytics, App Functionality | Events like "paywall viewed" and "study opened"; reading days and progress |
| Diagnostics → Other Diagnostic Data | App Functionality | Error reports |

**Not collected:** location, contacts, health, financial info (Apple handles payment), browsing history, search history, sensitive info, advertising data.

This must stay in step with the Privacy Policy. If a new SDK or data type is added, update both.

## App Review information

- **Sign-in required:** No. The app starts with a guest account automatically.
- **Contact:** Nathan Okolo · macnatephil@gmail.com · phone (the owner adds it)
- **Notes for the reviewer:**

> Her Crown needs no sign-in: the app creates a guest account on first launch. Reading the Bible (KJV, BSB and WEB, built in and available offline) is free.
>
> Her Crown Plus is an auto-renewable subscription (yearly with a 7-day free trial, weekly, and a one-time discounted first year offered after declining). The paywall appears after onboarding (choose any answers; "Explore as a guest" skips it). It also appears from Settings → Subscription and when a free account opens a study tool or reading plan. Restore Purchases is in Settings → Subscription.
>
> To see the study tools: open The Bible tab, tap the magnifier beside any verse, and choose Explain Easier, Deeper Study, Original Language or Related Verses. Explain Easier and Deeper Study are generated by an AI model, only from public-domain commentaries that each answer cites. They're labeled as AI and not Scripture, and each one has "Report a problem". Original Language and Related Verses come from open datasets (STEPBible, OpenBible.info), not AI.
>
> Sign in with Apple is optional (Settings → Your account) and only saves the guest's data to an account. Account deletion is in Settings → Your account → Delete account.

## Version 1.0 "What's New"

Not shown for the first version.

## Screenshots (to do after the phone test)

Required: the 6.9" iPhone size (1320 × 2868). Apple scales it down for smaller phones. Plan, in order:

1. The reader: one verse on the screen ("Scroll less. Read the Word.")
2. Verse of the Day and the streak on Home
3. A study tool with its cited sources ("Understand every verse")
4. Discover by topic ("Scripture for the season you're in")
5. Today's devotional
6. The widget on a home screen

Use real screens from the app. Captions sit above the phone frame. Don't show prices in screenshots.
