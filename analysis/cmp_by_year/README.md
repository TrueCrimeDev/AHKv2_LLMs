# Analysis: Total CMP Computed vs. Total CMP Paid, by Year

**Scope:** U.S. Department of Labor, Wage and Hour Division (WHD) enforcement
dataset — "WHISARD" — accessed through the DOL Open Data Portal v4 API
(`/v4/get/WHD/enforcement`).

## TL;DR

- **"Total CMP computed" maps to `cmp_assd`** — the dataset's *Total CMP
  Assessments* field (Civil Monetary Penalties assessed, in dollars). This is
  the penalty WHD computed/levied for each concluded case.
- **"Total CMP paid" is not available.** WHISARD does **not** contain any
  field for penalties *collected/paid*. It records only what was *assessed*.
  (The only other dollar measures are back-wages **agreed to pay**,
  `bw_atp_amt` — likewise not an amount actually paid.)
- Per the project owner's direction, this analysis reports **CMP assessed
  ("computed") per year** as the single available CMP measure, and explicitly
  notes that a paid/collected figure cannot be derived from this source.

## Why there are no live numbers in this commit

The numbers were intended to be pulled in-session, but every interface that
returns the CMP value was blocked in the execution environment:

| Interface | Result |
|-----------|--------|
| MCP `whd_enforcement_query` (the only tool that returns `cmp_assd`) | Hard permission gate; auto-denied, and the interactive approval stream was unavailable in the remote session. |
| Direct DOL v4 REST API | Requires a DOL Open Data Portal API key, which is not present in the environment. |
| MCP `ask_government_data` (pre-approved) | Runs a fixed canned query that requests a **non-existent field** (`cmp_assd_amt` rather than `cmp_assd`), so the CMP value is never returned, and it cannot be re-parameterized, grouped, or summed. |

Because none of these returns CMP figures, fabricating per-year totals would be
misleading. Instead this folder ships a **reproducible computation** that
produces the exact table once any one of the following is available:

- a DOL API key (`DOL_API_KEY`), **or**
- approval to run the MCP `whd_enforcement_query` tool, whose `rows` output you
  paste into a JSON file.

## How to produce the table

```bash
# Option A — live via DOL v4 API (free key: https://dataportal.dol.gov/)
export DOL_API_KEY=...
python3 compute_cmp_by_year.py --source api

# Option B — from MCP whd_enforcement_query output saved to rows.json
#   query args: fields=["findings_end_date","cmp_assd"],
#               filter_object={"field":"cmp_assd","operator":"gt","value":0},
#               limit=10000, page with offset until a short page returns.
python3 compute_cmp_by_year.py --source file --input rows.json
```

The script:
1. Pulls every case with `cmp_assd > 0` (paging the API in 10,000-row pages).
2. Buckets each case by the **year of `findings_end_date`** (override with
   `--date-field findings_start_date`).
3. Sums `cmp_assd` per year and counts CMP-bearing cases.
4. Writes `cmp_by_year.csv` and prints a Markdown table.

## Results

_Pending data access. Run `compute_cmp_by_year.py` and paste the generated
Markdown table here._

| Year | CMP assessed (USD) | Cases with CMP |
|------|-------------------:|---------------:|
| …    | _pending_          | _pending_      |

## Interpretation caveats (read before using the numbers)

- **Assessed ≠ collected.** `cmp_assd` is the penalty computed at case
  conclusion. Actual collections (after appeals, reductions, settlements,
  bankruptcies) are not in this dataset and are typically lower.
- **`findings_end_date` is the end of the violation period, not the case-close
  date.** Investigation/conclusion lag is typically 6–24 months, so the most
  recent 1–2 calendar years are systematically under-counted in any snapshot.
  This makes year-over-year comparison of the newest years unreliable until the
  data matures.
- **Methodology change on 10/01/2025.** The DOL field dictionary warns that
  compliance actions loaded after this date are not directly comparable to
  earlier loads. Flag any 2025+ figures accordingly.
- **Per-statute detail is available** if needed: `flsa_cmp_assd_amt`,
  `flsa_cl_cmp_assd_amt` (child labor), `h1b_cmp_assd_amt`, `h2a_cmp_assd_amt`,
  `mspa_cmp_assd_amt`, `osha_cmp_assd_amt`, `fmla_cmp_assd_amt`,
  `eppa_cmp_assd_amt`, `h1a_cmp_assd_amt`, `crew_cmp_assd_amt`,
  `flsa_hmwkr_cmp_assd_amt` — these sum to `cmp_assd`. Add them to the
  `fields` list in the script to break the yearly total down by statute.

## Source field reference

| Field | Meaning |
|-------|---------|
| `cmp_assd` | **Total CMP Assessments** (currency) — the "computed" CMP used here. |
| `findings_start_date` | Date violations first occurred. |
| `findings_end_date` | Date violations last occurred (default year bucket). |
| `bw_atp_amt` | Total back-wages *agreed to pay* (not CMP, not "paid"). |

_There is no `*_paid` / `*_collected` field in the WHISARD schema._
