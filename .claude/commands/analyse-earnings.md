---
description: Run the full earnings analysis workflow for a company — fetch the latest (or a named) release, extract structured financials, run all four analysis subagents, assemble the report, produce a PDF, save to archive, and deliver via Telegram.
---

Usage: `/analyse-earnings <TICKER> [PERIOD]` — omit PERIOD to fetch/analyse
the latest release not yet archived.

1. Resolve `<TICKER>` against `config/companies.yaml` (exact ticker match, or
   fuzzy match against `aliases` if invoked with a free-text company name —
   this matters for the Telegram trigger path, where people type company
   names, not tickers).

2. If `archive/<ticker>/` doesn't exist yet or has fewer than ~4 archived
   periods, warn that this ticker hasn't been backfilled and ask whether to
   run `/backfill-archive <ticker>` first — comparisons need history to be
   meaningful, and a same-session backfill is cheap insurance.

3. Spawn **document-fetcher** for `<ticker>` and the target period (or
   `latest`). Confirm the resolved period label before proceeding.

4. Spawn **financial-data-extractor** for that ticker/period.

5. In parallel, spawn:
   - **profitability-earnings-analyst**
   - **balance-sheet-cashflow-analyst**
   - **disclosure-tone-analyst**

   Each reads the current period's structured-financials.yaml plus as many
   prior periods as are archived (up to 6 halves / 3 years).

6. Spawn **report-synthesizer** with the three outputs from step 5. It
   writes the report, produces the PDF, saves both to
   `archive/<ticker>/analysis/`, and triggers Telegram delivery.

7. Confirm completion: report the resolved ticker/period, confirm the PDF
   was saved and (if applicable) sent to Telegram, and surface the one-line
   headline finding from section 5.

## Notes
- If invoked from a Telegram-triggered session (see
  `scripts/telegram_listener.py`), delivery is mandatory — don't skip the
  Telegram send step even if running non-interactively.
- If invoked locally without a delivery requirement, still write the
  archive copy; only skip the Telegram send if explicitly told to.
