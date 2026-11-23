# 0017 — Distinct Faith Medal requirements

Accepted November 22, 2026 after owner reported identical Fruit/Armor unlocks.

Fruit of the Spirit retains sustained general reading-day and distinct-chapter milestones. Armor of God now requires each medal’s own named thematic chapter list plus its existing reading-day minimum. Promises of God likewise requires separate Faithfulness, Hope, and Peace/Trust chapter lists. Psalms stays Psalm-specific; Women of the Bible stays book-specific. Reading-day minimums mean total reading days, not a consecutive streak or days spent on that journey; visible copy states both requirements. Historical recorded chapter completions count, and repeated completions never add extra credit. Two medals may still be earned together if both distinct requirements have actually been fulfilled.

The native catalog defines the required chapter identities and tests validate every reference against the bundled Bible catalog, ensure unique lists, and prove that any one journey alone cannot grant another themed medal even at 1,000 general reading days. No Scripture text is changed or generated.

`GET /me/progress` adds `bible.completedChapterRefs`, an account-scoped array of canonical BOOK.chapter identities from existing chapter_completions. Existing aggregate fields and database schema remain unchanged. Older API/cache payloads without this field grant zero thematic chapter credit until refreshed; totals are never used as a substitute. A Required reading disclosure shows exact chapters, completion indicators and native reader links. Analytics records medal IDs, not chapter references.

Rules version 2 retains first-detected dates for unchanged Fruit/Psalms/Women medals; old Armor/Promises detection dates are dropped and those medals are recalculated against verified reading. Server reading history is retained. No production mutation, backend deployment or app release is authorized by this rule change alone; staging first, reviewed native update later.
