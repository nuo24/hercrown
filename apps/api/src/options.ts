// Onboarding and Settings choices, copied from specs/content-fixtures.json.
// The client shows these strings; the API only accepts values from these lists.

export const INTENTIONS = [
  "Grow closer to God",
  "Build a reading habit",
  "Explore the Bible for the first time",
  "Find encouragement",
] as const;

export const FAMILIARITY = ["Just getting started", "A little familiar", "I read regularly"] as const;

export const TOPICS = [
  "Peace",
  "Purpose",
  "Faith",
  "Relationships",
  "Identity",
  "Anxiety",
  "Gratitude",
  "Hope",
  "Wisdom",
] as const;

export const ROUTINES = ["2 minutes", "5 minutes", "10 minutes", "No time goal"] as const;

export const APPEARANCES = ["light", "dark", "system"] as const;
export const FONT_SIZES = ["default", "large", "larger", "largest"] as const;

/** Current onboarding flow version (prototype `flowVersion`). */
export const ONBOARDING_VERSION = 2;
