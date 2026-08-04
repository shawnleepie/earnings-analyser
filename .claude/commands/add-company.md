---
description: Add a new company to the earnings-analyser cares list and create its archive folder, optionally kicking off a backfill.
---

Usage: `/add-company <TICKER> <EXCHANGE> "<FULL NAME>"`

1. Append a new entry to `config/companies.yaml` following the existing
   schema. Ask the user for (or infer conservatively and flag for
   confirmation) fiscal_year_end, reporting_cadence, currency, and sector if
   not supplied — do not guess segment structure, leave `segments: []` until
   the first extraction confirms it.

2. Create `archive/<ticker>/` (empty — document-fetcher populates it).

3. Ask whether to run `/backfill-archive <ticker>` now or later; if the user
   confirms now, run it.

4. Confirm the addition and, if relevant, remind the user this ticker can
   now also be triggered via Telegram using any of its configured aliases.
