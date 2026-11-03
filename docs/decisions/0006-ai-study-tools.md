# 0006 · AI study tools

**Date:** 2026-11-03 · **Status:** approved; design proposed

**Decision:** Build the four Plus study tools — Explain Easier, Deeper Study, Original Language, Related Verses — using every appropriate source, to beat the "AI slop" complaints about Scroll the Bible (see `docs/research/`).

**Design:**
- Ground answers in checkable sources: public-domain commentaries (Matthew Henry, Barnes, Jamieson-Fausset-Brown, Adam Clarke), STEPBible lexicon/morphology data (CC BY, Tyndale House) for Greek/Hebrew, OpenBible.info cross-references (CC BY) for Related Verses.
- Model: DeepSeek via OpenRouter behind Cloudflare AI Gateway (playbook). Server-side only; logged with cost.
- Generate once per verse + tool, store, review, serve the same answer to everyone; fix wrong answers permanently. Show citations and an "AI-assisted" label. Never alter Scripture.
- Copyrighted teachers (e.g. Andrew Wommack's Living Commentary) only with a written license from the rights holder.
