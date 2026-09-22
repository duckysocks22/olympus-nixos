#!/usr/bin/env node
import fs from "node:fs/promises";
import os from "node:os";
import { join } from "node:path";
import * as api from "@actual-app/api";

for (const key of ["ACTUAL_PASSWORD", "ACTUAL_SYNC_ID"]) {
  if (!process.env[key]) {
    throw new Error(`missing required env var: ${key}`);
  }
}

const actualUrl = process.env.ACTUAL_SERVER_URL ?? "http://localhost:5006";
const cacheDir =
  process.env.ACTUAL_CACHE_DIR ??
  join(os.homedir(), ".cache", "finance-summary", "actual-cache");
const llamaBase = process.env.LLAMA_BASE_URL ?? "http://127.0.0.1:5387/v1";

function shiftMonth(month, delta) {
  const [y, m] = month.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1 + delta, 1)).toISOString().slice(0, 7);
}

const month =
  process.env.SUMMARY_MONTH ??
  shiftMonth(new Date().toISOString().slice(0, 7), -1);

await fs.mkdir(cacheDir, { recursive: true });

await api.init({
  dataDir: cacheDir,
  serverURL: actualUrl,
  password: process.env.ACTUAL_PASSWORD,
});
await api.downloadBudget(process.env.ACTUAL_SYNC_ID);

const budget = await api.getBudgetMonth(month);
if (!Array.isArray(budget.categoryGroups) || budget.categoryGroups.length === 0) {
  throw new Error(
    `no categoryGroups returned for ${month}; keys: ${Object.keys(budget).join(", ")}`,
  );
}
const flatten = (b) => (b.categoryGroups ?? []).flatMap((g) => g.categories ?? []);
const expenseCats = flatten(budget).filter(
  (c) =>
    typeof c.budgeted === "number" &&
    typeof c.spent === "number" &&
    typeof c.balance === "number",
);
if (expenseCats.length === 0) {
  throw new Error(`no expense categories returned for ${month}`);
}
const previous = await api.getBudgetMonth(shiftMonth(month, -1));
const prevById = new Map(flatten(previous).map((c) => [c.id, c]));

const figures = expenseCats.map((c) => {
  const p = prevById.get(c.id);
  const spentNow = -c.spent / 100;
  const spentPrev =
    p && typeof p.spent === "number" ? -p.spent / 100 : null;
  return {
    category: c.name,
    budgeted: Number((c.budgeted / 100).toFixed(2)),
    spent: Number(spentNow.toFixed(2)),
    remaining: Number((c.balance / 100).toFixed(2)),
    change_vs_prev_month:
      spentPrev === null ? null : Number((spentNow - spentPrev).toFixed(2)),
  };
});

await api.shutdown();

let apiKey = process.env.LLAMA_API_KEY ?? "";
if (!apiKey && process.env.LLAMA_API_KEY_FILE) {
  apiKey = (await fs.readFile(process.env.LLAMA_API_KEY_FILE, "utf8"))
    .split("\n")[0]
    .trim();
}

const headers = {
  "Content-Type": "application/json",
  ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}),
};

let model = process.env.LLAMA_MODEL;
if (!model) {
  const listRes = await fetch(`${llamaBase}/models`, { headers });
  if (!listRes.ok) {
    throw new Error(`GET /models failed: ${listRes.status} ${await listRes.text()}`);
  }
  const list = await listRes.json();
  model = list.data?.[0]?.id;
  if (!model) {
    throw new Error("llama-server /v1/models returned no model id");
  }
}

const res = await fetch(`${llamaBase}/chat/completions`, {
  method: "POST",
  headers,
  body: JSON.stringify({
    model,
    messages: [
      {
        role: "system",
        content:
          "You write concise monthly budget summaries. All figures are precomputed and authoritative: narrate them, never recalculate or invent numbers. Amounts are in the budget's currency.",
      },
      {
        role: "user",
        content: `Budget data for ${month} vs ${shiftMonth(month, -1)} (JSON):\n${JSON.stringify(figures, null, 2)}\n\nWrite a summary of about 150 words: the biggest overruns, the wins, and notable changes from the previous month.`,
      },
    ],
  }),
});
if (!res.ok) {
  throw new Error(`chat completion failed: ${res.status} ${await res.text()}`);
}
const out = await res.json();
const text = out.choices?.[0]?.message?.content;
if (!text) {
  throw new Error(`empty completion: ${JSON.stringify(out).slice(0, 500)}`);
}
console.log(text);
