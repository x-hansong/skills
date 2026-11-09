---
name: native-routed-guide-cc
description: "Guide to the native-routed skill set for Claude Code (no Paseo): which of native-routed-cc, native-implement-routed-cc, native-implement-spec-routed-cc or native-watch-cc fits a situation, which models play worker, reviewer and committee and how to change them, and a guided first run. Use when the user asks how to use routed or delegated execution in Claude Code without Paseo, which native-routed skill to pick, or is getting started."
license: MIT
compatibility: "Claude Code only. Uses native-routed-setup-cc for its readiness check."
metadata:
  author: x-hansong
---

# Native Routed guide (Claude Code)

Help the user pick and use the right native-routed skill. Reply in the user's language. For a Chinese-speaking user, use the `.zh-CN.md` versions of the references.

Before telling the user what a skill does, read that skill's `SKILL.md`. The summaries here are for orientation only.

## 1. Check readiness first

Load the `native-routed-setup-cc` skill in **check-only** mode (its `check` argument) and show its table. If any row the user's goal needs is not ✅, explain what's missing in one or two sentences and offer `/native-routed-setup-cc` to fix it. Don't walk through a first run on a machine that isn't ready.

## 2. Answer the question

Use [scenarios](references/scenarios.md) ([中文](references/scenarios.zh-CN.md)) to:

- pick the skill for the user's situation;
- explain which models play each role and how to change them;
- answer common questions.

Keep the answer to what the user asked; offer the rest.

## 3. Offer a guided first run

When the user is new, offer a small, safe first run in the current repo: a read-only research task through `native-routed-cc`, for example "explain how <some module> works and where its tests are". Walk through what happens as it happens: model resolution, the notes directory and `session.json`, the worker dispatch, acceptance. Afterwards show where the notes ended up.

Only run it when the user agrees; it starts real subagents that cost tokens.
