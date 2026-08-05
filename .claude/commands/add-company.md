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

3. Automatically run `/backfill-archive <ticker>` immediately after creating
   the folder — don't ask whether to do it now or later. Same reasoning as
   `/analyse-earnings`: this command may run headlessly (e.g. triggered
   remotely) with no one able to answer a question, so a sensible default
   (backfill now) beats a blocking ask. State in the completion summary that
   a backfill was kicked off automatically.

4. Confirm the addition and, if relevant, remind the user this ticker can
   now also be triggered via Telegram using any of its configured aliases.
