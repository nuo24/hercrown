-- Offline translations BSB and WEB, words of Jesus, and psalm titles.
-- Verse text is loaded separately: npm run seed:kjv / seed:bsb / seed:web (or seed:scripture for all three).

-- Words of Jesus as JSON [[start, length], …] in UTF-16 code units (JS string indices / Swift NSRange). NULL = none.
ALTER TABLE verses ADD COLUMN words_of_jesus TEXT;

-- Canonical psalm superscriptions ("A Psalm of David."), kept apart from verse 1.
CREATE TABLE chapter_titles (
  translation_id TEXT NOT NULL REFERENCES translations (id),
  book_id        TEXT NOT NULL REFERENCES books (id),
  chapter        INTEGER NOT NULL,
  text           TEXT NOT NULL,
  PRIMARY KEY (translation_id, book_id, chapter)
);

INSERT INTO translations (id, name, abbreviation, license, source_url, attribution, availability, provider, position) VALUES
  ('bsb', 'Berean Standard Bible', 'BSB', 'Public Domain', 'https://ebible.org/Scriptures/engbsb_usfm.zip',
   'Berean Standard Bible. Public domain. BSB Publishing, LLC.', 'bundled', 'local', 2),
  ('web', 'World English Bible', 'WEB', 'Public Domain', 'https://ebible.org/Scriptures/engwebp_usfm.zip',
   'World English Bible. Public domain. "World English Bible" is a trademark of eBible.org.', 'bundled', 'local', 3);

-- chapter_verse_counts is the canonical upper bound for references: the highest verse number in any bundled
-- translation. WEB places the Romans doxology at 14:24–26 (KJV 16:25–27). Gaps (BSB omits 16 verses that are
-- absent from early manuscripts, e.g. Matthew 17:21) are per translation and come from the stored verses.
UPDATE chapter_verse_counts SET verse_count = 26 WHERE book_id = 'ROM' AND chapter = 14;
