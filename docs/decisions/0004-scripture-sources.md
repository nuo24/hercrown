# 0004 · Scripture sources

**Date:** 2026-11-02 · **Status:** KJV accepted; API.Bible proposed, awaiting owner confirmation

**KJV (offline):** full text from [seven1m/open-bibles](https://github.com/seven1m/open-bibles) `eng-kjv.osis.xml` (public domain; the data bible-api.com serves, which produced the kit's fixtures). Pinned by SHA-256 in `apps/api/scripts/build-kjv.mjs`; every build verifies 66 books / 1,189 chapters / 31,102 verses and an exact match with the kit's 46 verified verses. Rejected: scrollmapper's KJV.json ("Lord" for LORD, psalm titles merged into verse 1, Psalm 119 Hebrew headings, missing commas).

**Online translations:** via [API.Bible](https://api.bible), fetched per request, not stored. Each translation is a row in `translations` (`provider = 'api_bible'`). Requires FUMS v3 reporting from the app (we pass `fumsToken` through). API.Bible is a vendor outside the playbook's list, added before the owner confirmed it.

**Open:** which translations (NIV/ESV/NLT etc. need publisher licenses); API.Bible caching terms (caching is off until confirmed); API.Bible account + key.
