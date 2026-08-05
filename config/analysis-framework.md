# Earnings analysis framework (fixed spec)

Every earnings-analysis run must produce all five sections below, in this
order, for the target company/period. Agents pull from:
- `archive/<TICKER>/<PERIOD>/structured-financials.yaml` (current period)
- the same file in the prior 5 periods available (HoH and YoY/PCP)
- the raw PDFs in each period folder (for commentary/tone/notes text)
- FactSet MCP for consensus, where available

Comparatives required throughout: **HoH** (vs immediately prior half), **YoY/PCP**
(vs same half last year), and **vs consensus/market expectations**. Every
comparison needs a number AND a one-line "why" — never a table with no
commentary, never commentary with no number behind it.



---

## 0. Executive summary (page 1 — read this section standalone)

Sits at the very top of the report, before Section 1, written by
report-synthesizer after all four analysis agents' outputs are in — same
timing as Section 5, just reordered to the front and compressed hard for a
30-60 second read on reporting day. **Hard length ceiling: roughly half a
page to one page.** This is a constraint to enforce, not an aspiration —
if it's running long, cut findings, don't shrink the font.

**Non-negotiable rule: the executive summary may not contain any claim or
number that doesn't also appear, fully sourced, in Sections 1-5 below.**
It is a distillation and reordering of the same material, never a separate
or additional analysis pass. Preserve hedging/uncertainty language exactly
as it appears in the full sections — don't strip "n/a" or "not confirmed"
qualifiers for the sake of brevity.

Required contents, in this order:

1. **One-sentence verdict**: beat/miss/in-line vs PCP (and vs consensus,
   when available), guidance status (raised/reiterated/cut/withdrawn/none),
   and a one-phrase quality-of-earnings read (clean / structurally soft /
   acutely flagged).
2. **Compact scorecard table**: Revenue, EBITDA (or the company's primary
   EBITDA variant), NPAT, EPS only — HoH%, YoY%, vs-consensus columns.
   No margins, no PBT/tax breakdown, no segment detail — that's what
   Section 1's full table is for.
3. **Guidance snapshot** (omit entirely if no guidance was given): status,
   and the bridge/asymmetry call in one line — e.g. "H2 needs only +X% YoY
   vs H1's own +Y% delivered — an easy/hard bar."
4. **Top 3-5 ranked findings**, one line each, each tagged with a section
   cross-reference (e.g. "(§2.1)") so the reader can jump straight to the
   source discussion. Pulled from the same material Section 5.1 covers, but
   capped at 5 and ordered strictly by decision-relevance — not by which
   section they happened to come from.
5. **Tone/topic shift** — one sentence.
6. **Market reaction view** — 2-3 sentences max, condensed from Section
   5.3, same "this is a view, not a prediction" framing preserved.
7. **"Read past the headline" callout** — 1-3 bullets, formatted as a
   markdown blockquote (renders as a shaded callout in the PDF), covering
   only the items where a reader who stops at the press release would be
   genuinely misled. This is the single highest-value piece of the whole
   summary — the asymmetric-setup flag the framework already requires,
   surfaced where it will actually get read on a busy reporting day.

---

## 1. Profitability analysis

**Table:** Revenue (divisional breakdown where the company reports segments),
gross margin, EBITDA + EBITDA margin, EBIT, PBT, NPAT — current period vs
prior half, vs PCP half, vs consensus. Include $ and % variance columns.

**Commentary requirements:**
- Explain the *drivers* behind each material variance, not just the direction.
- Cross-reference how the company's own description of the same driver has
  changed since the prior period(s) — quote sparingly (max one short phrase
  per source, per copyright limits) but characterise the shift: e.g. "more
  confident framing around backlog conversion than prior half" or "growth
  language has been replaced by cost-discipline language."
- **Quality of earnings**: identify anything that flatters underlying
  earnings — cost normalisation add-backs, provision releases, one-off
  gains, favourable FX/derivative marks, changes to capitalisation policy
  (e.g. capitalised vs expensed costs), changes to depreciation/useful life
  assumptions, related-party pricing. For each item found, state the $ impact
  and compare to whether the same *type* of adjustment appeared in prior
  periods (recurring "one-offs" are a flag in themselves).
- **Guidance analysis** (if guidance given): state the quantitative guidance
  range, bridge it from the exit run-rate of the just-reported half (annualise
  H2 or state why not), and list the specific puts and takes (positive and
  negative) needed to hit it. Compare the guidance to consensus/market
  expectations at time of release — beat, miss, or in-line, and by how much.
  Flag asymmetries: where's the realistic upside, where's the real risk.

## 2. Balance sheet analysis

- Working capital: debtors, creditors, inventory — level and days-based
  measures (DSO/DPO/DIO or turnover) relative to revenue growth, vs prior
  periods. Flag any divergence between working capital growth and sales
  growth as a cash-conversion signal.
- Gearing and debt: net debt, gearing ratio, facility maturities, repayment
  schedule, interest rate mix (fixed/floating), hedging in place, and
  headroom vs covenants — sourced from the notes in current AND prior
  periods' financial statements (maturity profiles shift release to release;
  track what rolled off, what got refinanced, on what terms).
- Other balance sheet movements: provisions (and their P&L impact — links
  back to QoE in section 1), write-backs/write-offs, contract
  assets/liabilities, goodwill/intangible carrying values, and anything else
  material to interpreting underlying performance.

## 3. Cash flow analysis

- Cash conversion: EBITDA-to-operating-cashflow conversion ratio, current vs
  prior periods, with the specific working capital drivers behind any
  change.
- Capex: split growth vs maintenance capex where disclosed; compare
  intensity (capex/revenue or capex/EBITDA) to prior periods.
- M&A, financing, and other cash flows: acquisitions, debt drawdown/
  repayment, equity raised/returned, dividends — material items only.
- Compare actual cash performance to consensus/market expectations where a
  source exists (e.g. FactSet FCF/capex estimates); call out beats/misses.

## 4. Other disclosure analysis

Read the full notes to the financial statements (not just the headline
release/presentation) for the current period and flag changes vs prior
periods in:
- Related party transactions/disclosures
- Impairments or credit losses (new, reversed, or changed methodology)
- Segment/divisional reporting structure changes (a restructure can mask or
  reveal underlying trends — always note when segment definitions change)
- Contracts flagged as loss-making, under review, or otherwise
  non-performing
- Any other note-level item material to interpreting the result that
  wouldn't show up in the headline P&L/balance sheet/cash flow tables

## 5. Summary analysis

- Synthesise the key findings from sections 1–4 into a short, ranked list —
  most material items first.
- Qualitative tone/topic assessment: compare the language, structure, and
  emphasis of this period's investor presentation and results announcement
  against prior periods' equivalents. What's new in the topics covered? What
  dropped off? Has tone shifted (more/less confident, more/less detail on a
  given segment, changed order of emphasis)? This is a genuine textual
  comparison against archived prior documents, not a generic read of the
  current release alone.
- Market reaction view: given everything above (results vs consensus,
  guidance vs consensus, QoE quality, balance sheet/cash flow signals, tone
  shift), give a view on the likely market reaction and the reasoning
  behind it. Flag if the setup looks asymmetric (e.g. headline beat but
  poor quality of earnings, or headline miss but conservative guidance
  with genuine upside skew).

---

## Formatting rules for the final report
- Tables first, then commentary, in each section — never text-only where a
  table is asked for.
- Every number in a table must be traceable to a structured-financials.yaml
  entry or a named consensus source; no unattributed figures.
- Keep commentary succinct — bullet points over paragraphs where possible.
- Explicitly label anything that is an estimate, an inference, or unavailable
  — do not present inferred numbers as confirmed.
