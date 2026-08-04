# earnings-analyser

Sibling project to `news-crawler`. Archives half-yearly/annual results
releases per company on the cares list and produces a structured 5-section
earnings-quality analysis on command, or when a new release is detected via
a Telegram message.

## One-time setup
1. Copy this folder structure into a new repo/folder, same pattern as
   news-crawler (`.claude/agents`, `.claude/commands`, `config/`).
2. Fill out `config/companies.yaml` — either hand-populate the remaining
   cares-list entities, or (recommended) point this file's `entities` list
   at the same tickers already maintained in news-crawler's
   `config/cares-list.yaml` so the two projects don't drift apart.
3. Confirm `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are already set as
   environment variables (reused from news-crawler).
4. Install Python deps for the PDF/Telegram scripts:
   ```
   pip install markdown xhtml2pdf requests pyyaml
   ```
   (xhtml2pdf is pure Python — no separate GTK/Pango install needed, unlike
   WeasyPrint, so this should install cleanly with just pip.)
5. Confirm the FactSet MCP connector is available in this Claude Code
   environment (`claude mcp list`) — it's the consensus-estimate source the
   extractor agent relies on. Without it, consensus comparisons will be
   marked "not available" rather than guessed.

## Backfilling history (do this first, per company)
```
/backfill-archive SKS
/backfill-archive GNP
...
```
Run one company at a time — same lesson as news-crawler's search-cap issue,
batching per-company keeps tool-call volume manageable.

## Running an analysis
Locally (Claude Code, at your desktop):
```
/analyse-earnings SKS
```
or for a specific historical period:
```
/analyse-earnings SKS FY26H1
```

Remotely via Telegram: send a message like "analyse the result from SKS
Technologies" to the bot. This requires `scripts/telegram_listener.py`
running continuously (see below) — it polls Telegram, matches the company
name against `config/companies.yaml` aliases, and invokes the same
`/analyse-earnings` command non-interactively.

## Keeping the Telegram trigger live
The listener needs to be running on a machine that's on. Two options:
- **Windows Task Scheduler**: create a task triggered "at log on," action
  `python scripts/telegram_listener.py`, set to restart on failure.
- **Manual**: run `python scripts/telegram_listener.py` in a terminal you
  leave open.

Claude Code Routines are cron-like (minimum 1-hour interval) and aren't a
good fit for near-real-time Telegram triggering — the polling script is the
right tool for "responds within seconds of a message," Routines are the
right tool for "runs every morning regardless."

## Adding a new company
```
/add-company XYZ ASX "Example Company Limited"
```

## Output
Every analysis run writes:
- `archive/<TICKER>/analysis/<PERIOD>-earnings-analysis.md`
- `archive/<TICKER>/analysis/<PERIOD>-earnings-analysis.pdf`
- and sends the PDF to Telegram (unless run without delivery).
