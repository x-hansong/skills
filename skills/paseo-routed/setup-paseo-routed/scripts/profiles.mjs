#!/usr/bin/env node
// Safe read-modify-write for Paseo agent profiles.
//
// `paseo daemon config set daemon.agentProfiles <json>` replaces the whole
// array, so passing only the new profile would delete every other one. This
// script reads the current array, merges by profile name, writes the full
// array back, then re-reads and verifies nothing else changed.
//
//   node profiles.mjs backup  [--home <dir>]
//   node profiles.mjs upsert  --file <profiles.json> [--home <dir>] [--dry-run]
//
// <profiles.json> is an array of profiles. Each needs `name` and, when new,
// `provider`. An entry whose name already exists is merged into that profile
// (its id is kept); otherwise it is appended with a generated id.

import { execFileSync } from "node:child_process";
import { copyFileSync, existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { isDeepStrictEqual } from "node:util";
import { randomBytes } from "node:crypto";

function parseArgs(argv) {
  const [command, ...rest] = argv;
  const opts = { command, home: join(homedir(), ".paseo"), dryRun: false };
  for (let i = 0; i < rest.length; i++) {
    const arg = rest[i];
    if (arg === "--home") opts.home = resolve(rest[++i]);
    else if (arg === "--file") opts.file = resolve(rest[++i]);
    else if (arg === "--dry-run") opts.dryRun = true;
    else fail(`unknown argument: ${arg}`);
  }
  return opts;
}

function fail(message, extra = {}) {
  process.stderr.write(JSON.stringify({ ok: false, error: message, ...extra }, null, 2) + "\n");
  process.exit(1);
}

function paseo(home, args) {
  // execFileSync with an argument array: no shell, so profile JSON is never interpreted.
  return execFileSync("paseo", ["daemon", "config", ...args, "--home", home, "--json"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function readProfiles(home) {
  const out = JSON.parse(paseo(home, ["get", "daemon.agentProfiles"]));
  if (!out.set) return [];
  if (!Array.isArray(out.value)) fail("daemon.agentProfiles is not an array", { value: out.value });
  return out.value;
}

function backup(home) {
  const config = join(home, "config.json");
  if (!existsSync(config)) return null;
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const target = join(home, `config.json.bak-paseo-routed-${stamp}`);
  copyFileSync(config, target);
  return target;
}

function newId() {
  return `agent_profile_${Date.now().toString(36)}_${randomBytes(7).toString("hex")}`;
}

function merge(before, incoming) {
  const after = before.map((p) => ({ ...p }));
  const changes = [];
  for (const entry of incoming) {
    if (!entry || typeof entry.name !== "string" || !entry.name) fail("every profile needs a name", { entry });
    const { id: _ignored, ...fields } = entry;
    const index = after.findIndex((p) => p.name === entry.name);
    if (index >= 0) {
      const changed = Object.keys(fields).filter((k) => !isDeepStrictEqual(after[index][k], fields[k]));
      if (changed.length) {
        after[index] = { ...after[index], ...fields };
        changes.push({ action: "update", name: entry.name, fields: changed });
      }
    } else {
      if (typeof fields.provider !== "string" || !fields.provider) fail("a new profile needs a provider", { entry });
      after.push({ id: newId(), ...fields });
      changes.push({ action: "add", name: entry.name });
    }
  }
  return { after, changes };
}

function verify(before, expected, actual) {
  const problems = [];
  if (actual.length !== expected.length) problems.push(`expected ${expected.length} profiles, found ${actual.length}`);
  for (const want of expected) {
    const got = actual.find((p) => p.id === want.id);
    if (!got) problems.push(`profile missing after write: ${want.name} (${want.id})`);
    else if (!isDeepStrictEqual(got, want)) problems.push(`profile differs after write: ${want.name}`);
  }
  const untouched = before.filter((b) => expected.some((e) => isDeepStrictEqual(e, b)));
  return { problems, untouched: untouched.length };
}

const opts = parseArgs(process.argv.slice(2));

if (opts.command === "backup") {
  console.log(JSON.stringify({ ok: true, backup: backup(opts.home) }, null, 2));
} else if (opts.command === "upsert") {
  if (!opts.file) fail("--file is required");
  const incoming = JSON.parse(readFileSync(opts.file, "utf8"));
  if (!Array.isArray(incoming)) fail("--file must contain a JSON array of profiles");

  const before = readProfiles(opts.home);
  const { after, changes } = merge(before, incoming);
  const plan = { home: opts.home, before: before.length, after: after.length, changes };

  if (opts.dryRun || changes.length === 0) {
    console.log(JSON.stringify({ ok: true, dryRun: opts.dryRun, ...plan }, null, 2));
    process.exit(0);
  }

  const backupPath = backup(opts.home);
  const rollback = backupPath
    ? `cp '${backupPath}' '${join(opts.home, "config.json")}' && paseo daemon reload --home '${opts.home}'`
    : null;

  let setResult;
  try {
    setResult = JSON.parse(paseo(opts.home, ["set", "daemon.agentProfiles", JSON.stringify(after)]));
  } catch (error) {
    // A failed reload still leaves the file saved, so verify before deciding.
    setResult = { warning: String(error.stderr || error.message).trim() };
  }

  const actual = readProfiles(opts.home);
  const { problems, untouched } = verify(before, after, actual);
  const report = { ...plan, backup: backupPath, rollback, set: setResult, unchangedProfiles: untouched };
  if (problems.length) fail("verification failed after write; roll back with the command below", { ...report, problems });
  console.log(JSON.stringify({ ok: true, ...report }, null, 2));
} else {
  fail("usage: profiles.mjs backup|upsert [--home <dir>] [--file <profiles.json>] [--dry-run]");
}
