#!/usr/bin/env node
import { createServer } from "node:http";
import { createReadStream, existsSync, readFileSync } from "node:fs";
import { join, resolve, sep } from "node:path";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";

const args = {};
for (let i = 0; i < process.argv.length - 1; i++) {
  if (process.argv[i].startsWith("--")) args[process.argv[i].slice(2)] = process.argv[i + 1];
}

const root = resolve(args.root || ".");
const port = Number(args.port) || 31215;
const configPath = resolve(args.config || "");
const userOverridePath = args["user-config"] || join(homedir(), ".config", "pi-pet", "config.json");

const MIME = {
  ".webm": "video/webm",
  ".png": "image/png",
  ".ttf": "font/ttf",
  ".json": "application/json; charset=utf-8",
};

function deepMerge(base, over) {
  if (over === undefined) return base;
  if (
    Array.isArray(base) || Array.isArray(over) ||
    typeof base !== "object" || typeof over !== "object" ||
    base === null || over === null
  ) {
    return over;
  }
  const out = { ...base };
  for (const k of Object.keys(over)) out[k] = deepMerge(base[k], over[k]);
  return out;
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function send(res, code, body, type = "application/json; charset=utf-8") {
  res.writeHead(code, {
    "content-type": type,
    "access-control-allow-origin": "*",
    "cache-control": "no-store",
  });
  res.end(typeof body === "string" ? body : JSON.stringify(body));
}

function serveFile(res, dir, rel) {
  const target = resolve(join(dir, rel));
  if (!target.startsWith(resolve(dir) + sep)) {
    send(res, 403, { error: "forbidden" });
    return;
  }
  if (!existsSync(target)) {
    send(res, 404, { error: "not found" });
    return;
  }
  const i = target.lastIndexOf(".");
  const type = MIME[i === -1 ? "" : target.slice(i)] || "application/octet-stream";
  res.writeHead(200, {
    "content-type": type,
    "access-control-allow-origin": "*",
    "cache-control": "public, max-age=3600",
  });
  createReadStream(target).pipe(res);
}

const baseConfig = JSON.parse(readFileSync(configPath, "utf8"));
const fileWhispers = args.whispers ? JSON.parse(readFileSync(args.whispers, "utf8")) : [];
const userOverride = existsSync(userOverridePath)
  ? await readFile(userOverridePath, "utf8").then(JSON.parse).catch(() => ({}))
  : {};

const config = deepMerge(baseConfig, userOverride);
const whispers = Array.isArray(userOverride.whispers) ? userOverride.whispers : fileWhispers;

const server = createServer((req, res) => {
  let pathname;
  try {
    pathname = decodeURIComponent(new URL(req.url, "http://127.0.0.1").pathname);
  } catch {
    send(res, 400, { error: "bad request" });
    return;
  }

  if (req.method === "OPTIONS") {
    send(res, 204, "");
    return;
  }

  if (pathname === "/dsh-pet-7340/config") {
    send(res, 200, config);
    return;
  }
  if (pathname === "/dsh-pet-7340/config/meta") {
    send(res, 200, {
      user: "managed by NixOS (piAgentPlugins)",
      default: "managed by NixOS (piAgentPlugins)",
      animations: "managed by NixOS (piAgentPlugins)",
    });
    return;
  }
  const thumb = pathname.match(/^\/dsh-pet-7340\/thumb\/[^/]+\/(.+)$/);
  if (thumb) {
    serveFile(res, join(root, "assets", "webm"), thumb[1]);
    return;
  }
  const font = pathname.match(/^\/dsh-pet-7340\/font\/(.+)$/);
  if (font) {
    serveFile(res, join(root, "assets", "fonts"), font[1]);
    return;
  }
  const pic = pathname.match(/^\/dsh-pet-7340\/pic\/(.+)$/);
  if (pic) {
    serveFile(res, join(root, "assets", "pic"), pic[1]);
    return;
  }
  if (pathname === "/dsh-pet-7340/whisper" || pathname === "/dsh-pet-7340/whisper/trigger") {
    if (!whispers.length) {
      send(res, 200, { ok: false, reason: "provider-missing" });
      return;
    }
    send(res, 200, { ok: true, text: pick(whispers), ts: Date.now() });
    return;
  }
  if (pathname === "/dsh-pet-7340/chat") {
    send(res, 200, { ok: false, reason: "provider-missing" });
    return;
  }
  if (pathname === "/dsh-pet-7340/balance" || pathname === "/dsh-pet-7340/balance/trigger") {
    send(res, 200, { ok: false, reason: "unsupported" });
    return;
  }
  if (pathname === "/dsh-pet-7340/broadcast") {
    send(res, 200, { ts: 0, text: "" });
    return;
  }
  send(res, 404, { error: "not found" });
});

server.listen(port, "127.0.0.1", () => {
  console.log(`[pi-pet] host on http://127.0.0.1:${port}/dsh-pet-7340/config`);
});
