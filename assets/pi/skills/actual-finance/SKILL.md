---
name: actual-finance
description: Use when the user asks anything about money — spending, purchases, payees, accounts, transactions, subscriptions, bills, recurring payments, budgets, or the Actual budget. Gathers data only via the get_transactions and find_recurring tools.
---

# Actual Finance

Answer financial questions using ONLY the `get_transactions` and `find_recurring` tools. They query the user's Actual budget (read-only, over ssh into the nyx cache).

## Rules

- Never produce money figures without a tool call. An answer without tool results is wrong.
- Never answer from memory or guess amounts, totals, or cadences.
- Do not inspect the local file system, search the repo, or run shell commands to find financial data. The tools are the only source.
- If a question cannot be answered with these tools, say so plainly instead of exploring the local system.

## Recipes

**Spending / transaction questions** → `get_transactions`:
- Narrow the date range first with `start_date` / `end_date` (inclusive `YYYY-MM-DD`).
- Keep `limit` at 25 or less (results share an 8192-token context); raise only if the first page is insufficient, max 50.
- Paginate with `offset` while `total_matches` exceeds the returned rows.
- Filters: `payee_contains` (case-insensitive substring), `category` (exact), `account` (exact), `kind` (exact type tag).
- Every row carries a `kind` tag: rent, mortgage, utilities, internet, phone, insurance, streaming, subscription, fuel, income, other — use `kind` to pull e.g. all utility payments in one call.
- `kind` comes from your Actual category first (categories named Rent, Utilities, Income, ... decide directly); payee/bank-description keywords are only a fallback when the category is generic (Bills, Other). If a `kind` looks wrong, recategorize the transaction in Actual — that beats re-querying.
- Amounts are precomputed currency units: negative = money out, positive = money in.
- Split transactions are expanded to their parts; tombstoned rows are excluded.

**Subscriptions / bills / repeating payments** → `find_recurring`:
- Default `min_occurrences` 3 is a good start: candidates are tagged with a `kind` and bill-like kinds (rent, mortgage, utilities, internet, phone, insurance, streaming, subscription) sort ahead of high-frequency noise, so rent and utilities surface even with few occurrences.
- Pass `kind` (e.g. `"utilities"`) to focus on one type; lower `min_occurrences` to 2 only for bills with short history; default limit 12 (max 40).
- Candidates are per payment stream, not per payee: one payee can yield several candidates (e.g. a fixed rent charge and a smaller recurring fee as two separate monthly lines). Report each stream with its own amount and cadence — do not merge them.
- A candidate is only kept if its amounts are consistent (spread ≤ 1.5× the median) — wildly varying charges like assorted game-store purchases are discarded and counted in the `note`; never re-add them by digging through `get_transactions`.
- Occurrence counts, cadence, median interval, and fixed/min/max/avg amounts are computed server-side — narrate them, never recompute or scan `get_transactions` pages looking for repetition yourself.

## Reporting

- Every result includes `cache_synced_at`. If it predates recent bank activity, say so and suggest refreshing with `sudo systemctl start finance-summary.service` on nyx instead of guessing at fresh numbers.
- Keep pages small and respect the shared 8192-token context: one narrow query beats one broad one.
