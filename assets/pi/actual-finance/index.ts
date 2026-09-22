import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SSH_TARGET = process.env.PI_ACTUAL_SSH ?? "server@nyx-nixos.vpn.olympus.moe";
const SCRIPT_PATH = join(
  dirname(fileURLToPath(import.meta.url)),
  "query.py",
);

function shellQuote(s: string): string {
  return "'" + s.replace(/'/g, "'\\''") + "'";
}

const FINANCE_TOOLS = ["get_transactions", "find_recurring"];

function scopeKey(names: string[]): string {
  return [...names].sort().join("\n");
}

export default function (pi: ExtensionAPI) {
  function applyModelScope(model?: { provider?: string } | null) {
    const all = pi.getAllTools();
    if (model?.provider !== "llama.cpp") {
      const restore = all
        .map((t) => t.name)
        .filter((name) => !FINANCE_TOOLS.includes(name));
      if (scopeKey(restore) !== scopeKey(pi.getActiveTools())) {
        pi.setActiveTools(restore);
      }
      return;
    }
    const keep = new Set(
      all
        .filter((t) => t.sourceInfo?.source === "builtin")
        .map((t) => t.name),
    );
    keep.add("bash");
    for (const name of FINANCE_TOOLS) keep.add(name);
    const slim = [...keep];
    if (scopeKey(slim) !== scopeKey(pi.getActiveTools())) {
      pi.setActiveTools(slim);
    }
  }

  pi.on("session_start", (_event, ctx) => {
    applyModelScope(ctx.model);
  });
  pi.on("model_select", (event) => {
    applyModelScope(event.model);
  });
  pi.on("before_agent_start", (event, ctx) => {
    if (ctx.model?.provider !== "llama.cpp") {
      applyModelScope(ctx.model);
      return;
    }
    applyModelScope(ctx.model);
    return {
      systemPrompt:
        event.systemPrompt +
        "\n\n## Actual budget access\n" +
        "You have read-only access to the user's Actual budget via the get_transactions and find_recurring tools. " +
        "For ANY question about spending, money, payees, accounts, subscriptions, bills, or budgets: call one of those tools first — never answer from memory or guess. " +
        "Recipe: narrow date range first (start_date/end_date), keep limit at 25, paginate with offset while total_matches exceeds the returned rows, " +
        "always report the cache_synced_at staleness, and relay statistics from find_recurring verbatim instead of recomputing them.\n\n" +
        "find_recurring tags every candidate with a kind (rent, utilities, internet, phone, insurance, streaming, subscription, ...) and sorts those bill kinds ahead of high-frequency noise — when asked about recurring bills, report the rent/utility/subscription candidates even when their occurrence counts are low, and pass kind to focus a query.\n\n" +
        "## Scope of work\n" +
        "Do not inspect, search, read, or reason about anything on the local machine — no file system digging, no repo exploration, no shell archaeology. " +
        "Your only job is to gather financial information with the tools provided above and report it. " +
        "If a question cannot be answered by get_transactions or find_recurring, say so plainly instead of exploring the local system.",
    };
  });

  function assertScope(ctx: { model?: { provider?: string } | null }) {
    if (ctx.model?.provider !== "llama.cpp") {
      throw new Error(
        "actual-finance tools are scoped to llama.cpp models only",
      );
    }
  }

  async function queryFinance(
    tool: string,
    params: Record<string, unknown>,
    signal?: AbortSignal,
  ): Promise<{ text: string; data: Record<string, unknown> }> {
    const payload = Buffer.from(JSON.stringify({ tool, params })).toString("base64");
    const cmd =
      "ssh -o BatchMode=yes -o ConnectTimeout=15 " +
      shellQuote(SSH_TARGET) +
      " python3 - " +
      shellQuote(payload) +
      " < " +
      shellQuote(SCRIPT_PATH);
    const res = await pi.exec("bash", ["-c", cmd], { signal, timeout: 30000 });
    if (res.code !== 0) {
      throw new Error(
        "actual-finance query failed (exit " +
          res.code +
          "): " +
          (res.stderr || res.stdout || "no output"),
      );
    }
    let data: Record<string, unknown>;
    try {
      data = JSON.parse(res.stdout);
    } catch {
      throw new Error("actual-finance returned invalid JSON: " + res.stdout.slice(0, 300));
    }
    return { text: JSON.stringify(data), data };
  }

  const sharedGuidelines = [
    "For any question mentioning money, spending, prices, transactions, payees, accounts, subscriptions, bills, or budgets, call get_transactions or find_recurring before answering — even if you think you know the answer.",
    "Never produce financial figures without a tool call; an answer without tool results is wrong.",
    "Use get_transactions and find_recurring for all information gathering; do not inspect the local file system or run shell commands to find financial data.",
    "Tool results share an 8192-token context: keep get_transactions limit at 25 or less, and only ask for larger results if the first page is insufficient; find_recurring is safe at its default min_occurrences 3 because bill kinds sort first.",
    "Every transaction row and find_recurring candidate carries a kind tag (rent, mortgage, utilities, internet, phone, insurance, streaming, subscription, fuel, income, other): the Actual category decides it when the category names a type (e.g. Rent, Utilities, Income), otherwise payee/bank-description keywords are the fallback. Both tools accept kind as an exact filter — when the question is about rent, utilities, subscriptions, or bills, filter with kind or lead with the matching candidates. If a kind looks wrong, the fix is recategorizing in Actual, not re-querying.",
    "Every get_transactions and find_recurring result reports cache_synced_at; if it predates recent bank activity, say so and suggest refreshing with `sudo systemctl start finance-summary.service` on nyx instead of guessing at fresh numbers.",
  ];

  pi.registerTool({
    name: "get_transactions",
    label: "Actual transactions",
    description:
      "Search the user's Actual budget transaction history, read-only, over ssh into the nyx cache. " +
      "Filters: payee substring, exact category name, exact account name, inclusive YYYY-MM-DD date range. " +
      "Returns newest-first JSON pages with total_matches, offset, limit (max 50 rows per call, default 25). " +
      "Keep pages small: results share an 8192-token model context, so prefer limit of 25 or less. " +
      "Amounts are currency units already divided for you: negative = money out, positive = money in. " +
      "Every row is tagged with a kind (rent, mortgage, utilities, internet, phone, insurance, streaming, subscription, fuel, income, other) derived from the Actual category first with bank keywords as fallback; pass kind to filter by it. " +
      "Split transactions are expanded to their parts; tombstoned rows are excluded. " +
      "Each result includes cache_synced_at (when the budget was last synced) and live_transactions.",
    promptSnippet: "Look up Actual budget transactions or detect recurring payments",
    promptGuidelines: [
      "Use get_transactions for any question about spending, purchases, payees, accounts, or transaction dates in the Actual budget; amounts are precomputed (negative = money out) — never sum or average rows yourself, and keep calling with offset while total_matches is larger than returned.",
      ...sharedGuidelines,
    ],
    parameters: Type.Object({
      payee_contains: Type.Optional(
        Type.String({ description: "Case-insensitive substring match on payee name" }),
      ),
      category: Type.Optional(
        Type.String({ description: "Exact category name, e.g. Groceries" }),
      ),
      account: Type.Optional(
        Type.String({ description: "Exact account name, e.g. Checking" }),
      ),
      kind: Type.Optional(
        Type.String({
          description:
            "Exact type tag: rent, mortgage, utilities, internet, phone, insurance, streaming, subscription, fuel, income, other",
        }),
      ),
      start_date: Type.Optional(Type.String({ description: "YYYY-MM-DD, inclusive" })),
      end_date: Type.Optional(Type.String({ description: "YYYY-MM-DD, inclusive" })),
      limit: Type.Optional(
        Type.Number({ description: "Rows per page, 1-50, default 25" }),
      ),
      offset: Type.Optional(
        Type.Number({ description: "Pagination offset, default 0" }),
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      assertScope(ctx);
      const { text, data } = await queryFinance(
        "get_transactions",
        params as Record<string, unknown>,
        signal,
      );
      return {
        content: [{ type: "text", text }],
        details: data,
      };
    },
  });

  pi.registerTool({
    name: "find_recurring",
    label: "Find recurring transactions",
    description:
      "Deterministically detect likely recurring transactions (subscriptions, bills) in the user's Actual budget: " +
      "groups non-transfer transactions into per-payee amount streams — a payee with two fixed recurring charges (e.g. rent + fee) yields one candidate per stream with its own cadence, while variable-amount bills (utilities) merge into a single group — " +
      "requires each stream to appear on N distinct dates (min_occurrences, " +
      "default 3, max 24), and reports occurrence count, cadence, median interval, first/last dates, and " +
      "fixed or min/max/avg amounts. Candidates are tagged with a kind (rent, mortgage, utilities, internet, phone, insurance, streaming, subscription, fuel, income, other) — derived from the Actual category first, with payee/bank-description keywords only as fallback — " +
      "and sorted with bill-like kinds first, then by occurrence count, so monthly rent and utilities surface ahead of daily/weekly noise; pass kind to filter. " +
      "Returns the top 12 candidates (raise with limit, max 40) " +
      "plus candidate_count for the true total, rows_scanned and cache_synced_at. Candidates whose amounts spread wider than 1.5x their median are discarded as non-recurring (varied one-off purchases like game-store charges) and a note reports how many were removed. All statistics are computed in code — narrate them, never recompute. Results are compact JSON; respect the 8192-token context.",
    promptSnippet: "Detect recurring payments (subscriptions/bills) with computed cadence",
    promptGuidelines: [
      "Use find_recurring when asked about subscriptions, bills, rent, utilities, or repeating payments; cadence statistics are computed for you — do not scan get_transactions pages looking for repetition yourself. Bill-like kinds sort first, so rent and utilities appear near the top even with few occurrences; pass kind (e.g. 'utilities') to focus, and lower min_occurrences to 2 only for bills with short history.",
      ...sharedGuidelines,
    ],
    parameters: Type.Object({
      min_occurrences: Type.Optional(
        Type.Number({ description: "Minimum distinct dates per payee, default 3, max 24" }),
      ),
      limit: Type.Optional(
        Type.Number({ description: "Candidates to return, 1-40, default 12" }),
      ),
      kind: Type.Optional(
        Type.String({
          description:
            "Exact type tag: rent, mortgage, utilities, internet, phone, insurance, streaming, subscription, fuel, income, other",
        }),
      ),
      start_date: Type.Optional(Type.String({ description: "YYYY-MM-DD, inclusive" })),
      end_date: Type.Optional(Type.String({ description: "YYYY-MM-DD, inclusive" })),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      assertScope(ctx);
      const { text, data } = await queryFinance(
        "find_recurring",
        params as Record<string, unknown>,
        signal,
      );
      return {
        content: [{ type: "text", text }],
        details: data,
      };
    },
  });
}
