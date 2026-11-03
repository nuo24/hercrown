-- Plus study tools (decision 0006, src/study.ts). Source data is loaded separately: npm run seed:study (built by
-- scripts/build-study.mjs from OpenBible.info, STEPBible and public-domain commentaries).

CREATE TABLE commentary_sources (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  author      TEXT NOT NULL,
  published   TEXT NOT NULL,
  license     TEXT NOT NULL,
  url         TEXT NOT NULL
);
INSERT INTO commentary_sources (id, name, author, published, license, url) VALUES
  ('jfb', 'Commentary Critical and Explanatory on the Whole Bible', 'Jamieson, Fausset & Brown', '1871', 'Public domain',
   'https://bible.helloao.org/api/c/jamieson-fausset-brown/books.json'),
  ('henry', 'Commentary on the Whole Bible', 'Matthew Henry', '1706', 'Public domain',
   'https://bible.helloao.org/api/c/matthew-henry/books.json'),
  ('clarke', 'Commentary on the Bible', 'Adam Clarke', '1831', 'Public domain',
   'https://bible.helloao.org/api/c/adam-clarke/books.json');

-- A note starts at `verse` (0 = chapter introduction). Matthew Henry comments on passages: the note for a verse is the
-- one with the highest starting verse ≤ that verse.
CREATE TABLE commentary_notes (
  source   TEXT NOT NULL REFERENCES commentary_sources (id),
  book_id  TEXT NOT NULL,
  chapter  INTEGER NOT NULL,
  verse    INTEGER NOT NULL,
  text     TEXT NOT NULL,
  PRIMARY KEY (source, book_id, chapter, verse)
);

-- OpenBible.info cross-references (CC BY), best-voted first. `target` is a canonical ref, possibly a range in one chapter.
CREATE TABLE cross_references (
  book_id  TEXT NOT NULL,
  chapter  INTEGER NOT NULL,
  verse    INTEGER NOT NULL,
  rank     INTEGER NOT NULL,
  target   TEXT NOT NULL,
  votes    INTEGER NOT NULL,
  PRIMARY KEY (book_id, chapter, verse, rank)
);

-- STEPBible TAGNT / TAHOT (CC BY 4.0): JSON array of [text, transliteration, gloss, strong, morphology, lemma, editions].
CREATE TABLE original_words (
  book_id  TEXT NOT NULL,
  chapter  INTEGER NOT NULL,
  verse    INTEGER NOT NULL,
  language TEXT NOT NULL CHECK (language IN ('grc', 'hbo')),
  words    TEXT NOT NULL,
  PRIMARY KEY (book_id, chapter, verse)
);

-- STEPBible brief lexicons TBESG / TBESH (CC BY 4.0), by extended Strong's number.
CREATE TABLE lexicon (
  strong          TEXT PRIMARY KEY,
  language        TEXT NOT NULL,
  lemma           TEXT NOT NULL,
  transliteration TEXT NOT NULL,
  part_of_speech  TEXT NOT NULL,
  gloss           TEXT NOT NULL,
  definition      TEXT NOT NULL
);

-- AI study notes: generated once per verse, tool and prompt version, then served to everyone. Reported answers are
-- hidden after enough reports and regenerated.
CREATE TABLE study_answers (
  ref               TEXT NOT NULL,
  tool              TEXT NOT NULL CHECK (tool IN ('explain', 'deeper')),
  version           INTEGER NOT NULL,
  status            TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'hidden')),
  sections          TEXT NOT NULL, -- JSON [{ "title", "text" }]
  sources           TEXT NOT NULL, -- JSON ["jfb", "henry", ...] actually cited
  model             TEXT NOT NULL,
  prompt_tokens     INTEGER NOT NULL,
  completion_tokens INTEGER NOT NULL,
  cost_micros       INTEGER NOT NULL,
  reports           INTEGER NOT NULL DEFAULT 0,
  created_at        INTEGER NOT NULL,
  PRIMARY KEY (ref, tool, version)
);

CREATE TABLE study_reports (
  id         TEXT PRIMARY KEY,
  ref        TEXT NOT NULL,
  tool       TEXT NOT NULL,
  version    INTEGER NOT NULL,
  user_id    TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  reason     TEXT NOT NULL CHECK (reason IN ('inaccurate', 'unclear', 'offensive', 'other')),
  note       TEXT,
  created_at INTEGER NOT NULL,
  UNIQUE (ref, tool, version, user_id)
);
