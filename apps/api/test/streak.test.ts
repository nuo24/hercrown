// Same cases as reference-web/streak.test.mjs, plus milestones.
import { describe, expect, it } from "vitest";
import { localDayIn, streakSummary } from "../src/streak";

describe("streakSummary (ported from the prototype)", () => {
  const days = ["2026-10-31", "2026-11-01", "2026-11-02"];

  it("matches the prototype's calendar rules", () => {
    expect(streakSummary([], "2026-11-02").current).toBe(0);
    expect(streakSummary(days, "2026-11-02").current).toBe(3);
    expect(streakSummary(days, "2026-11-03").current).toBe(3); // last read yesterday: still current
    expect(streakSummary(days, "2026-11-04").current).toBe(0); // a full missed day breaks it
    expect(streakSummary([...days, "2026-11-04"], "2026-11-04").best).toBe(3);
    expect(streakSummary(["bad", "2026-02-30", "2027-01-01"], "2026-11-02").best).toBe(0); // invalid + future ignored
    expect(streakSummary(days, "2026-11-02").week.filter((d) => d.read)).toHaveLength(3);
  });

  it("counts duplicate days once and reports today", () => {
    const s = streakSummary([...days, "2026-11-02", "2026-11-02"], "2026-11-02");
    expect(s).toMatchObject({ current: 3, best: 3, readToday: true });
    expect(streakSummary(days, "2026-11-03").readToday).toBe(false);
  });

  it("crosses month and leap-year boundaries", () => {
    expect(streakSummary(["2028-02-28", "2028-02-29", "2028-03-01"], "2028-03-01").current).toBe(3);
    expect(streakSummary(["2026-12-31", "2027-01-01"], "2027-01-01").current).toBe(2);
  });

  it("returns the week ending today", () => {
    const { week } = streakSummary(["2026-11-02"], "2026-11-02");
    expect(week.map((d) => d.day)).toEqual(["2026-10-27", "2026-10-28", "2026-10-29", "2026-10-30", "2026-10-31", "2026-11-01", "2026-11-02"]);
    expect(week.at(-1)).toEqual({ day: "2026-11-02", read: true });
  });

  it("reports the highest milestone reached", () => {
    const run = (n: number) => Array.from({ length: n }, (_, i) => new Date(Date.UTC(2026, 0, 1) + i * 86_400_000).toISOString().slice(0, 10));
    expect(streakSummary(run(6), run(6).at(-1)!).milestone).toBeNull();
    expect(streakSummary(run(7), run(7).at(-1)!).milestone).toBe(7);
    expect(streakSummary(run(45), run(45).at(-1)!).milestone).toBe(30);
  });

  it("finds the local day in a time zone", () => {
    const instant = new Date("2026-11-02T03:00:00Z");
    expect(localDayIn("UTC", instant)).toBe("2026-11-02");
    expect(localDayIn("America/Los_Angeles", instant)).toBe("2026-11-01");
    expect(localDayIn("Asia/Tokyo", instant)).toBe("2026-11-02");
  });
});
