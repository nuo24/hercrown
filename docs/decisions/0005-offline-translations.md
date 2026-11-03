# 0005 · Offline translations: KJV, BSB, WEB (CPDV pending)

**Date:** 2026-11-02, updated 2026-11-03 · **Status:** KJV, BSB, WEB built and verified; CPDV awaiting a decision

**Built:** three public-domain translations stored in D1 and bundled for the app (`apps/api/seeds/{kjv,bsb,web}.json`), each through a pinned, checksummed build:

| | Edition | Source | Verses | Verified against |
|---|---|---|---|---|
| KJV | King James Version (1769) | seven1m/open-bibles `eng-kjv.osis.xml` | 31,102 | kit fixtures (46 verses); text unchanged across rebuilds |
| BSB | Berean Standard Bible (eBible `engbsb`, release 2026-10-30) | eBible.org USFM | 31,086 | every verse equals eBible's own VPL edition |
| WEB | World English Bible (eBible `engwebp`, 66-book edition, uses "LORD", release 2026-10-30) | eBible.org USFM | 31,098 | every verse equals eBible's own VPL edition |

Kept out of verse text: footnotes, cross-references, section headings, Psalm 119 letter headings, Song of Solomon speaker labels. Kept separately: the 116 psalm superscriptions (`chapter_titles`), and the words of Jesus as red-letter ranges (KJV 2,066 verses, WEB 2,059; BSB's source has no red-letter markup).

**Versification:** BSB omits 16 verses absent from the earliest manuscripts (e.g. Matthew 17:21, John 5:4); WEB omits 4 and places the Romans doxology at 14:24–26 instead of 16:25–27. The API serves each translation's own verse numbers (gaps included) and per-translation rail counts; `chapter_verse_counts` is the canonical upper bound for references (Romans 14 → 26).

**Terms:** both eBible texts are public domain. "World English Bible" is a trademark of eBible.org: the name may only be used for the unmodified text. We change no words (only remove notes/headings, as eBible's own plain-text edition does).

**CPDV (Catholic Public Domain Version) — needs a decision before building.** Public domain (Ronald L. Conte Jr.), USFM maintained by CrossWire. It is the 73-book Catholic canon translated from the Latin Vulgate: it adds Tobit, Judith, Wisdom, Sirach, Baruch, 1–2 Maccabees and the longer Esther/Daniel, and numbers the Psalms the Vulgate way (Hebrew Psalm 23 = CPDV Psalm 22). Supporting it means extending the book catalog and mapping Psalm/verse numbers so saves, plans and cross-translation features line up. Recommended as its own step.
