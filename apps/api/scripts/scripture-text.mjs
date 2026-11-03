// Shared by the Scripture builds: words-of-Jesus markers → UTF-16 [start, length] ranges.
// UTF-16 offsets match JavaScript string indices and Swift NSRange/NSString on iOS.

export const WJ_OPEN = "\u0001";
export const WJ_CLOSE = "\u0002";

/** Removes WJ markers, collapses whitespace, and returns [text, ranges | null]. */
export function finishVerse(marked) {
  // Keep spaces outside the markers so removing them can't leave a double space.
  const spaced = marked
    .replace(/\s*\u0001\s*/g, (m) => (/\s/.test(m) ? " " : "") + WJ_OPEN)
    .replace(/\s*\u0002\s*/g, (m) => WJ_CLOSE + (/\s/.test(m) ? " " : ""))
    .replace(/\s+/g, " ").trim();
  let out = "", start = -1;
  const ranges = [];
  const pushRange = (from, to) => {
    while (from < to && out[from] === " ") from++;
    while (to > from && out[to - 1] === " ") to--;
    if (to <= from) return;
    const last = ranges.at(-1);
    if (last && from - (last[0] + last[1]) <= 1) last[1] = to - last[0]; // merge adjacent spans
    else ranges.push([from, to - from]);
  };
  for (const ch of spaced) {
    if (ch === WJ_OPEN) { if (start < 0) start = out.length; continue; }
    if (ch === WJ_CLOSE) { if (start >= 0) pushRange(start, out.length); start = -1; continue; }
    out += ch;
  }
  if (start >= 0) pushRange(start, out.length);
  return [out.trim(), ranges.length ? ranges : null];
}
