import base64
import glob
import json
import os
import re
import sqlite3
import sys
from datetime import date, datetime, timedelta, timezone

MAX_PAGE = 50
MAX_RECURRING = 40
DEFAULT_RECURRING = 12
DEFAULT_PAGE = 25
RESULT_BYTE_BUDGET = 3000
TX_BYTE_BUDGET = 4000
MAX_AMOUNT_SPREAD = 1.5


def die(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def rows_of(db, table, wanted):
    cols = [c[1] for c in db.execute("PRAGMA table_info(" + table + ")")]
    have = [c for c in wanted if c in cols]
    return [dict(zip(have, r)) for r in db.execute("SELECT " + ", ".join(have) + " FROM " + table)]


def iso_date(value):
    s = str(value or "")
    if len(s) == 8 and s.isdigit():
        return s[0:4] + "-" + s[4:6] + "-" + s[6:8]
    return s


def check_date(value, name):
    if value is not None and not re.match(r"^\d{4}-\d{2}-\d{2}$", str(value)):
        raise ValueError(name + " must be YYYY-MM-DD, got: " + str(value))


def round2(n):
    return round(n + 0.0, 2)


def median(nums):
    s = sorted(nums)
    mid = len(s) // 2
    if len(s) % 2:
        return s[mid]
    return round((s[mid - 1] + s[mid]) / 2)


def cadence_label(days):
    if 5 <= days <= 8:
        return "weekly"
    if 12 <= days <= 17:
        return "every ~2 weeks"
    if 26 <= days <= 35:
        return "monthly"
    if 55 <= days <= 70:
        return "every ~2 months"
    if 85 <= days <= 100:
        return "quarterly"
    return "every ~" + str(days) + " days"


KIND_RULES = [
    ("fuel", r"gasoline|diesel|\bfuel\b|gas station|gas and fuel"),
    ("rent", r"\brent\b|\brental\b|\blease|apartment|landlord"),
    ("mortgage", r"mortgage"),
    ("utilities", r"utilit|electric|\benergy\b|\bpower\b|\blight\b|natural gas|\bgas\b|\bwater\b|\bsewer\b|\btrash\b|\bwaste\b|\bheat\b"),
    ("internet", r"internet|broadband|\bfiber\b|\bwifi\b|\bisp\b"),
    ("phone", r"mobile|\bcell\b|phone|\btelecom\b"),
    ("insurance", r"insurance"),
    ("streaming", r"streaming"),
    ("subscription", r"subscription|recurring|renewal|membership|\blicense\b|software"),
    ("income", r"payroll|salary|direct deposit|\bwages\b|\bincome\b"),
]
KIND_PRIORITY = {
    "rent": 0,
    "mortgage": 0,
    "utilities": 0,
    "internet": 0,
    "phone": 0,
    "insurance": 0,
    "streaming": 0,
    "subscription": 0,
    "income": 2,
}
KNOWN_KINDS = [k for k, _ in KIND_RULES] + ["other"]

NOTE_NOISE_CATEGORIES = {
    "groceries",
    "car",
    "investment",
    "reconciliation",
    "savings contribution",
    "starting balances",
}


def match_kind(text):
    low = (text or "").lower()
    for kind, pattern in KIND_RULES:
        if re.search(pattern, low):
            return kind
    return None


def classify(payee, imported, notes, category):
    hit = match_kind(category)
    if hit:
        return hit
    for field in (payee, imported):
        hit = match_kind(field)
        if hit:
            return hit
    hit = match_kind(notes)
    if hit and (category or "").lower() not in NOTE_NOISE_CATEGORIES:
        return hit
    return "other"


def check_kind(value):
    if value and value not in KNOWN_KINDS:
        raise ValueError("kind must be one of " + ", ".join(KNOWN_KINDS) + ", got: " + value)


def group_kind(rows):
    return min(
        rows,
        key=lambda t: (KIND_PRIORITY.get(t["kind"], 1), KNOWN_KINDS.index(t["kind"])),
    )["kind"]


def load(db_path):
    db = sqlite3.connect("file:" + db_path + "?mode=ro", uri=True)

    payees = {}
    transfer_payees = set()
    for r in rows_of(db, "payees", ["id", "name", "transfer_acct", "tombstone"]):
        if r.get("tombstone"):
            continue
        payees[r["id"]] = r.get("name") or ""
        if r.get("transfer_acct"):
            transfer_payees.add(r["id"])

    cat_names = {}
    for r in rows_of(db, "categories", ["id", "name", "tombstone"]):
        if not r.get("tombstone"):
            cat_names[r["id"]] = r.get("name") or ""

    acct_names = {}
    for r in rows_of(db, "accounts", ["id", "name", "tombstone"]):
        if not r.get("tombstone"):
            acct_names[r["id"]] = r.get("name") or ""

    txns = [
        r
        for r in rows_of(
            db,
            "transactions",
            [
                "id",
                "isParent",
                "parent_id",
                "acct",
                "category",
                "amount",
                "description",
                "imported_description",
                "notes",
                "date",
                "transferred_id",
                "tombstone",
            ],
        )
        if not r.get("tombstone")
    ]
    db.close()

    children = {}
    tops = []
    for t in txns:
        if t.get("parent_id"):
            children.setdefault(t["parent_id"], []).append(t)
        else:
            tops.append(t)

    def norm(row, parent=None):
        desc = row.get("description") or (parent or {}).get("description") or ""
        payee = payees.get(desc, "")
        category = cat_names.get(row.get("category"), "") if row.get("category") else ""
        imported = row.get("imported_description") or (parent or {}).get("imported_description") or ""
        notes = row.get("notes") or ""
        return {
            "date": iso_date(row.get("date") or (parent or {}).get("date")),
            "payee": payee,
            "category": category,
            "account": acct_names.get(row.get("acct") or (parent or {}).get("acct"), ""),
            "amount": round2((row.get("amount") or 0) / 100),
            "notes": notes,
            "transfer": desc in transfer_payees or bool(row.get("transferred_id")),
            "kind": classify(payee, imported, notes, category),
        }

    all_txns = []
    for top in tops:
        kids = children.get(top["id"]) if top.get("isParent") else None
        if kids:
            for kid in kids:
                all_txns.append(norm(kid, top))
        else:
            all_txns.append(norm(top))
    return all_txns


def in_window(t, start, end):
    if start and t["date"] < start:
        return False
    if end and t["date"] > end:
        return False
    return True


def tool_get_transactions(all_txns, params):
    check_date(params.get("start_date"), "start_date")
    check_date(params.get("end_date"), "end_date")
    sub = str(params.get("payee_contains") or "").lower()
    cat = str(params.get("category") or "").lower()
    acct = str(params.get("account") or "").lower()
    kind = str(params.get("kind") or "").lower()
    check_kind(kind)
    limit = min(max(int(float(params.get("limit", DEFAULT_PAGE))), 1), MAX_PAGE)
    offset = max(int(float(params.get("offset", 0))), 0)

    matches = [
        t
        for t in all_txns
        if in_window(t, params.get("start_date"), params.get("end_date"))
        and (not sub or sub in t["payee"].lower())
        and (not cat or t["category"].lower() == cat)
        and (not acct or t["account"].lower() == acct)
        and (not kind or t["kind"] == kind)
    ]
    matches.sort(key=lambda t: t["date"], reverse=True)
    page = matches[offset : offset + limit]
    out = []
    trimmed = 0
    for t in page:
        row = {
            "date": t["date"],
            "payee": t["payee"] or "(none)",
            "category": t["category"] or "uncategorized",
            "account": t["account"],
            "amount": t["amount"],
            "kind": t["kind"],
        }
        if t["notes"]:
            row["notes"] = t["notes"]
        out.append(row)
    while len(out) > 1 and len(json.dumps(out, separators=(",", ":"))) > TX_BYTE_BUDGET:
        out.pop()
        trimmed += 1
    result = {
        "total_matches": len(matches),
        "returned": len(out),
        "offset": offset,
        "limit": limit,
        "transactions": out,
    }
    if kind:
        result["kind"] = kind
    if trimmed:
        result["note"] = "page trimmed by " + str(trimmed) + " rows for context budget; lower limit or narrow filters"
    return result


def tool_find_recurring(all_txns, params):
    check_date(params.get("start_date"), "start_date")
    check_date(params.get("end_date"), "end_date")
    minimum = min(max(int(float(params.get("min_occurrences", 3))), 2), 24)
    limit = min(max(int(float(params.get("limit", DEFAULT_RECURRING))), 1), MAX_RECURRING)
    kind = str(params.get("kind") or "").lower()
    check_kind(kind)

    buckets = {}
    scanned = 0
    for t in all_txns:
        if t["transfer"] or not t["payee"] or t["amount"] == 0:
            continue
        if not in_window(t, params.get("start_date"), params.get("end_date")):
            continue
        scanned += 1
        buckets.setdefault((t["payee"], t["amount"]), []).append(t)

    streams = {}
    leftovers = {}
    for (payee, _amount), rows in buckets.items():
        if len({t["date"] for t in rows}) >= minimum:
            streams.setdefault(payee, []).append(rows)
        else:
            leftovers.setdefault(payee, []).extend(rows)
    for payee, rows in leftovers.items():
        if len({t["date"] for t in rows}) >= minimum:
            streams.setdefault(payee, []).append(rows)

    candidates = []
    spread_dropped = 0
    for payee, grouped in streams.items():
        for rows in grouped:
            dates = sorted({t["date"] for t in rows})
            if len(dates) < minimum:
                continue
            intervals = []
            for prev, cur in zip(dates, dates[1:]):
                delta = date.fromisoformat(cur) - date.fromisoformat(prev)
                intervals.append(delta.days)
            mid = median(intervals)
            amounts = [abs(t["amount"]) for t in rows]
            mid_amount = median(amounts)
            if (max(amounts) - min(amounts)) / mid_amount > MAX_AMOUNT_SPREAD:
                spread_dropped += 1
                continue
            same = all(a == amounts[0] for a in amounts)
            candidates.append(
                {
                    "payee": payee,
                    "kind": group_kind(rows),
                    "occurrences": len(dates),
                    "every": cadence_label(mid),
                    "median_days": mid,
                    "first": dates[0],
                    "last": dates[-1],
                    "amount": amounts[0]
                    if same
                    else {
                        "min": min(amounts),
                        "max": max(amounts),
                        "avg": round2(sum(amounts) / len(amounts)),
                    },
                }
            )
    if kind:
        candidates = [c for c in candidates if c["kind"] == kind]
    candidates.sort(
        key=lambda c: (KIND_PRIORITY.get(c["kind"], 1), -c["occurrences"], c["payee"])
    )
    picked = candidates[:limit]
    budget_hit = False
    while len(picked) > 1 and len(json.dumps(picked, separators=(",", ":"))) > RESULT_BYTE_BUDGET:
        picked.pop()
        budget_hit = True
    notes = []
    if len(candidates) > len(picked):
        notes.append(
            "showing top " + str(len(picked)) + " of " + str(len(candidates))
            + "; candidate_count is the true total"
        )
    if budget_hit:
        notes.append("context byte budget reached (" + str(RESULT_BYTE_BUDGET) + " bytes)")
    if spread_dropped:
        notes.append(
            str(spread_dropped)
            + " candidate(s) removed: amounts vary more than "
            + str(MAX_AMOUNT_SPREAD)
            + "x their median (not recurring)"
        )
    result = {
        "min_occurrences": minimum,
        "rows_scanned": scanned,
        "candidate_count": len(candidates),
        "candidates": picked,
    }
    if kind:
        result["kind"] = kind
    if notes:
        result["note"] = "; ".join(notes)
    return result


def main():
    if len(sys.argv) < 2:
        die("missing base64-encoded arguments")
    try:
        args = json.loads(base64.b64decode(sys.argv[1]).decode("utf-8"))
    except Exception as exc:
        die("invalid arguments: " + str(exc))

    tool = args.get("tool")
    params = args.get("params") or {}

    dbs = glob.glob("/var/lib/finance-summary/actual-cache/*/db.sqlite")
    if len(dbs) != 1:
        die("expected exactly one budget db under actual-cache, found " + str(len(dbs)))
    db_path = dbs[0]
    synced_at = datetime.fromtimestamp(
        os.path.getmtime(db_path), timezone.utc
    ).isoformat(timespec="seconds")

    all_txns = load(db_path)
    if tool == "get_transactions":
        result = tool_get_transactions(all_txns, params)
    elif tool == "find_recurring":
        result = tool_find_recurring(all_txns, params)
    else:
        die("unknown tool: " + str(tool))
        return

    result["cache_synced_at"] = synced_at
    result["live_transactions"] = len(all_txns)
    print(json.dumps(result, separators=(",", ":")))


try:
    main()
except Exception as exc:
    die(type(exc).__name__ + ": " + str(exc))
