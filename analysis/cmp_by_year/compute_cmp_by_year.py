#!/usr/bin/env python3
"""
Total CMP assessed ("computed") per year — DOL WHD Enforcement (WHISARD).

Background
----------
The U.S. Department of Labor Wage and Hour Division (WHD) enforcement dataset
("WHISARD") records, for each concluded compliance action, the Civil Monetary
Penalties (CMP) *assessed*. The relevant field is:

    cmp_assd  -  "Total CMP Assessments" (currency, dollars)

There are also per-statute CMP breakdown fields (flsa_cmp_assd_amt,
h1b_cmp_assd_amt, osha_cmp_assd_amt, mspa_cmp_assd_amt, ...) whose total
equals cmp_assd.

IMPORTANT — "computed" vs "paid":
    WHISARD tracks the penalty *assessed* (i.e. computed/levied), NOT the
    amount ultimately *collected/paid*. There is no "CMP paid" field anywhere
    in this dataset. This script therefore reports CMP **assessed** per year,
    which is the only CMP money measure the source exposes. Treat "total CMP
    computed" == cmp_assd. "Total CMP paid" is not available from WHISARD.

Year attribution:
    Cases are bucketed by the YEAR of `findings_end_date` (the date the
    violations stopped occurring) by default. Note this is NOT the case-close
    date; investigation lag from end-of-violation to case conclusion is
    typically 6-24 months, so the most recent 1-2 years are under-counted in
    any snapshot of the dataset. Use --date-field findings_start_date to bucket
    by when violations began instead.

Data collection note (from the DOL field dictionary):
    A change in data-collection procedures occurred on 10/01/2025; counts/
    measures loaded after that date are not directly comparable to earlier ones.

Usage
-----
1) Live, against the DOL v4 API (requires a free DOL Open Data Portal key):

       export DOL_API_KEY=...      # https://dataportal.dol.gov/
       python3 compute_cmp_by_year.py --source api

2) From a JSON file exported via the MCP `whd_enforcement_query` tool
   (run that tool with fields=["findings_end_date","cmp_assd"],
   filter_object={"field":"cmp_assd","operator":"gt","value":0}, paging by
   offset in 10000-row pages, and concatenate the `rows` arrays into a JSON
   list or {"rows":[...]} file):

       python3 compute_cmp_by_year.py --source file --input rows.json

Outputs cmp_by_year.csv and prints a Markdown table to stdout.
"""
import argparse
import csv
import json
import os
import sys
import urllib.parse
import urllib.request
from collections import defaultdict

API_BASE = "https://apiprod.dol.gov/v4/get/WHD/enforcement/json"
PAGE = 10000  # DOL max rows per request


def fetch_api(api_key):
    """Page through every case with cmp_assd > 0, yielding row dicts."""
    offset = 0
    flt = json.dumps({"field": "cmp_assd", "operator": "gt", "value": 0})
    while True:
        params = {
            "limit": PAGE,
            "offset": offset,
            "fields": "case_id,cmp_assd,findings_start_date,findings_end_date",
            "filter_object": flt,
            "sort": "asc",
            "sort_by": "case_id",
            "X-API-KEY": api_key,
        }
        url = API_BASE + "?" + urllib.parse.urlencode(params)
        with urllib.request.urlopen(url, timeout=120) as resp:
            payload = json.loads(resp.read().decode())
        rows = payload if isinstance(payload, list) else payload.get("rows", [])
        if not rows:
            break
        for r in rows:
            yield r
        if len(rows) < PAGE:
            break
        offset += PAGE


def load_file(path):
    with open(path) as fh:
        data = json.load(fh)
    if isinstance(data, dict):
        # accept either {"rows":[...]} or the full MCP/ask_government_data envelope
        data = data.get("rows") or data.get("result", {}).get("rows") or []
    return data


def year_of(value):
    if not value:
        return None
    # accepts "2023-06-22T00:00:00" or "2023-06-22"
    return value[:4]


def aggregate(rows, date_field):
    totals = defaultdict(float)
    counts = defaultdict(int)
    skipped = 0
    for r in rows:
        yr = year_of(r.get(date_field))
        amt = r.get("cmp_assd")
        if yr is None or amt is None:
            skipped += 1
            continue
        try:
            amt = float(amt)
        except (TypeError, ValueError):
            skipped += 1
            continue
        if amt <= 0:
            continue
        totals[yr] += amt
        counts[yr] += 1
    return totals, counts, skipped


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", choices=["api", "file"], default="api")
    ap.add_argument("--input", help="JSON file when --source file")
    ap.add_argument("--date-field", default="findings_end_date",
                    choices=["findings_end_date", "findings_start_date"])
    ap.add_argument("--out", default="cmp_by_year.csv")
    args = ap.parse_args()

    if args.source == "api":
        key = os.environ.get("DOL_API_KEY")
        if not key:
            sys.exit("ERROR: set DOL_API_KEY (free key from https://dataportal.dol.gov/).")
        rows = list(fetch_api(key))
    else:
        if not args.input:
            sys.exit("ERROR: --input required when --source file.")
        rows = load_file(args.input)

    totals, counts, skipped = aggregate(rows, args.date_field)

    grand = sum(totals.values())
    grand_n = sum(counts.values())

    with open(args.out, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["year", "cmp_assessed_usd", "cases_with_cmp"])
        for yr in sorted(totals):
            w.writerow([yr, f"{totals[yr]:.2f}", counts[yr]])
        w.writerow(["TOTAL", f"{grand:.2f}", grand_n])

    # Markdown table to stdout
    print(f"# Total CMP assessed per year (bucketed by {args.date_field})\n")
    print(f"Rows processed: {len(rows):,} | skipped (missing year/amount): {skipped:,}\n")
    print("| Year | CMP assessed (USD) | Cases with CMP |")
    print("|------|-------------------:|---------------:|")
    for yr in sorted(totals):
        print(f"| {yr} | {totals[yr]:,.0f} | {counts[yr]:,} |")
    print(f"| **TOTAL** | **{grand:,.0f}** | **{grand_n:,}** |")


if __name__ == "__main__":
    main()
