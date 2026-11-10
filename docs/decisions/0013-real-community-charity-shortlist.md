# Real Community nominees — November 10, 2026

The owner requests replacing the fictional Community profiles with researched women's causes in the US, Africa, Europe and Asia. The initial shortlist is Dress for Success Worldwide, CAMFED, Women's Aid Federation of England, and Educate Girls US (India programs). Official program and accountability sources, image provenance and rollout are recorded in `docs/community-charities.md`.

Open a nonbinding monthly preference ballot in staging and, after owner deployment, production. A vote helps guide future giving; it does not guarantee a grant, transfer money or imply partnership. Retain the owner-reported historical $7,350 giving aggregate without attributing it to these new nominees. Actual recipient checks and grant payments remain owner responsibilities.

Use distinct charity IDs and `YYYY-MM-charities-v1` rounds. Preserve legacy fixture votes without converting them into real votes. Migration 0015 extends the candidate constraint; server validation admits only the current shortlist. No schema edits to applied migration 0013.

Use licensed, representative stock photography with a clear caption, official-site links, and no fabricated beneficiary stories. We have no permission to reuse charity-owned photos or logos. Production remains a human-run migration/deploy, and the matching native update must be tested first because photos and copy are bundled.
