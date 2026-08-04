# earnings-analyser — standing rules

## Purpose
Sibling project to `news-crawler`. Where news-crawler tracks daily newsflow across
the cares list, this project archives and analyses **half-yearly/annual results
releases** (financial statements, investor presentations, appendix 4D/4E,
transcripts) for the same cares list, and produces a structured earnings-quality
report on command or on new-release detection.

## Repo map
```
CLAUDE.md, README.md
config/
  companies.yaml            - master entity list (ticker, exchange, cadence, etc.)
  analysis-framework.md     - the fixed analytical spec every agent must follow
archive/
  <TICKER>/
    <PERIOD>/                - e.g. FY24H1, FY24H2, FY25H1 ...
      results-announcement.pdf
      financial-statements.pdf
      investor-presentation.pdf
      appendix-4d.pdf        (or 4E for annual)
      transcript.pdf         (if available)
      metadata.yaml          - source URLs, release datetime, period label
      structured-financials.yaml  - extracted comparable figures (see extractor agent)
    analysis/
      <PERIOD>-earnings-analysis.md
      <PERIOD>-earnings-analysis.pdf
.claude/
  agents/    - subagents, one per analytical function
  commands/  - slash command orchestrators
scripts/     - Telegram listener, PDF export, delivery
reports/     - not used for output (reports live in archive/<TICKER>/analysis/);
               kept only for ad-hoc cross-company notes
```

## Style
Terse, evidence-graded, institutional. No filler, no hedging where the evidence
is clear. State plainly when a figure is confirmed vs estimated vs unavailable.
Never fabricate a consensus number — if no consensus source is available for a
line item, say so explicitly rather than inferring one.

## Non-negotiable conventions
- Period naming: `FY<YY>H1` / `FY<YY>H2` for half-years, `FY<YY>` for full year,
  matching the company's own fiscal year end (see `config/companies.yaml`).
- All comparatives: HoH (vs immediately preceding half), YoY/PCP (vs same half
  prior year), and vs consensus/market expectations where a source exists.
- Currency: report in the company's reporting currency (AUD or NZD per
  `config/companies.yaml`); never silently convert.
- Every structured-financials.yaml write must record the **source document and
  page/note reference** for each figure pulled — no unattributed numbers.
- Before writing a new period's structured-financials.yaml, an agent must load
  and diff against the prior period(s) in the same archive folder — comparisons
  are the point of this whole pipeline, not an afterthought.
- If a figure can't be confidently extracted (e.g. scanned/non-searchable PDF,
  ambiguous segment mapping), flag it in metadata.yaml under `extraction_flags`
  rather than guessing.
- Consensus/market expectations: prefer FactSet MCP (already connected) for
  consensus EPS/revenue/EBITDA where available. If FactSet doesn't have a
  clean read for a specific line item (e.g. divisional revenue splits are
  rarely covered by consensus), say "no consensus available for this line"
  rather than inventing one from web search.
- PR-based commits, same as news-crawler, if branch push restrictions apply
  in this repo too.
