---
description: Populate the archive for a company with the last 3 years (~6 half-yearly, or 3 annual) of results documents and structured financials, so future comparisons have real history to work against.
---

Usage: `/backfill-archive <TICKER>`

1. Resolve `<TICKER>` against `config/companies.yaml`.

2. Spawn **document-fetcher** in backfill mode: fetch and archive the last
   6 half-yearly periods (or last 3 annual periods, per the entity's
   `reporting_cadence`), oldest first.

3. For each archived period, in order, spawn **financial-data-extractor**.
   Running oldest-first matters — the continuity checks in the extractor
   (e.g. opening debt = prior closing debt) only work if earlier periods
   are already on disk when later ones are processed.

4. After all periods are populated, do a final continuity pass: load all
   structured-financials.yaml files for this ticker and confirm the
   balance sheet roll-forward is internally consistent across the full
   set. Report any discontinuities found (could be genuine restatements,
   or extraction errors worth re-checking).

5. Report a summary: periods successfully archived, any documents that
   couldn't be located, and any extraction_flags raised across the set.

## Notes
- This is a heavier, slower command than `/analyse-earnings` — expect it to
  take meaningfully longer given the volume of documents. Run per-company,
  not as a single call across the whole cares list, to keep search/tool-call
  volume manageable per session (same lesson as news-crawler's search cap
  issue — batch, don't blast).
- Safe to re-run: existing periods are skipped unless force-refresh is
  requested.
