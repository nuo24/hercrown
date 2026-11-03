// Readable grammar for STEPBible morphology codes: Greek (Robinson, e.g. "V-AAI-3S") and Hebrew (OSHB-style with an
// "H" prefix, e.g. "HVqp3ms"). Unknown codes give null rather than a guess.

const GREEK_POS: Record<string, string> = {
  N: "Noun", V: "Verb", A: "Adjective", T: "Article", P: "Pronoun", R: "Relative pronoun", C: "Reciprocal pronoun",
  D: "Demonstrative pronoun", K: "Correlative pronoun", I: "Interrogative pronoun", X: "Indefinite pronoun", Q: "Correlative pronoun",
  F: "Reflexive pronoun", S: "Possessive pronoun", ADV: "Adverb", CONJ: "Conjunction", COND: "Conditional", PREP: "Preposition",
  PRT: "Particle", INJ: "Interjection", ARAM: "Aramaic word", HEB: "Hebrew word",
};
const CASE: Record<string, string> = { N: "nominative", G: "genitive", D: "dative", A: "accusative", V: "vocative" };
const NUMBER: Record<string, string> = { S: "singular", P: "plural" };
const GENDER: Record<string, string> = { M: "masculine", F: "feminine", N: "neuter" };
const TENSE: Record<string, string> = { P: "present", I: "imperfect", F: "future", A: "aorist", R: "perfect", L: "pluperfect", "2A": "aorist", "2R": "perfect", "2F": "future", "2L": "pluperfect" };
const VOICE: Record<string, string> = { A: "active", M: "middle", P: "passive", E: "middle or passive", D: "middle", O: "passive", N: "middle or passive" };
const MOOD: Record<string, string> = { I: "indicative", S: "subjunctive", O: "optative", M: "imperative", N: "infinitive", P: "participle" };
const PERSON: Record<string, string> = { "1": "1st person", "2": "2nd person", "3": "3rd person" };

function greekCaseNumberGender(code: string): string[] {
  const m = /^([NGDAV])([SP])([MFN])?/.exec(code);
  if (!m) return [];
  return [CASE[m[1]!]!, NUMBER[m[2]!]!, m[3] ? GENDER[m[3]]! : ""].filter(Boolean);
}

export function greekParsing(morph: string): string | null {
  const [pos, ...rest] = morph.split("-");
  if (!pos) return null;
  const name = GREEK_POS[pos];
  if (!name) return null;
  if (pos === "V") {
    const m = /^(2?[PIFARL])([AMPEDON])([ISOMNP])$/.exec(rest[0] ?? "");
    if (!m) return name;
    const parts = [`${TENSE[m[1]!]} ${VOICE[m[2]!]} ${MOOD[m[3]!]}`];
    const tail = rest[1] ?? "";
    const person = /^([123])([SP])$/.exec(tail);
    if (person) parts.push(`${PERSON[person[1]!]} ${NUMBER[person[2]!]}`);
    else if (greekCaseNumberGender(tail).length) parts.push(greekCaseNumberGender(tail).join(" "));
    return [name, ...parts].join(" · ");
  }
  const detail = greekCaseNumberGender(rest.find((r) => /^[NGDAV][SP]/.test(r)) ?? "");
  return detail.length ? `${name} · ${detail.join(" ")}` : name;
}

const HEBREW_POS: Record<string, string> = {
  A: "Adjective", C: "Conjunction", D: "Adverb", N: "Noun", P: "Pronoun", R: "Preposition", S: "Suffix", T: "Particle", V: "Verb",
};
const STEM: Record<string, string> = {
  q: "qal", N: "niphal", p: "piel", P: "pual", h: "hiphil", H: "hophal", t: "hithpael", o: "polel", O: "polal", r: "hithpolel",
  m: "poel", M: "poal", k: "palel", K: "pulal", Q: "qal passive", l: "pilpel", L: "polpal", f: "hithpalpel", D: "nithpael",
  j: "pealal", i: "pilel", u: "hothpaal", c: "tiphil", v: "hishtaphel", w: "nithpalel", y: "nithpoel", z: "hithpoel",
};
const ASPECT: Record<string, string> = {
  p: "perfect", q: "sequential perfect", i: "imperfect", w: "sequential imperfect", h: "cohortative", j: "jussive",
  v: "imperative", r: "participle (active)", s: "participle (passive)", a: "infinitive absolute", c: "infinitive construct",
};
const H_GENDER: Record<string, string> = { m: "masculine", f: "feminine", b: "common", c: "common" };
const H_NUMBER: Record<string, string> = { s: "singular", p: "plural", d: "dual" };
const H_STATE: Record<string, string> = { a: "absolute", c: "construct", d: "determined" };

export function hebrewParsing(morph: string): string | null {
  const m = /^H([A-Z])(.*)$/.exec(morph);
  if (!m) return null;
  const name = HEBREW_POS[m[1]!];
  if (!name) return null;
  const rest = m[2]!;
  if (m[1] === "V") {
    const v = /^([a-zA-Z])([a-z])([123])?([mfbc])?([spd])?/.exec(rest);
    if (!v) return name;
    const parts = [`${STEM[v[1]!] ?? "verb"} ${ASPECT[v[2]!] ?? ""}`.trim()];
    const pgn = [v[3] ? PERSON[v[3]] : "", v[4] ? H_GENDER[v[4]] : "", v[5] ? H_NUMBER[v[5]] : ""].filter(Boolean).join(" ");
    if (pgn) parts.push(pgn);
    return [name, ...parts].join(" · ");
  }
  if (m[1] === "N" || m[1] === "A") {
    const n = /^([cgpo])?([mfbc])?([spd])?([acd])?/.exec(rest);
    const kind = n?.[1] === "p" ? "proper " : "";
    const detail = [n?.[2] ? H_GENDER[n[2]] : "", n?.[3] ? H_NUMBER[n[3]] : "", n?.[4] ? H_STATE[n[4]] : ""].filter(Boolean).join(" ");
    const label = kind ? `Proper ${name.toLowerCase()}` : name;
    return detail ? `${label} · ${detail}` : label;
  }
  return name;
}

export const parsing = (language: string, morph: string) => (language === "grc" ? greekParsing(morph) : hebrewParsing(morph));
