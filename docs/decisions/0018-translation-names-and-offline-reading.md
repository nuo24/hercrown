# 0018 — Translation names and effective offline reading

Accepted November 22, 2026. Translation selectors show names without Online/Offline suffixes. While the app is offline, the reader picker offers bundled versions. A stored remote preference uses KJV under its actual KJV label until connection returns; retain the preference and chapter/verse position. Never display fallback Scripture under a licensed version’s name. Network transport failure uses this effective-translation policy; provider HTTP errors still offer retry and bundled choices.

CSB stays on hold by owner instruction; ESV/NIV are not enabled in this build. No publisher licenses, attribution or Scripture text change. The fallback event carries only the KJV ID. Verify preference/position preservation and all bundled reading before release, staging first.
